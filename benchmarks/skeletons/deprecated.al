preamble __init__:
  source: deprecated/__init__.py
  imports: |
    from deprecated.classic import deprecated
  constants: |
    __version__ = '1.2.14'
    __author__ = u'Laurent LAPORTE <tantale.solutions@gmail.com>'
    __date__ = 'unreleased'
    __credits__ = '(c) Laurent LAPORTE'
  body: |
    '\nDeprecated Library\n==================\n\nPython ``@deprecated`` decorator to deprecate old python classes, functions or methods.\n\n'


preamble classic:
  source: deprecated/classic.py
  imports: |
    import functools
    import inspect
    import platform
    import warnings
    import wrapt
  constants: |
    string_types = (type(b''), type(u''))
  body: |
    '\nClassic deprecation warning\n===========================\n\nClassic ``@deprecated`` decorator to deprecate old python classes, functions or methods.\n\n.. _The Warnings Filter: https://docs.python.org/3/library/warnings.html#the-warnings-filter\n'
    try:
        import wrapt._wrappers
        _routine_stacklevel = 2
        _class_stacklevel = 2
    except ImportError:
        _routine_stacklevel = 3
        if platform.python_implementation() == 'PyPy':
            _class_stacklevel = 2
        else:
            _class_stacklevel = 3
    class ClassicAdapter(wrapt.AdapterFactory):
        """
        Classic adapter -- *for advanced usage only*

        This adapter is used to get the deprecation message according to the wrapped object type:
        class, function, standard method, static method, or class method.

        This is the base class of the :class:`~deprecated.sphinx.SphinxAdapter` class
        which is used to update the wrapped object docstring.

        You can also inherit this class to change the deprecation message.

        In the following example, we change the message into "The ... is deprecated.":

        .. code-block:: python

           import inspect

           from deprecated.classic import ClassicAdapter
           from deprecated.classic import deprecated


           class MyClassicAdapter(ClassicAdapter):
               def get_deprecated_msg(self, wrapped, instance):
                   if instance is None:
                       if inspect.isclass(wrapped):
                           fmt = "The class {name} is deprecated."
                       else:
                           fmt = "The function {name} is deprecated."
                   else:
                       if inspect.isclass(instance):
                           fmt = "The class method {name} is deprecated."
                       else:
                           fmt = "The method {name} is deprecated."
                   if self.reason:
                       fmt += " ({reason})"
                   if self.version:
                       fmt += " -- Deprecated since version {version}."
                   return fmt.format(name=wrapped.__name__,
                                     reason=self.reason or "",
                                     version=self.version or "")

        Then, you can use your ``MyClassicAdapter`` class like this in your source code:

        .. code-block:: python

           @deprecated(reason="use another function", adapter_cls=MyClassicAdapter)
           def some_old_function(x, y):
               return x + y
        """

        def __init__(self, reason='', version='', action=None, category=DeprecationWarning):
            """
            Construct a wrapper adapter.

            :type  reason: str
            :param reason:
                Reason message which documents the deprecation in your library (can be omitted).

            :type  version: str
            :param version:
                Version of your project which deprecates this feature.
                If you follow the `Semantic Versioning <https://semver.org/>`_,
                the version number has the format "MAJOR.MINOR.PATCH".

            :type  action: str
            :param action:
                A warning filter used to activate or not the deprecation warning.
                Can be one of "error", "ignore", "always", "default", "module", or "once".
                If ``None`` or empty, the the global filtering mechanism is used.
                See: `The Warnings Filter`_ in the Python documentation.

            :type  category: type
            :param category:
                The warning category to use for the deprecation warning.
                By default, the category class is :class:`~DeprecationWarning`,
                you can inherit this class to define your own deprecation warning category.
            """
            self.reason = reason or ''
            self.version = version or ''
            self.action = action
            self.category = category
            super(ClassicAdapter, self).__init__()

        def get_deprecated_msg(self, wrapped, instance):
            """
            Get the deprecation warning message for the user.

            :param wrapped: Wrapped class or function.

            :param instance: The object to which the wrapped function was bound when it was called.

            :return: The warning message.
            """
            pass

        def __call__(self, wrapped):
            """
            Decorate your class or function.

            :param wrapped: Wrapped class or function.

            :return: the decorated class or function.

            .. versionchanged:: 1.2.4
               Don't pass arguments to :meth:`object.__new__` (other than *cls*).

            .. versionchanged:: 1.2.8
               The warning filter is not set if the *action* parameter is ``None`` or empty.
            """
            if inspect.isclass(wrapped):
                old_new1 = wrapped.__new__

                def wrapped_cls(cls, *args, **kwargs):
                    msg = self.get_deprecated_msg(wrapped, None)
                    if self.action:
                        with warnings.catch_warnings():
                            warnings.simplefilter(self.action, self.category)
                            warnings.warn(msg, category=self.category, stacklevel=_class_stacklevel)
                    else:
                        warnings.warn(msg, category=self.category, stacklevel=_class_stacklevel)
                    if old_new1 is object.__new__:
                        return old_new1(cls)
                    return old_new1(cls, *args, **kwargs)
                wrapped.__new__ = staticmethod(wrapped_cls)
            return wrapped


preamble sphinx:
  source: deprecated/sphinx.py
  imports: |
    import re
    import textwrap
    import wrapt
    from deprecated.classic import ClassicAdapter
    from deprecated.classic import deprecated as _classic_deprecated
  body: |
    '\nSphinx directive integration\n============================\n\nWe usually need to document the life-cycle of functions and classes:\nwhen they are created, modified or deprecated.\n\nTo do that, `Sphinx <http://www.sphinx-doc.org>`_ has a set\nof `Paragraph-level markups <http://www.sphinx-doc.org/en/stable/markup/para.html>`_:\n\n- ``versionadded``: to document the version of the project which added the described feature to the library,\n- ``versionchanged``: to document changes of a feature,\n- ``deprecated``: to document a deprecated feature.\n\nThe purpose of this module is to defined decorators which adds this Sphinx directives\nto the docstring of your function and classes.\n\nOf course, the ``@deprecated`` decorator will emit a deprecation warning\nwhen the function/method is called or the class is constructed.\n'
    class SphinxAdapter(ClassicAdapter):
        """
        Sphinx adapter -- *for advanced usage only*

        This adapter override the :class:`~deprecated.classic.ClassicAdapter`
        in order to add the Sphinx directives to the end of the function/class docstring.
        Such a directive is a `Paragraph-level markup <http://www.sphinx-doc.org/en/stable/markup/para.html>`_

        - The directive can be one of "versionadded", "versionchanged" or "deprecated".
        - The version number is added if provided.
        - The reason message is obviously added in the directive block if not empty.
        """

        def __init__(self, directive, reason='', version='', action=None, category=DeprecationWarning, line_length=70):
            """
            Construct a wrapper adapter.

            :type  directive: str
            :param directive:
                Sphinx directive: can be one of "versionadded", "versionchanged" or "deprecated".

            :type  reason: str
            :param reason:
                Reason message which documents the deprecation in your library (can be omitted).

            :type  version: str
            :param version:
                Version of your project which deprecates this feature.
                If you follow the `Semantic Versioning <https://semver.org/>`_,
                the version number has the format "MAJOR.MINOR.PATCH".

            :type  action: str
            :param action:
                A warning filter used to activate or not the deprecation warning.
                Can be one of "error", "ignore", "always", "default", "module", or "once".
                If ``None`` or empty, the the global filtering mechanism is used.
                See: `The Warnings Filter`_ in the Python documentation.

            :type  category: type
            :param category:
                The warning category to use for the deprecation warning.
                By default, the category class is :class:`~DeprecationWarning`,
                you can inherit this class to define your own deprecation warning category.

            :type  line_length: int
            :param line_length:
                Max line length of the directive text. If non nul, a long text is wrapped in several lines.
            """
            if not version:
                raise ValueError("'version' argument is required in Sphinx directives")
            self.directive = directive
            self.line_length = line_length
            super(SphinxAdapter, self).__init__(reason=reason, version=version, action=action, category=category)

        def __call__(self, wrapped):
            """
            Add the Sphinx directive to your class or function.

            :param wrapped: Wrapped class or function.

            :return: the decorated class or function.
            """
            fmt = '.. {directive}:: {version}' if self.version else '.. {directive}::'
            div_lines = [fmt.format(directive=self.directive, version=self.version)]
            width = self.line_length - 3 if self.line_length > 3 else 2 ** 16
            reason = textwrap.dedent(self.reason).strip()
            for paragraph in reason.splitlines():
                if paragraph:
                    div_lines.extend(textwrap.fill(paragraph, width=width, initial_indent='   ', subsequent_indent='   ').splitlines())
                else:
                    div_lines.append('')
            docstring = wrapped.__doc__ or ''
            lines = docstring.splitlines(keepends=True) or ['']
            docstring = textwrap.dedent(''.join(lines[1:])) if len(lines) > 1 else ''
            docstring = lines[0] + docstring
            if docstring:
                docstring = re.sub('\\n+$', '', docstring, flags=re.DOTALL) + '\n\n'
            else:
                docstring = '\n'
            docstring += ''.join(('{}\n'.format(line) for line in div_lines))
            wrapped.__doc__ = docstring
            if self.directive in {'versionadded', 'versionchanged'}:
                return wrapped
            return super(SphinxAdapter, self).__call__(wrapped)

        def get_deprecated_msg(self, wrapped, instance):
            """
            Get the deprecation warning message (without Sphinx cross-referencing syntax) for the user.

            :param wrapped: Wrapped class or function.

            :param instance: The object to which the wrapped function was bound when it was called.

            :return: The warning message.

            .. versionadded:: 1.2.12
               Strip Sphinx cross-referencing syntax from warning message.

            """
            pass


flow deprecated_lib:
  steps:
    - classic_group
    - sphinx_group


flow classic_group:
  steps:
    - ClassicAdapter__get_deprecated_msg
    - deprecated


flow sphinx_group:
  steps:
    - SphinxAdapter__get_deprecated_msg
    - versionadded
    - versionchanged
    - deprecated


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


code deprecated:
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
    
        You can give a *reason* message to help the developer to choose another function/class,
        and a *version* number to specify the starting version number of the deprecation.
    
        .. code-block:: python
    
           from deprecated import deprecated
    
    
           @deprecated(reason="use another function", version='1.2.0')
           def some_old_function(x, y):
               return x + y
    
        The *category* keyword argument allow you to specify the deprecation warning class of your choice.
        By default, :exc:`DeprecationWarning` is used but you can choose :exc:`FutureWarning`,
        :exc:`PendingDeprecationWarning` or a custom subclass.
    
        .. code-block:: python
    
           from deprecated import deprecated
    
    
           @deprecated(category=PendingDeprecationWarning)
           def some_old_function(x, y):
               return x + y
    
        The *action* keyword argument allow you to locally change the warning filtering.
        *action* can be one of "error", "ignore", "always", "default", "module", or "once".
        If ``None``, empty or missing, the the global filtering mechanism is used.
        See: `The Warnings Filter`_ in the Python documentation.
    
        .. code-block:: python
    
           from deprecated import deprecated
    
    
           @deprecated(action="error")
           def some_old_function(x, y):
               return x + y
    
        
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
    
            .. versionadded:: 1.2.12
               Strip Sphinx cross-referencing syntax from warning message.
    
            
        """
        pass


code versionadded:
  body: |
    def versionadded(reason='', version='', line_length=70):
        """
        This decorator can be used to insert a "versionadded" directive
        in your function/class docstring in order to documents the
        version of the project which adds this new functionality in your library.
    
        :param str reason:
            Reason message which documents the addition in your library (can be omitted).
    
        :param str version:
            Version of your project which adds this feature.
            If you follow the `Semantic Versioning <https://semver.org/>`_,
            the version number has the format "MAJOR.MINOR.PATCH", and,
            in the case of a new functionality, the "PATCH" component should be "0".
    
        :type  line_length: int
        :param line_length:
            Max line length of the directive text. If non nul, a long text is wrapped in several lines.
    
        :return: the decorated function.
        
        """
        pass


code versionchanged:
  body: |
    def versionchanged(reason='', version='', line_length=70):
        """
        This decorator can be used to insert a "versionchanged" directive
        in your function/class docstring in order to documents the
        version of the project which modifies this functionality in your library.
    
        :param str reason:
            Reason message which documents the modification in your library (can be omitted).
    
        :param str version:
            Version of your project which modifies this feature.
            If you follow the `Semantic Versioning <https://semver.org/>`_,
            the version number has the format "MAJOR.MINOR.PATCH".
    
        :type  line_length: int
        :param line_length:
            Max line length of the directive text. If non nul, a long text is wrapped in several lines.
    
        :return: the decorated function.
        
        """
        pass


code deprecated:
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
            If you follow the `Semantic Versioning <https://semver.org/>`_,
            the version number has the format "MAJOR.MINOR.PATCH".
    
        :type  line_length: int
        :param line_length:
            Max line length of the directive text. If non nul, a long text is wrapped in several lines.
    
        Keyword arguments can be:
    
        -   "action":
            A warning filter used to activate or not the deprecation warning.
            Can be one of "error", "ignore", "always", "default", "module", or "once".
            If ``None``, empty or missing, the the global filtering mechanism is used.
    
        -   "category":
            The warning category to use for the deprecation warning.
            By default, the category class is :class:`~DeprecationWarning`,
            you can inherit this class to define your own deprecation warning category.
    
        :return: a decorator used to deprecate a function.
    
        .. versionchanged:: 1.2.13
           Change the signature of the decorator to reflect the valid use cases.
        
        """
        pass
