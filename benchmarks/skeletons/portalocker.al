preamble __about__:
  source: portalocker/__about__.py
  body: |
    __package_name__ = 'portalocker'
    __author__ = 'Rick van Hattem'
    __email__ = 'wolph@wol.ph'
    __version__ = '2.10.1'
    __description__ = 'Wraps the portalocker recipe for easy usage'
    __url__ = 'https://github.com/WoLpH/portalocker'


preamble __init__:
  source: portalocker/__init__.py
  body: |
    from . import __about__, constants, exceptions, portalocker
    from .utils import BoundedSemaphore, Lock, RLock, TemporaryFileLock, open_atomic
    try:
        from .redis import RedisLock
    except ImportError:
        RedisLock = None
    __package_name__ = __about__.__package_name__
    __author__ = __about__.__author__
    __email__ = __about__.__email__
    __version__ = '2.10.1'
    __description__ = __about__.__description__
    __url__ = __about__.__url__
    AlreadyLocked = exceptions.AlreadyLocked
    LockException = exceptions.LockException
    lock = portalocker.lock
    unlock = portalocker.unlock
    LOCK_EX: constants.LockFlags = constants.LockFlags.EXCLUSIVE
    LOCK_SH: constants.LockFlags = constants.LockFlags.SHARED
    LOCK_NB: constants.LockFlags = constants.LockFlags.NON_BLOCKING
    LOCK_UN: constants.LockFlags = constants.LockFlags.UNBLOCK
    LockFlags = constants.LockFlags
    __all__ = ['lock', 'unlock', 'LOCK_EX', 'LOCK_SH', 'LOCK_NB', 'LOCK_UN', 'LockFlags', 'LockException', 'Lock', 'RLock', 'AlreadyLocked', 'BoundedSemaphore', 'TemporaryFileLock', 'open_atomic', 'RedisLock']


preamble __main__:
  source: portalocker/__main__.py
  body: |
    import argparse
    import logging
    import os
    import pathlib
    import re
    import typing
    base_path = pathlib.Path(__file__).parent.parent
    src_path = base_path / 'portalocker'
    dist_path = base_path / 'dist'
    _default_output_path = base_path / 'dist' / 'portalocker.py'
    _NAMES_RE = re.compile('(?P<names>[^()]+)$')
    _RELATIVE_IMPORT_RE = re.compile('^from \\.(?P<from>.*?) import (?P<paren>\\(?)(?P<names>[^()]+)$')
    _USELESS_ASSIGNMENT_RE = re.compile('^(?P<name>\\w+) = \\1\\n$')
    _TEXT_TEMPLATE = "'''\n{}\n'''\n\n"
    logger = logging.getLogger(__name__)
    if __name__ == '__main__':
        logging.basicConfig(level=logging.INFO)
        main()


preamble constants:
  source: portalocker/constants.py
  body: |
    '\nLocking constants\n\nLock types:\n\n- `EXCLUSIVE` exclusive lock\n- `SHARED` shared lock\n\nLock flags:\n\n- `NON_BLOCKING` non-blocking\n\nManually unlock, only needed internally\n\n- `UNBLOCK` unlock\n'
    import enum
    import os
    if os.name == 'nt':
        import msvcrt
        LOCK_EX = 1
        LOCK_SH = 2
        LOCK_NB = 4
        LOCK_UN = msvcrt.LK_UNLCK
    elif os.name == 'posix':
        import fcntl
        LOCK_EX = fcntl.LOCK_EX
        LOCK_SH = fcntl.LOCK_SH
        LOCK_NB = fcntl.LOCK_NB
        LOCK_UN = fcntl.LOCK_UN
    else:
        raise RuntimeError('PortaLocker only defined for nt and posix platforms')
    class LockFlags(enum.IntFlag):
        EXCLUSIVE = LOCK_EX
        SHARED = LOCK_SH
        NON_BLOCKING = LOCK_NB
        UNBLOCK = LOCK_UN


preamble exceptions:
  source: portalocker/exceptions.py
  body: |
    import typing
    class BaseLockException(Exception):
        LOCK_FAILED = 1

        def __init__(self, *args: typing.Any, fh: typing.Union[typing.IO, None, int]=None, **kwargs: typing.Any) -> None:
            self.fh = fh
            Exception.__init__(self, *args)
    class LockException(BaseLockException):
        pass
    class AlreadyLocked(LockException):
        pass
    class FileToLarge(LockException):
        pass


preamble portalocker:
  source: portalocker/portalocker.py
  body: |
    import os
    import typing
    from . import constants, exceptions
    LockFlags = constants.LockFlags
    class HasFileno(typing.Protocol):
        pass
    LOCKER: typing.Optional[typing.Callable[[typing.Union[int, HasFileno], int], typing.Any]] = None
    if os.name == 'nt':
        import msvcrt
        import pywintypes
        import win32con
        import win32file
        import winerror
        __overlapped = pywintypes.OVERLAPPED()
    elif os.name == 'posix':
        import errno
        import fcntl
        LOCKER = fcntl.flock
    else:
        raise RuntimeError('PortaLocker only defined for nt and posix platforms')


preamble redis:
  source: portalocker/redis.py
  body: |
    import _thread
    import json
    import logging
    import random
    import time
    import typing
    from redis import client
    from . import exceptions, utils
    logger = logging.getLogger(__name__)
    DEFAULT_UNAVAILABLE_TIMEOUT = 1
    DEFAULT_THREAD_SLEEP_TIME = 0.1
    class PubSubWorkerThread(client.PubSubWorkerThread):
        pass
    class RedisLock(utils.LockBase):
        """
        An extremely reliable Redis lock based on pubsub with a keep-alive thread

        As opposed to most Redis locking systems based on key/value pairs,
        this locking method is based on the pubsub system. The big advantage is
        that if the connection gets killed due to network issues, crashing
        processes or otherwise, it will still immediately unlock instead of
        waiting for a lock timeout.

        To make sure both sides of the lock know about the connection state it is
        recommended to set the `health_check_interval` when creating the redis
        connection..

        Args:
            channel: the redis channel to use as locking key.
            connection: an optional redis connection if you already have one
            or if you need to specify the redis connection
            timeout: timeout when trying to acquire a lock
            check_interval: check interval while waiting
            fail_when_locked: after the initial lock failed, return an error
                or lock the file. This does not wait for the timeout.
            thread_sleep_time: sleep time between fetching messages from redis to
                prevent a busy/wait loop. In the case of lock conflicts this
                increases the time it takes to resolve the conflict. This should
                be smaller than the `check_interval` to be useful.
            unavailable_timeout: If the conflicting lock is properly connected
                this should never exceed twice your redis latency. Note that this
                will increase the wait time possibly beyond your `timeout` and is
                always executed if a conflict arises.
            redis_kwargs: The redis connection arguments if no connection is
                given. The `DEFAULT_REDIS_KWARGS` are used as default, if you want
                to override these you need to explicitly specify a value (e.g.
                `health_check_interval=0`)

        """
        redis_kwargs: typing.Dict[str, typing.Any]
        thread: typing.Optional[PubSubWorkerThread]
        channel: str
        timeout: float
        connection: typing.Optional[client.Redis]
        pubsub: typing.Optional[client.PubSub] = None
        close_connection: bool
        DEFAULT_REDIS_KWARGS: typing.ClassVar[typing.Dict[str, typing.Any]] = dict(health_check_interval=10)

        def __init__(self, channel: str, connection: typing.Optional[client.Redis]=None, timeout: typing.Optional[float]=None, check_interval: typing.Optional[float]=None, fail_when_locked: typing.Optional[bool]=False, thread_sleep_time: float=DEFAULT_THREAD_SLEEP_TIME, unavailable_timeout: float=DEFAULT_UNAVAILABLE_TIMEOUT, redis_kwargs: typing.Optional[typing.Dict]=None):
            self.close_connection = not connection
            self.thread = None
            self.channel = channel
            self.connection = connection
            self.thread_sleep_time = thread_sleep_time
            self.unavailable_timeout = unavailable_timeout
            self.redis_kwargs = redis_kwargs or dict()
            for key, value in self.DEFAULT_REDIS_KWARGS.items():
                self.redis_kwargs.setdefault(key, value)
            super().__init__(timeout=timeout, check_interval=check_interval, fail_when_locked=fail_when_locked)

        def __del__(self):
            self.release()


preamble utils:
  source: portalocker/utils.py
  body: |
    import abc
    import atexit
    import contextlib
    import logging
    import os
    import pathlib
    import random
    import tempfile
    import time
    import typing
    import warnings
    from . import constants, exceptions, portalocker
    logger = logging.getLogger(__name__)
    DEFAULT_TIMEOUT = 5
    DEFAULT_CHECK_INTERVAL = 0.25
    DEFAULT_FAIL_WHEN_LOCKED = False
    LOCK_METHOD = constants.LockFlags.EXCLUSIVE | constants.LockFlags.NON_BLOCKING
    __all__ = ['Lock', 'open_atomic']
    Filename = typing.Union[str, pathlib.Path]
    class LockBase(abc.ABC):
        timeout: float
        check_interval: float
        fail_when_locked: bool

        def __init__(self, timeout: typing.Optional[float]=None, check_interval: typing.Optional[float]=None, fail_when_locked: typing.Optional[bool]=None):
            self.timeout = coalesce(timeout, DEFAULT_TIMEOUT)
            self.check_interval = coalesce(check_interval, DEFAULT_CHECK_INTERVAL)
            self.fail_when_locked = coalesce(fail_when_locked, DEFAULT_FAIL_WHEN_LOCKED)

        def __enter__(self) -> typing.IO[typing.AnyStr]:
            return self.acquire()

        def __exit__(self, exc_type: typing.Optional[typing.Type[BaseException]], exc_value: typing.Optional[BaseException], traceback: typing.Any) -> typing.Optional[bool]:
            self.release()
            return None

        def __delete__(self, instance):
            instance.release()
    class Lock(LockBase):
        """Lock manager with built-in timeout

        Args:
            filename: filename
            mode: the open mode, 'a' or 'ab' should be used for writing. When mode
                contains `w` the file will be truncated to 0 bytes.
            timeout: timeout when trying to acquire a lock
            check_interval: check interval while waiting
            fail_when_locked: after the initial lock failed, return an error
                or lock the file. This does not wait for the timeout.
            **file_open_kwargs: The kwargs for the `open(...)` call

        fail_when_locked is useful when multiple threads/processes can race
        when creating a file. If set to true than the system will wait till
        the lock was acquired and then return an AlreadyLocked exception.

        Note that the file is opened first and locked later. So using 'w' as
        mode will result in truncate _BEFORE_ the lock is checked.
        """

        def __init__(self, filename: Filename, mode: str='a', timeout: typing.Optional[float]=None, check_interval: float=DEFAULT_CHECK_INTERVAL, fail_when_locked: bool=DEFAULT_FAIL_WHEN_LOCKED, flags: constants.LockFlags=LOCK_METHOD, **file_open_kwargs):
            if 'w' in mode:
                truncate = True
                mode = mode.replace('w', 'a')
            else:
                truncate = False
            if timeout is None:
                timeout = DEFAULT_TIMEOUT
            elif not flags & constants.LockFlags.NON_BLOCKING:
                warnings.warn('timeout has no effect in blocking mode', stacklevel=1)
            self.fh: typing.Optional[typing.IO] = None
            self.filename: str = str(filename)
            self.mode: str = mode
            self.truncate: bool = truncate
            self.timeout: float = timeout
            self.check_interval: float = check_interval
            self.fail_when_locked: bool = fail_when_locked
            self.flags: constants.LockFlags = flags
            self.file_open_kwargs = file_open_kwargs

        def acquire(self, timeout: typing.Optional[float]=None, check_interval: typing.Optional[float]=None, fail_when_locked: typing.Optional[bool]=None) -> typing.IO[typing.AnyStr]:
            """Acquire the locked filehandle"""
            pass

        def __enter__(self) -> typing.IO[typing.AnyStr]:
            return self.acquire()

        def release(self):
            """Releases the currently locked file handle"""
            pass

        def _get_fh(self) -> typing.IO:
            """Get a new filehandle"""
            pass

        def _get_lock(self, fh: typing.IO) -> typing.IO:
            """
            Try to lock the given filehandle

            returns LockException if it fails"""
            pass

        def _prepare_fh(self, fh: typing.IO) -> typing.IO:
            """
            Prepare the filehandle for usage

            If truncate is a number, the file will be truncated to that amount of
            bytes
            """
            pass
    class RLock(Lock):
        """
        A reentrant lock, functions in a similar way to threading.RLock in that it
        can be acquired multiple times.  When the corresponding number of release()
        calls are made the lock will finally release the underlying file lock.
        """

        def __init__(self, filename, mode='a', timeout=DEFAULT_TIMEOUT, check_interval=DEFAULT_CHECK_INTERVAL, fail_when_locked=False, flags=LOCK_METHOD):
            super().__init__(filename, mode, timeout, check_interval, fail_when_locked, flags)
            self._acquire_count = 0
    class TemporaryFileLock(Lock):

        def __init__(self, filename='.lock', timeout=DEFAULT_TIMEOUT, check_interval=DEFAULT_CHECK_INTERVAL, fail_when_locked=True, flags=LOCK_METHOD):
            Lock.__init__(self, filename=filename, mode='w', timeout=timeout, check_interval=check_interval, fail_when_locked=fail_when_locked, flags=flags)
            atexit.register(self.release)
    class BoundedSemaphore(LockBase):
        """
        Bounded semaphore to prevent too many parallel processes from running

        This method is deprecated because multiple processes that are completely
        unrelated could end up using the same semaphore.  To prevent this,
        use `NamedBoundedSemaphore` instead. The
        `NamedBoundedSemaphore` is a drop-in replacement for this class.

        >>> semaphore = BoundedSemaphore(2, directory='')
        >>> str(semaphore.get_filenames()[0])
        'bounded_semaphore.00.lock'
        >>> str(sorted(semaphore.get_random_filenames())[1])
        'bounded_semaphore.01.lock'
        """
        lock: typing.Optional[Lock]

        def __init__(self, maximum: int, name: str='bounded_semaphore', filename_pattern: str='{name}.{number:02d}.lock', directory: str=tempfile.gettempdir(), timeout: typing.Optional[float]=DEFAULT_TIMEOUT, check_interval: typing.Optional[float]=DEFAULT_CHECK_INTERVAL, fail_when_locked: typing.Optional[bool]=True):
            self.maximum = maximum
            self.name = name
            self.filename_pattern = filename_pattern
            self.directory = directory
            self.lock: typing.Optional[Lock] = None
            super().__init__(timeout=timeout, check_interval=check_interval, fail_when_locked=fail_when_locked)
            if not name or name == 'bounded_semaphore':
                warnings.warn('`BoundedSemaphore` without an explicit `name` argument is deprecated, use NamedBoundedSemaphore', DeprecationWarning, stacklevel=1)
    class NamedBoundedSemaphore(BoundedSemaphore):
        """
        Bounded semaphore to prevent too many parallel processes from running

        It's also possible to specify a timeout when acquiring the lock to wait
        for a resource to become available.  This is very similar to
        `threading.BoundedSemaphore` but works across multiple processes and across
        multiple operating systems.

        Because this works across multiple processes it's important to give the
        semaphore a name.  This name is used to create the lock files.  If you
        don't specify a name, a random name will be generated.  This means that
        you can't use the same semaphore in multiple processes unless you pass the
        semaphore object to the other processes.

        >>> semaphore = NamedBoundedSemaphore(2, name='test')
        >>> str(semaphore.get_filenames()[0])
        '...test.00.lock'

        >>> semaphore = NamedBoundedSemaphore(2)
        >>> 'bounded_semaphore' in str(semaphore.get_filenames()[0])
        True

        """

        def __init__(self, maximum: int, name: typing.Optional[str]=None, filename_pattern: str='{name}.{number:02d}.lock', directory: str=tempfile.gettempdir(), timeout: typing.Optional[float]=DEFAULT_TIMEOUT, check_interval: typing.Optional[float]=DEFAULT_CHECK_INTERVAL, fail_when_locked: typing.Optional[bool]=True):
            if name is None:
                name = 'bounded_semaphore.%d' % random.randint(0, 1000000)
            super().__init__(maximum, name, filename_pattern, directory, timeout, check_interval, fail_when_locked)


flow portalocker_lib:
  steps:
    - utils_group


flow utils_group:
  steps:
    - coalesce
    - open_atomic
    - Lock__acquire
    - Lock__release
    - Lock___get_fh
    - Lock___get_lock
    - Lock___prepare_fh


code coalesce:
  body: |
    def coalesce(*args: typing.Any, test_value: typing.Any=None):
        """Simple coalescing function that returns the first value that is not
        equal to the `test_value`. Or `None` if no value is valid. Usually this
        means that the last given value is the default value.
    
        Note that the `test_value` is compared using an identity check
        (i.e. `value is not test_value`) so changing the `test_value` won't work
        for all values.
    
        >>> coalesce(None, 1)
        1
        >>> coalesce()
    
        >>> coalesce(0, False, True)
        0
        >>> coalesce(0, False, True, test_value=0)
        False
    
        # This won't work because of the `is not test_value` type testing:
        >>> coalesce([], dict(spam='eggs'), test_value=[])
        []
        
        """
        pass


code open_atomic:
  body: |
    def open_atomic(filename: Filename, binary: bool=True):
        """Open a file for atomic writing. Instead of locking this method allows
        you to write the entire file and move it to the actual location. Note that
        this makes the assumption that a rename is atomic on your platform which
        is generally the case but not a guarantee.
    
        http://docs.python.org/library/os.html#os.rename
    
        >>> filename = 'test_file.txt'
        >>> if os.path.exists(filename):
        ...     os.remove(filename)
    
        >>> with open_atomic(filename) as fh:
        ...     written = fh.write(b'test')
        >>> assert os.path.exists(filename)
        >>> os.remove(filename)
    
        >>> import pathlib
        >>> path_filename = pathlib.Path('test_file.txt')
    
        >>> with open_atomic(path_filename) as fh:
        ...     written = fh.write(b'test')
        >>> assert path_filename.exists()
        >>> path_filename.unlink()
        
        """
        pass


code Lock__acquire:
  body: |
    def acquire(self, timeout: typing.Optional[float]=None, check_interval: typing.Optional[float]=None, fail_when_locked: typing.Optional[bool]=None):
        """Acquire the locked filehandle"""
        pass


code Lock__release:
  body: |
    def release(self):
        """Releases the currently locked file handle"""
        pass


code Lock___get_fh:
  body: |
    def _get_fh(self):
        """Get a new filehandle"""
        pass


code Lock___get_lock:
  body: |
    def _get_lock(self, fh: typing.IO):
        """
            Try to lock the given filehandle
    
            returns LockException if it fails
        """
        pass


code Lock___prepare_fh:
  body: |
    def _prepare_fh(self, fh: typing.IO):
        """
            Prepare the filehandle for usage
    
            If truncate is a number, the file will be truncated to that amount of
            bytes
            
        """
        pass
