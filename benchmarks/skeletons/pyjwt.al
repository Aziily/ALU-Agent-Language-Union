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
    - help_main


code get_default_algorithms:
  body: |
    def get_default_algorithms():
        """Return the default supported algorithms registry."""
        pass


code Algorithm__compute_hash_digest:
  body: |
    def compute_hash_digest(self, bytestr: bytes):
        """Compute a hash digest using the specified algorithm's hash module."""
        pass


code Algorithm__prepare_key:
  body: |
    def prepare_key(self, key):
        """Performs necessary validation and conversions on the key and returns
        the key value in the proper format for sign() and verify().
        """
        pass


code Algorithm__sign:
  body: |
    def sign(self, msg: bytes, key):
        """Returns a digital signature for the specified message
        using the specified key value.
        """
        pass


code Algorithm__verify:
  body: |
    def verify(self, msg: bytes, key, sig: bytes):
        """Verifies that the specified digital signature is valid
        for the specified message and key values.
        """
        pass


code Algorithm__to_jwk:
  body: |
    def to_jwk(key_obj, as_dict: bool=False):
        """Serializes a given key into a JWK (returns string or dict)."""
        pass


code Algorithm__from_jwk:
  body: |
    def from_jwk(jwk):
        """Deserializes a given JWK string back into a key object."""
        pass


code PyJWS__register_algorithm:
  body: |
    def register_algorithm(self, alg_id: str, alg_obj):
        """Registers a new Algorithm for use when creating and verifying JWS."""
        pass


code PyJWS__unregister_algorithm:
  body: |
    def unregister_algorithm(self, alg_id: str):
        """Unregisters an Algorithm for use when creating and verifying JWS."""
        pass


code PyJWS__get_algorithms:
  body: |
    def get_algorithms(self):
        """Returns a list of supported values for the 'alg' parameter."""
        pass


code PyJWS__get_algorithm_by_name:
  body: |
    def get_algorithm_by_name(self, alg_name: str):
        """For a given string name, return the matching Algorithm object."""
        pass


code PyJWS__get_unverified_header:
  body: |
    def get_unverified_header(self, jwt):
        """Returns back the JWT header parameters as a dict().

        Note: The signature is not verified so the header parameters
        should not be fully trusted until signature verification is complete.
        """
        pass


code PyJWT___encode_payload:
  body: |
    def _encode_payload(self, payload, headers=None, json_encoder=None):
        """Encode a given payload to the bytes to be signed.

        This method is intended to be overridden by subclasses that need to
        encode the payload in a different way, e.g. compress the payload.
        """
        pass


code PyJWT___decode_payload:
  body: |
    def _decode_payload(self, decoded):
        """Decode the payload from a JWS dictionary (payload as bytes)
        to a dict (the JWT payload).
        """
        pass


code info:
  body: |
    def info():
        """Generate information for a bug report.

        Used by ``python -m jwt --help``.
        """
        pass


code help_main:
  body: |
    def main():
        """Pretty-print the bug information as JSON."""
        pass
