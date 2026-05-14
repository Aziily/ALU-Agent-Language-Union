flow deprecated_lib:
  steps:
    - classic_group
    - sphinx_group


flow classic_group:
  steps:
    - classic_deprecated
    - ClassicAdapter__get_deprecated_msg


flow sphinx_group:
  steps:
    - sphinx_versionadded
    - sphinx_versionchanged
    - sphinx_deprecated
    - SphinxAdapter__get_deprecated_msg


code classic_deprecated:
  body: |
    def deprecated(*args, **kwargs):
        """
        This is a decorator which can be used to mark functions
        as deprecated. It will result in a warning being emitted
        when the function is used.

        **Classic usage:**

        To use this, decorate your deprecated function with **@deprecated** decorator:

        .. code-block:: python

           from deprecated import deprecated

           @deprecated
           def some_old_function(x, y):
               return x + y

        You can also decorate a class or a method:

        .. code-block:: python

           from deprecated import deprecated

           class SomeClass(object):
               @deprecated
               def some_old_method(self, x, y):
                   return x + y

           @deprecated
           class SomeOldClass(object):
               pass

        You can give a "reason" message to help the developer to choose another function/class,
        and a "version" number to specify the starting version number of the deprecation.

        .. code-block:: python

           from deprecated import deprecated

           @deprecated(reason="use another function", version='1.2.0')
           def some_old_function(x, y):
               return x + y

        The reason message is intended to be passed to the user. The version number
        is used so that a project may decide to remove the deprecated function in a
        future version.
        """
        pass


code ClassicAdapter__get_deprecated_msg:
  body: |
    def get_deprecated_msg(self, wrapped, instance):
        """
        Get the deprecation warning message for the user.

        :param wrapped: Wrapped class or function.

        :param instance: The object to which the wrapped function was bound when it was called.

        :return: The warning message.
        """
        pass


code sphinx_versionadded:
  body: |
    def versionadded(reason='', version='', line_length=70):
        """
        This decorator can be used to insert a "versionadded" directive
        in your function/class docstring in order to documents the
        version of the project which adds this new functionality in your library.

        :param str reason:
            Reason message which documents the addition in your library
            (can be omitted).

        :param str version:
            Version of your project which adds this feature.
            If you follow the `Semantic Versioning <https://semver.org/>`_,
            the version number has the format "MAJOR.MINOR.PATCH".

        :param int line_length:
            Max line length of help text. Set to 0 to disable wrapping.

        :return: the decorated function.
        """
        pass


code sphinx_versionchanged:
  body: |
    def versionchanged(reason='', version='', line_length=70):
        """
        This decorator can be used to insert a "versionchanged" directive
        in your function/class docstring in order to documents the
        version of the project which modifies this functionality in your library.

        :param str reason:
            Reason message which documents the modification in your library
            (can be omitted).

        :param str version:
            Version of your project which modifies this feature.

        :param int line_length:
            Max line length of help text. Set to 0 to disable wrapping.

        :return: the decorated function.
        """
        pass


code sphinx_deprecated:
  body: |
    def deprecated(reason='', version='', line_length=70, **kwargs):
        """
        This decorator can be used to insert a "deprecated" directive
        in your function/class docstring in order to documents the
        version of the project which deprecates this functionality in your library.

        :param str reason:
            Reason message which documents the deprecation in your library (can be omitted).

        :param str version:
            Version of your project which deprecates this feature.

        :param int line_length:
            Max line length of help text. Set to 0 to disable wrapping.

        Keyword arguments can be:

        -   "action": warning filter ("default" if omitted).
        -   "category": warning category (default: DeprecationWarning).

        :return: the decorated function.
        """
        pass


code SphinxAdapter__get_deprecated_msg:
  body: |
    def get_deprecated_msg(self, wrapped, instance):
        """
        Get the deprecation warning message (without Sphinx cross-referencing syntax) for the user.

        :param wrapped: Wrapped class or function.

        :param instance: The object to which the wrapped function was bound when it was called.

        :return: The warning message.
        """
        pass
