flow wcwidth_lib:
  steps:
    - helpers
    - public_api
    - version_api


flow helpers:
  steps:
    - _bisearch


flow public_api:
  steps:
    - wcwidth
    - wcswidth


flow version_api:
  steps:
    - list_versions
    - _wcversion_value
    - _wcmatch_version


code _bisearch:
  body: |
    def _bisearch(ucs, table):
        """Auxiliary function for binary search in interval table.

        :arg int ucs: Ordinal value of unicode character.
        :arg list table: List of starting and ending ranges of ordinal values,
            in form of ``[(start, end), ...]``.
        :rtype: int
        :returns: 1 if ordinal value ucs is found within lookup table, else 0.
        """
        pass


code wcwidth:
  body: |
    def wcwidth(wc, unicode_version='auto'):
        r"""Given one Unicode character, return its printable length on a terminal.

        :param str wc: A single Unicode character.
        :param str unicode_version: A Unicode version number, such as ``'6.0.0'``.
            A value of ``'auto'`` (default) will select the latest Unicode version.
        :rtype: int
        :returns: The width, in cells, of the character. Returns -1 for
            C0/C1 control characters, 0 for combining or other zero-width chars,
            2 for East Asian Wide and Full-width characters, 1 otherwise.
        """
        pass


code wcswidth:
  body: |
    def wcswidth(pwcs, n=None, unicode_version='auto'):
        """Given a unicode string, return its printable length on a terminal.

        :param str pwcs: Measure width of given unicode string.
        :param int n: When ``n`` is None (default), return the length of the
            entire string; otherwise the first ``n`` characters.
        :param str unicode_version: Unicode version number; ``'auto'`` (default).
        :rtype: int
        :returns: The width, in cells, necessary to display the first ``n``
            characters of the unicode string ``pwcs``. Returns ``-1`` if a
            non-printable character is encountered.
        """
        pass


code list_versions:
  body: |
    def list_versions():
        """Return Unicode version levels supported by this module release.

        Any of the version strings returned may be used as keyword argument
        ``unicode_version`` to the public functions of this module.
        :rtype: list[str]
        """
        pass


code _wcversion_value:
  body: |
    def _wcversion_value(ver_string):
        """Integer-tuple form of unicode version, e.g. ``'6.2.0'`` becomes ``(6, 2, 0)``.

        :param str ver_string: Such as ``"6.2.0"``.
        :rtype: tuple
        """
        pass


code _wcmatch_version:
  body: |
    def _wcmatch_version(given_version):
        """Return nearest matching supported Unicode version level.

        If ``Specifier`` is unmatched, the next-greatest version is returned.

        :param str given_version: Given version for compare, exactly given
            version, or ``"auto"`` for the latest available.
        :rtype: str
        """
        pass
