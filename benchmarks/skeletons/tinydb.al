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
