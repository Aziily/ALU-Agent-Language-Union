preamble __init__:
  source: imapclient/__init__.py
  body: |
    from .imapclient import *
    from .response_parser import *
    from .tls import *
    from .version import author as __author__
    from .version import version as __version__
    from .version import version_info


preamble config:
  source: imapclient/config.py
  body: |
    import argparse
    import configparser
    import json
    import os
    import ssl
    import urllib.parse
    import urllib.request
    from typing import Any, Callable, Dict, Optional, Tuple, TYPE_CHECKING, TypeVar
    import imapclient
    T = TypeVar('T')
    OAUTH2_REFRESH_URLS = {'imap.gmail.com': 'https://accounts.google.com/o/oauth2/token', 'imap.mail.yahoo.com': 'https://api.login.yahoo.com/oauth2/get_token'}
    _oauth2_cache: Dict[Tuple[str, str, str, str], str] = {}


preamble datetime_util:
  source: imapclient/datetime_util.py
  body: |
    import re
    from datetime import datetime
    from email.utils import parsedate_tz
    from .fixed_offset import FixedOffset
    _SHORT_MONTHS = ' Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec'.split(' ')
    _rfc822_dotted_time = re.compile('\\w+, ?\\d{1,2} \\w+ \\d\\d(\\d\\d)? \\d\\d?\\.\\d\\d?\\.\\d\\d?.*')


preamble exceptions:
  source: imapclient/exceptions.py
  body: |
    import imaplib
    IMAPClientError = imaplib.IMAP4.error
    IMAPClientAbortError = imaplib.IMAP4.abort
    IMAPClientReadOnlyError = imaplib.IMAP4.readonly
    class CapabilityError(IMAPClientError):
        """
        The command tried by the user needs a capability not installed
        on the IMAP server
        """
    class LoginError(IMAPClientError):
        """
        A connection has been established with the server but an error
        occurred during the authentication.
        """
    class IllegalStateError(IMAPClientError):
        """
        The command tried needs a different state to be executed. This
        means the user is not logged in or the command needs a folder to
        be selected.
        """
    class InvalidCriteriaError(IMAPClientError):
        """
        A command using a search criteria failed, probably due to a syntax
        error in the criteria string.
        """
    class ProtocolError(IMAPClientError):
        """The server replied with a response that violates the IMAP protocol."""


preamble fixed_offset:
  source: imapclient/fixed_offset.py
  body: |
    import datetime
    import time
    from typing import Optional
    ZERO = datetime.timedelta(0)
    class FixedOffset(datetime.tzinfo):
        """
        This class describes fixed timezone offsets in hours and minutes
        east from UTC
        """

        def __init__(self, minutes: float) -> None:
            self.__offset = datetime.timedelta(minutes=minutes)
            sign = '+'
            if minutes < 0:
                sign = '-'
            hours, remaining_mins = divmod(abs(minutes), 60)
            self.__name = '%s%02d%02d' % (sign, hours, remaining_mins)

        @classmethod
        def for_system(cls) -> 'FixedOffset':
            """Return a FixedOffset instance for the current working timezone and
            DST conditions.
            """
            pass


preamble imap4:
  source: imapclient/imap4.py
  body: |
    import imaplib
    import socket
    from typing import Optional
    class IMAP4WithTimeout(imaplib.IMAP4):

        def __init__(self, address: str, port: int, timeout: Optional[float]) -> None:
            self._timeout = timeout
            imaplib.IMAP4.__init__(self, address, port)


preamble imap_utf7:
  source: imapclient/imap_utf7.py
  body: |
    import binascii
    from typing import List, Union
    AMPERSAND_ORD = ord('&')
    DASH_ORD = ord('-')


preamble imapclient:
  source: imapclient/imapclient.py
  body: |
    import dataclasses
    import functools
    import imaplib
    import itertools
    import re
    import select
    import socket
    import ssl as ssl_lib
    import sys
    import warnings
    from datetime import date, datetime
    from logging import getLogger, LoggerAdapter
    from operator import itemgetter
    from typing import List, Optional
    from . import exceptions, imap4, response_lexer, tls
    from .datetime_util import datetime_to_INTERNALDATE, format_criteria_date
    from .imap_utf7 import decode as decode_utf7
    from .imap_utf7 import encode as encode_utf7
    from .response_parser import parse_fetch_response, parse_message_list, parse_response
    from .util import assert_imap_protocol, chunk, to_bytes, to_unicode
    if hasattr(select, 'poll'):
        POLL_SUPPORT = True
    else:
        POLL_SUPPORT = False
    logger = getLogger(__name__)
    __all__ = ['IMAPClient', 'SocketTimeout', 'DELETED', 'SEEN', 'ANSWERED', 'FLAGGED', 'DRAFT', 'RECENT']
    if 'XLIST' not in imaplib.Commands:
        imaplib.Commands['XLIST'] = ('NONAUTH', 'AUTH', 'SELECTED')
    if 'IDLE' not in imaplib.Commands:
        imaplib.Commands['IDLE'] = ('NONAUTH', 'AUTH', 'SELECTED')
    if 'STARTTLS' not in imaplib.Commands:
        imaplib.Commands['STARTTLS'] = ('NONAUTH',)
    if 'ID' not in imaplib.Commands:
        imaplib.Commands['ID'] = ('NONAUTH', 'AUTH', 'SELECTED')
    if 'UNSELECT' not in imaplib.Commands:
        imaplib.Commands['UNSELECT'] = ('AUTH', 'SELECTED')
    if 'ENABLE' not in imaplib.Commands:
        imaplib.Commands['ENABLE'] = ('AUTH',)
    if 'MOVE' not in imaplib.Commands:
        imaplib.Commands['MOVE'] = ('AUTH', 'SELECTED')
    DELETED = b'\\Deleted'
    SEEN = b'\\Seen'
    ANSWERED = b'\\Answered'
    FLAGGED = b'\\Flagged'
    DRAFT = b'\\Draft'
    RECENT = b'\\Recent'
    ALL = b'\\All'
    ARCHIVE = b'\\Archive'
    DRAFTS = b'\\Drafts'
    JUNK = b'\\Junk'
    SENT = b'\\Sent'
    TRASH = b'\\Trash'
    _POPULAR_PERSONAL_NAMESPACES = (('', ''), ('INBOX.', '.'))
    _POPULAR_SPECIAL_FOLDERS = {SENT: ('Sent', 'Sent Items', 'Sent items'), DRAFTS: ('Drafts',), ARCHIVE: ('Archive',), TRASH: ('Trash', 'Deleted Items', 'Deleted Messages', 'Deleted'), JUNK: ('Junk', 'Spam')}
    _RE_SELECT_RESPONSE = re.compile(b'\\[(?P<key>[A-Z-]+)( \\((?P<data>.*)\\))?\\]')
    class Namespace(tuple):

        def __new__(cls, personal, other, shared):
            return tuple.__new__(cls, (personal, other, shared))
        personal = property(itemgetter(0))
        other = property(itemgetter(1))
        shared = property(itemgetter(2))
    @dataclasses.dataclass
    class SocketTimeout:
        """Represents timeout configuration for an IMAP connection.

        :ivar connect: maximum time to wait for a connection attempt to remote server
        :ivar read: maximum time to wait for performing a read/write operation

        As an example, ``SocketTimeout(connect=15, read=60)`` will make the socket
        timeout if the connection takes more than 15 seconds to establish but
        read/write operations can take up to 60 seconds once the connection is done.
        """
        connect: float
        read: float
    @dataclasses.dataclass
    class MailboxQuotaRoots:
        """Quota roots associated with a mailbox.

        Represents the response of a GETQUOTAROOT command.

        :ivar mailbox: the mailbox
        :ivar quota_roots: list of quota roots associated with the mailbox
        """
        mailbox: str
        quota_roots: List[str]
    @dataclasses.dataclass
    class Quota:
        """Resource quota.

        Represents the response of a GETQUOTA command.

        :ivar quota_roots: the quota roots for which the limit apply
        :ivar resource: the resource being limited (STORAGE, MESSAGES...)
        :ivar usage: the current usage of the resource
        :ivar limit: the maximum allowed usage of the resource
        """
        quota_root: str
        resource: str
        usage: bytes
        limit: bytes
    class IMAPClient:
        """A connection to the IMAP server specified by *host* is made when
        this class is instantiated.

        *port* defaults to 993, or 143 if *ssl* is ``False``.

        If *use_uid* is ``True`` unique message UIDs be used for all calls
        that accept message ids (defaults to ``True``).

        If *ssl* is ``True`` (the default) a secure connection will be made.
        Otherwise an insecure connection over plain text will be
        established.

        If *ssl* is ``True`` the optional *ssl_context* argument can be
        used to provide an ``ssl.SSLContext`` instance used to
        control SSL/TLS connection parameters. If this is not provided a
        sensible default context will be used.

        If *stream* is ``True`` then *host* is used as the command to run
        to establish a connection to the IMAP server (defaults to
        ``False``). This is useful for exotic connection or authentication
        setups.

        Use *timeout* to specify a timeout for the socket connected to the
        IMAP server. The timeout can be either a float number, or an instance
        of :py:class:`imapclient.SocketTimeout`.

        * If a single float number is passed, the same timeout delay applies
          during the  initial connection to the server and for all future socket
          reads and writes.

        * In case of a ``SocketTimeout``, connection timeout and
          read/write operations can have distinct timeouts.

        * The default is ``None``, where no timeout is used.

        The *normalise_times* attribute specifies whether datetimes
        returned by ``fetch()`` are normalised to the local system time
        and include no timezone information (native), or are datetimes
        that include timezone information (aware). By default
        *normalise_times* is True (times are normalised to the local
        system time). This attribute can be changed between ``fetch()``
        calls if required.

        Can be used as a context manager to automatically close opened connections:

        >>> with IMAPClient(host="imap.foo.org") as client:
        ...     client.login("bar@foo.org", "passwd")

        """
        Error = exceptions.IMAPClientError
        AbortError = exceptions.IMAPClientAbortError
        ReadOnlyError = exceptions.IMAPClientReadOnlyError

        def __init__(self, host: str, port: int=None, use_uid: bool=True, ssl: bool=True, stream: bool=False, ssl_context: Optional[ssl_lib.SSLContext]=None, timeout: Optional[float]=None):
            if stream:
                if port is not None:
                    raise ValueError("can't set 'port' when 'stream' True")
                if ssl:
                    raise ValueError("can't use 'ssl' when 'stream' is True")
            elif port is None:
                port = ssl and 993 or 143
            if ssl and port == 143:
                logger.warning('Attempting to establish an encrypted connection to a port (143) often used for unencrypted connections')
            self.host = host
            self.port = port
            self.ssl = ssl
            self.ssl_context = ssl_context
            self.stream = stream
            self.use_uid = use_uid
            self.folder_encode = True
            self.normalise_times = True
            if not isinstance(timeout, SocketTimeout):
                timeout = SocketTimeout(timeout, timeout)
            self._timeout = timeout
            self._starttls_done = False
            self._cached_capabilities = None
            self._idle_tag = None
            self._imap = self._create_IMAP4()
            logger.debug('Connected to host %s over %s', self.host, 'SSL/TLS' if ssl else 'plain text')
            self._set_read_timeout()
            imaplib_logger = IMAPlibLoggerAdapter(getLogger('imapclient.imaplib'), {})
            self._imap.debug = 5
            self._imap._mesg = imaplib_logger.debug

        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc_val, exc_tb):
            """Logout and closes the connection when exiting the context manager.

            All exceptions during logout and connection shutdown are caught because
            an error here usually means the connection was already closed.
            """
            try:
                self.logout()
            except Exception:
                try:
                    self.shutdown()
                except Exception as e:
                    logger.info('Could not close the connection cleanly: %s', e)

        def socket(self):
            """Returns socket used to connect to server.

            The socket is provided for polling purposes only.
            It can be used in,
            for example, :py:meth:`selectors.BaseSelector.register`
            and :py:meth:`asyncio.loop.add_reader` to wait for data.

            .. WARNING::
               All other uses of the returned socket are unsupported.
               This includes reading from and writing to the socket,
               as they are likely to break internal bookkeeping of messages.
            """
            pass

        @require_capability('STARTTLS')
        def starttls(self, ssl_context=None):
            """Switch to an SSL encrypted connection by sending a STARTTLS command.

            The *ssl_context* argument is optional and should be a
            :py:class:`ssl.SSLContext` object. If no SSL context is given, a SSL
            context with reasonable default settings will be used.

            You can enable checking of the hostname in the certificate presented
            by the server  against the hostname which was used for connecting, by
            setting the *check_hostname* attribute of the SSL context to ``True``.
            The default SSL context has this setting enabled.

            Raises :py:exc:`Error` if the SSL connection could not be established.

            Raises :py:exc:`AbortError` if the server does not support STARTTLS
            or an SSL connection is already established.
            """
            pass

        def login(self, username: str, password: str):
            """Login using *username* and *password*, returning the
            server response.
            """
            pass

        def oauth2_login(self, user: str, access_token: str, mech: str='XOAUTH2', vendor: Optional[str]=None):
            """Authenticate using the OAUTH2 or XOAUTH2 methods.

            Gmail and Yahoo both support the 'XOAUTH2' mechanism, but Yahoo requires
            the 'vendor' portion in the payload.
            """
            pass

        def oauthbearer_login(self, identity, access_token):
            """Authenticate using the OAUTHBEARER method.

            This is supported by Gmail and is meant to supersede the non-standard
            'OAUTH2' and 'XOAUTH2' mechanisms.
            """
            pass

        def plain_login(self, identity, password, authorization_identity=None):
            """Authenticate using the PLAIN method (requires server support)."""
            pass

        def sasl_login(self, mech_name, mech_callable):
            """Authenticate using a provided SASL mechanism (requires server support).

            The *mech_callable* will be called with one parameter (the server
            challenge as bytes) and must return the corresponding client response
            (as bytes, or as string which will be automatically encoded).

            It will be called as many times as the server produces challenges,
            which will depend on the specific SASL mechanism. (If the mechanism is
            defined as "client-first", the server will nevertheless produce a
            zero-length challenge.)

            For example, PLAIN has just one step with empty challenge, so a handler
            might look like this::

                plain_mech = lambda _: "\\0%s\\0%s" % (username, password)

                imap.sasl_login("PLAIN", plain_mech)

            A more complex but still stateless handler might look like this::

                def example_mech(challenge):
                    if challenge == b"Username:"
                        return username.encode("utf-8")
                    elif challenge == b"Password:"
                        return password.encode("utf-8")
                    else:
                        return b""

                imap.sasl_login("EXAMPLE", example_mech)

            A stateful handler might look like this::

                class ScramSha256SaslMechanism():
                    def __init__(self, username, password):
                        ...

                    def __call__(self, challenge):
                        self.step += 1
                        if self.step == 1:
                            response = ...
                        elif self.step == 2:
                            response = ...
                        return response

                scram_mech = ScramSha256SaslMechanism(username, password)

                imap.sasl_login("SCRAM-SHA-256", scram_mech)
            """
            pass

        def logout(self):
            """Logout, returning the server response."""
            pass

        def shutdown(self) -> None:
            """Close the connection to the IMAP server (without logging out)

            In most cases, :py:meth:`.logout` should be used instead of
            this. The logout method also shutdown down the connection.
            """
            pass

        @require_capability('ENABLE')
        def enable(self, *capabilities):
            """Activate one or more server side capability extensions.

            Most capabilities do not need to be enabled. This is only
            required for extensions which introduce backwards incompatible
            behaviour. Two capabilities which may require enable are
            ``CONDSTORE`` and ``UTF8=ACCEPT``.

            A list of the requested extensions that were successfully
            enabled on the server is returned.

            Once enabled each extension remains active until the IMAP
            connection is closed.

            See :rfc:`5161` for more details.
            """
            pass

        @require_capability('ID')
        def id_(self, parameters=None):
            """Issue the ID command, returning a dict of server implementation
            fields.

            *parameters* should be specified as a dictionary of field/value pairs,
            for example: ``{"name": "IMAPClient", "version": "0.12"}``
            """
            pass

        def capabilities(self):
            """Returns the server capability list.

            If the session is authenticated and the server has returned an
            untagged CAPABILITY response at authentication time, this
            response will be returned. Otherwise, the CAPABILITY command
            will be issued to the server, with the results cached for
            future calls.

            If the session is not yet authenticated, the capabilities
            requested at connection time will be returned.
            """
            pass

        def has_capability(self, capability):
            """Return ``True`` if the IMAP server has the given *capability*."""
            pass

        @require_capability('NAMESPACE')
        def namespace(self):
            """Return the namespace for the account as a (personal, other,
            shared) tuple.

            Each element may be None if no namespace of that type exists,
            or a sequence of (prefix, separator) pairs.

            For convenience the tuple elements may be accessed
            positionally or using attributes named *personal*, *other* and
            *shared*.

            See :rfc:`2342` for more details.
            """
            pass

        def list_folders(self, directory='', pattern='*'):
            """Get a listing of folders on the server as a list of
            ``(flags, delimiter, name)`` tuples.

            Specifying *directory* will limit returned folders to the
            given base directory. The directory and any child directories
            will returned.

            Specifying *pattern* will limit returned folders to those with
            matching names. The wildcards are supported in
            *pattern*. ``*`` matches zero or more of any character and
            ``%`` matches 0 or more characters except the folder
            delimiter.

            Calling list_folders with no arguments will recursively list
            all folders available for the logged in user.

            Folder names are always returned as unicode strings, and
            decoded from modified UTF-7, except if folder_decode is not
            set.
            """
            pass

        @require_capability('XLIST')
        def xlist_folders(self, directory='', pattern='*'):
            """Execute the XLIST command, returning ``(flags, delimiter,
            name)`` tuples.

            This method returns special flags for each folder and a
            localized name for certain folders (e.g. the name of the
            inbox may be localized and the flags can be used to
            determine the actual inbox, even if the name has been
            localized.

            A ``XLIST`` response could look something like::

                [((b'\\HasNoChildren', b'\\Inbox'), b'/', u'Inbox'),
                 ((b'\\Noselect', b'\\HasChildren'), b'/', u'[Gmail]'),
                 ((b'\\HasNoChildren', b'\\AllMail'), b'/', u'[Gmail]/All Mail'),
                 ((b'\\HasNoChildren', b'\\Drafts'), b'/', u'[Gmail]/Drafts'),
                 ((b'\\HasNoChildren', b'\\Important'), b'/', u'[Gmail]/Important'),
                 ((b'\\HasNoChildren', b'\\Sent'), b'/', u'[Gmail]/Sent Mail'),
                 ((b'\\HasNoChildren', b'\\Spam'), b'/', u'[Gmail]/Spam'),
                 ((b'\\HasNoChildren', b'\\Starred'), b'/', u'[Gmail]/Starred'),
                 ((b'\\HasNoChildren', b'\\Trash'), b'/', u'[Gmail]/Trash')]

            This is a *deprecated* Gmail-specific IMAP extension (See
            https://developers.google.com/gmail/imap_extensions#xlist_is_deprecated
            for more information).

            The *directory* and *pattern* arguments are as per
            list_folders().
            """
            pass

        def list_sub_folders(self, directory='', pattern='*'):
            """Return a list of subscribed folders on the server as
            ``(flags, delimiter, name)`` tuples.

            The default behaviour will list all subscribed folders. The
            *directory* and *pattern* arguments are as per list_folders().
            """
            pass

        def find_special_folder(self, folder_flag):
            """Try to locate a special folder, like the Sent or Trash folder.

            >>> server.find_special_folder(imapclient.SENT)
            'INBOX.Sent'

            This function tries its best to find the correct folder (if any) but
            uses heuristics when the server is unable to precisely tell where
            special folders are located.

            Returns the name of the folder if found, or None otherwise.
            """
            pass

        def select_folder(self, folder, readonly=False):
            """Set the current folder on the server.

            Future calls to methods such as search and fetch will act on
            the selected folder.

            Returns a dictionary containing the ``SELECT`` response. At least
            the ``b'EXISTS'``, ``b'FLAGS'`` and ``b'RECENT'`` keys are guaranteed
            to exist. An example::

                {b'EXISTS': 3,
                 b'FLAGS': (b'\\Answered', b'\\Flagged', b'\\Deleted', ... ),
                 b'RECENT': 0,
                 b'PERMANENTFLAGS': (b'\\Answered', b'\\Flagged', b'\\Deleted', ... ),
                 b'READ-WRITE': True,
                 b'UIDNEXT': 11,
                 b'UIDVALIDITY': 1239278212}
            """
            pass

        @require_capability('UNSELECT')
        def unselect_folder(self):
            """Unselect the current folder and release associated resources.

            Unlike ``close_folder``, the ``UNSELECT`` command does not expunge
            the mailbox, keeping messages with \\Deleted flag set for example.

            Returns the UNSELECT response string returned by the server.
            """
            pass

        def noop(self):
            """Execute the NOOP command.

            This command returns immediately, returning any server side
            status updates. It can also be used to reset any auto-logout
            timers.

            The return value is the server command response message
            followed by a list of status responses. For example::

                (b'NOOP completed.',
                 [(4, b'EXISTS'),
                  (3, b'FETCH', (b'FLAGS', (b'bar', b'sne'))),
                  (6, b'FETCH', (b'FLAGS', (b'sne',)))])

            """
            pass

        @require_capability('IDLE')
        def idle(self):
            """Put the server into IDLE mode.

            In this mode the server will return unsolicited responses
            about changes to the selected mailbox. This method returns
            immediately. Use ``idle_check()`` to look for IDLE responses
            and ``idle_done()`` to stop IDLE mode.

            .. note::

                Any other commands issued while the server is in IDLE
                mode will fail.

            See :rfc:`2177` for more information about the IDLE extension.
            """
            pass

        def _poll_socket(self, sock, timeout=None):
            """
            Polls the socket for events telling us it's available to read.
            This implementation is more scalable because it ALLOWS your process
            to have more than 1024 file descriptors.
            """
            pass

        def _select_poll_socket(self, sock, timeout=None):
            """
            Polls the socket for events telling us it's available to read.
            This implementation is a fallback because it FAILS if your process
            has more than 1024 file descriptors.
            We still need this for Windows and some other niche systems.
            """
            pass

        @require_capability('IDLE')
        def idle_check(self, timeout=None):
            """Check for any IDLE responses sent by the server.

            This method should only be called if the server is in IDLE
            mode (see ``idle()``).

            By default, this method will block until an IDLE response is
            received. If *timeout* is provided, the call will block for at
            most this many seconds while waiting for an IDLE response.

            The return value is a list of received IDLE responses. These
            will be parsed with values converted to appropriate types. For
            example::

                [(b'OK', b'Still here'),
                 (1, b'EXISTS'),
                 (1, b'FETCH', (b'FLAGS', (b'\\NotJunk',)))]
            """
            pass

        @require_capability('IDLE')
        def idle_done(self):
            """Take the server out of IDLE mode.

            This method should only be called if the server is already in
            IDLE mode.

            The return value is of the form ``(command_text,
            idle_responses)`` where *command_text* is the text sent by the
            server when the IDLE command finished (eg. ``b'Idle
            terminated'``) and *idle_responses* is a list of parsed idle
            responses received since the last call to ``idle_check()`` (if
            any). These are returned in parsed form as per
            ``idle_check()``.
            """
            pass

        def folder_status(self, folder, what=None):
            """Return the status of *folder*.

            *what* should be a sequence of status items to query. This
            defaults to ``('MESSAGES', 'RECENT', 'UIDNEXT', 'UIDVALIDITY',
            'UNSEEN')``.

            Returns a dictionary of the status items for the folder with
            keys matching *what*.
            """
            pass

        def close_folder(self):
            """Close the currently selected folder, returning the server
            response string.
            """
            pass

        def create_folder(self, folder):
            """Create *folder* on the server returning the server response string."""
            pass

        def rename_folder(self, old_name, new_name):
            """Change the name of a folder on the server."""
            pass

        def delete_folder(self, folder):
            """Delete *folder* on the server returning the server response string."""
            pass

        def folder_exists(self, folder):
            """Return ``True`` if *folder* exists on the server."""
            pass

        def subscribe_folder(self, folder):
            """Subscribe to *folder*, returning the server response string."""
            pass

        def unsubscribe_folder(self, folder):
            """Unsubscribe to *folder*, returning the server response string."""
            pass

        def search(self, criteria='ALL', charset=None):
            """Return a list of messages ids from the currently selected
            folder matching *criteria*.

            *criteria* should be a sequence of one or more criteria
            items. Each criteria item may be either unicode or
            bytes. Example values::

                [u'UNSEEN']
                [u'SMALLER', 500]
                [b'NOT', b'DELETED']
                [u'TEXT', u'foo bar', u'FLAGGED', u'SUBJECT', u'baz']
                [u'SINCE', date(2005, 4, 3)]

            IMAPClient will perform conversion and quoting as
            required. The caller shouldn't do this.

            It is also possible (but not recommended) to pass the combined
            criteria as a single string. In this case IMAPClient won't
            perform quoting, allowing lower-level specification of
            criteria. Examples of this style::

                u'UNSEEN'
                u'SMALLER 500'
                b'NOT DELETED'
                u'TEXT "foo bar" FLAGGED SUBJECT "baz"'
                b'SINCE 03-Apr-2005'

            To support complex search expressions, criteria lists can be
            nested. IMAPClient will insert parentheses in the right
            places. The following will match messages that are both not
            flagged and do not have "foo" in the subject::

                ['NOT', ['SUBJECT', 'foo', 'FLAGGED']]

            *charset* specifies the character set of the criteria. It
            defaults to US-ASCII as this is the only charset that a server
            is required to support by the RFC. UTF-8 is commonly supported
            however.

            Any criteria specified using unicode will be encoded as per
            *charset*. Specifying a unicode criteria that can not be
            encoded using *charset* will result in an error.

            Any criteria specified using bytes will be sent as-is but
            should use an encoding that matches *charset* (the character
            set given is still passed on to the server).

            See :rfc:`3501#section-6.4.4` for more details.

            Note that criteria arguments that are 8-bit will be
            transparently sent by IMAPClient as IMAP literals to ensure
            adherence to IMAP standards.

            The returned list of message ids will have a special *modseq*
            attribute. This is set if the server included a MODSEQ value
            to the search response (i.e. if a MODSEQ criteria was included
            in the search).

            """
            pass

        @require_capability('X-GM-EXT-1')
        def gmail_search(self, query, charset='UTF-8'):
            """Search using Gmail's X-GM-RAW attribute.

            *query* should be a valid Gmail search query string. For
            example: ``has:attachment in:unread``. The search string may
            be unicode and will be encoded using the specified *charset*
            (defaulting to UTF-8).

            This method only works for IMAP servers that support X-GM-RAW,
            which is only likely to be Gmail.

            See https://developers.google.com/gmail/imap_extensions#extension_of_the_search_command_x-gm-raw
            for more info.
            """
            pass

        @require_capability('SORT')
        def sort(self, sort_criteria, criteria='ALL', charset='UTF-8'):
            """Return a list of message ids from the currently selected
            folder, sorted by *sort_criteria* and optionally filtered by
            *criteria*.

            *sort_criteria* may be specified as a sequence of strings or a
            single string. IMAPClient will take care any required
            conversions. Valid *sort_criteria* values::

                ['ARRIVAL']
                ['SUBJECT', 'ARRIVAL']
                'ARRIVAL'
                'REVERSE SIZE'

            The *criteria* and *charset* arguments are as per
            :py:meth:`.search`.

            See :rfc:`5256` for full details.

            Note that SORT is an extension to the IMAP4 standard so it may
            not be supported by all IMAP servers.
            """
            pass

        def thread(self, algorithm='REFERENCES', criteria='ALL', charset='UTF-8'):
            """Return a list of messages threads from the currently
            selected folder which match *criteria*.

            Each returned thread is a list of messages ids. An example
            return value containing three message threads::

                ((1, 2), (3,), (4, 5, 6))

            The optional *algorithm* argument specifies the threading
            algorithm to use.

            The *criteria* and *charset* arguments are as per
            :py:meth:`.search`.

            See :rfc:`5256` for more details.
            """
            pass

        def get_flags(self, messages):
            """Return the flags set for each message in *messages* from
            the currently selected folder.

            The return value is a dictionary structured like this: ``{
            msgid1: (flag1, flag2, ... ), }``.
            """
            pass

        def add_flags(self, messages, flags, silent=False):
            """Add *flags* to *messages* in the currently selected folder.

            *flags* should be a sequence of strings.

            Returns the flags set for each modified message (see
            *get_flags*), or None if *silent* is true.
            """
            pass

        def remove_flags(self, messages, flags, silent=False):
            """Remove one or more *flags* from *messages* in the currently
            selected folder.

            *flags* should be a sequence of strings.

            Returns the flags set for each modified message (see
            *get_flags*), or None if *silent* is true.
            """
            pass

        def set_flags(self, messages, flags, silent=False):
            """Set the *flags* for *messages* in the currently selected
            folder.

            *flags* should be a sequence of strings.

            Returns the flags set for each modified message (see
            *get_flags*), or None if *silent* is true.
            """
            pass

        def get_gmail_labels(self, messages):
            """Return the label set for each message in *messages* in the
            currently selected folder.

            The return value is a dictionary structured like this: ``{
            msgid1: (label1, label2, ... ), }``.

            This only works with IMAP servers that support the X-GM-LABELS
            attribute (eg. Gmail).
            """
            pass

        def add_gmail_labels(self, messages, labels, silent=False):
            """Add *labels* to *messages* in the currently selected folder.

            *labels* should be a sequence of strings.

            Returns the label set for each modified message (see
            *get_gmail_labels*), or None if *silent* is true.

            This only works with IMAP servers that support the X-GM-LABELS
            attribute (eg. Gmail).
            """
            pass

        def remove_gmail_labels(self, messages, labels, silent=False):
            """Remove one or more *labels* from *messages* in the
            currently selected folder, or None if *silent* is true.

            *labels* should be a sequence of strings.

            Returns the label set for each modified message (see
            *get_gmail_labels*).

            This only works with IMAP servers that support the X-GM-LABELS
            attribute (eg. Gmail).
            """
            pass

        def set_gmail_labels(self, messages, labels, silent=False):
            """Set the *labels* for *messages* in the currently selected
            folder.

            *labels* should be a sequence of strings.

            Returns the label set for each modified message (see
            *get_gmail_labels*), or None if *silent* is true.

            This only works with IMAP servers that support the X-GM-LABELS
            attribute (eg. Gmail).
            """
            pass

        def delete_messages(self, messages, silent=False):
            """Delete one or more *messages* from the currently selected
            folder.

            Returns the flags set for each modified message (see
            *get_flags*).
            """
            pass

        def fetch(self, messages, data, modifiers=None):
            """Retrieve selected *data* associated with one or more
            *messages* in the currently selected folder.

            *data* should be specified as a sequence of strings, one item
            per data selector, for example ``['INTERNALDATE',
            'RFC822']``.

            *modifiers* are required for some extensions to the IMAP
            protocol (eg. :rfc:`4551`). These should be a sequence of strings
            if specified, for example ``['CHANGEDSINCE 123']``.

            A dictionary is returned, indexed by message number. Each item
            in this dictionary is also a dictionary, with an entry
            corresponding to each item in *data*. Returned values will be
            appropriately typed. For example, integer values will be returned as
            Python integers, timestamps will be returned as datetime
            instances and ENVELOPE responses will be returned as
            :py:class:`Envelope <imapclient.response_types.Envelope>` instances.

            String data will generally be returned as bytes (Python 3) or
            str (Python 2).

            In addition to an element for each *data* item, the dict
            returned for each message also contains a *SEQ* key containing
            the sequence number for the message. This allows for mapping
            between the UID and sequence number (when the *use_uid*
            property is ``True``).

            Example::

                >> c.fetch([3293, 3230], ['INTERNALDATE', 'FLAGS'])
                {3230: {b'FLAGS': (b'\\Seen',),
                        b'INTERNALDATE': datetime.datetime(2011, 1, 30, 13, 32, 9),
                        b'SEQ': 84},
                 3293: {b'FLAGS': (),
                        b'INTERNALDATE': datetime.datetime(2011, 2, 24, 19, 30, 36),
                        b'SEQ': 110}}

            """
            pass

        def append(self, folder, msg, flags=(), msg_time=None):
            """Append a message to *folder*.

            *msg* should be a string contains the full message including
            headers.

            *flags* should be a sequence of message flags to set. If not
            specified no flags will be set.

            *msg_time* is an optional datetime instance specifying the
            date and time to set on the message. The server will set a
            time if it isn't specified. If *msg_time* contains timezone
            information (tzinfo), this will be honoured. Otherwise the
            local machine's time zone sent to the server.

            Returns the APPEND response as returned by the server.
            """
            pass

        @require_capability('MULTIAPPEND')
        def multiappend(self, folder, msgs):
            """Append messages to *folder* using the MULTIAPPEND feature from :rfc:`3502`.

            *msgs* must be an iterable. Each item must be either a string containing the
            full message including headers, or a dict containing the keys "msg" with the
            full message as before, "flags" with a sequence of message flags to set, and
            "date" with a datetime instance specifying the internal date to set.
            The keys "flags" and "date" are optional.

            Returns the APPEND response from the server.
            """
            pass

        def copy(self, messages, folder):
            """Copy one or more messages from the current folder to
            *folder*. Returns the COPY response string returned by the
            server.
            """
            pass

        @require_capability('MOVE')
        def move(self, messages, folder):
            """Atomically move messages to another folder.

            Requires the MOVE capability, see :rfc:`6851`.

            :param messages: List of message UIDs to move.
            :param folder: The destination folder name.
            """
            pass

        def expunge(self, messages=None):
            """Use of the *messages* argument is discouraged.
            Please see the ``uid_expunge`` method instead.

            When, no *messages* are specified, remove all messages
            from the currently selected folder that have the
            ``\\Deleted`` flag set.

            The return value is the server response message
            followed by a list of expunge responses. For example::

                ('Expunge completed.',
                 [(2, 'EXPUNGE'),
                  (1, 'EXPUNGE'),
                  (0, 'RECENT')])

            In this case, the responses indicate that the message with
            sequence numbers 2 and 1 where deleted, leaving no recent
            messages in the folder.

            See :rfc:`3501#section-6.4.3` section 6.4.3 and
            :rfc:`3501#section-7.4.1` section 7.4.1 for more details.

            When *messages* are specified, remove the specified messages
            from the selected folder, provided those messages also have
            the ``\\Deleted`` flag set. The return value is ``None`` in
            this case.

            Expunging messages by id(s) requires that *use_uid* is
            ``True`` for the client.

            See :rfc:`4315#section-2.1` section 2.1 for more details.
            """
            pass

        @require_capability('UIDPLUS')
        def uid_expunge(self, messages):
            """Expunge deleted messages with the specified message ids from the
            folder.

            This requires the UIDPLUS capability.

            See :rfc:`4315#section-2.1` section 2.1 for more details.
            """
            pass

        @require_capability('ACL')
        def getacl(self, folder):
            """Returns a list of ``(who, acl)`` tuples describing the
            access controls for *folder*.
            """
            pass

        @require_capability('ACL')
        def setacl(self, folder, who, what):
            """Set an ACL (*what*) for user (*who*) for a folder.

            Set *what* to an empty string to remove an ACL. Returns the
            server response string.
            """
            pass

        @require_capability('QUOTA')
        def get_quota(self, mailbox='INBOX'):
            """Get the quotas associated with a mailbox.

            Returns a list of Quota objects.
            """
            pass

        @require_capability('QUOTA')
        def _get_quota(self, quota_root=''):
            """Get the quotas associated with a quota root.

            This method is not private but put behind an underscore to show that
            it is a low-level function. Users probably want to use `get_quota`
            instead.

            Returns a list of Quota objects.
            """
            pass

        @require_capability('QUOTA')
        def get_quota_root(self, mailbox):
            """Get the quota roots for a mailbox.

            The IMAP server responds with the quota root and the quotas associated
            so there is usually no need to call `get_quota` after.

            See :rfc:`2087` for more details.

            Return a tuple of MailboxQuotaRoots and list of Quota associated
            """
            pass

        @require_capability('QUOTA')
        def set_quota(self, quotas):
            """Set one or more quotas on resources.

            :param quotas: list of Quota objects
            """
            pass

        def _check_resp(self, expected, command, typ, data):
            """Check command responses for errors.

            Raises IMAPClient.Error if the command fails.
            """
            pass

        def _raw_command(self, command, args, uid=True):
            """Run the specific command with the arguments given. 8-bit arguments
            are sent as literals. The return value is (typ, data).

            This sidesteps much of imaplib's command sending
            infrastructure because imaplib can't send more than one
            literal.

            *command* should be specified as bytes.
            *args* should be specified as a list of bytes.
            """
            pass

        def _send_literal(self, tag, item):
            """Send a single literal for the command with *tag*."""
            pass

        def _store(self, cmd, messages, flags, fetch_key, silent):
            """Worker function for the various flag manipulation methods.

            *cmd* is the STORE command to use (eg. '+FLAGS').
            """
            pass

        @property
        def welcome(self):
            """access the server greeting message"""
            pass
    class _literal(bytes):
        """Hold message data that should always be sent as a literal."""
    class _quoted(bytes):
        """
        This class holds a quoted bytes value which provides access to the
        unquoted value via the *original* attribute.

        They should be created via the *maybe* classmethod.
        """

        @classmethod
        def maybe(cls, original):
            """Maybe quote a bytes value.

            If the input requires no quoting it is returned unchanged.

            If quoting is required a *_quoted* instance is returned. This
            holds the quoted version of the input while also providing
            access to the original unquoted source.
            """
            pass
    _not_present = object()
    class _dict_bytes_normaliser:
        """Wrap a dict with unicode/bytes keys and normalise the keys to
        bytes.
        """

        def __init__(self, d):
            self._d = d
        items = iteritems

        def __contains__(self, ink):
            for k in self._gen_keys(ink):
                if k in self._d:
                    return True
            return False
    class IMAPlibLoggerAdapter(LoggerAdapter):
        """Adapter preventing IMAP secrets from going to the logging facility."""


preamble interact:
  source: imapclient/interact.py
  body: |
    import argparse
    from getpass import getpass
    from . import imapclient
    from .config import create_client_from_config, get_config_defaults, parse_config_file
    if __name__ == '__main__':
        main()


preamble response_lexer:
  source: imapclient/response_lexer.py
  body: |
    '\nA lexical analyzer class for IMAP responses.\n\nAlthough Lexer does all the work, TokenSource is the class to use for\nexternal callers.\n'
    from typing import Iterator, List, Optional, Tuple, TYPE_CHECKING, Union
    from .util import assert_imap_protocol
    __all__ = ['TokenSource']
    CTRL_CHARS = frozenset((c for c in range(32)))
    ALL_CHARS = frozenset((c for c in range(256)))
    SPECIALS = frozenset((c for c in b' ()%"['))
    NON_SPECIALS = ALL_CHARS - SPECIALS - CTRL_CHARS
    WHITESPACE = frozenset((c for c in b' \t\r\n'))
    BACKSLASH = ord('\\')
    OPEN_SQUARE = ord('[')
    CLOSE_SQUARE = ord(']')
    DOUBLE_QUOTE = ord('"')
    class TokenSource:
        """
        A simple iterator for the Lexer class that also provides access to
        the current IMAP literal.
        """

        def __init__(self, text: List[bytes]):
            self.lex = Lexer(text)
            self.src = iter(self.lex)

        def __iter__(self) -> Iterator[bytes]:
            return self.src
    class Lexer:
        """
        A lexical analyzer class for IMAP
        """

        def __init__(self, text: List[bytes]):
            self.sources = (LiteralHandlingIter(chunk) for chunk in text)
            self.current_source: Optional[LiteralHandlingIter] = None

        def __iter__(self) -> Iterator[bytes]:
            for source in self.sources:
                self.current_source = source
                for tok in self.read_token_stream(iter(source)):
                    yield bytes(tok)
    class LiteralHandlingIter:

        def __init__(self, resp_record: Union[Tuple[bytes, bytes], bytes]):
            self.literal: Optional[bytes]
            if isinstance(resp_record, tuple):
                self.src_text = resp_record[0]
                assert_imap_protocol(self.src_text.endswith(b'}'), self.src_text)
                self.literal = resp_record[1]
            else:
                self.src_text = resp_record
                self.literal = None

        def __iter__(self) -> 'PushableIterator':
            return PushableIterator(self.src_text)
    class PushableIterator:
        NO_MORE = object()

        def __init__(self, it: bytes):
            self.it = iter(it)
            self.pushed: List[int] = []

        def __iter__(self) -> 'PushableIterator':
            return self

        def __next__(self) -> int:
            if self.pushed:
                return self.pushed.pop()
            return next(self.it)
        next = __next__


preamble response_parser:
  source: imapclient/response_parser.py
  body: |
    '\nParsing for IMAP command responses with focus on FETCH responses as\nreturned by imaplib.\n\nInitially inspired by http://effbot.org/zone/simple-iterator-parser.htm\n'
    import datetime
    import re
    import sys
    from collections import defaultdict
    from typing import cast, Dict, Iterator, List, Optional, Tuple, TYPE_CHECKING, Union
    from .datetime_util import parse_to_datetime
    from .exceptions import ProtocolError
    from .response_lexer import TokenSource
    from .response_types import Address, BodyData, Envelope, SearchIds
    from .typing_imapclient import _Atom
    __all__ = ['parse_response', 'parse_message_list']
    _msg_id_pattern = re.compile('(\\d+(?: +\\d+)*)')
    _ParseFetchResponseInnerDict = Dict[bytes, Optional[Union[datetime.datetime, int, BodyData, Envelope, _Atom]]]


preamble response_types:
  source: imapclient/response_types.py
  body: |
    import dataclasses
    import datetime
    from email.utils import formataddr
    from typing import Any, List, Optional, Tuple, TYPE_CHECKING, Union
    from .typing_imapclient import _Atom
    from .util import to_unicode
    @dataclasses.dataclass
    class Envelope:
        """Represents envelope structures of messages. Returned when parsing
        ENVELOPE responses.

        :ivar date: A datetime instance that represents the "Date" header.
        :ivar subject: A string that contains the "Subject" header.
        :ivar from\\_: A tuple of Address objects that represent one or more
          addresses from the "From" header, or None if header does not exist.
        :ivar sender: As for from\\_ but represents the "Sender" header.
        :ivar reply_to: As for from\\_ but represents the "Reply-To" header.
        :ivar to: As for from\\_ but represents the "To" header.
        :ivar cc: As for from\\_ but represents the "Cc" header.
        :ivar bcc: As for from\\_ but represents the "Bcc" recipients.
        :ivar in_reply_to: A string that contains the "In-Reply-To" header.
        :ivar message_id: A string that contains the "Message-Id" header.

        A particular issue to watch out for is IMAP's handling of "group
        syntax" in address fields. This is often encountered as a
        recipient header of the form::

            undisclosed-recipients:;

        but can also be expressed per this more general example::

            A group: a@example.com, B <b@example.org>;

        This example would yield the following Address tuples::

          Address(name=None, route=None, mailbox=u'A group', host=None)
          Address(name=None, route=None, mailbox=u'a', host=u'example.com')
          Address(name=u'B', route=None, mailbox=u'b', host=u'example.org')
          Address(name=None, route=None, mailbox=None, host=None)

        The first Address, where ``host`` is ``None``, indicates the start
        of the group. The ``mailbox`` field contains the group name. The
        final Address, where both ``mailbox`` and ``host`` are ``None``,
        indicates the end of the group.

        See :rfc:`3501#section-7.4.2` and :rfc:`2822` for further details.

        """
        date: Optional[datetime.datetime]
        subject: bytes
        from_: Optional[Tuple['Address', ...]]
        sender: Optional[Tuple['Address', ...]]
        reply_to: Optional[Tuple['Address', ...]]
        to: Optional[Tuple['Address', ...]]
        cc: Optional[Tuple['Address', ...]]
        bcc: Optional[Tuple['Address', ...]]
        in_reply_to: bytes
        message_id: bytes
    @dataclasses.dataclass
    class Address:
        """Represents electronic mail addresses. Used to store addresses in
        :py:class:`Envelope`.

        :ivar name: The address "personal name".
        :ivar route: SMTP source route (rarely used).
        :ivar mailbox: Mailbox name (what comes just before the @ sign).
        :ivar host: The host/domain name.

        As an example, an address header that looks like::

            Mary Smith <mary@foo.com>

        would be represented as::

            Address(name=u'Mary Smith', route=None, mailbox=u'mary', host=u'foo.com')

        See :rfc:`2822` for more detail.

        See also :py:class:`Envelope` for information about handling of
        "group syntax".
        """
        name: bytes
        route: bytes
        mailbox: bytes
        host: bytes

        def __str__(self) -> str:
            if self.mailbox and self.host:
                address = to_unicode(self.mailbox) + '@' + to_unicode(self.host)
            else:
                address = to_unicode(self.mailbox or self.host)
            return formataddr((to_unicode(self.name), address))
    class SearchIds(List[int]):
        """
        Contains a list of message ids as returned by IMAPClient.search().

        The *modseq* attribute will contain the MODSEQ value returned by
        the server (only if the SEARCH command sent involved the MODSEQ
        criteria). See :rfc:`4551` for more details.
        """

        def __init__(self, *args: Any):
            super().__init__(*args)
            self.modseq: Optional[int] = None
    _BodyDataType = Tuple[Union[bytes, int, 'BodyData'], '_BodyDataType']
    class BodyData(_BodyDataType):
        """
        Returned when parsing BODY and BODYSTRUCTURE responses.
        """


preamble testable_imapclient:
  source: imapclient/testable_imapclient.py
  body: |
    from typing import Any, Dict
    from unittest.mock import Mock
    from .imapclient import IMAPClient
    class TestableIMAPClient(IMAPClient):
        """Wrapper of :py:class:`imapclient.IMAPClient` that mocks all
        interaction with real IMAP server.

        This class should only be used in tests, where you can safely
        interact with imapclient without running commands on a real
        IMAP account.
        """

        def __init__(self) -> None:
            super().__init__('somehost')
    class MockIMAP4(Mock):

        def __init__(self, *args: Any, **kwargs: Any):
            super().__init__(*args, **kwargs)
            self.use_uid = True
            self.sent = b''
            self.tagged_commands: Dict[Any, Any] = {}
            self._starttls_done = False


preamble tls:
  source: imapclient/tls.py
  body: |
    "\nThis module contains IMAPClient's functionality related to Transport\nLayer Security (TLS a.k.a. SSL).\n"
    import imaplib
    import io
    import socket
    import ssl
    from typing import Optional, TYPE_CHECKING
    if TYPE_CHECKING:
        from typing_extensions import Buffer
    class IMAP4_TLS(imaplib.IMAP4):
        """IMAP4 client class for TLS/SSL connections.

        Adapted from imaplib.IMAP4_SSL.
        """

        def __init__(self, host: str, port: int, ssl_context: Optional[ssl.SSLContext], timeout: Optional[float]=None):
            self.ssl_context = ssl_context
            self._timeout = timeout
            imaplib.IMAP4.__init__(self, host, port)
            self.file: io.BufferedReader


preamble typing_imapclient:
  source: imapclient/typing_imapclient.py
  body: |
    from typing import Tuple, Union
    _AtomPart = Union[None, int, bytes]
    _Atom = Union[_AtomPart, Tuple['_Atom', ...]]


preamble util:
  source: imapclient/util.py
  body: |
    import logging
    from typing import Iterator, Optional, Tuple, Union
    from . import exceptions
    logger = logging.getLogger(__name__)
    _TupleAtomPart = Union[None, int, bytes]
    _TupleAtom = Tuple[Union[_TupleAtomPart, '_TupleAtom'], ...]


preamble version:
  source: imapclient/version.py
  body: |
    from typing import Tuple
    version_info = (3, 0, 1, 'final')
    version = _imapclient_version_string(version_info)
    maintainer = 'IMAPClient Maintainers'
    maintainer_email = 'imapclient@groups.io'
    author = 'Menno Finlay-Smits'
    author_email = 'inbox@menno.io'


flow imapclient_lib:
  steps:
    - config_group
    - datetime_util_group
    - fixed_offset_group
    - imap_utf7_group
    - imapclient_group
    - response_parser_group


flow config_group:
  steps:
    - parse_config_file


flow datetime_util_group:
  steps:
    - parse_to_datetime
    - datetime_to_INTERNALDATE
    - format_criteria_date


flow fixed_offset_group:
  steps:
    - FixedOffset__for_system


flow imap_utf7_group:
  steps:
    - encode
    - decode


flow imapclient_group:
  steps:
    - require_capability
    - IMAPClient__socket
    - IMAPClient__starttls
    - IMAPClient__login
    - IMAPClient__oauth2_login
    - IMAPClient__oauthbearer_login
    - IMAPClient__plain_login
    - IMAPClient__sasl_login
    - IMAPClient__logout
    - IMAPClient__shutdown
    - IMAPClient__enable
    - IMAPClient__id_
    - IMAPClient__capabilities
    - IMAPClient__has_capability
    - IMAPClient__namespace
    - IMAPClient__list_folders
    - IMAPClient__xlist_folders
    - IMAPClient__list_sub_folders
    - IMAPClient__find_special_folder
    - IMAPClient__select_folder
    - IMAPClient__unselect_folder
    - IMAPClient__noop
    - IMAPClient__idle
    - IMAPClient___poll_socket
    - IMAPClient___select_poll_socket
    - IMAPClient__idle_check
    - IMAPClient__idle_done
    - IMAPClient__folder_status
    - IMAPClient__close_folder
    - IMAPClient__create_folder
    - IMAPClient__rename_folder
    - IMAPClient__delete_folder
    - IMAPClient__folder_exists
    - IMAPClient__subscribe_folder
    - IMAPClient__unsubscribe_folder
    - IMAPClient__search
    - IMAPClient__gmail_search
    - IMAPClient__sort
    - IMAPClient__thread
    - IMAPClient__get_flags
    - IMAPClient__add_flags
    - IMAPClient__remove_flags
    - IMAPClient__set_flags
    - IMAPClient__get_gmail_labels
    - IMAPClient__add_gmail_labels
    - IMAPClient__remove_gmail_labels
    - IMAPClient__set_gmail_labels
    - IMAPClient__delete_messages
    - IMAPClient__fetch
    - IMAPClient__append
    - IMAPClient__multiappend
    - IMAPClient__copy
    - IMAPClient__move
    - IMAPClient__expunge
    - IMAPClient__uid_expunge
    - IMAPClient__getacl
    - IMAPClient__setacl
    - IMAPClient__get_quota
    - IMAPClient___get_quota
    - IMAPClient__get_quota_root
    - IMAPClient__set_quota
    - IMAPClient___check_resp
    - IMAPClient___raw_command
    - IMAPClient___send_literal
    - IMAPClient___store
    - IMAPClient__welcome
    - _quoted__maybe
    - join_message_ids


flow response_parser_group:
  steps:
    - parse_response
    - parse_message_list
    - parse_fetch_response


code parse_config_file:
  body: |
    def parse_config_file(filename: str):
        """Parse INI files containing IMAP connection details.
    
        Used by livetest.py and interact.py
        
        """
        pass


code parse_to_datetime:
  body: |
    def parse_to_datetime(timestamp: bytes, normalise: bool=True):
        """Convert an IMAP datetime string to a datetime.
    
        If normalise is True (the default), then the returned datetime
        will be timezone-naive but adjusted to the local time.
    
        If normalise is False, then the returned datetime will be
        unadjusted but will contain timezone information as per the input.
        
        """
        pass


code datetime_to_INTERNALDATE:
  body: |
    def datetime_to_INTERNALDATE(dt: datetime):
        """Convert a datetime instance to a IMAP INTERNALDATE string.
    
        If timezone information is missing the current system
        timezone is used.
        
        """
        pass


code format_criteria_date:
  body: |
    def format_criteria_date(dt: datetime):
        """Format a date or datetime instance for use in IMAP search criteria."""
        pass


code FixedOffset__for_system:
  body: |
    def for_system(cls):
        """Return a FixedOffset instance for the current working timezone and
            DST conditions.
            
        """
        pass


code encode:
  body: |
    def encode(s: Union[str, bytes]):
        """Encode a folder name using IMAP modified UTF-7 encoding.
    
        Input is unicode; output is bytes (Python 3) or str (Python 2). If
        non-unicode input is provided, the input is returned unchanged.
        
        """
        pass


code decode:
  body: |
    def decode(s: Union[bytes, str]):
        """Decode a folder name from IMAP modified UTF-7 encoding to unicode.
    
        Input is bytes (Python 3) or str (Python 2); output is always
        unicode. If non-bytes/str input is provided, the input is returned
        unchanged.
        
        """
        pass


code require_capability:
  body: |
    def require_capability(capability):
        """Decorator raising CapabilityError when a capability is not available."""
        pass


code IMAPClient__socket:
  body: |
    def socket(self):
        """Returns socket used to connect to server.
    
            The socket is provided for polling purposes only.
            It can be used in,
            for example, :py:meth:`selectors.BaseSelector.register`
            and :py:meth:`asyncio.loop.add_reader` to wait for data.
    
            .. WARNING::
               All other uses of the returned socket are unsupported.
               This includes reading from and writing to the socket,
               as they are likely to break internal bookkeeping of messages.
            
        """
        pass


code IMAPClient__starttls:
  body: |
    def starttls(self, ssl_context=None):
        """Switch to an SSL encrypted connection by sending a STARTTLS command.
    
            The *ssl_context* argument is optional and should be a
            :py:class:`ssl.SSLContext` object. If no SSL context is given, a SSL
            context with reasonable default settings will be used.
    
            You can enable checking of the hostname in the certificate presented
            by the server  against the hostname which was used for connecting, by
            setting the *check_hostname* attribute of the SSL context to ``True``.
            The default SSL context has this setting enabled.
    
            Raises :py:exc:`Error` if the SSL connection could not be established.
    
            Raises :py:exc:`AbortError` if the server does not support STARTTLS
            or an SSL connection is already established.
            
        """
        pass


code IMAPClient__login:
  body: |
    def login(self, username: str, password: str):
        """Login using *username* and *password*, returning the
            server response.
            
        """
        pass


code IMAPClient__oauth2_login:
  body: |
    def oauth2_login(self, user: str, access_token: str, mech: str='XOAUTH2', vendor: Optional[str]=None):
        """Authenticate using the OAUTH2 or XOAUTH2 methods.
    
            Gmail and Yahoo both support the 'XOAUTH2' mechanism, but Yahoo requires
            the 'vendor' portion in the payload.
            
        """
        pass


code IMAPClient__oauthbearer_login:
  body: |
    def oauthbearer_login(self, identity, access_token):
        """Authenticate using the OAUTHBEARER method.
    
            This is supported by Gmail and is meant to supersede the non-standard
            'OAUTH2' and 'XOAUTH2' mechanisms.
            
        """
        pass


code IMAPClient__plain_login:
  body: |
    def plain_login(self, identity, password, authorization_identity=None):
        """Authenticate using the PLAIN method (requires server support)."""
        pass


code IMAPClient__sasl_login:
  body: |
    def sasl_login(self, mech_name, mech_callable):
        """Authenticate using a provided SASL mechanism (requires server support).
    
            The *mech_callable* will be called with one parameter (the server
            challenge as bytes) and must return the corresponding client response
            (as bytes, or as string which will be automatically encoded).
    
            It will be called as many times as the server produces challenges,
            which will depend on the specific SASL mechanism. (If the mechanism is
            defined as "client-first", the server will nevertheless produce a
            zero-length challenge.)
    
            For example, PLAIN has just one step with empty challenge, so a handler
            might look like this::
    
                plain_mech = lambda _: "\0%s\0%s" % (username, password)
    
                imap.sasl_login("PLAIN", plain_mech)
    
            A more complex but still stateless handler might look like this::
    
                def example_mech(challenge):
                    if challenge == b"Username:"
                        return username.encode("utf-8")
                    elif challenge == b"Password:"
                        return password.encode("utf-8")
                    else:
                        return b""
    
                imap.sasl_login("EXAMPLE", example_mech)
    
            A stateful handler might look like this::
    
                class ScramSha256SaslMechanism():
                    def __init__(self, username, password):
                        ...
    
                    def __call__(self, challenge):
                        self.step += 1
                        if self.step == 1:
                            response = ...
                        elif self.step == 2:
                            response = ...
                        return response
    
                scram_mech = ScramSha256SaslMechanism(username, password)
    
                imap.sasl_login("SCRAM-SHA-256", scram_mech)
            
        """
        pass


code IMAPClient__logout:
  body: |
    def logout(self):
        """Logout, returning the server response."""
        pass


code IMAPClient__shutdown:
  body: |
    def shutdown(self):
        """Close the connection to the IMAP server (without logging out)
    
            In most cases, :py:meth:`.logout` should be used instead of
            this. The logout method also shutdown down the connection.
            
        """
        pass


code IMAPClient__enable:
  body: |
    def enable(self, *capabilities):
        """Activate one or more server side capability extensions.
    
            Most capabilities do not need to be enabled. This is only
            required for extensions which introduce backwards incompatible
            behaviour. Two capabilities which may require enable are
            ``CONDSTORE`` and ``UTF8=ACCEPT``.
    
            A list of the requested extensions that were successfully
            enabled on the server is returned.
    
            Once enabled each extension remains active until the IMAP
            connection is closed.
    
            See :rfc:`5161` for more details.
            
        """
        pass


code IMAPClient__id_:
  body: |
    def id_(self, parameters=None):
        """Issue the ID command, returning a dict of server implementation
            fields.
    
            *parameters* should be specified as a dictionary of field/value pairs,
            for example: ``{"name": "IMAPClient", "version": "0.12"}``
            
        """
        pass


code IMAPClient__capabilities:
  body: |
    def capabilities(self):
        """Returns the server capability list.
    
            If the session is authenticated and the server has returned an
            untagged CAPABILITY response at authentication time, this
            response will be returned. Otherwise, the CAPABILITY command
            will be issued to the server, with the results cached for
            future calls.
    
            If the session is not yet authenticated, the capabilities
            requested at connection time will be returned.
            
        """
        pass


code IMAPClient__has_capability:
  body: |
    def has_capability(self, capability):
        """Return ``True`` if the IMAP server has the given *capability*."""
        pass


code IMAPClient__namespace:
  body: |
    def namespace(self):
        """Return the namespace for the account as a (personal, other,
            shared) tuple.
    
            Each element may be None if no namespace of that type exists,
            or a sequence of (prefix, separator) pairs.
    
            For convenience the tuple elements may be accessed
            positionally or using attributes named *personal*, *other* and
            *shared*.
    
            See :rfc:`2342` for more details.
            
        """
        pass


code IMAPClient__list_folders:
  body: |
    def list_folders(self, directory='', pattern='*'):
        """Get a listing of folders on the server as a list of
            ``(flags, delimiter, name)`` tuples.
    
            Specifying *directory* will limit returned folders to the
            given base directory. The directory and any child directories
            will returned.
    
            Specifying *pattern* will limit returned folders to those with
            matching names. The wildcards are supported in
            *pattern*. ``*`` matches zero or more of any character and
            ``%`` matches 0 or more characters except the folder
            delimiter.
    
            Calling list_folders with no arguments will recursively list
            all folders available for the logged in user.
    
            Folder names are always returned as unicode strings, and
            decoded from modified UTF-7, except if folder_decode is not
            set.
            
        """
        pass


code IMAPClient__xlist_folders:
  body: |
    def xlist_folders(self, directory='', pattern='*'):
        """Execute the XLIST command, returning ``(flags, delimiter,
            name)`` tuples.
    
            This method returns special flags for each folder and a
            localized name for certain folders (e.g. the name of the
            inbox may be localized and the flags can be used to
            determine the actual inbox, even if the name has been
            localized.
    
            A ``XLIST`` response could look something like::
    
                [((b'\HasNoChildren', b'\Inbox'), b'/', u'Inbox'),
                 ((b'\Noselect', b'\HasChildren'), b'/', u'[Gmail]'),
                 ((b'\HasNoChildren', b'\AllMail'), b'/', u'[Gmail]/All Mail'),
                 ((b'\HasNoChildren', b'\Drafts'), b'/', u'[Gmail]/Drafts'),
                 ((b'\HasNoChildren', b'\Important'), b'/', u'[Gmail]/Important'),
                 ((b'\HasNoChildren', b'\Sent'), b'/', u'[Gmail]/Sent Mail'),
                 ((b'\HasNoChildren', b'\Spam'), b'/', u'[Gmail]/Spam'),
                 ((b'\HasNoChildren', b'\Starred'), b'/', u'[Gmail]/Starred'),
                 ((b'\HasNoChildren', b'\Trash'), b'/', u'[Gmail]/Trash')]
    
            This is a *deprecated* Gmail-specific IMAP extension (See
            https://developers.google.com/gmail/imap_extensions#xlist_is_deprecated
            for more information).
    
            The *directory* and *pattern* arguments are as per
            list_folders().
            
        """
        pass


code IMAPClient__list_sub_folders:
  body: |
    def list_sub_folders(self, directory='', pattern='*'):
        """Return a list of subscribed folders on the server as
            ``(flags, delimiter, name)`` tuples.
    
            The default behaviour will list all subscribed folders. The
            *directory* and *pattern* arguments are as per list_folders().
            
        """
        pass


code IMAPClient__find_special_folder:
  body: |
    def find_special_folder(self, folder_flag):
        """Try to locate a special folder, like the Sent or Trash folder.
    
            >>> server.find_special_folder(imapclient.SENT)
            'INBOX.Sent'
    
            This function tries its best to find the correct folder (if any) but
            uses heuristics when the server is unable to precisely tell where
            special folders are located.
    
            Returns the name of the folder if found, or None otherwise.
            
        """
        pass


code IMAPClient__select_folder:
  body: |
    def select_folder(self, folder, readonly=False):
        """Set the current folder on the server.
    
            Future calls to methods such as search and fetch will act on
            the selected folder.
    
            Returns a dictionary containing the ``SELECT`` response. At least
            the ``b'EXISTS'``, ``b'FLAGS'`` and ``b'RECENT'`` keys are guaranteed
            to exist. An example::
    
                {b'EXISTS': 3,
                 b'FLAGS': (b'\Answered', b'\Flagged', b'\Deleted', ... ),
                 b'RECENT': 0,
                 b'PERMANENTFLAGS': (b'\Answered', b'\Flagged', b'\Deleted', ... ),
                 b'READ-WRITE': True,
                 b'UIDNEXT': 11,
                 b'UIDVALIDITY': 1239278212}
            
        """
        pass


code IMAPClient__unselect_folder:
  body: |
    def unselect_folder(self):
        """Unselect the current folder and release associated resources.
    
            Unlike ``close_folder``, the ``UNSELECT`` command does not expunge
            the mailbox, keeping messages with \Deleted flag set for example.
    
            Returns the UNSELECT response string returned by the server.
            
        """
        pass


code IMAPClient__noop:
  body: |
    def noop(self):
        """Execute the NOOP command.
    
            This command returns immediately, returning any server side
            status updates. It can also be used to reset any auto-logout
            timers.
    
            The return value is the server command response message
            followed by a list of status responses. For example::
    
                (b'NOOP completed.',
                 [(4, b'EXISTS'),
                  (3, b'FETCH', (b'FLAGS', (b'bar', b'sne'))),
                  (6, b'FETCH', (b'FLAGS', (b'sne',)))])
    
            
        """
        pass


code IMAPClient__idle:
  body: |
    def idle(self):
        """Put the server into IDLE mode.
    
            In this mode the server will return unsolicited responses
            about changes to the selected mailbox. This method returns
            immediately. Use ``idle_check()`` to look for IDLE responses
            and ``idle_done()`` to stop IDLE mode.
    
            .. note::
    
                Any other commands issued while the server is in IDLE
                mode will fail.
    
            See :rfc:`2177` for more information about the IDLE extension.
            
        """
        pass


code IMAPClient___poll_socket:
  body: |
    def _poll_socket(self, sock, timeout=None):
        """
            Polls the socket for events telling us it's available to read.
            This implementation is more scalable because it ALLOWS your process
            to have more than 1024 file descriptors.
            
        """
        pass


code IMAPClient___select_poll_socket:
  body: |
    def _select_poll_socket(self, sock, timeout=None):
        """
            Polls the socket for events telling us it's available to read.
            This implementation is a fallback because it FAILS if your process
            has more than 1024 file descriptors.
            We still need this for Windows and some other niche systems.
            
        """
        pass


code IMAPClient__idle_check:
  body: |
    def idle_check(self, timeout=None):
        """Check for any IDLE responses sent by the server.
    
            This method should only be called if the server is in IDLE
            mode (see ``idle()``).
    
            By default, this method will block until an IDLE response is
            received. If *timeout* is provided, the call will block for at
            most this many seconds while waiting for an IDLE response.
    
            The return value is a list of received IDLE responses. These
            will be parsed with values converted to appropriate types. For
            example::
    
                [(b'OK', b'Still here'),
                 (1, b'EXISTS'),
                 (1, b'FETCH', (b'FLAGS', (b'\NotJunk',)))]
            
        """
        pass


code IMAPClient__idle_done:
  body: |
    def idle_done(self):
        """Take the server out of IDLE mode.
    
            This method should only be called if the server is already in
            IDLE mode.
    
            The return value is of the form ``(command_text,
            idle_responses)`` where *command_text* is the text sent by the
            server when the IDLE command finished (eg. ``b'Idle
            terminated'``) and *idle_responses* is a list of parsed idle
            responses received since the last call to ``idle_check()`` (if
            any). These are returned in parsed form as per
            ``idle_check()``.
            
        """
        pass


code IMAPClient__folder_status:
  body: |
    def folder_status(self, folder, what=None):
        """Return the status of *folder*.
    
            *what* should be a sequence of status items to query. This
            defaults to ``('MESSAGES', 'RECENT', 'UIDNEXT', 'UIDVALIDITY',
            'UNSEEN')``.
    
            Returns a dictionary of the status items for the folder with
            keys matching *what*.
            
        """
        pass


code IMAPClient__close_folder:
  body: |
    def close_folder(self):
        """Close the currently selected folder, returning the server
            response string.
            
        """
        pass


code IMAPClient__create_folder:
  body: |
    def create_folder(self, folder):
        """Create *folder* on the server returning the server response string."""
        pass


code IMAPClient__rename_folder:
  body: |
    def rename_folder(self, old_name, new_name):
        """Change the name of a folder on the server."""
        pass


code IMAPClient__delete_folder:
  body: |
    def delete_folder(self, folder):
        """Delete *folder* on the server returning the server response string."""
        pass


code IMAPClient__folder_exists:
  body: |
    def folder_exists(self, folder):
        """Return ``True`` if *folder* exists on the server."""
        pass


code IMAPClient__subscribe_folder:
  body: |
    def subscribe_folder(self, folder):
        """Subscribe to *folder*, returning the server response string."""
        pass


code IMAPClient__unsubscribe_folder:
  body: |
    def unsubscribe_folder(self, folder):
        """Unsubscribe to *folder*, returning the server response string."""
        pass


code IMAPClient__search:
  body: |
    def search(self, criteria='ALL', charset=None):
        """Return a list of messages ids from the currently selected
            folder matching *criteria*.
    
            *criteria* should be a sequence of one or more criteria
            items. Each criteria item may be either unicode or
            bytes. Example values::
    
                [u'UNSEEN']
                [u'SMALLER', 500]
                [b'NOT', b'DELETED']
                [u'TEXT', u'foo bar', u'FLAGGED', u'SUBJECT', u'baz']
                [u'SINCE', date(2005, 4, 3)]
    
            IMAPClient will perform conversion and quoting as
            required. The caller shouldn't do this.
    
            It is also possible (but not recommended) to pass the combined
            criteria as a single string. In this case IMAPClient won't
            perform quoting, allowing lower-level specification of
            criteria. Examples of this style::
    
                u'UNSEEN'
                u'SMALLER 500'
                b'NOT DELETED'
                u'TEXT "foo bar" FLAGGED SUBJECT "baz"'
                b'SINCE 03-Apr-2005'
    
            To support complex search expressions, criteria lists can be
            nested. IMAPClient will insert parentheses in the right
            places. The following will match messages that are both not
            flagged and do not have "foo" in the subject::
    
                ['NOT', ['SUBJECT', 'foo', 'FLAGGED']]
    
            *charset* specifies the character set of the criteria. It
            defaults to US-ASCII as this is the only charset that a server
            is required to support by the RFC. UTF-8 is commonly supported
            however.
    
            Any criteria specified using unicode will be encoded as per
            *charset*. Specifying a unicode criteria that can not be
            encoded using *charset* will result in an error.
    
            Any criteria specified using bytes will be sent as-is but
            should use an encoding that matches *charset* (the character
            set given is still passed on to the server).
    
            See :rfc:`3501#section-6.4.4` for more details.
    
            Note that criteria arguments that are 8-bit will be
            transparently sent by IMAPClient as IMAP literals to ensure
            adherence to IMAP standards.
    
            The returned list of message ids will have a special *modseq*
            attribute. This is set if the server included a MODSEQ value
            to the search response (i.e. if a MODSEQ criteria was included
            in the search).
    
            
        """
        pass


code IMAPClient__gmail_search:
  body: |
    def gmail_search(self, query, charset='UTF-8'):
        """Search using Gmail's X-GM-RAW attribute.
    
            *query* should be a valid Gmail search query string. For
            example: ``has:attachment in:unread``. The search string may
            be unicode and will be encoded using the specified *charset*
            (defaulting to UTF-8).
    
            This method only works for IMAP servers that support X-GM-RAW,
            which is only likely to be Gmail.
    
            See https://developers.google.com/gmail/imap_extensions#extension_of_the_search_command_x-gm-raw
            for more info.
            
        """
        pass


code IMAPClient__sort:
  body: |
    def sort(self, sort_criteria, criteria='ALL', charset='UTF-8'):
        """Return a list of message ids from the currently selected
            folder, sorted by *sort_criteria* and optionally filtered by
            *criteria*.
    
            *sort_criteria* may be specified as a sequence of strings or a
            single string. IMAPClient will take care any required
            conversions. Valid *sort_criteria* values::
    
                ['ARRIVAL']
                ['SUBJECT', 'ARRIVAL']
                'ARRIVAL'
                'REVERSE SIZE'
    
            The *criteria* and *charset* arguments are as per
            :py:meth:`.search`.
    
            See :rfc:`5256` for full details.
    
            Note that SORT is an extension to the IMAP4 standard so it may
            not be supported by all IMAP servers.
            
        """
        pass


code IMAPClient__thread:
  body: |
    def thread(self, algorithm='REFERENCES', criteria='ALL', charset='UTF-8'):
        """Return a list of messages threads from the currently
            selected folder which match *criteria*.
    
            Each returned thread is a list of messages ids. An example
            return value containing three message threads::
    
                ((1, 2), (3,), (4, 5, 6))
    
            The optional *algorithm* argument specifies the threading
            algorithm to use.
    
            The *criteria* and *charset* arguments are as per
            :py:meth:`.search`.
    
            See :rfc:`5256` for more details.
            
        """
        pass


code IMAPClient__get_flags:
  body: |
    def get_flags(self, messages):
        """Return the flags set for each message in *messages* from
            the currently selected folder.
    
            The return value is a dictionary structured like this: ``{
            msgid1: (flag1, flag2, ... ), }``.
            
        """
        pass


code IMAPClient__add_flags:
  body: |
    def add_flags(self, messages, flags, silent=False):
        """Add *flags* to *messages* in the currently selected folder.
    
            *flags* should be a sequence of strings.
    
            Returns the flags set for each modified message (see
            *get_flags*), or None if *silent* is true.
            
        """
        pass


code IMAPClient__remove_flags:
  body: |
    def remove_flags(self, messages, flags, silent=False):
        """Remove one or more *flags* from *messages* in the currently
            selected folder.
    
            *flags* should be a sequence of strings.
    
            Returns the flags set for each modified message (see
            *get_flags*), or None if *silent* is true.
            
        """
        pass


code IMAPClient__set_flags:
  body: |
    def set_flags(self, messages, flags, silent=False):
        """Set the *flags* for *messages* in the currently selected
            folder.
    
            *flags* should be a sequence of strings.
    
            Returns the flags set for each modified message (see
            *get_flags*), or None if *silent* is true.
            
        """
        pass


code IMAPClient__get_gmail_labels:
  body: |
    def get_gmail_labels(self, messages):
        """Return the label set for each message in *messages* in the
            currently selected folder.
    
            The return value is a dictionary structured like this: ``{
            msgid1: (label1, label2, ... ), }``.
    
            This only works with IMAP servers that support the X-GM-LABELS
            attribute (eg. Gmail).
            
        """
        pass


code IMAPClient__add_gmail_labels:
  body: |
    def add_gmail_labels(self, messages, labels, silent=False):
        """Add *labels* to *messages* in the currently selected folder.
    
            *labels* should be a sequence of strings.
    
            Returns the label set for each modified message (see
            *get_gmail_labels*), or None if *silent* is true.
    
            This only works with IMAP servers that support the X-GM-LABELS
            attribute (eg. Gmail).
            
        """
        pass


code IMAPClient__remove_gmail_labels:
  body: |
    def remove_gmail_labels(self, messages, labels, silent=False):
        """Remove one or more *labels* from *messages* in the
            currently selected folder, or None if *silent* is true.
    
            *labels* should be a sequence of strings.
    
            Returns the label set for each modified message (see
            *get_gmail_labels*).
    
            This only works with IMAP servers that support the X-GM-LABELS
            attribute (eg. Gmail).
            
        """
        pass


code IMAPClient__set_gmail_labels:
  body: |
    def set_gmail_labels(self, messages, labels, silent=False):
        """Set the *labels* for *messages* in the currently selected
            folder.
    
            *labels* should be a sequence of strings.
    
            Returns the label set for each modified message (see
            *get_gmail_labels*), or None if *silent* is true.
    
            This only works with IMAP servers that support the X-GM-LABELS
            attribute (eg. Gmail).
            
        """
        pass


code IMAPClient__delete_messages:
  body: |
    def delete_messages(self, messages, silent=False):
        """Delete one or more *messages* from the currently selected
            folder.
    
            Returns the flags set for each modified message (see
            *get_flags*).
            
        """
        pass


code IMAPClient__fetch:
  body: |
    def fetch(self, messages, data, modifiers=None):
        """Retrieve selected *data* associated with one or more
            *messages* in the currently selected folder.
    
            *data* should be specified as a sequence of strings, one item
            per data selector, for example ``['INTERNALDATE',
            'RFC822']``.
    
            *modifiers* are required for some extensions to the IMAP
            protocol (eg. :rfc:`4551`). These should be a sequence of strings
            if specified, for example ``['CHANGEDSINCE 123']``.
    
            A dictionary is returned, indexed by message number. Each item
            in this dictionary is also a dictionary, with an entry
            corresponding to each item in *data*. Returned values will be
            appropriately typed. For example, integer values will be returned as
            Python integers, timestamps will be returned as datetime
            instances and ENVELOPE responses will be returned as
            :py:class:`Envelope <imapclient.response_types.Envelope>` instances.
    
            String data will generally be returned as bytes (Python 3) or
            str (Python 2).
    
            In addition to an element for each *data* item, the dict
            returned for each message also contains a *SEQ* key containing
            the sequence number for the message. This allows for mapping
            between the UID and sequence number (when the *use_uid*
            property is ``True``).
    
            Example::
    
                >> c.fetch([3293, 3230], ['INTERNALDATE', 'FLAGS'])
                {3230: {b'FLAGS': (b'\Seen',),
                        b'INTERNALDATE': datetime.datetime(2011, 1, 30, 13, 32, 9),
                        b'SEQ': 84},
                 3293: {b'FLAGS': (),
                        b'INTERNALDATE': datetime.datetime(2011, 2, 24, 19, 30, 36),
                        b'SEQ': 110}}
    
            
        """
        pass


code IMAPClient__append:
  body: |
    def append(self, folder, msg, flags=(), msg_time=None):
        """Append a message to *folder*.
    
            *msg* should be a string contains the full message including
            headers.
    
            *flags* should be a sequence of message flags to set. If not
            specified no flags will be set.
    
            *msg_time* is an optional datetime instance specifying the
            date and time to set on the message. The server will set a
            time if it isn't specified. If *msg_time* contains timezone
            information (tzinfo), this will be honoured. Otherwise the
            local machine's time zone sent to the server.
    
            Returns the APPEND response as returned by the server.
            
        """
        pass


code IMAPClient__multiappend:
  body: |
    def multiappend(self, folder, msgs):
        """Append messages to *folder* using the MULTIAPPEND feature from :rfc:`3502`.
    
            *msgs* must be an iterable. Each item must be either a string containing the
            full message including headers, or a dict containing the keys "msg" with the
            full message as before, "flags" with a sequence of message flags to set, and
            "date" with a datetime instance specifying the internal date to set.
            The keys "flags" and "date" are optional.
    
            Returns the APPEND response from the server.
            
        """
        pass


code IMAPClient__copy:
  body: |
    def copy(self, messages, folder):
        """Copy one or more messages from the current folder to
            *folder*. Returns the COPY response string returned by the
            server.
            
        """
        pass


code IMAPClient__move:
  body: |
    def move(self, messages, folder):
        """Atomically move messages to another folder.
    
            Requires the MOVE capability, see :rfc:`6851`.
    
            :param messages: List of message UIDs to move.
            :param folder: The destination folder name.
            
        """
        pass


code IMAPClient__expunge:
  body: |
    def expunge(self, messages=None):
        """Use of the *messages* argument is discouraged.
            Please see the ``uid_expunge`` method instead.
    
            When, no *messages* are specified, remove all messages
            from the currently selected folder that have the
            ``\Deleted`` flag set.
    
            The return value is the server response message
            followed by a list of expunge responses. For example::
    
                ('Expunge completed.',
                 [(2, 'EXPUNGE'),
                  (1, 'EXPUNGE'),
                  (0, 'RECENT')])
    
            In this case, the responses indicate that the message with
            sequence numbers 2 and 1 where deleted, leaving no recent
            messages in the folder.
    
            See :rfc:`3501#section-6.4.3` section 6.4.3 and
            :rfc:`3501#section-7.4.1` section 7.4.1 for more details.
    
            When *messages* are specified, remove the specified messages
            from the selected folder, provided those messages also have
            the ``\Deleted`` flag set. The return value is ``None`` in
            this case.
    
            Expunging messages by id(s) requires that *use_uid* is
            ``True`` for the client.
    
            See :rfc:`4315#section-2.1` section 2.1 for more details.
            
        """
        pass


code IMAPClient__uid_expunge:
  body: |
    def uid_expunge(self, messages):
        """Expunge deleted messages with the specified message ids from the
            folder.
    
            This requires the UIDPLUS capability.
    
            See :rfc:`4315#section-2.1` section 2.1 for more details.
            
        """
        pass


code IMAPClient__getacl:
  body: |
    def getacl(self, folder):
        """Returns a list of ``(who, acl)`` tuples describing the
            access controls for *folder*.
            
        """
        pass


code IMAPClient__setacl:
  body: |
    def setacl(self, folder, who, what):
        """Set an ACL (*what*) for user (*who*) for a folder.
    
            Set *what* to an empty string to remove an ACL. Returns the
            server response string.
            
        """
        pass


code IMAPClient__get_quota:
  body: |
    def get_quota(self, mailbox='INBOX'):
        """Get the quotas associated with a mailbox.
    
            Returns a list of Quota objects.
            
        """
        pass


code IMAPClient___get_quota:
  body: |
    def _get_quota(self, quota_root=''):
        """Get the quotas associated with a quota root.
    
            This method is not private but put behind an underscore to show that
            it is a low-level function. Users probably want to use `get_quota`
            instead.
    
            Returns a list of Quota objects.
            
        """
        pass


code IMAPClient__get_quota_root:
  body: |
    def get_quota_root(self, mailbox):
        """Get the quota roots for a mailbox.
    
            The IMAP server responds with the quota root and the quotas associated
            so there is usually no need to call `get_quota` after.
    
            See :rfc:`2087` for more details.
    
            Return a tuple of MailboxQuotaRoots and list of Quota associated
            
        """
        pass


code IMAPClient__set_quota:
  body: |
    def set_quota(self, quotas):
        """Set one or more quotas on resources.
    
            :param quotas: list of Quota objects
            
        """
        pass


code IMAPClient___check_resp:
  body: |
    def _check_resp(self, expected, command, typ, data):
        """Check command responses for errors.
    
            Raises IMAPClient.Error if the command fails.
            
        """
        pass


code IMAPClient___raw_command:
  body: |
    def _raw_command(self, command, args, uid=True):
        """Run the specific command with the arguments given. 8-bit arguments
            are sent as literals. The return value is (typ, data).
    
            This sidesteps much of imaplib's command sending
            infrastructure because imaplib can't send more than one
            literal.
    
            *command* should be specified as bytes.
            *args* should be specified as a list of bytes.
            
        """
        pass


code IMAPClient___send_literal:
  body: |
    def _send_literal(self, tag, item):
        """Send a single literal for the command with *tag*."""
        pass


code IMAPClient___store:
  body: |
    def _store(self, cmd, messages, flags, fetch_key, silent):
        """Worker function for the various flag manipulation methods.
    
            *cmd* is the STORE command to use (eg. '+FLAGS').
            
        """
        pass


code IMAPClient__welcome:
  body: |
    def welcome(self):
        """access the server greeting message"""
        pass


code _quoted__maybe:
  body: |
    def maybe(cls, original):
        """Maybe quote a bytes value.
    
            If the input requires no quoting it is returned unchanged.
    
            If quoting is required a *_quoted* instance is returned. This
            holds the quoted version of the input while also providing
            access to the original unquoted source.
            
        """
        pass


code join_message_ids:
  body: |
    def join_message_ids(messages):
        """Convert a sequence of messages ids or a single integer message id
        into an id byte string for use with IMAP commands
        
        """
        pass


code parse_response:
  body: |
    def parse_response(data: List[bytes]):
        """Pull apart IMAP command responses.
    
        Returns nested tuples of appropriately typed objects.
        
        """
        pass


code parse_message_list:
  body: |
    def parse_message_list(data: List[Union[bytes, str]]):
        """Parse a list of message ids and return them as a list.
    
        parse_response is also capable of doing this but this is
        faster. This also has special handling of the optional MODSEQ part
        of a SEARCH response.
    
        The returned list is a SearchIds instance which has a *modseq*
        attribute which contains the MODSEQ response (if returned by the
        server).
        
        """
        pass


code parse_fetch_response:
  body: |
    def parse_fetch_response(text: List[bytes], normalise_times: bool=True, uid_is_key: bool=True):
        """Pull apart IMAP FETCH responses as returned by imaplib.
    
        Returns a dictionary, keyed by message ID. Each value a dictionary
        keyed by FETCH field type (eg."RFC822").
        
        """
        pass
