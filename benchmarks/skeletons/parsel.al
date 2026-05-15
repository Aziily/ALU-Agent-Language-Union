preamble __init__:
  source: parsel/__init__.py
  imports: |
    from parsel import xpathfuncs
    from parsel.csstranslator import css2xpath
    from parsel.selector import Selector, SelectorList
  body: |
    '\nParsel lets you extract text from XML/HTML documents using XPath\nor CSS selectors\n'
    __author__ = 'Scrapy project'
    __email__ = 'info@scrapy.org'
    __version__ = '1.9.1'
    __all__ = ['Selector', 'SelectorList', 'css2xpath', 'xpathfuncs']


preamble csstranslator:
  source: parsel/csstranslator.py
  imports: |
    from functools import lru_cache
    from typing import TYPE_CHECKING, Any, Optional, Protocol
    from cssselect import GenericTranslator as OriginalGenericTranslator
    from cssselect import HTMLTranslator as OriginalHTMLTranslator
    from cssselect.parser import Element, FunctionalPseudoElement, PseudoElement
    from cssselect.xpath import ExpressionError
    from cssselect.xpath import XPathExpr as OriginalXPathExpr
  body: |
    if TYPE_CHECKING:
        from typing_extensions import Self
    class XPathExpr(OriginalXPathExpr):
        textnode: bool = False
        attribute: Optional[str] = None

        def __str__(self) -> str:
            path = super().__str__()
            if self.textnode:
                if path == '*':
                    path = 'text()'
                elif path.endswith('::*/*'):
                    path = path[:-3] + 'text()'
                else:
                    path += '/text()'
            if self.attribute is not None:
                if path.endswith('::*/*'):
                    path = path[:-2]
                path += f'/@{self.attribute}'
            return path
    class TranslatorProtocol(Protocol):
        pass
    class TranslatorMixin:
        """This mixin adds support to CSS pseudo elements via dynamic dispatch.

        Currently supported pseudo-elements are ``::text`` and ``::attr(ATTR_NAME)``.
        """

        def xpath_pseudo_element(self, xpath: OriginalXPathExpr, pseudo_element: PseudoElement) -> OriginalXPathExpr:
            """
            Dispatch method that transforms XPath to support pseudo-element
            """
            pass

        def xpath_attr_functional_pseudo_element(self, xpath: OriginalXPathExpr, function: FunctionalPseudoElement) -> XPathExpr:
            """Support selecting attribute values using ::attr() pseudo-element"""
            pass

        def xpath_text_simple_pseudo_element(self, xpath: OriginalXPathExpr) -> XPathExpr:
            """Support selecting text nodes using ::text pseudo-element"""
            pass
    class GenericTranslator(TranslatorMixin, OriginalGenericTranslator):
        pass
    class HTMLTranslator(TranslatorMixin, OriginalHTMLTranslator):
        pass
    _translator = HTMLTranslator()


preamble selector:
  source: parsel/selector.py
  imports: |
    import json
    import typing
    import warnings
    from io import BytesIO
    from typing import Any, Dict, List, Literal, Mapping, Optional, Pattern, SupportsIndex, Tuple, Type, TypedDict, TypeVar, Union
    from warnings import warn
    import jmespath
    from lxml import etree, html
    from packaging.version import Version
    from .csstranslator import GenericTranslator, HTMLTranslator
    from .utils import extract_regex, flatten, iflatten, shorten
  body: |
    'XPath and JMESPath selectors based on the lxml and jmespath Python\npackages.'
    _SelectorType = TypeVar('_SelectorType', bound='Selector')
    _ParserType = Union[etree.XMLParser, etree.HTMLParser]
    _TostringMethodType = Literal['html', 'xml']
    lxml_version = Version(etree.__version__)
    lxml_huge_tree_version = Version('4.2')
    LXML_SUPPORTS_HUGE_TREE = lxml_version >= lxml_huge_tree_version
    class CannotRemoveElementWithoutRoot(Exception):
        pass
    class CannotRemoveElementWithoutParent(Exception):
        pass
    class CannotDropElementWithoutParent(CannotRemoveElementWithoutParent):
        pass
    class SafeXMLParser(etree.XMLParser):

        def __init__(self, *args: Any, **kwargs: Any) -> None:
            kwargs.setdefault('resolve_entities', False)
            super().__init__(*args, **kwargs)
    class CTGroupValue(TypedDict):
        _parser: Union[Type[etree.XMLParser], Type[html.HTMLParser]]
        _csstranslator: Union[GenericTranslator, HTMLTranslator]
        _tostring_method: str
    _ctgroup: Dict[str, CTGroupValue] = {'html': {'_parser': html.HTMLParser, '_csstranslator': HTMLTranslator(), '_tostring_method': 'html'}, 'xml': {'_parser': SafeXMLParser, '_csstranslator': GenericTranslator(), '_tostring_method': 'xml'}}
    class SelectorList(List[_SelectorType]):
        """
        The :class:`SelectorList` class is a subclass of the builtin ``list``
        class, which provides a few additional methods.
        """

        @typing.overload
        def __getitem__(self, pos: 'SupportsIndex') -> _SelectorType:
            pass

        @typing.overload
        def __getitem__(self, pos: slice) -> 'SelectorList[_SelectorType]':
            pass

        def __getitem__(self, pos: Union['SupportsIndex', slice]) -> Union[_SelectorType, 'SelectorList[_SelectorType]']:
            o = super().__getitem__(pos)
            if isinstance(pos, slice):
                return self.__class__(typing.cast('SelectorList[_SelectorType]', o))
            else:
                return typing.cast(_SelectorType, o)

        def __getstate__(self) -> None:
            raise TypeError("can't pickle SelectorList objects")

        def jmespath(self, query: str, **kwargs: Any) -> 'SelectorList[_SelectorType]':
            """
            Call the ``.jmespath()`` method for each element in this list and return
            their results flattened as another :class:`SelectorList`.

            ``query`` is the same argument as the one in :meth:`Selector.jmespath`.

            Any additional named arguments are passed to the underlying
            ``jmespath.search`` call, e.g.::

                selector.jmespath('author.name', options=jmespath.Options(dict_cls=collections.OrderedDict))
            """
            pass

        def xpath(self, xpath: str, namespaces: Optional[Mapping[str, str]]=None, **kwargs: Any) -> 'SelectorList[_SelectorType]':
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

        def css(self, query: str) -> 'SelectorList[_SelectorType]':
            """
            Call the ``.css()`` method for each element in this list and return
            their results flattened as another :class:`SelectorList`.

            ``query`` is the same argument as the one in :meth:`Selector.css`
            """
            pass

        def re(self, regex: Union[str, Pattern[str]], replace_entities: bool=True) -> List[str]:
            """
            Call the ``.re()`` method for each element in this list and return
            their results flattened, as a list of strings.

            By default, character entity references are replaced by their
            corresponding character (except for ``&amp;`` and ``&lt;``.
            Passing ``replace_entities`` as ``False`` switches off these
            replacements.
            """
            pass

        def re_first(self, regex: Union[str, Pattern[str]], default: Optional[str]=None, replace_entities: bool=True) -> Optional[str]:
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

        def getall(self) -> List[str]:
            """
            Call the ``.get()`` method for each element is this list and return
            their results flattened, as a list of strings.
            """
            pass
        extract = getall

        def get(self, default: Optional[str]=None) -> Any:
            """
            Return the result of ``.get()`` for the first element in this list.
            If the list is empty, return the default value.
            """
            pass
        extract_first = get

        @property
        def attrib(self) -> Mapping[str, str]:
            """Return the attributes dictionary for the first element.
            If the list is empty, return an empty dict.
            """
            pass

        def remove(self) -> None:
            """
            Remove matched nodes from the parent for each element in this list.
            """
            pass

        def drop(self) -> None:
            """
            Drop matched nodes from the parent for each element in this list.
            """
            pass
    _NOT_SET = object()
    class Selector:
        """Wrapper for input data in HTML, JSON, or XML format, that allows
        selecting parts of it using selection expressions.

        You can write selection expressions in CSS or XPath for HTML and XML
        inputs, or in JMESPath for JSON inputs.

        ``text`` is an ``str`` object.

        ``body`` is a ``bytes`` object. It can be used together with the
        ``encoding`` argument instead of the ``text`` argument.

        ``type`` defines the selector type. It can be ``"html"`` (default),
        ``"json"``, or ``"xml"``.

        ``base_url`` allows setting a URL for the document. This is needed when looking up external entities with relative paths.
        See the documentation for :func:`lxml.etree.fromstring` for more information.

        ``huge_tree`` controls the lxml/libxml2 feature that forbids parsing
        certain large documents to protect from possible memory exhaustion. The
        argument is ``True`` by default if the installed lxml version supports it,
        which disables the protection to allow parsing such documents. Set it to
        ``False`` if you want to enable the protection.
        See `this lxml FAQ entry <https://lxml.de/FAQ.html#is-lxml-vulnerable-to-xml-bombs>`_
        for more information.
        """
        __slots__ = ['namespaces', 'type', '_expr', '_huge_tree', 'root', '_text', 'body', '__weakref__']
        _default_namespaces = {'re': 'http://exslt.org/regular-expressions', 'set': 'http://exslt.org/sets'}
        _lxml_smart_strings = False
        selectorlist_cls = SelectorList['Selector']

        def __init__(self, text: Optional[str]=None, type: Optional[str]=None, body: bytes=b'', encoding: str='utf8', namespaces: Optional[Mapping[str, str]]=None, root: Optional[Any]=_NOT_SET, base_url: Optional[str]=None, _expr: Optional[str]=None, huge_tree: bool=LXML_SUPPORTS_HUGE_TREE) -> None:
            self.root: Any
            if type not in ('html', 'json', 'text', 'xml', None):
                raise ValueError(f'Invalid type: {type}')
            if text is None and (not body) and (root is _NOT_SET):
                raise ValueError('Selector needs text, body, or root arguments')
            if text is not None and (not isinstance(text, str)):
                msg = f'text argument should be of type str, got {text.__class__}'
                raise TypeError(msg)
            if text is not None:
                if root is not _NOT_SET:
                    warnings.warn('Selector got both text and root, root is being ignored.', stacklevel=2)
                if not isinstance(text, str):
                    msg = f'text argument should be of type str, got {text.__class__}'
                    raise TypeError(msg)
                root, type = _get_root_and_type_from_text(text, input_type=type, base_url=base_url, huge_tree=huge_tree)
                self.root = root
                self.type = type
            elif body:
                if not isinstance(body, bytes):
                    msg = f'body argument should be of type bytes, got {body.__class__}'
                    raise TypeError(msg)
                root, type = _get_root_and_type_from_bytes(body=body, encoding=encoding, input_type=type, base_url=base_url, huge_tree=huge_tree)
                self.root = root
                self.type = type
            elif root is _NOT_SET:
                raise ValueError('Selector needs text, body, or root arguments')
            else:
                self.root = root
                self.type = _get_root_type(root, input_type=type)
            self.namespaces = dict(self._default_namespaces)
            if namespaces is not None:
                self.namespaces.update(namespaces)
            self._expr = _expr
            self._huge_tree = huge_tree
            self._text = text

        def __getstate__(self) -> Any:
            raise TypeError("can't pickle Selector objects")

        def jmespath(self: _SelectorType, query: str, **kwargs: Any) -> SelectorList[_SelectorType]:
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

        def xpath(self: _SelectorType, query: str, namespaces: Optional[Mapping[str, str]]=None, **kwargs: Any) -> SelectorList[_SelectorType]:
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

        def css(self: _SelectorType, query: str) -> SelectorList[_SelectorType]:
            """
            Apply the given CSS selector and return a :class:`SelectorList` instance.

            ``query`` is a string containing the CSS selector to apply.

            In the background, CSS queries are translated into XPath queries using
            `cssselect`_ library and run ``.xpath()`` method.

            .. _cssselect: https://pypi.python.org/pypi/cssselect/
            """
            pass

        def re(self, regex: Union[str, Pattern[str]], replace_entities: bool=True) -> List[str]:
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

        def re_first(self, regex: Union[str, Pattern[str]], default: Optional[str]=None, replace_entities: bool=True) -> Optional[str]:
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

        def get(self) -> Any:
            """
            Serialize and return the matched nodes.

            For HTML and XML, the result is always a string, and percent-encoded
            content is unquoted.
            """
            pass
        extract = get

        def getall(self) -> List[str]:
            """
            Serialize and return the matched node in a 1-element list of strings.
            """
            pass

        def register_namespace(self, prefix: str, uri: str) -> None:
            """
            Register the given namespace to be used in this :class:`Selector`.
            Without registering namespaces you can't select or extract data from
            non-standard namespaces. See :ref:`selector-examples-xml`.
            """
            pass

        def remove_namespaces(self) -> None:
            """
            Remove all namespaces, allowing to traverse the document using
            namespace-less xpaths. See :ref:`removing-namespaces`.
            """
            pass

        def remove(self) -> None:
            """
            Remove matched nodes from the parent element.
            """
            pass

        def drop(self) -> None:
            """
            Drop matched nodes from the parent element.
            """
            pass

        @property
        def attrib(self) -> Dict[str, str]:
            """Return the attributes dictionary for underlying element."""
            pass

        def __bool__(self) -> bool:
            """
            Return ``True`` if there is any real content selected or ``False``
            otherwise.  In other words, the boolean value of a :class:`Selector` is
            given by the contents it selects.
            """
            return bool(self.get())
        __nonzero__ = __bool__

        def __str__(self) -> str:
            return str(self.get())

        def __repr__(self) -> str:
            data = repr(shorten(str(self.get()), width=40))
            return f'<{type(self).__name__} query={self._expr!r} data={data}>'


preamble utils:
  source: parsel/utils.py
  imports: |
    import re
    from typing import Any, Iterable, Iterator, List, Match, Pattern, Union, cast
    from w3lib.html import replace_entities as w3lib_replace_entities


preamble xpathfuncs:
  source: parsel/xpathfuncs.py
  imports: |
    import re
    from typing import Any, Callable, Optional
    from lxml import etree
    from w3lib.html import HTML5_WHITESPACE
  body: |
    regex = f'[{HTML5_WHITESPACE}]+'
    replace_html5_whitespaces = re.compile(regex).sub


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
