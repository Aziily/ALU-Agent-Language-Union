preamble __init__:
  source: jwt/__init__.py
  body: |
    from .api_jwk import PyJWK, PyJWKSet
    from .api_jws import PyJWS, get_algorithm_by_name, get_unverified_header, register_algorithm, unregister_algorithm
    from .api_jwt import PyJWT, decode, encode
    from .exceptions import DecodeError, ExpiredSignatureError, ImmatureSignatureError, InvalidAlgorithmError, InvalidAudienceError, InvalidIssuedAtError, InvalidIssuerError, InvalidKeyError, InvalidSignatureError, InvalidTokenError, MissingRequiredClaimError, PyJWKClientConnectionError, PyJWKClientError, PyJWKError, PyJWKSetError, PyJWTError
    from .jwks_client import PyJWKClient
    __version__ = '2.8.0'
    __title__ = 'PyJWT'
    __description__ = 'JSON Web Token implementation in Python'
    __url__ = 'https://pyjwt.readthedocs.io'
    __uri__ = __url__
    __doc__ = f'{__description__} <{__uri__}>'
    __author__ = 'José Padilla'
    __email__ = 'hello@jpadilla.com'
    __license__ = 'MIT'
    __copyright__ = 'Copyright 2015-2022 José Padilla'
    __all__ = ['PyJWS', 'PyJWT', 'PyJWKClient', 'PyJWK', 'PyJWKSet', 'decode', 'encode', 'get_unverified_header', 'register_algorithm', 'unregister_algorithm', 'get_algorithm_by_name', 'DecodeError', 'ExpiredSignatureError', 'ImmatureSignatureError', 'InvalidAlgorithmError', 'InvalidAudienceError', 'InvalidIssuedAtError', 'InvalidIssuerError', 'InvalidKeyError', 'InvalidSignatureError', 'InvalidTokenError', 'MissingRequiredClaimError', 'PyJWKClientConnectionError', 'PyJWKClientError', 'PyJWKError', 'PyJWKSetError', 'PyJWTError']


preamble algorithms:
  source: jwt/algorithms.py
  body: |
    from __future__ import annotations
    import hashlib
    import hmac
    import json
    import sys
    from abc import ABC, abstractmethod
    from typing import TYPE_CHECKING, Any, ClassVar, NoReturn, Union, cast, overload
    from .exceptions import InvalidKeyError
    from .types import HashlibHash, JWKDict
    from .utils import base64url_decode, base64url_encode, der_to_raw_signature, force_bytes, from_base64url_uint, is_pem_format, is_ssh_key, raw_to_der_signature, to_base64url_uint
    if sys.version_info >= (3, 8):
        from typing import Literal
    else:
        from typing_extensions import Literal
    try:
        from cryptography.exceptions import InvalidSignature
        from cryptography.hazmat.backends import default_backend
        from cryptography.hazmat.primitives import hashes
        from cryptography.hazmat.primitives.asymmetric import padding
        from cryptography.hazmat.primitives.asymmetric.ec import ECDSA, SECP256K1, SECP256R1, SECP384R1, SECP521R1, EllipticCurve, EllipticCurvePrivateKey, EllipticCurvePrivateNumbers, EllipticCurvePublicKey, EllipticCurvePublicNumbers
        from cryptography.hazmat.primitives.asymmetric.ed448 import Ed448PrivateKey, Ed448PublicKey
        from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey, Ed25519PublicKey
        from cryptography.hazmat.primitives.asymmetric.rsa import RSAPrivateKey, RSAPrivateNumbers, RSAPublicKey, RSAPublicNumbers, rsa_crt_dmp1, rsa_crt_dmq1, rsa_crt_iqmp, rsa_recover_prime_factors
        from cryptography.hazmat.primitives.serialization import Encoding, NoEncryption, PrivateFormat, PublicFormat, load_pem_private_key, load_pem_public_key, load_ssh_public_key
        has_crypto = True
    except ModuleNotFoundError:
        has_crypto = False
    if TYPE_CHECKING:
        AllowedRSAKeys = RSAPrivateKey | RSAPublicKey
        AllowedECKeys = EllipticCurvePrivateKey | EllipticCurvePublicKey
        AllowedOKPKeys = Ed25519PrivateKey | Ed25519PublicKey | Ed448PrivateKey | Ed448PublicKey
        AllowedKeys = AllowedRSAKeys | AllowedECKeys | AllowedOKPKeys
        AllowedPrivateKeys = RSAPrivateKey | EllipticCurvePrivateKey | Ed25519PrivateKey | Ed448PrivateKey
        AllowedPublicKeys = RSAPublicKey | EllipticCurvePublicKey | Ed25519PublicKey | Ed448PublicKey
    requires_cryptography = {'RS256', 'RS384', 'RS512', 'ES256', 'ES256K', 'ES384', 'ES521', 'ES512', 'PS256', 'PS384', 'PS512', 'EdDSA'}
    class Algorithm(ABC):
        """
        The interface for an algorithm used to sign and verify tokens.
        """

        def compute_hash_digest(self, bytestr: bytes) -> bytes:
            """
            Compute a hash digest using the specified algorithm's hash algorithm.

            If there is no hash algorithm, raises a NotImplementedError.
            """
            pass

        @abstractmethod
        def prepare_key(self, key: Any) -> Any:
            """
            Performs necessary validation and conversions on the key and returns
            the key value in the proper format for sign() and verify().
            """
            pass

        @abstractmethod
        def sign(self, msg: bytes, key: Any) -> bytes:
            """
            Returns a digital signature for the specified message
            using the specified key value.
            """
            pass

        @abstractmethod
        def verify(self, msg: bytes, key: Any, sig: bytes) -> bool:
            """
            Verifies that the specified digital signature is valid
            for the specified message and key values.
            """
            pass

        @staticmethod
        @abstractmethod
        def to_jwk(key_obj, as_dict: bool=False) -> Union[JWKDict, str]:
            """
            Serializes a given key into a JWK
            """
            pass

        @staticmethod
        @abstractmethod
        def from_jwk(jwk: str | JWKDict) -> Any:
            """
            Deserializes a given key from JWK back into a key object
            """
            pass
    class NoneAlgorithm(Algorithm):
        """
        Placeholder for use when no signing or verification
        operations are required.
        """
    class HMACAlgorithm(Algorithm):
        """
        Performs signing and verification operations using HMAC
        and the specified hash function.
        """
        SHA256: ClassVar[HashlibHash] = hashlib.sha256
        SHA384: ClassVar[HashlibHash] = hashlib.sha384
        SHA512: ClassVar[HashlibHash] = hashlib.sha512

        def __init__(self, hash_alg: HashlibHash) -> None:
            self.hash_alg = hash_alg
    if has_crypto:

        class RSAAlgorithm(Algorithm):
            """
            Performs signing and verification operations using
            RSASSA-PKCS-v1_5 and the specified hash function.
            """
            SHA256: ClassVar[type[hashes.HashAlgorithm]] = hashes.SHA256
            SHA384: ClassVar[type[hashes.HashAlgorithm]] = hashes.SHA384
            SHA512: ClassVar[type[hashes.HashAlgorithm]] = hashes.SHA512

            def __init__(self, hash_alg: type[hashes.HashAlgorithm]) -> None:
                self.hash_alg = hash_alg

        class ECAlgorithm(Algorithm):
            """
            Performs signing and verification operations using
            ECDSA and the specified hash function
            """
            SHA256: ClassVar[type[hashes.HashAlgorithm]] = hashes.SHA256
            SHA384: ClassVar[type[hashes.HashAlgorithm]] = hashes.SHA384
            SHA512: ClassVar[type[hashes.HashAlgorithm]] = hashes.SHA512

            def __init__(self, hash_alg: type[hashes.HashAlgorithm]) -> None:
                self.hash_alg = hash_alg

        class RSAPSSAlgorithm(RSAAlgorithm):
            """
            Performs a signature using RSASSA-PSS with MGF1
            """

        class OKPAlgorithm(Algorithm):
            """
            Performs signing and verification operations using EdDSA

            This class requires ``cryptography>=2.6`` to be installed.
            """

            def __init__(self, **kwargs: Any) -> None:
                pass

            def sign(self, msg: str | bytes, key: Ed25519PrivateKey | Ed448PrivateKey) -> bytes:
                """
                Sign a message ``msg`` using the EdDSA private key ``key``
                :param str|bytes msg: Message to sign
                :param Ed25519PrivateKey}Ed448PrivateKey key: A :class:`.Ed25519PrivateKey`
                    or :class:`.Ed448PrivateKey` isinstance
                :return bytes signature: The signature, as bytes
                """
                pass

            def verify(self, msg: str | bytes, key: AllowedOKPKeys, sig: str | bytes) -> bool:
                """
                Verify a given ``msg`` against a signature ``sig`` using the EdDSA key ``key``

                :param str|bytes sig: EdDSA signature to check ``msg`` against
                :param str|bytes msg: Message to sign
                :param Ed25519PrivateKey|Ed25519PublicKey|Ed448PrivateKey|Ed448PublicKey key:
                    A private or public EdDSA key instance
                :return bool verified: True if signature is valid, False if not.
                """
                pass


preamble api_jwk:
  source: jwt/api_jwk.py
  body: |
    from __future__ import annotations
    import json
    import time
    from typing import Any
    from .algorithms import get_default_algorithms, has_crypto, requires_cryptography
    from .exceptions import InvalidKeyError, PyJWKError, PyJWKSetError, PyJWTError
    from .types import JWKDict
    class PyJWK:

        def __init__(self, jwk_data: JWKDict, algorithm: str | None=None) -> None:
            self._algorithms = get_default_algorithms()
            self._jwk_data = jwk_data
            kty = self._jwk_data.get('kty', None)
            if not kty:
                raise InvalidKeyError(f'kty is not found: {self._jwk_data}')
            if not algorithm and isinstance(self._jwk_data, dict):
                algorithm = self._jwk_data.get('alg', None)
            if not algorithm:
                crv = self._jwk_data.get('crv', None)
                if kty == 'EC':
                    if crv == 'P-256' or not crv:
                        algorithm = 'ES256'
                    elif crv == 'P-384':
                        algorithm = 'ES384'
                    elif crv == 'P-521':
                        algorithm = 'ES512'
                    elif crv == 'secp256k1':
                        algorithm = 'ES256K'
                    else:
                        raise InvalidKeyError(f'Unsupported crv: {crv}')
                elif kty == 'RSA':
                    algorithm = 'RS256'
                elif kty == 'oct':
                    algorithm = 'HS256'
                elif kty == 'OKP':
                    if not crv:
                        raise InvalidKeyError(f'crv is not found: {self._jwk_data}')
                    if crv == 'Ed25519':
                        algorithm = 'EdDSA'
                    else:
                        raise InvalidKeyError(f'Unsupported crv: {crv}')
                else:
                    raise InvalidKeyError(f'Unsupported kty: {kty}')
            if not has_crypto and algorithm in requires_cryptography:
                raise PyJWKError(f"{algorithm} requires 'cryptography' to be installed.")
            self.Algorithm = self._algorithms.get(algorithm)
            if not self.Algorithm:
                raise PyJWKError(f'Unable to find an algorithm for key: {self._jwk_data}')
            self.key = self.Algorithm.from_jwk(self._jwk_data)
    class PyJWKSet:

        def __init__(self, keys: list[JWKDict]) -> None:
            self.keys = []
            if not keys:
                raise PyJWKSetError('The JWK Set did not contain any keys')
            if not isinstance(keys, list):
                raise PyJWKSetError('Invalid JWK Set value')
            for key in keys:
                try:
                    self.keys.append(PyJWK(key))
                except PyJWTError:
                    continue
            if len(self.keys) == 0:
                raise PyJWKSetError("The JWK Set did not contain any usable keys. Perhaps 'cryptography' is not installed?")

        def __getitem__(self, kid: str) -> 'PyJWK':
            for key in self.keys:
                if key.key_id == kid:
                    return key
            raise KeyError(f'keyset has no key for kid: {kid}')
    class PyJWTSetWithTimestamp:

        def __init__(self, jwk_set: PyJWKSet):
            self.jwk_set = jwk_set
            self.timestamp = time.monotonic()


preamble api_jws:
  source: jwt/api_jws.py
  body: |
    from __future__ import annotations
    import binascii
    import json
    import warnings
    from typing import TYPE_CHECKING, Any
    from .algorithms import Algorithm, get_default_algorithms, has_crypto, requires_cryptography
    from .exceptions import DecodeError, InvalidAlgorithmError, InvalidSignatureError, InvalidTokenError
    from .utils import base64url_decode, base64url_encode
    from .warnings import RemovedInPyjwt3Warning
    if TYPE_CHECKING:
        from .algorithms import AllowedPrivateKeys, AllowedPublicKeys
    class PyJWS:
        header_typ = 'JWT'

        def __init__(self, algorithms: list[str] | None=None, options: dict[str, Any] | None=None) -> None:
            self._algorithms = get_default_algorithms()
            self._valid_algs = set(algorithms) if algorithms is not None else set(self._algorithms)
            for key in list(self._algorithms.keys()):
                if key not in self._valid_algs:
                    del self._algorithms[key]
            if options is None:
                options = {}
            self.options = {**self._get_default_options(), **options}

        def register_algorithm(self, alg_id: str, alg_obj: Algorithm) -> None:
            """
            Registers a new Algorithm for use when creating and verifying tokens.
            """
            pass

        def unregister_algorithm(self, alg_id: str) -> None:
            """
            Unregisters an Algorithm for use when creating and verifying tokens
            Throws KeyError if algorithm is not registered.
            """
            pass

        def get_algorithms(self) -> list[str]:
            """
            Returns a list of supported values for the 'alg' parameter.
            """
            pass

        def get_algorithm_by_name(self, alg_name: str) -> Algorithm:
            """
            For a given string name, return the matching Algorithm object.

            Example usage:

            >>> jws_obj.get_algorithm_by_name("RS256")
            """
            pass

        def get_unverified_header(self, jwt: str | bytes) -> dict[str, Any]:
            """Returns back the JWT header parameters as a dict()

            Note: The signature is not verified so the header parameters
            should not be fully trusted until signature verification is complete
            """
            pass
    _jws_global_obj = PyJWS()
    encode = _jws_global_obj.encode
    decode_complete = _jws_global_obj.decode_complete
    decode = _jws_global_obj.decode
    register_algorithm = _jws_global_obj.register_algorithm
    unregister_algorithm = _jws_global_obj.unregister_algorithm
    get_algorithm_by_name = _jws_global_obj.get_algorithm_by_name
    get_unverified_header = _jws_global_obj.get_unverified_header


preamble api_jwt:
  source: jwt/api_jwt.py
  body: |
    from __future__ import annotations
    import json
    import warnings
    from calendar import timegm
    from collections.abc import Iterable
    from datetime import datetime, timedelta, timezone
    from typing import TYPE_CHECKING, Any
    from . import api_jws
    from .exceptions import DecodeError, ExpiredSignatureError, ImmatureSignatureError, InvalidAudienceError, InvalidIssuedAtError, InvalidIssuerError, MissingRequiredClaimError
    from .warnings import RemovedInPyjwt3Warning
    if TYPE_CHECKING:
        from .algorithms import AllowedPrivateKeys, AllowedPublicKeys
    class PyJWT:

        def __init__(self, options: dict[str, Any] | None=None) -> None:
            if options is None:
                options = {}
            self.options: dict[str, Any] = {**self._get_default_options(), **options}

        def _encode_payload(self, payload: dict[str, Any], headers: dict[str, Any] | None=None, json_encoder: type[json.JSONEncoder] | None=None) -> bytes:
            """
            Encode a given payload to the bytes to be signed.

            This method is intended to be overridden by subclasses that need to
            encode the payload in a different way, e.g. compress the payload.
            """
            pass

        def _decode_payload(self, decoded: dict[str, Any]) -> Any:
            """
            Decode the payload from a JWS dictionary (payload, signature, header).

            This method is intended to be overridden by subclasses that need to
            decode the payload in a different way, e.g. decompress compressed
            payloads.
            """
            pass
    _jwt_global_obj = PyJWT()
    encode = _jwt_global_obj.encode
    decode_complete = _jwt_global_obj.decode_complete
    decode = _jwt_global_obj.decode


preamble exceptions:
  source: jwt/exceptions.py
  body: |
    class PyJWTError(Exception):
        """
        Base class for all exceptions
        """
        pass
    class InvalidTokenError(PyJWTError):
        pass
    class DecodeError(InvalidTokenError):
        pass
    class InvalidSignatureError(DecodeError):
        pass
    class ExpiredSignatureError(InvalidTokenError):
        pass
    class InvalidAudienceError(InvalidTokenError):
        pass
    class InvalidIssuerError(InvalidTokenError):
        pass
    class InvalidIssuedAtError(InvalidTokenError):
        pass
    class ImmatureSignatureError(InvalidTokenError):
        pass
    class InvalidKeyError(PyJWTError):
        pass
    class InvalidAlgorithmError(InvalidTokenError):
        pass
    class MissingRequiredClaimError(InvalidTokenError):

        def __init__(self, claim: str) -> None:
            self.claim = claim

        def __str__(self) -> str:
            return f'Token is missing the "{self.claim}" claim'
    class PyJWKError(PyJWTError):
        pass
    class PyJWKSetError(PyJWTError):
        pass
    class PyJWKClientError(PyJWTError):
        pass
    class PyJWKClientConnectionError(PyJWKClientError):
        pass


preamble help:
  source: jwt/help.py
  body: |
    import json
    import platform
    import sys
    from typing import Dict
    from . import __version__ as pyjwt_version
    try:
        import cryptography
        cryptography_version = cryptography.__version__
    except ModuleNotFoundError:
        cryptography_version = ''
    if __name__ == '__main__':
        main()


preamble jwk_set_cache:
  source: jwt/jwk_set_cache.py
  body: |
    import time
    from typing import Optional
    from .api_jwk import PyJWKSet, PyJWTSetWithTimestamp
    class JWKSetCache:

        def __init__(self, lifespan: int) -> None:
            self.jwk_set_with_timestamp: Optional[PyJWTSetWithTimestamp] = None
            self.lifespan = lifespan


preamble jwks_client:
  source: jwt/jwks_client.py
  body: |
    import json
    import urllib.request
    from functools import lru_cache
    from ssl import SSLContext
    from typing import Any, Dict, List, Optional
    from urllib.error import URLError
    from .api_jwk import PyJWK, PyJWKSet
    from .api_jwt import decode_complete as decode_token
    from .exceptions import PyJWKClientConnectionError, PyJWKClientError
    from .jwk_set_cache import JWKSetCache
    class PyJWKClient:

        def __init__(self, uri: str, cache_keys: bool=False, max_cached_keys: int=16, cache_jwk_set: bool=True, lifespan: int=300, headers: Optional[Dict[str, Any]]=None, timeout: int=30, ssl_context: Optional[SSLContext]=None):
            if headers is None:
                headers = {}
            self.uri = uri
            self.jwk_set_cache: Optional[JWKSetCache] = None
            self.headers = headers
            self.timeout = timeout
            self.ssl_context = ssl_context
            if cache_jwk_set:
                if lifespan <= 0:
                    raise PyJWKClientError(f'Lifespan must be greater than 0, the input is "{lifespan}"')
                self.jwk_set_cache = JWKSetCache(lifespan)
            else:
                self.jwk_set_cache = None
            if cache_keys:
                self.get_signing_key = lru_cache(maxsize=max_cached_keys)(self.get_signing_key)


preamble types:
  source: jwt/types.py
  body: |
    from typing import Any, Callable, Dict
    JWKDict = Dict[str, Any]
    HashlibHash = Callable[..., Any]


preamble utils:
  source: jwt/utils.py
  body: |
    import base64
    import binascii
    import re
    from typing import Union
    try:
        from cryptography.hazmat.primitives.asymmetric.ec import EllipticCurve
        from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature, encode_dss_signature
    except ModuleNotFoundError:
        pass
    _PEMS = {b'CERTIFICATE', b'TRUSTED CERTIFICATE', b'PRIVATE KEY', b'PUBLIC KEY', b'ENCRYPTED PRIVATE KEY', b'OPENSSH PRIVATE KEY', b'DSA PRIVATE KEY', b'RSA PRIVATE KEY', b'RSA PUBLIC KEY', b'EC PRIVATE KEY', b'DH PARAMETERS', b'NEW CERTIFICATE REQUEST', b'CERTIFICATE REQUEST', b'SSH2 PUBLIC KEY', b'SSH2 ENCRYPTED PRIVATE KEY', b'X509 CRL'}
    _PEM_RE = re.compile(b'----[- ]BEGIN (' + b'|'.join(_PEMS) + b')[- ]----\r?\n.+?\r?\n----[- ]END \\1[- ]----\r?\n?', re.DOTALL)
    _CERT_SUFFIX = b'-cert-v01@openssh.com'
    _SSH_PUBKEY_RC = re.compile(b'\\A(\\S+)[ \\t]+(\\S+)')
    _SSH_KEY_FORMATS = [b'ssh-ed25519', b'ssh-rsa', b'ssh-dss', b'ecdsa-sha2-nistp256', b'ecdsa-sha2-nistp384', b'ecdsa-sha2-nistp521']


preamble warnings:
  source: jwt/warnings.py
  body: |
    class RemovedInPyjwt3Warning(DeprecationWarning):
        pass


flow pyjwt_lib:
  steps:
    - algorithms_group
    - api_jws_group
    - api_jwt_group
    - help_group


flow algorithms_group:
  steps:
    - get_default_algorithms
    - Algorithm__compute_hash_digest
    - Algorithm__prepare_key
    - Algorithm__sign
    - Algorithm__verify
    - Algorithm__to_jwk
    - Algorithm__from_jwk


flow api_jws_group:
  steps:
    - PyJWS__register_algorithm
    - PyJWS__unregister_algorithm
    - PyJWS__get_algorithms
    - PyJWS__get_algorithm_by_name
    - PyJWS__get_unverified_header


flow api_jwt_group:
  steps:
    - PyJWT___encode_payload
    - PyJWT___decode_payload


flow help_group:
  steps:
    - info
    - main


code get_default_algorithms:
  body: |
    def get_default_algorithms():
        """
        Returns the algorithms that are implemented by the library.
        
        """
        pass


code Algorithm__compute_hash_digest:
  body: |
    def compute_hash_digest(self, bytestr: bytes):
        """
            Compute a hash digest using the specified algorithm's hash algorithm.
    
            If there is no hash algorithm, raises a NotImplementedError.
            
        """
        pass


code Algorithm__prepare_key:
  body: |
    def prepare_key(self, key: Any):
        """
            Performs necessary validation and conversions on the key and returns
            the key value in the proper format for sign() and verify().
            
        """
        pass


code Algorithm__sign:
  body: |
    def sign(self, msg: bytes, key: Any):
        """
            Returns a digital signature for the specified message
            using the specified key value.
            
        """
        pass


code Algorithm__verify:
  body: |
    def verify(self, msg: bytes, key: Any, sig: bytes):
        """
            Verifies that the specified digital signature is valid
            for the specified message and key values.
            
        """
        pass


code Algorithm__to_jwk:
  body: |
    def to_jwk(key_obj, as_dict: bool=False):
        """
            Serializes a given key into a JWK
            
        """
        pass


code Algorithm__from_jwk:
  body: |
    def from_jwk(jwk: str | JWKDict):
        """
            Deserializes a given key from JWK back into a key object
            
        """
        pass


code PyJWS__register_algorithm:
  body: |
    def register_algorithm(self, alg_id: str, alg_obj: Algorithm):
        """
            Registers a new Algorithm for use when creating and verifying tokens.
            
        """
        pass


code PyJWS__unregister_algorithm:
  body: |
    def unregister_algorithm(self, alg_id: str):
        """
            Unregisters an Algorithm for use when creating and verifying tokens
            Throws KeyError if algorithm is not registered.
            
        """
        pass


code PyJWS__get_algorithms:
  body: |
    def get_algorithms(self):
        """
            Returns a list of supported values for the 'alg' parameter.
            
        """
        pass


code PyJWS__get_algorithm_by_name:
  body: |
    def get_algorithm_by_name(self, alg_name: str):
        """
            For a given string name, return the matching Algorithm object.
    
            Example usage:
    
            >>> jws_obj.get_algorithm_by_name("RS256")
            
        """
        pass


code PyJWS__get_unverified_header:
  body: |
    def get_unverified_header(self, jwt: str | bytes):
        """Returns back the JWT header parameters as a dict()
    
            Note: The signature is not verified so the header parameters
            should not be fully trusted until signature verification is complete
            
        """
        pass


code PyJWT___encode_payload:
  body: |
    def _encode_payload(self, payload: dict[str, Any], headers: dict[str, Any] | None=None, json_encoder: type[json.JSONEncoder] | None=None):
        """
            Encode a given payload to the bytes to be signed.
    
            This method is intended to be overridden by subclasses that need to
            encode the payload in a different way, e.g. compress the payload.
            
        """
        pass


code PyJWT___decode_payload:
  body: |
    def _decode_payload(self, decoded: dict[str, Any]):
        """
            Decode the payload from a JWS dictionary (payload, signature, header).
    
            This method is intended to be overridden by subclasses that need to
            decode the payload in a different way, e.g. decompress compressed
            payloads.
            
        """
        pass


code info:
  body: |
    def info():
        """
        Generate information for a bug report.
        Based on the requests package help utility module.
        
        """
        pass


code main:
  body: |
    def main():
        """Pretty-print the bug information as JSON."""
        pass
