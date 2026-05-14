flow portalocker_lib:
  steps:
    - utils_top
    - lock_class_methods


flow utils_top:
  steps:
    - coalesce
    - open_atomic


flow lock_class_methods:
  steps:
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
        (i.e. `is`) so changing the default to `False` would not work.

        >>> coalesce(None, 1)
        1
        >>> coalesce(1, 2)
        1
        >>> coalesce(None, None, 0)
        0
        >>> coalesce(None, None, None, default=1)  # not the right kw, won't work
        Traceback (most recent call last):
        TypeError: coalesce() got an unexpected keyword argument 'default'
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

        returns LockException if it fails"""
        pass


code Lock___prepare_fh:
  body: |
    def _prepare_fh(self, fh: typing.IO):
        """
        Prepare the filehandle for usage

        If truncate is a number, the file will be truncated to that amount of
        bytes"""
        pass
