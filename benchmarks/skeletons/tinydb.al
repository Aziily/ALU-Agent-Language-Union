preamble __init__:
  source: tinydb/__init__.py
  imports: |
    from .queries import Query, where
    from .storages import Storage, JSONStorage
    from .database import TinyDB
    from .version import __version__
  constants: |
    __all__ = ('TinyDB', 'Storage', 'JSONStorage', 'Query', 'where')
  body: |
    "\nTinyDB is a tiny, document oriented database optimized for your happiness :)\n\nTinyDB stores different types of Python data types using a configurable\nstorage mechanism. It comes with a syntax for querying data and storing\ndata in multiple tables.\n\n.. codeauthor:: Markus Siemens <markus@m-siemens.de>\n\nUsage example:\n\n>>> from tinydb import TinyDB, where\n>>> from tinydb.storages import MemoryStorage\n>>> db = TinyDB(storage=MemoryStorage)\n>>> db.insert({'data': 5})  # Insert into '_default' table\n>>> db.search(where('data') == 5)\n[{'data': 5, '_id': 1}]\n>>> # Now let's create a new table\n>>> tbl = db.table('our_table')\n>>> for i in range(10):\n...     tbl.insert({'data': i})\n...\n>>> len(tbl.search(where('data') < 5))\n5\n"


preamble database:
  source: tinydb/database.py
  imports: |
    from typing import Dict, Iterator, Set, Type
    from . import JSONStorage
    from .storages import Storage
    from .table import Table, Document
    from .utils import with_typehint
  constants: |
    TableBase: Type[Table] = with_typehint(Table)
  body: |
    '\nThis module contains the main component of TinyDB: the database.\n'
    class TinyDB(TableBase):
        """
        The main class of TinyDB.

        The ``TinyDB`` class is responsible for creating the storage class instance
        that will store this database's documents, managing the database
        tables as well as providing access to the default table.

        For table management, a simple ``dict`` is used that stores the table class
        instances accessible using their table name.

        Default table access is provided by forwarding all unknown method calls
        and property access operations to the default table by implementing
        ``__getattr__``.

        When creating a new instance, all arguments and keyword arguments (except
        for ``storage``) will be passed to the storage class that is provided. If
        no storage class is specified, :class:`~tinydb.storages.JSONStorage` will be
        used.

        .. admonition:: Customization

            For customization, the following class variables can be set:

            - ``table_class`` defines the class that is used to create tables,
            - ``default_table_name`` defines the name of the default table, and
            - ``default_storage_class`` will define the class that will be used to
              create storage instances if no other storage is passed.

            .. versionadded:: 4.0

        .. admonition:: Data Storage Model

            Data is stored using a storage class that provides persistence for a
            ``dict`` instance. This ``dict`` contains all tables and their data.
            The data is modelled like this::

                {
                    'table1': {
                        0: {document...},
                        1: {document...},
                    },
                    'table2': {
                        ...
                    }
                }

            Each entry in this ``dict`` uses the table name as its key and a
            ``dict`` of documents as its value. The document ``dict`` contains
            document IDs as keys and the documents themselves as values.

        :param storage: The class of the storage to use. Will be initialized
                        with ``args`` and ``kwargs``.
        """
        table_class = Table
        default_table_name = '_default'
        default_storage_class = JSONStorage

        def __init__(self, *args, **kwargs) -> None:
            """
            Create a new instance of TinyDB.
            """
            storage = kwargs.pop('storage', self.default_storage_class)
            self._storage: Storage = storage(*args, **kwargs)
            self._opened = True
            self._tables: Dict[str, Table] = {}

        def __repr__(self):
            args = ['tables={}'.format(list(self.tables())), 'tables_count={}'.format(len(self.tables())), 'default_table_documents_count={}'.format(self.__len__()), 'all_tables_documents_count={}'.format(['{}={}'.format(table, len(self.table(table))) for table in self.tables()])]
            return '<{} {}>'.format(type(self).__name__, ', '.join(args))

        def table(self, name: str, **kwargs) -> Table:
            """
            Get access to a specific table.

            If the table hasn't been accessed yet, a new table instance will be
            created using the :attr:`~tinydb.database.TinyDB.table_class` class.
            Otherwise, the previously created table instance will be returned.

            All further options besides the name are passed to the table class which
            by default is :class:`~tinydb.table.Table`. Check its documentation
            for further parameters you can pass.

            :param name: The name of the table.
            :param kwargs: Keyword arguments to pass to the table class constructor
            """
            pass

        def tables(self) -> Set[str]:
            """
            Get the names of all tables in the database.

            :returns: a set of table names
            """
            pass

        def drop_tables(self) -> None:
            """
            Drop all tables from the database. **CANNOT BE REVERSED!**
            """
            pass

        def drop_table(self, name: str) -> None:
            """
            Drop a specific table from the database. **CANNOT BE REVERSED!**

            :param name: The name of the table to drop.
            """
            pass

        @property
        def storage(self) -> Storage:
            """
            Get the storage instance used for this TinyDB instance.

            :return: This instance's storage
            :rtype: Storage
            """
            pass

        def close(self) -> None:
            """
            Close the database.

            This may be needed if the storage instance used for this database
            needs to perform cleanup operations like closing file handles.

            To ensure this method is called, the TinyDB instance can be used as a
            context manager::

                with TinyDB('data.json') as db:
                    db.insert({'foo': 'bar'})

            Upon leaving this context, the ``close`` method will be called.
            """
            pass

        def __enter__(self):
            """
            Use the database as a context manager.

            Using the database as a context manager ensures that the
            :meth:`~tinydb.database.TinyDB.close` method is called upon leaving
            the context.

            :return: The current instance
            """
            return self

        def __exit__(self, *args):
            """
            Close the storage instance when leaving a context.
            """
            if self._opened:
                self.close()

        def __getattr__(self, name):
            """
            Forward all unknown attribute calls to the default table instance.
            """
            return getattr(self.table(self.default_table_name), name)

        def __len__(self):
            """
            Get the total number of documents in the default table.

            >>> db = TinyDB('db.json')
            >>> len(db)
            0
            """
            return len(self.table(self.default_table_name))

        def __iter__(self) -> Iterator[Document]:
            """
            Return an iterator for the default table's documents.
            """
            return iter(self.table(self.default_table_name))


preamble middlewares:
  source: tinydb/middlewares.py
  imports: |
    from typing import Optional
    from tinydb import Storage
  body: |
    '\nContains the :class:`base class <tinydb.middlewares.Middleware>` for\nmiddlewares and implementations.\n'
    class Middleware:
        """
        The base class for all Middlewares.

        Middlewares hook into the read/write process of TinyDB allowing you to
        extend the behaviour by adding caching, logging, ...

        Your middleware's ``__init__`` method has to call the parent class
        constructor so the middleware chain can be configured properly.
        """

        def __init__(self, storage_cls) -> None:
            self._storage_cls = storage_cls
            self.storage: Storage = None

        def __call__(self, *args, **kwargs):
            """
            Create the storage instance and store it as self.storage.

            Usually a user creates a new TinyDB instance like this::

                TinyDB(storage=StorageClass)

            The storage keyword argument is used by TinyDB this way::

                self.storage = storage(*args, **kwargs)

            As we can see, ``storage(...)`` runs the constructor and returns the
            new storage instance.


            Using Middlewares, the user will call::

                                           The 'real' storage class
                                           v
                TinyDB(storage=Middleware(StorageClass))
                           ^
                           Already an instance!

            So, when running ``self.storage = storage(*args, **kwargs)`` Python
            now will call ``__call__`` and TinyDB will expect the return value to
            be the storage (or Middleware) instance. Returning the instance is
            simple, but we also got the underlying (*real*) StorageClass as an
            __init__ argument that still is not an instance.
            So, we initialize it in __call__ forwarding any arguments we receive
            from TinyDB (``TinyDB(arg1, kwarg1=value, storage=...)``).

            In case of nested Middlewares, calling the instance as if it was a
            class results in calling ``__call__`` what initializes the next
            nested Middleware that itself will initialize the next Middleware and
            so on.
            """
            self.storage = self._storage_cls(*args, **kwargs)
            return self

        def __getattr__(self, name):
            """
            Forward all unknown attribute calls to the underlying storage, so we
            remain as transparent as possible.
            """
            return getattr(self.__dict__['storage'], name)
    class CachingMiddleware(Middleware):
        """
        Add some caching to TinyDB.

        This Middleware aims to improve the performance of TinyDB by writing only
        the last DB state every :attr:`WRITE_CACHE_SIZE` time and reading always
        from cache.
        """
        WRITE_CACHE_SIZE = 1000

        def __init__(self, storage_cls):
            super().__init__(storage_cls)
            self.cache = None
            self._cache_modified_count = 0

        def flush(self):
            """
            Flush all unwritten data to disk.
            """
            pass


preamble mypy_plugin:
  source: tinydb/mypy_plugin.py
  imports: |
    from typing import TypeVar, Optional, Callable, Dict
    from mypy.nodes import NameExpr
    from mypy.options import Options
    from mypy.plugin import Plugin, DynamicClassDefContext
  constants: |
    T = TypeVar('T')
    CB = Optional[Callable[[T], None]]
    DynamicClassDef = DynamicClassDefContext
  body: |
    class TinyDBPlugin(Plugin):

        def __init__(self, options: Options):
            super().__init__(options)
            self.named_placeholders: Dict[str, str] = {}


preamble operations:
  source: tinydb/operations.py
  body: |
    "\nA collection of update operations for TinyDB.\n\nThey are used for updates like this:\n\n>>> db.update(delete('foo'), where('foo') == 2)\n\nThis would delete the ``foo`` field from all documents where ``foo`` equals 2.\n"


preamble queries:
  source: tinydb/queries.py
  imports: |
    import re
    import sys
    from typing import Mapping, Tuple, Callable, Any, Union, List, Optional
    from .utils import freeze
  constants: |
    __all__ = ('Query', 'QueryLike', 'where')
  body: |
    "\nContains the querying interface.\n\nStarting with :class:`~tinydb.queries.Query` you can construct complex\nqueries:\n\n>>> ((where('f1') == 5) & (where('f2') != 2)) | where('s').matches(r'^\\w+$')\n(('f1' == 5) and ('f2' != 2)) or ('s' ~= ^\\w+$ )\n\nQueries are executed by using the ``__call__``:\n\n>>> q = where('val') == 5\n>>> q({'val': 5})\nTrue\n>>> q({'val': 1})\nFalse\n"
    if sys.version_info >= (3, 8):
        from typing import Protocol
    else:
        from typing_extensions import Protocol
    class QueryLike(Protocol):
        """
        A typing protocol that acts like a query.

        Something that we use as a query must have two properties:

        1. It must be callable, accepting a `Mapping` object and returning a
           boolean that indicates whether the value matches the query, and
        2. it must have a stable hash that will be used for query caching.

        In addition, to mark a query as non-cacheable (e.g. if it involves
        some remote lookup) it needs to have a method called ``is_cacheable``
        that returns ``False``.

        This query protocol is used to make MyPy correctly support the query
        pattern that TinyDB uses.

        See also https://mypy.readthedocs.io/en/stable/protocols.html#simple-user-defined-protocols
        """

        def __call__(self, value: Mapping) -> bool:
            ...

        def __hash__(self) -> int:
            ...
    class QueryInstance:
        """
        A query instance.

        This is the object on which the actual query operations are performed. The
        :class:`~tinydb.queries.Query` class acts like a query builder and
        generates :class:`~tinydb.queries.QueryInstance` objects which will
        evaluate their query against a given document when called.

        Query instances can be combined using logical OR and AND and inverted using
        logical NOT.

        In order to be usable in a query cache, a query needs to have a stable hash
        value with the same query always returning the same hash. That way a query
        instance can be used as a key in a dictionary.
        """

        def __init__(self, test: Callable[[Mapping], bool], hashval: Optional[Tuple]):
            self._test = test
            self._hash = hashval

        def __call__(self, value: Mapping) -> bool:
            """
            Evaluate the query to check if it matches a specified value.

            :param value: The value to check.
            :return: Whether the value matches this query.
            """
            return self._test(value)

        def __hash__(self) -> int:
            return hash(self._hash)

        def __repr__(self):
            return 'QueryImpl{}'.format(self._hash)

        def __eq__(self, other: object):
            if isinstance(other, QueryInstance):
                return self._hash == other._hash
            return False

        def __and__(self, other: 'QueryInstance') -> 'QueryInstance':
            if self.is_cacheable() and other.is_cacheable():
                hashval = ('and', frozenset([self._hash, other._hash]))
            else:
                hashval = None
            return QueryInstance(lambda value: self(value) and other(value), hashval)

        def __or__(self, other: 'QueryInstance') -> 'QueryInstance':
            if self.is_cacheable() and other.is_cacheable():
                hashval = ('or', frozenset([self._hash, other._hash]))
            else:
                hashval = None
            return QueryInstance(lambda value: self(value) or other(value), hashval)

        def __invert__(self) -> 'QueryInstance':
            hashval = ('not', self._hash) if self.is_cacheable() else None
            return QueryInstance(lambda value: not self(value), hashval)
    class Query(QueryInstance):
        """
        TinyDB Queries.

        Allows building queries for TinyDB databases. There are two main ways of
        using queries:

        1) ORM-like usage:

        >>> User = Query()
        >>> db.search(User.name == 'John Doe')
        >>> db.search(User['logged-in'] == True)

        2) Classical usage:

        >>> db.search(where('value') == True)

        Note that ``where(...)`` is a shorthand for ``Query(...)`` allowing for
        a more fluent syntax.

        Besides the methods documented here you can combine queries using the
        binary AND and OR operators:

        >>> # Binary AND:
        >>> db.search((where('field1').exists()) & (where('field2') == 5))
        >>> # Binary OR:
        >>> db.search((where('field1').exists()) | (where('field2') == 5))

        Queries are executed by calling the resulting object. They expect to get
        the document to test as the first argument and return ``True`` or
        ``False`` depending on whether the documents match the query or not.
        """

        def __init__(self) -> None:
            self._path: Tuple[Union[str, Callable], ...] = ()

            def notest(_):
                raise RuntimeError('Empty query was evaluated')
            super().__init__(test=notest, hashval=(None,))

        def __repr__(self):
            return '{}()'.format(type(self).__name__)

        def __hash__(self):
            return super().__hash__()

        def __getattr__(self, item: str):
            query = type(self)()
            query._path = self._path + (item,)
            query._hash = ('path', query._path) if self.is_cacheable() else None
            return query

        def __getitem__(self, item: str):
            return self.__getattr__(item)

        def _generate_test(self, test: Callable[[Any], bool], hashval: Tuple, allow_empty_path: bool=False) -> QueryInstance:
            """
            Generate a query based on a test function that first resolves the query
            path.

            :param test: The test the query executes.
            :param hashval: The hash of the query.
            :return: A :class:`~tinydb.queries.QueryInstance` object
            """
            pass

        def __eq__(self, rhs: Any):
            """
            Test a dict value for equality.

            >>> Query().f1 == 42

            :param rhs: The value to compare against
            """
            return self._generate_test(lambda value: value == rhs, ('==', self._path, freeze(rhs)))

        def __ne__(self, rhs: Any):
            """
            Test a dict value for inequality.

            >>> Query().f1 != 42

            :param rhs: The value to compare against
            """
            return self._generate_test(lambda value: value != rhs, ('!=', self._path, freeze(rhs)))

        def __lt__(self, rhs: Any) -> QueryInstance:
            """
            Test a dict value for being lower than another value.

            >>> Query().f1 < 42

            :param rhs: The value to compare against
            """
            return self._generate_test(lambda value: value < rhs, ('<', self._path, rhs))

        def __le__(self, rhs: Any) -> QueryInstance:
            """
            Test a dict value for being lower than or equal to another value.

            >>> where('f1') <= 42

            :param rhs: The value to compare against
            """
            return self._generate_test(lambda value: value <= rhs, ('<=', self._path, rhs))

        def __gt__(self, rhs: Any) -> QueryInstance:
            """
            Test a dict value for being greater than another value.

            >>> Query().f1 > 42

            :param rhs: The value to compare against
            """
            return self._generate_test(lambda value: value > rhs, ('>', self._path, rhs))

        def __ge__(self, rhs: Any) -> QueryInstance:
            """
            Test a dict value for being greater than or equal to another value.

            >>> Query().f1 >= 42

            :param rhs: The value to compare against
            """
            return self._generate_test(lambda value: value >= rhs, ('>=', self._path, rhs))

        def exists(self) -> QueryInstance:
            """
            Test for a dict where a provided key exists.

            >>> Query().f1.exists()
            """
            pass

        def matches(self, regex: str, flags: int=0) -> QueryInstance:
            """
            Run a regex test against a dict value (whole string has to match).

            >>> Query().f1.matches(r'^\\w+$')

            :param regex: The regular expression to use for matching
            :param flags: regex flags to pass to ``re.match``
            """
            pass

        def search(self, regex: str, flags: int=0) -> QueryInstance:
            """
            Run a regex test against a dict value (only substring string has to
            match).

            >>> Query().f1.search(r'^\\w+$')

            :param regex: The regular expression to use for matching
            :param flags: regex flags to pass to ``re.match``
            """
            pass

        def test(self, func: Callable[[Mapping], bool], *args) -> QueryInstance:
            """
            Run a user-defined test function against a dict value.

            >>> def test_func(val):
            ...     return val == 42
            ...
            >>> Query().f1.test(test_func)

            .. warning::

                The test function provided needs to be deterministic (returning the
                same value when provided with the same arguments), otherwise this
                may mess up the query cache that :class:`~tinydb.table.Table`
                implements.

            :param func: The function to call, passing the dict as the first
                         argument
            :param args: Additional arguments to pass to the test function
            """
            pass

        def any(self, cond: Union[QueryInstance, List[Any]]) -> QueryInstance:
            """
            Check if a condition is met by any document in a list,
            where a condition can also be a sequence (e.g. list).

            >>> Query().f1.any(Query().f2 == 1)

            Matches::

                {'f1': [{'f2': 1}, {'f2': 0}]}

            >>> Query().f1.any([1, 2, 3])

            Matches::

                {'f1': [1, 2]}
                {'f1': [3, 4, 5]}

            :param cond: Either a query that at least one document has to match or
                         a list of which at least one document has to be contained
                         in the tested document.
            """
            pass

        def all(self, cond: Union['QueryInstance', List[Any]]) -> QueryInstance:
            """
            Check if a condition is met by all documents in a list,
            where a condition can also be a sequence (e.g. list).

            >>> Query().f1.all(Query().f2 == 1)

            Matches::

                {'f1': [{'f2': 1}, {'f2': 1}]}

            >>> Query().f1.all([1, 2, 3])

            Matches::

                {'f1': [1, 2, 3, 4, 5]}

            :param cond: Either a query that all documents have to match or a list
                         which has to be contained in the tested document.
            """
            pass

        def one_of(self, items: List[Any]) -> QueryInstance:
            """
            Check if the value is contained in a list or generator.

            >>> Query().f1.one_of(['value 1', 'value 2'])

            :param items: The list of items to check with
            """
            pass

        def noop(self) -> QueryInstance:
            """
            Always evaluate to ``True``.

            Useful for having a base value when composing queries dynamically.
            """
            pass

        def map(self, fn: Callable[[Any], Any]) -> 'Query':
            """
            Add a function to the query path. Similar to __getattr__ but for
            arbitrary functions.
            """
            pass


preamble storages:
  source: tinydb/storages.py
  imports: |
    import io
    import json
    import os
    import warnings
    from abc import ABC, abstractmethod
    from typing import Dict, Any, Optional
  constants: |
    __all__ = ('Storage', 'JSONStorage', 'MemoryStorage')
  body: |
    '\nContains the :class:`base class <tinydb.storages.Storage>` for storages and\nimplementations.\n'
    class Storage(ABC):
        """
        The abstract base class for all Storages.

        A Storage (de)serializes the current state of the database and stores it in
        some place (memory, file on disk, ...).
        """

        @abstractmethod
        def read(self) -> Optional[Dict[str, Dict[str, Any]]]:
            """
            Read the current state.

            Any kind of deserialization should go here.

            Return ``None`` here to indicate that the storage is empty.
            """
            pass

        @abstractmethod
        def write(self, data: Dict[str, Dict[str, Any]]) -> None:
            """
            Write the current state of the database to the storage.

            Any kind of serialization should go here.

            :param data: The current state of the database.
            """
            pass

        def close(self) -> None:
            """
            Optional: Close open file handles, etc.
            """
            pass
    class JSONStorage(Storage):
        """
        Store the data in a JSON file.
        """

        def __init__(self, path: str, create_dirs=False, encoding=None, access_mode='r+', **kwargs):
            """
            Create a new instance.

            Also creates the storage file, if it doesn't exist and the access mode
            is appropriate for writing.

            Note: Using an access mode other than `r` or `r+` will probably lead to
            data loss or data corruption!

            :param path: Where to store the JSON data.
            :param access_mode: mode in which the file is opened (r, r+)
            :type access_mode: str
            """
            super().__init__()
            self._mode = access_mode
            self.kwargs = kwargs
            if access_mode not in ('r', 'rb', 'r+', 'rb+'):
                warnings.warn("Using an `access_mode` other than 'r', 'rb', 'r+' or 'rb+' can cause data loss or corruption")
            if any([character in self._mode for character in ('+', 'w', 'a')]):
                touch(path, create_dirs=create_dirs)
            self._handle = open(path, mode=self._mode, encoding=encoding)
    class MemoryStorage(Storage):
        """
        Store the data as JSON in memory.
        """

        def __init__(self):
            """
            Create a new instance.
            """
            super().__init__()
            self.memory = None


preamble table:
  source: tinydb/table.py
  imports: |
    from typing import Callable, Dict, Iterable, Iterator, List, Mapping, Optional, Union, cast, Tuple
    from .queries import QueryLike
    from .storages import Storage
    from .utils import LRUCache
  constants: |
    __all__ = ('Document', 'Table')
  body: |
    '\nThis module implements tables, the central place for accessing and manipulating\ndata in TinyDB.\n'
    class Document(dict):
        """
        A document stored in the database.

        This class provides a way to access both a document's content and
        its ID using ``doc.doc_id``.
        """

        def __init__(self, value: Mapping, doc_id: int):
            super().__init__(value)
            self.doc_id = doc_id
    class Table:
        """
        Represents a single TinyDB table.

        It provides methods for accessing and manipulating documents.

        .. admonition:: Query Cache

            As an optimization, a query cache is implemented using a
            :class:`~tinydb.utils.LRUCache`. This class mimics the interface of
            a normal ``dict``, but starts to remove the least-recently used entries
            once a threshold is reached.

            The query cache is updated on every search operation. When writing
            data, the whole cache is discarded as the query results may have
            changed.

        .. admonition:: Customization

            For customization, the following class variables can be set:

            - ``document_class`` defines the class that is used to represent
              documents,
            - ``document_id_class`` defines the class that is used to represent
              document IDs,
            - ``query_cache_class`` defines the class that is used for the query
              cache
            - ``default_query_cache_capacity`` defines the default capacity of
              the query cache

            .. versionadded:: 4.0


        :param storage: The storage instance to use for this table
        :param name: The table name
        :param cache_size: Maximum capacity of query cache
        """
        document_class = Document
        document_id_class = int
        query_cache_class = LRUCache
        default_query_cache_capacity = 10

        def __init__(self, storage: Storage, name: str, cache_size: int=default_query_cache_capacity):
            """
            Create a table instance.
            """
            self._storage = storage
            self._name = name
            self._query_cache: LRUCache[QueryLike, List[Document]] = self.query_cache_class(capacity=cache_size)
            self._next_id = None

        def __repr__(self):
            args = ['name={!r}'.format(self.name), 'total={}'.format(len(self)), 'storage={}'.format(self._storage)]
            return '<{} {}>'.format(type(self).__name__, ', '.join(args))

        @property
        def name(self) -> str:
            """
            Get the table name.
            """
            pass

        @property
        def storage(self) -> Storage:
            """
            Get the table storage instance.
            """
            pass

        def insert(self, document: Mapping) -> int:
            """
            Insert a new document into the table.

            :param document: the document to insert
            :returns: the inserted document's ID
            """
            pass

        def insert_multiple(self, documents: Iterable[Mapping]) -> List[int]:
            """
            Insert multiple documents into the table.

            :param documents: an Iterable of documents to insert
            :returns: a list containing the inserted documents' IDs
            """
            pass

        def all(self) -> List[Document]:
            """
            Get all documents stored in the table.

            :returns: a list with all documents.
            """
            pass

        def search(self, cond: QueryLike) -> List[Document]:
            """
            Search for all documents matching a 'where' cond.

            :param cond: the condition to check against
            :returns: list of matching documents
            """
            pass

        def get(self, cond: Optional[QueryLike]=None, doc_id: Optional[int]=None, doc_ids: Optional[List]=None) -> Optional[Union[Document, List[Document]]]:
            """
            Get exactly one document specified by a query or a document ID.
            However, if multiple document IDs are given then returns all
            documents in a list.
            
            Returns ``None`` if the document doesn't exist.

            :param cond: the condition to check against
            :param doc_id: the document's ID
            :param doc_ids: the document's IDs(multiple)

            :returns: the document(s) or ``None``
            """
            pass

        def contains(self, cond: Optional[QueryLike]=None, doc_id: Optional[int]=None) -> bool:
            """
            Check whether the database contains a document matching a query or
            an ID.

            If ``doc_id`` is set, it checks if the db contains the specified ID.

            :param cond: the condition use
            :param doc_id: the document ID to look for
            """
            pass

        def update(self, fields: Union[Mapping, Callable[[Mapping], None]], cond: Optional[QueryLike]=None, doc_ids: Optional[Iterable[int]]=None) -> List[int]:
            """
            Update all matching documents to have a given set of fields.

            :param fields: the fields that the matching documents will have
                           or a method that will update the documents
            :param cond: which documents to update
            :param doc_ids: a list of document IDs
            :returns: a list containing the updated document's ID
            """
            pass

        def update_multiple(self, updates: Iterable[Tuple[Union[Mapping, Callable[[Mapping], None]], QueryLike]]) -> List[int]:
            """
            Update all matching documents to have a given set of fields.

            :returns: a list containing the updated document's ID
            """
            pass

        def upsert(self, document: Mapping, cond: Optional[QueryLike]=None) -> List[int]:
            """
            Update documents, if they exist, insert them otherwise.

            Note: This will update *all* documents matching the query. Document
            argument can be a tinydb.table.Document object if you want to specify a
            doc_id.

            :param document: the document to insert or the fields to update
            :param cond: which document to look for, optional if you've passed a
            Document with a doc_id
            :returns: a list containing the updated documents' IDs
            """
            pass

        def remove(self, cond: Optional[QueryLike]=None, doc_ids: Optional[Iterable[int]]=None) -> List[int]:
            """
            Remove all matching documents.

            :param cond: the condition to check against
            :param doc_ids: a list of document IDs
            :returns: a list containing the removed documents' ID
            """
            pass

        def truncate(self) -> None:
            """
            Truncate the table by removing all documents.
            """
            pass

        def count(self, cond: QueryLike) -> int:
            """
            Count the documents matching a query.

            :param cond: the condition use
            """
            pass

        def clear_cache(self) -> None:
            """
            Clear the query cache.
            """
            pass

        def __len__(self):
            """
            Count the total number of documents in this table.
            """
            return len(self._read_table())

        def __iter__(self) -> Iterator[Document]:
            """
            Iterate over all documents stored in the table.

            :returns: an iterator over all documents.
            """
            for doc_id, doc in self._read_table().items():
                yield self.document_class(doc, self.document_id_class(doc_id))

        def _get_next_id(self):
            """
            Return the ID for a newly inserted document.
            """
            pass

        def _read_table(self) -> Dict[str, Mapping]:
            """
            Read the table data from the underlying storage.

            Documents and doc_ids are NOT yet transformed, as 
            we may not want to convert *all* documents when returning
            only one document for example.
            """
            pass

        def _update_table(self, updater: Callable[[Dict[int, Mapping]], None]):
            """
            Perform a table update operation.

            The storage interface used by TinyDB only allows to read/write the
            complete database data, but not modifying only portions of it. Thus,
            to only update portions of the table data, we first perform a read
            operation, perform the update on the table data and then write
            the updated data back to the storage.

            As a further optimization, we don't convert the documents into the
            document class, as the table data will *not* be returned to the user.
            """
            pass


preamble utils:
  source: tinydb/utils.py
  imports: |
    from collections import OrderedDict, abc
    from typing import List, Iterator, TypeVar, Generic, Union, Optional, Type, TYPE_CHECKING
  constants: |
    K = TypeVar('K')
    V = TypeVar('V')
    D = TypeVar('D')
    T = TypeVar('T')
    __all__ = ('LRUCache', 'freeze', 'with_typehint')
  body: |
    '\nUtility functions.\n'
    class LRUCache(abc.MutableMapping, Generic[K, V]):
        """
        A least-recently used (LRU) cache with a fixed cache size.

        This class acts as a dictionary but has a limited size. If the number of
        entries in the cache exceeds the cache size, the least-recently accessed
        entry will be discarded.

        This is implemented using an ``OrderedDict``. On every access the accessed
        entry is moved to the front by re-inserting it into the ``OrderedDict``.
        When adding an entry and the cache size is exceeded, the last entry will
        be discarded.
        """

        def __init__(self, capacity=None) -> None:
            self.capacity = capacity
            self.cache: OrderedDict[K, V] = OrderedDict()

        def __len__(self) -> int:
            return self.length

        def __contains__(self, key: object) -> bool:
            return key in self.cache

        def __setitem__(self, key: K, value: V) -> None:
            self.set(key, value)

        def __delitem__(self, key: K) -> None:
            del self.cache[key]

        def __getitem__(self, key) -> V:
            value = self.get(key)
            if value is None:
                raise KeyError(key)
            return value

        def __iter__(self) -> Iterator[K]:
            return iter(self.cache)
    class FrozenDict(dict):
        """
        An immutable dictionary.

        This is used to generate stable hashes for queries that contain dicts.
        Usually, Python dicts are not hashable because they are mutable. This
        class removes the mutability and implements the ``__hash__`` method.
        """

        def __hash__(self):
            return hash(tuple(sorted(self.items())))
        __setitem__ = _immutable
        __delitem__ = _immutable
        clear = _immutable
        setdefault = _immutable
        popitem = _immutable


preamble version:
  source: tinydb/version.py
  constants: |
    __version__ = '4.8.0'


flow tinydb_lib:
  steps:
    - database_group
    - middlewares_group
    - operations_group
    - queries_group
    - storages_group
    - table_group
    - utils_group


flow database_group:
  steps:
    - TinyDB__table
    - TinyDB__tables
    - TinyDB__drop_tables
    - TinyDB__drop_table
    - TinyDB__storage
    - TinyDB__close


flow middlewares_group:
  steps:
    - CachingMiddleware__flush


flow operations_group:
  steps:
    - delete
    - add
    - subtract
    - set
    - increment
    - decrement


flow queries_group:
  steps:
    - Query___generate_test
    - Query__exists
    - Query__matches
    - Query__search
    - Query__test
    - Query__any
    - Query__all
    - Query__one_of
    - Query__noop
    - Query__map
    - where


flow storages_group:
  steps:
    - touch
    - Storage__read
    - Storage__write
    - Storage__close


flow table_group:
  steps:
    - Table__name
    - Table__storage
    - Table__insert
    - Table__insert_multiple
    - Table__all
    - Table__search
    - Table__get
    - Table__contains
    - Table__update
    - Table__update_multiple
    - Table__upsert
    - Table__remove
    - Table__truncate
    - Table__count
    - Table__clear_cache
    - Table___get_next_id
    - Table___read_table
    - Table___update_table


flow utils_group:
  steps:
    - with_typehint
    - freeze


code TinyDB__table:
  body: |
    def table(self, name: str, **kwargs):
        """
            Get access to a specific table.
    
            If the table hasn't been accessed yet, a new table instance will be
            created using the :attr:`~tinydb.database.TinyDB.table_class` class.
            Otherwise, the previously created table instance will be returned.
    
            All further options besides the name are passed to the table class which
            by default is :class:`~tinydb.table.Table`. Check its documentation
            for further parameters you can pass.
    
            :param name: The name of the table.
            :param kwargs: Keyword arguments to pass to the table class constructor
            
        """
        pass


code TinyDB__tables:
  body: |
    def tables(self):
        """
            Get the names of all tables in the database.
    
            :returns: a set of table names
            
        """
        pass


code TinyDB__drop_tables:
  body: |
    def drop_tables(self):
        """
            Drop all tables from the database. **CANNOT BE REVERSED!**
            
        """
        pass


code TinyDB__drop_table:
  body: |
    def drop_table(self, name: str):
        """
            Drop a specific table from the database. **CANNOT BE REVERSED!**
    
            :param name: The name of the table to drop.
            
        """
        pass


code TinyDB__storage:
  body: |
    def storage(self):
        """
            Get the storage instance used for this TinyDB instance.
    
            :return: This instance's storage
            :rtype: Storage
            
        """
        pass


code TinyDB__close:
  body: |
    def close(self):
        """
            Close the database.
    
            This may be needed if the storage instance used for this database
            needs to perform cleanup operations like closing file handles.
    
            To ensure this method is called, the TinyDB instance can be used as a
            context manager::
    
                with TinyDB('data.json') as db:
                    db.insert({'foo': 'bar'})
    
            Upon leaving this context, the ``close`` method will be called.
            
        """
        pass


code CachingMiddleware__flush:
  body: |
    def flush(self):
        """
            Flush all unwritten data to disk.
            
        """
        pass


code delete:
  body: |
    def delete(field):
        """
        Delete a given field from the document.
        
        """
        pass


code add:
  body: |
    def add(field, n):
        """
        Add ``n`` to a given field in the document.
        
        """
        pass


code subtract:
  body: |
    def subtract(field, n):
        """
        Subtract ``n`` to a given field in the document.
        
        """
        pass


code set:
  body: |
    def set(field, val):
        """
        Set a given field to ``val``.
        
        """
        pass


code increment:
  body: |
    def increment(field):
        """
        Increment a given field in the document by 1.
        
        """
        pass


code decrement:
  body: |
    def decrement(field):
        """
        Decrement a given field in the document by 1.
        
        """
        pass


code Query___generate_test:
  body: |
    def _generate_test(self, test: Callable[[Any], bool], hashval: Tuple, allow_empty_path: bool=False):
        """
            Generate a query based on a test function that first resolves the query
            path.
    
            :param test: The test the query executes.
            :param hashval: The hash of the query.
            :return: A :class:`~tinydb.queries.QueryInstance` object
            
        """
        pass


code Query__exists:
  body: |
    def exists(self):
        """
            Test for a dict where a provided key exists.
    
            >>> Query().f1.exists()
            
        """
        pass


code Query__matches:
  body: |
    def matches(self, regex: str, flags: int=0):
        """
            Run a regex test against a dict value (whole string has to match).
    
            >>> Query().f1.matches(r'^\w+$')
    
            :param regex: The regular expression to use for matching
            :param flags: regex flags to pass to ``re.match``
            
        """
        pass


code Query__search:
  body: |
    def search(self, regex: str, flags: int=0):
        """
            Run a regex test against a dict value (only substring string has to
            match).
    
            >>> Query().f1.search(r'^\w+$')
    
            :param regex: The regular expression to use for matching
            :param flags: regex flags to pass to ``re.match``
            
        """
        pass


code Query__test:
  body: |
    def test(self, func: Callable[[Mapping], bool], *args):
        """
            Run a user-defined test function against a dict value.
    
            >>> def test_func(val):
            ...     return val == 42
            ...
            >>> Query().f1.test(test_func)
    
            .. warning::
    
                The test function provided needs to be deterministic (returning the
                same value when provided with the same arguments), otherwise this
                may mess up the query cache that :class:`~tinydb.table.Table`
                implements.
    
            :param func: The function to call, passing the dict as the first
                         argument
            :param args: Additional arguments to pass to the test function
            
        """
        pass


code Query__any:
  body: |
    def any(self, cond: Union[QueryInstance, List[Any]]):
        """
            Check if a condition is met by any document in a list,
            where a condition can also be a sequence (e.g. list).
    
            >>> Query().f1.any(Query().f2 == 1)
    
            Matches::
    
                {'f1': [{'f2': 1}, {'f2': 0}]}
    
            >>> Query().f1.any([1, 2, 3])
    
            Matches::
    
                {'f1': [1, 2]}
                {'f1': [3, 4, 5]}
    
            :param cond: Either a query that at least one document has to match or
                         a list of which at least one document has to be contained
                         in the tested document.
            
        """
        pass


code Query__all:
  body: |
    def all(self, cond: Union['QueryInstance', List[Any]]):
        """
            Check if a condition is met by all documents in a list,
            where a condition can also be a sequence (e.g. list).
    
            >>> Query().f1.all(Query().f2 == 1)
    
            Matches::
    
                {'f1': [{'f2': 1}, {'f2': 1}]}
    
            >>> Query().f1.all([1, 2, 3])
    
            Matches::
    
                {'f1': [1, 2, 3, 4, 5]}
    
            :param cond: Either a query that all documents have to match or a list
                         which has to be contained in the tested document.
            
        """
        pass


code Query__one_of:
  body: |
    def one_of(self, items: List[Any]):
        """
            Check if the value is contained in a list or generator.
    
            >>> Query().f1.one_of(['value 1', 'value 2'])
    
            :param items: The list of items to check with
            
        """
        pass


code Query__noop:
  body: |
    def noop(self):
        """
            Always evaluate to ``True``.
    
            Useful for having a base value when composing queries dynamically.
            
        """
        pass


code Query__map:
  body: |
    def map(self, fn: Callable[[Any], Any]):
        """
            Add a function to the query path. Similar to __getattr__ but for
            arbitrary functions.
            
        """
        pass


code where:
  body: |
    def where(key: str):
        """
        A shorthand for ``Query()[key]``
        
        """
        pass


code touch:
  body: |
    def touch(path: str, create_dirs: bool):
        """
        Create a file if it doesn't exist yet.
    
        :param path: The file to create.
        :param create_dirs: Whether to create all missing parent directories.
        
        """
        pass


code Storage__read:
  body: |
    def read(self):
        """
            Read the current state.
    
            Any kind of deserialization should go here.
    
            Return ``None`` here to indicate that the storage is empty.
            
        """
        pass


code Storage__write:
  body: |
    def write(self, data: Dict[str, Dict[str, Any]]):
        """
            Write the current state of the database to the storage.
    
            Any kind of serialization should go here.
    
            :param data: The current state of the database.
            
        """
        pass


code Storage__close:
  body: |
    def close(self):
        """
            Optional: Close open file handles, etc.
            
        """
        pass


code Table__name:
  body: |
    def name(self):
        """
            Get the table name.
            
        """
        pass


code Table__storage:
  body: |
    def storage(self):
        """
            Get the table storage instance.
            
        """
        pass


code Table__insert:
  body: |
    def insert(self, document: Mapping):
        """
            Insert a new document into the table.
    
            :param document: the document to insert
            :returns: the inserted document's ID
            
        """
        pass


code Table__insert_multiple:
  body: |
    def insert_multiple(self, documents: Iterable[Mapping]):
        """
            Insert multiple documents into the table.
    
            :param documents: an Iterable of documents to insert
            :returns: a list containing the inserted documents' IDs
            
        """
        pass


code Table__all:
  body: |
    def all(self):
        """
            Get all documents stored in the table.
    
            :returns: a list with all documents.
            
        """
        pass


code Table__search:
  body: |
    def search(self, cond: QueryLike):
        """
            Search for all documents matching a 'where' cond.
    
            :param cond: the condition to check against
            :returns: list of matching documents
            
        """
        pass


code Table__get:
  body: |
    def get(self, cond: Optional[QueryLike]=None, doc_id: Optional[int]=None, doc_ids: Optional[List]=None):
        """
            Get exactly one document specified by a query or a document ID.
            However, if multiple document IDs are given then returns all
            documents in a list.
            
            Returns ``None`` if the document doesn't exist.
    
            :param cond: the condition to check against
            :param doc_id: the document's ID
            :param doc_ids: the document's IDs(multiple)
    
            :returns: the document(s) or ``None``
            
        """
        pass


code Table__contains:
  body: |
    def contains(self, cond: Optional[QueryLike]=None, doc_id: Optional[int]=None):
        """
            Check whether the database contains a document matching a query or
            an ID.
    
            If ``doc_id`` is set, it checks if the db contains the specified ID.
    
            :param cond: the condition use
            :param doc_id: the document ID to look for
            
        """
        pass


code Table__update:
  body: |
    def update(self, fields: Union[Mapping, Callable[[Mapping], None]], cond: Optional[QueryLike]=None, doc_ids: Optional[Iterable[int]]=None):
        """
            Update all matching documents to have a given set of fields.
    
            :param fields: the fields that the matching documents will have
                           or a method that will update the documents
            :param cond: which documents to update
            :param doc_ids: a list of document IDs
            :returns: a list containing the updated document's ID
            
        """
        pass


code Table__update_multiple:
  body: |
    def update_multiple(self, updates: Iterable[Tuple[Union[Mapping, Callable[[Mapping], None]], QueryLike]]):
        """
            Update all matching documents to have a given set of fields.
    
            :returns: a list containing the updated document's ID
            
        """
        pass


code Table__upsert:
  body: |
    def upsert(self, document: Mapping, cond: Optional[QueryLike]=None):
        """
            Update documents, if they exist, insert them otherwise.
    
            Note: This will update *all* documents matching the query. Document
            argument can be a tinydb.table.Document object if you want to specify a
            doc_id.
    
            :param document: the document to insert or the fields to update
            :param cond: which document to look for, optional if you've passed a
            Document with a doc_id
            :returns: a list containing the updated documents' IDs
            
        """
        pass


code Table__remove:
  body: |
    def remove(self, cond: Optional[QueryLike]=None, doc_ids: Optional[Iterable[int]]=None):
        """
            Remove all matching documents.
    
            :param cond: the condition to check against
            :param doc_ids: a list of document IDs
            :returns: a list containing the removed documents' ID
            
        """
        pass


code Table__truncate:
  body: |
    def truncate(self):
        """
            Truncate the table by removing all documents.
            
        """
        pass


code Table__count:
  body: |
    def count(self, cond: QueryLike):
        """
            Count the documents matching a query.
    
            :param cond: the condition use
            
        """
        pass


code Table__clear_cache:
  body: |
    def clear_cache(self):
        """
            Clear the query cache.
            
        """
        pass


code Table___get_next_id:
  body: |
    def _get_next_id(self):
        """
            Return the ID for a newly inserted document.
            
        """
        pass


code Table___read_table:
  body: |
    def _read_table(self):
        """
            Read the table data from the underlying storage.
    
            Documents and doc_ids are NOT yet transformed, as 
            we may not want to convert *all* documents when returning
            only one document for example.
            
        """
        pass


code Table___update_table:
  body: |
    def _update_table(self, updater: Callable[[Dict[int, Mapping]], None]):
        """
            Perform a table update operation.
    
            The storage interface used by TinyDB only allows to read/write the
            complete database data, but not modifying only portions of it. Thus,
            to only update portions of the table data, we first perform a read
            operation, perform the update on the table data and then write
            the updated data back to the storage.
    
            As a further optimization, we don't convert the documents into the
            document class, as the table data will *not* be returned to the user.
            
        """
        pass


code with_typehint:
  body: |
    def with_typehint(baseclass: Type[T]):
        """
        Add type hints from a specified class to a base class:
    
        >>> class Foo(with_typehint(Bar)):
        ...     pass
    
        This would add type hints from class ``Bar`` to class ``Foo``.
    
        Note that while PyCharm and Pyright (for VS Code) understand this pattern,
        MyPy does not. For that reason TinyDB has a MyPy plugin in
        ``mypy_plugin.py`` that adds support for this pattern.
        
        """
        pass


code freeze:
  body: |
    def freeze(obj):
        """
        Freeze an object by making it immutable and thus hashable.
        
        """
        pass
