flow parsel_lib:
  steps:
    - csstranslator_group
    - selector_group
    - utils_group
    - xpathfuncs_group


flow csstranslator_group:
  steps:
    - TranslatorMixin__xpath_pseudo_element
    - TranslatorMixin__xpath_attr_functional_pseudo_element
    - TranslatorMixin__xpath_text_simple_pseudo_element
    - css2xpath


flow selector_group:
  steps:
    - create_root_node
    - SelectorList____getitem__
    - SelectorList____getitem__
    - SelectorList__jmespath
    - SelectorList__xpath
    - SelectorList__css
    - SelectorList__re
    - SelectorList__re_first
    - SelectorList__getall
    - SelectorList__get
    - SelectorList__attrib
    - SelectorList__remove
    - SelectorList__drop
    - Selector__jmespath
    - Selector__xpath
    - Selector__css
    - Selector__re
    - Selector__re_first
    - Selector__get
    - Selector__getall
    - Selector__register_namespace
    - Selector__remove_namespaces
    - Selector__remove
    - Selector__drop
    - Selector__attrib


flow utils_group:
  steps:
    - flatten
    - iflatten
    - _is_listlike
    - extract_regex
    - shorten


flow xpathfuncs_group:
  steps:
    - set_xpathfunc
    - has_class


code TranslatorMixin__xpath_pseudo_element:
  body: |
    def xpath_pseudo_element(self, xpath: OriginalXPathExpr, pseudo_element: PseudoElement):
        """
            Dispatch method that transforms XPath to support pseudo-element
            
        """
        pass


code TranslatorMixin__xpath_attr_functional_pseudo_element:
  body: |
    def xpath_attr_functional_pseudo_element(self, xpath: OriginalXPathExpr, function: FunctionalPseudoElement):
        """Support selecting attribute values using ::attr() pseudo-element"""
        pass


code TranslatorMixin__xpath_text_simple_pseudo_element:
  body: |
    def xpath_text_simple_pseudo_element(self, xpath: OriginalXPathExpr):
        """Support selecting text nodes using ::text pseudo-element"""
        pass


code css2xpath:
  body: |
    def css2xpath(query: str):
        """Return translated XPath version of a given CSS query"""
        pass


code create_root_node:
  body: |
    def create_root_node(text: str, parser_cls: Type[_ParserType], base_url: Optional[str]=None, huge_tree: bool=LXML_SUPPORTS_HUGE_TREE, body: bytes=b'', encoding: str='utf8'):
        """Create root node for text using given parser class."""
        pass


code SelectorList____getitem__:
  body: |
    def __getitem__(self, pos: 'SupportsIndex'):
        pass


code SelectorList____getitem__:
  body: |
    def __getitem__(self, pos: slice):
        pass


code SelectorList__jmespath:
  body: |
    def jmespath(self, query: str, **kwargs: Any):
        """
            Call the ``.jmespath()`` method for each element in this list and return
            their results flattened as another :class:`SelectorList`.
    
            ``query`` is the same argument as the one in :meth:`Selector.jmespath`.
    
            Any additional named arguments are passed to the underlying
            ``jmespath.search`` call, e.g.::
    
                selector.jmespath('author.name', options=jmespath.Options(dict_cls=collections.OrderedDict))
            
        """
        pass


code SelectorList__xpath:
  body: |
    def xpath(self, xpath: str, namespaces: Optional[Mapping[str, str]]=None, **kwargs: Any):
        """
            Call the ``.xpath()`` method for each element in this list and return
            their results flattened as another :class:`SelectorList`.
    
            ``xpath`` is the same argument as the one in :meth:`Selector.xpath`
    
            ``namespaces`` is an optional ``prefix: namespace-uri`` mapping (dict)
            for additional prefixes to those registered with ``register_namespace(prefix, uri)``.
            Contrary to ``register_namespace()``, these prefixes are not
            saved for future calls.
    
            Any additional named arguments can be used to pass values for XPath
            variables in the XPath expression, e.g.::
    
                selector.xpath('//a[href=$url]', url="http://www.example.com")
            
        """
        pass


code SelectorList__css:
  body: |
    def css(self, query: str):
        """
            Call the ``.css()`` method for each element in this list and return
            their results flattened as another :class:`SelectorList`.
    
            ``query`` is the same argument as the one in :meth:`Selector.css`
            
        """
        pass


code SelectorList__re:
  body: |
    def re(self, regex: Union[str, Pattern[str]], replace_entities: bool=True):
        """
            Call the ``.re()`` method for each element in this list and return
            their results flattened, as a list of strings.
    
            By default, character entity references are replaced by their
            corresponding character (except for ``&amp;`` and ``&lt;``.
            Passing ``replace_entities`` as ``False`` switches off these
            replacements.
            
        """
        pass


code SelectorList__re_first:
  body: |
    def re_first(self, regex: Union[str, Pattern[str]], default: Optional[str]=None, replace_entities: bool=True):
        """
            Call the ``.re()`` method for the first element in this list and
            return the result in an string. If the list is empty or the
            regex doesn't match anything, return the default value (``None`` if
            the argument is not provided).
    
            By default, character entity references are replaced by their
            corresponding character (except for ``&amp;`` and ``&lt;``.
            Passing ``replace_entities`` as ``False`` switches off these
            replacements.
            
        """
        pass


code SelectorList__getall:
  body: |
    def getall(self):
        """
            Call the ``.get()`` method for each element is this list and return
            their results flattened, as a list of strings.
            
        """
        pass


code SelectorList__get:
  body: |
    def get(self, default: Optional[str]=None):
        """
            Return the result of ``.get()`` for the first element in this list.
            If the list is empty, return the default value.
            
        """
        pass


code SelectorList__attrib:
  body: |
    def attrib(self):
        """Return the attributes dictionary for the first element.
            If the list is empty, return an empty dict.
            
        """
        pass


code SelectorList__remove:
  body: |
    def remove(self):
        """
            Remove matched nodes from the parent for each element in this list.
            
        """
        pass


code SelectorList__drop:
  body: |
    def drop(self):
        """
            Drop matched nodes from the parent for each element in this list.
            
        """
        pass


code Selector__jmespath:
  body: |
    def jmespath(self: _SelectorType, query: str, **kwargs: Any):
        """
            Find objects matching the JMESPath ``query`` and return the result as a
            :class:`SelectorList` instance with all elements flattened. List
            elements implement :class:`Selector` interface too.
    
            ``query`` is a string containing the `JMESPath
            <https://jmespath.org/>`_ query to apply.
    
            Any additional named arguments are passed to the underlying
            ``jmespath.search`` call, e.g.::
    
                selector.jmespath('author.name', options=jmespath.Options(dict_cls=collections.OrderedDict))
            
        """
        pass


code Selector__xpath:
  body: |
    def xpath(self: _SelectorType, query: str, namespaces: Optional[Mapping[str, str]]=None, **kwargs: Any):
        """
            Find nodes matching the xpath ``query`` and return the result as a
            :class:`SelectorList` instance with all elements flattened. List
            elements implement :class:`Selector` interface too.
    
            ``query`` is a string containing the XPATH query to apply.
    
            ``namespaces`` is an optional ``prefix: namespace-uri`` mapping (dict)
            for additional prefixes to those registered with ``register_namespace(prefix, uri)``.
            Contrary to ``register_namespace()``, these prefixes are not
            saved for future calls.
    
            Any additional named arguments can be used to pass values for XPath
            variables in the XPath expression, e.g.::
    
                selector.xpath('//a[href=$url]', url="http://www.example.com")
            
        """
        pass


code Selector__css:
  body: |
    def css(self: _SelectorType, query: str):
        """
            Apply the given CSS selector and return a :class:`SelectorList` instance.
    
            ``query`` is a string containing the CSS selector to apply.
    
            In the background, CSS queries are translated into XPath queries using
            `cssselect`_ library and run ``.xpath()`` method.
    
            .. _cssselect: https://pypi.python.org/pypi/cssselect/
            
        """
        pass


code Selector__re:
  body: |
    def re(self, regex: Union[str, Pattern[str]], replace_entities: bool=True):
        """
            Apply the given regex and return a list of strings with the
            matches.
    
            ``regex`` can be either a compiled regular expression or a string which
            will be compiled to a regular expression using ``re.compile(regex)``.
    
            By default, character entity references are replaced by their
            corresponding character (except for ``&amp;`` and ``&lt;``).
            Passing ``replace_entities`` as ``False`` switches off these
            replacements.
            
        """
        pass


code Selector__re_first:
  body: |
    def re_first(self, regex: Union[str, Pattern[str]], default: Optional[str]=None, replace_entities: bool=True):
        """
            Apply the given regex and return the first string which matches. If
            there is no match, return the default value (``None`` if the argument
            is not provided).
    
            By default, character entity references are replaced by their
            corresponding character (except for ``&amp;`` and ``&lt;``).
            Passing ``replace_entities`` as ``False`` switches off these
            replacements.
            
        """
        pass


code Selector__get:
  body: |
    def get(self):
        """
            Serialize and return the matched nodes.
    
            For HTML and XML, the result is always a string, and percent-encoded
            content is unquoted.
            
        """
        pass


code Selector__getall:
  body: |
    def getall(self):
        """
            Serialize and return the matched node in a 1-element list of strings.
            
        """
        pass


code Selector__register_namespace:
  body: |
    def register_namespace(self, prefix: str, uri: str):
        """
            Register the given namespace to be used in this :class:`Selector`.
            Without registering namespaces you can't select or extract data from
            non-standard namespaces. See :ref:`selector-examples-xml`.
            
        """
        pass


code Selector__remove_namespaces:
  body: |
    def remove_namespaces(self):
        """
            Remove all namespaces, allowing to traverse the document using
            namespace-less xpaths. See :ref:`removing-namespaces`.
            
        """
        pass


code Selector__remove:
  body: |
    def remove(self):
        """
            Remove matched nodes from the parent element.
            
        """
        pass


code Selector__drop:
  body: |
    def drop(self):
        """
            Drop matched nodes from the parent element.
            
        """
        pass


code Selector__attrib:
  body: |
    def attrib(self):
        """Return the attributes dictionary for underlying element."""
        pass


code flatten:
  body: |
    def flatten(x: Iterable[Any]):
        """flatten(sequence) -> list
        Returns a single, flat list which contains all elements retrieved
        from the sequence and all recursively contained sub-sequences
        (iterables).
        Examples:
        >>> [1, 2, [3,4], (5,6)]
        [1, 2, [3, 4], (5, 6)]
        >>> flatten([[[1,2,3], (42,None)], [4,5], [6], 7, (8,9,10)])
        [1, 2, 3, 42, None, 4, 5, 6, 7, 8, 9, 10]
        >>> flatten(["foo", "bar"])
        ['foo', 'bar']
        >>> flatten(["foo", ["baz", 42], "bar"])
        ['foo', 'baz', 42, 'bar']
        
        """
        pass


code iflatten:
  body: |
    def iflatten(x: Iterable[Any]):
        """iflatten(sequence) -> Iterator
        Similar to ``.flatten()``, but returns iterator instead
        """
        pass


code _is_listlike:
  body: |
    def _is_listlike(x: Any):
        """
        >>> _is_listlike("foo")
        False
        >>> _is_listlike(5)
        False
        >>> _is_listlike(b"foo")
        False
        >>> _is_listlike([b"foo"])
        True
        >>> _is_listlike((b"foo",))
        True
        >>> _is_listlike({})
        True
        >>> _is_listlike(set())
        True
        >>> _is_listlike((x for x in range(3)))
        True
        >>> _is_listlike(range(5))
        True
        
        """
        pass


code extract_regex:
  body: |
    def extract_regex(regex: Union[str, Pattern[str]], text: str, replace_entities: bool=True):
        """Extract a list of strings from the given text/encoding using the following policies:
        * if the regex contains a named group called "extract" that will be returned
        * if the regex contains multiple numbered groups, all those will be returned (flattened)
        * if the regex doesn't contain any group the entire regex matching is returned
        
        """
        pass


code shorten:
  body: |
    def shorten(text: str, width: int, suffix: str='...'):
        """Truncate the given text to fit in the given width."""
        pass


code set_xpathfunc:
  body: |
    def set_xpathfunc(fname: str, func: Optional[Callable]):
        """Register a custom extension function to use in XPath expressions.
    
        The function ``func`` registered under ``fname`` identifier will be called
        for every matching node, being passed a ``context`` parameter as well as
        any parameters passed from the corresponding XPath expression.
    
        If ``func`` is ``None``, the extension function will be removed.
    
        See more `in lxml documentation`_.
    
        .. _`in lxml documentation`: https://lxml.de/extensions.html#xpath-extension-functions
    
        
        """
        pass


code has_class:
  body: |
    def has_class(context: Any, *classes: str):
        """has-class function.
    
        Return True if all ``classes`` are present in element's class attr.
    
        
        """
        pass
