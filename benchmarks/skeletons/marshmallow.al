flow marshmallow_lib:
  steps:
    - class_registry_group
    - decorators_group
    - error_store_group
    - fields_group
    - schema_group
    - utils_group
    - validate_group


flow class_registry_group:
  steps:
    - register
    - get_class


flow decorators_group:
  steps:
    - validates
    - validates_schema
    - pre_dump
    - post_dump
    - pre_load
    - post_load
    - set_hook


flow error_store_group:
  steps:
    - merge_errors


flow fields_group:
  steps:
    - Field__get_value
    - Field___validate
    - Field__make_error
    - Field__fail
    - Field___validate_missing
    - Field__serialize
    - Field__deserialize
    - Field___bind_to_schema
    - Field___serialize
    - Field___deserialize
    - Field__context
    - Nested__schema
    - Nested___deserialize
    - UUID___validated
    - Number___format_num
    - Number___validated
    - Number___serialize


flow schema_group:
  steps:
    - _get_fields
    - _get_fields_by_mro
    - SchemaMeta__get_declared_fields
    - SchemaMeta__resolve_hooks
    - Schema__from_dict
    - Schema__handle_error
    - Schema__get_attribute
    - Schema___call_and_store
    - Schema___serialize
    - Schema__dump
    - Schema__dumps
    - Schema___deserialize
    - Schema__load
    - Schema__loads
    - Schema__validate
    - Schema___do_load
    - Schema___normalize_nested_options
    - Schema____apply_nested_option
    - Schema___init_fields
    - Schema__on_bind_field
    - Schema___bind_field


flow utils_group:
  steps:
    - is_generator
    - is_iterable_but_not_string
    - is_collection
    - is_instance_or_subclass
    - is_keyed_tuple
    - pprint
    - from_rfc
    - rfcformat
    - get_fixed_timezone
    - from_iso_datetime
    - from_iso_time
    - from_iso_date
    - isoformat
    - pluck
    - get_value
    - set_value
    - callable_or_raise
    - get_func_args
    - resolve_field_instance
    - timedelta_to_microseconds


flow validate_group:
  steps:
    - Validator___repr_args
    - OneOf__options


code register:
  body: |
    def register(classname: str, cls: SchemaType):
        """Add a class to the registry of serializer classes. When a class is
        registered, an entry for both its classname and its full, module-qualified
        path are added to the registry.
    
        Example: ::
    
            class MyClass:
                pass
    
    
            register("MyClass", MyClass)
            # Registry:
            # {
            #   'MyClass': [path.to.MyClass],
            #   'path.to.MyClass': [path.to.MyClass],
            # }
    
        
        """
        pass


code get_class:
  body: |
    def get_class(classname: str, all: bool=False):
        """Retrieve a class from the registry.
    
        :raises: marshmallow.exceptions.RegistryError if the class cannot be found
            or if there are multiple entries for the given class name.
        
        """
        pass


code validates:
  body: |
    def validates(field_name: str):
        """Register a field validator.
    
        :param str field_name: Name of the field that the method validates.
        
        """
        pass


code validates_schema:
  body: |
    def validates_schema(fn: Callable[..., Any] | None=None, pass_many: bool=False, pass_original: bool=False, skip_on_field_errors: bool=True):
        """Register a schema-level validator.
    
        By default it receives a single object at a time, transparently handling the ``many``
        argument passed to the `Schema`'s :func:`~marshmallow.Schema.validate` call.
        If ``pass_many=True``, the raw data (which may be a collection) is passed.
    
        If ``pass_original=True``, the original data (before unmarshalling) will be passed as
        an additional argument to the method.
    
        If ``skip_on_field_errors=True``, this validation method will be skipped whenever
        validation errors have been detected when validating fields.
    
        .. versionchanged:: 3.0.0b1
            ``skip_on_field_errors`` defaults to `True`.
    
        .. versionchanged:: 3.0.0
            ``partial`` and ``many`` are always passed as keyword arguments to
            the decorated method.
        
        """
        pass


code pre_dump:
  body: |
    def pre_dump(fn: Callable[..., Any] | None=None, pass_many: bool=False):
        """Register a method to invoke before serializing an object. The method
        receives the object to be serialized and returns the processed object.
    
        By default it receives a single object at a time, transparently handling the ``many``
        argument passed to the `Schema`'s :func:`~marshmallow.Schema.dump` call.
        If ``pass_many=True``, the raw data (which may be a collection) is passed.
    
        .. versionchanged:: 3.0.0
            ``many`` is always passed as a keyword arguments to the decorated method.
        
        """
        pass


code post_dump:
  body: |
    def post_dump(fn: Callable[..., Any] | None=None, pass_many: bool=False, pass_original: bool=False):
        """Register a method to invoke after serializing an object. The method
        receives the serialized object and returns the processed object.
    
        By default it receives a single object at a time, transparently handling the ``many``
        argument passed to the `Schema`'s :func:`~marshmallow.Schema.dump` call.
        If ``pass_many=True``, the raw data (which may be a collection) is passed.
    
        If ``pass_original=True``, the original data (before serializing) will be passed as
        an additional argument to the method.
    
        .. versionchanged:: 3.0.0
            ``many`` is always passed as a keyword arguments to the decorated method.
        
        """
        pass


code pre_load:
  body: |
    def pre_load(fn: Callable[..., Any] | None=None, pass_many: bool=False):
        """Register a method to invoke before deserializing an object. The method
        receives the data to be deserialized and returns the processed data.
    
        By default it receives a single object at a time, transparently handling the ``many``
        argument passed to the `Schema`'s :func:`~marshmallow.Schema.load` call.
        If ``pass_many=True``, the raw data (which may be a collection) is passed.
    
        .. versionchanged:: 3.0.0
            ``partial`` and ``many`` are always passed as keyword arguments to
            the decorated method.
        
        """
        pass


code post_load:
  body: |
    def post_load(fn: Callable[..., Any] | None=None, pass_many: bool=False, pass_original: bool=False):
        """Register a method to invoke after deserializing an object. The method
        receives the deserialized data and returns the processed data.
    
        By default it receives a single object at a time, transparently handling the ``many``
        argument passed to the `Schema`'s :func:`~marshmallow.Schema.load` call.
        If ``pass_many=True``, the raw data (which may be a collection) is passed.
    
        If ``pass_original=True``, the original data (before deserializing) will be passed as
        an additional argument to the method.
    
        .. versionchanged:: 3.0.0
            ``partial`` and ``many`` are always passed as keyword arguments to
            the decorated method.
        
        """
        pass


code set_hook:
  body: |
    def set_hook(fn: Callable[..., Any] | None, key: tuple[str, bool] | str, **kwargs: Any):
        """Mark decorated function as a hook to be picked up later.
        You should not need to use this method directly.
    
        .. note::
            Currently only works with functions and instance methods. Class and
            static methods are not supported.
    
        :return: Decorated function if supplied, else this decorator with its args
            bound.
        
        """
        pass


code merge_errors:
  body: |
    def merge_errors(errors1, errors2):
        """Deeply merge two error messages.
    
        The format of ``errors1`` and ``errors2`` matches the ``message``
        parameter of :exc:`marshmallow.exceptions.ValidationError`.
        
        """
        pass


code Field__get_value:
  body: |
    def get_value(self, obj, attr, accessor=None, default=missing_):
        """Return the value for a given key from an object.
    
            :param object obj: The object to get the value from.
            :param str attr: The attribute/key in `obj` to get the value from.
            :param callable accessor: A callable used to retrieve the value of `attr` from
                the object `obj`. Defaults to `marshmallow.utils.get_value`.
            
        """
        pass


code Field___validate:
  body: |
    def _validate(self, value):
        """Perform validation on ``value``. Raise a :exc:`ValidationError` if validation
            does not succeed.
            
        """
        pass


code Field__make_error:
  body: |
    def make_error(self, key: str, **kwargs):
        """Helper method to make a `ValidationError` with an error message
            from ``self.error_messages``.
            
        """
        pass


code Field__fail:
  body: |
    def fail(self, key: str, **kwargs):
        """Helper method that raises a `ValidationError` with an error message
            from ``self.error_messages``.
    
            .. deprecated:: 3.0.0
                Use `make_error <marshmallow.fields.Field.make_error>` instead.
            
        """
        pass


code Field___validate_missing:
  body: |
    def _validate_missing(self, value):
        """Validate missing values. Raise a :exc:`ValidationError` if
            `value` should be considered missing.
            
        """
        pass


code Field__serialize:
  body: |
    def serialize(self, attr: str, obj: typing.Any, accessor: typing.Callable[[typing.Any, str, typing.Any], typing.Any] | None=None, **kwargs):
        """Pulls the value for the given key from the object, applies the
            field's formatting and returns the result.
    
            :param attr: The attribute/key to get from the object.
            :param obj: The object to access the attribute/key from.
            :param accessor: Function used to access values from ``obj``.
            :param kwargs: Field-specific keyword arguments.
            
        """
        pass


code Field__deserialize:
  body: |
    def deserialize(self, value: typing.Any, attr: str | None=None, data: typing.Mapping[str, typing.Any] | None=None, **kwargs):
        """Deserialize ``value``.
    
            :param value: The value to deserialize.
            :param attr: The attribute/key in `data` to deserialize.
            :param data: The raw input data passed to `Schema.load`.
            :param kwargs: Field-specific keyword arguments.
            :raise ValidationError: If an invalid value is passed or if a required value
                is missing.
            
        """
        pass


code Field___bind_to_schema:
  body: |
    def _bind_to_schema(self, field_name, schema):
        """Update field with values from its parent schema. Called by
            :meth:`Schema._bind_field <marshmallow.Schema._bind_field>`.
    
            :param str field_name: Field name set in schema.
            :param Schema|Field schema: Parent object.
            
        """
        pass


code Field___serialize:
  body: |
    def _serialize(self, value: typing.Any, attr: str | None, obj: typing.Any, **kwargs):
        """Serializes ``value`` to a basic Python datatype. Noop by default.
            Concrete :class:`Field` classes should implement this method.
    
            Example: ::
    
                class TitleCase(Field):
                    def _serialize(self, value, attr, obj, **kwargs):
                        if not value:
                            return ""
                        return str(value).title()
    
            :param value: The value to be serialized.
            :param str attr: The attribute or key on the object to be serialized.
            :param object obj: The object the value was pulled from.
            :param dict kwargs: Field-specific keyword arguments.
            :return: The serialized value
            
        """
        pass


code Field___deserialize:
  body: |
    def _deserialize(self, value: typing.Any, attr: str | None, data: typing.Mapping[str, typing.Any] | None, **kwargs):
        """Deserialize value. Concrete :class:`Field` classes should implement this method.
    
            :param value: The value to be deserialized.
            :param attr: The attribute/key in `data` to be deserialized.
            :param data: The raw input data passed to the `Schema.load`.
            :param kwargs: Field-specific keyword arguments.
            :raise ValidationError: In case of formatting or validation failure.
            :return: The deserialized value.
    
            .. versionchanged:: 2.0.0
                Added ``attr`` and ``data`` parameters.
    
            .. versionchanged:: 3.0.0
                Added ``**kwargs`` to signature.
            
        """
        pass


code Field__context:
  body: |
    def context(self):
        """The context dictionary for the parent :class:`Schema`."""
        pass


code Nested__schema:
  body: |
    def schema(self):
        """The nested Schema object.
    
            .. versionchanged:: 1.0.0
                Renamed from `serializer` to `schema`.
            
        """
        pass


code Nested___deserialize:
  body: |
    def _deserialize(self, value, attr, data, partial=None, **kwargs):
        """Same as :meth:`Field._deserialize` with additional ``partial`` argument.
    
            :param bool|tuple partial: For nested schemas, the ``partial``
                parameter passed to `Schema.load`.
    
            .. versionchanged:: 3.0.0
                Add ``partial`` parameter.
            
        """
        pass


code UUID___validated:
  body: |
    def _validated(self, value):
        """Format the value or raise a :exc:`ValidationError` if an error occurs."""
        pass


code Number___format_num:
  body: |
    def _format_num(self, value):
        """Return the number value for value, given this field's `num_type`."""
        pass


code Number___validated:
  body: |
    def _validated(self, value):
        """Format the value or raise a :exc:`ValidationError` if an error occurs."""
        pass


code Number___serialize:
  body: |
    def _serialize(self, value, attr, obj, **kwargs):
        """Return a string if `self.as_string=True`, otherwise return this field's `num_type`."""
        pass


code _get_fields:
  body: |
    def _get_fields(attrs):
        """Get fields from a class
    
        :param attrs: Mapping of class attributes
        
        """
        pass


code _get_fields_by_mro:
  body: |
    def _get_fields_by_mro(klass):
        """Collect fields from a class, following its method resolution order. The
        class itself is excluded from the search; only its parents are checked. Get
        fields from ``_declared_fields`` if available, else use ``__dict__``.
    
        :param type klass: Class whose fields to retrieve
        
        """
        pass


code SchemaMeta__get_declared_fields:
  body: |
    def get_declared_fields(mcs, klass: type, cls_fields: list, inherited_fields: list, dict_cls: type=dict):
        """Returns a dictionary of field_name => `Field` pairs declared on the class.
            This is exposed mainly so that plugins can add additional fields, e.g. fields
            computed from class Meta options.
    
            :param klass: The class object.
            :param cls_fields: The fields declared on the class, including those added
                by the ``include`` class Meta option.
            :param inherited_fields: Inherited fields.
            :param dict_cls: dict-like class to use for dict output Default to ``dict``.
            
        """
        pass


code SchemaMeta__resolve_hooks:
  body: |
    def resolve_hooks(cls):
        """Add in the decorated processors
    
            By doing this after constructing the class, we let standard inheritance
            do all the hard work.
            
        """
        pass


code Schema__from_dict:
  body: |
    def from_dict(cls, fields: dict[str, ma_fields.Field | type], *, name: str='GeneratedSchema'):
        """Generate a `Schema` class given a dictionary of fields.
    
            .. code-block:: python
    
                from marshmallow import Schema, fields
    
                PersonSchema = Schema.from_dict({"name": fields.Str()})
                print(PersonSchema().load({"name": "David"}))  # => {'name': 'David'}
    
            Generated schemas are not added to the class registry and therefore cannot
            be referred to by name in `Nested` fields.
    
            :param dict fields: Dictionary mapping field names to field instances.
            :param str name: Optional name for the class, which will appear in
                the ``repr`` for the class.
    
            .. versionadded:: 3.0.0
            
        """
        pass


code Schema__handle_error:
  body: |
    def handle_error(self, error: ValidationError, data: typing.Any, *, many: bool, **kwargs):
        """Custom error handler function for the schema.
    
            :param error: The `ValidationError` raised during (de)serialization.
            :param data: The original input data.
            :param many: Value of ``many`` on dump or load.
            :param partial: Value of ``partial`` on load.
    
            .. versionadded:: 2.0.0
    
            .. versionchanged:: 3.0.0rc9
                Receives `many` and `partial` (on deserialization) as keyword arguments.
            
        """
        pass


code Schema__get_attribute:
  body: |
    def get_attribute(self, obj: typing.Any, attr: str, default: typing.Any):
        """Defines how to pull values from an object to serialize.
    
            .. versionadded:: 2.0.0
    
            .. versionchanged:: 3.0.0a1
                Changed position of ``obj`` and ``attr``.
            
        """
        pass


code Schema___call_and_store:
  body: |
    def _call_and_store(getter_func, data, *, field_name, error_store, index=None):
        """Call ``getter_func`` with ``data`` as its argument, and store any `ValidationErrors`.
    
            :param callable getter_func: Function for getting the serialized/deserialized
                value from ``data``.
            :param data: The data passed to ``getter_func``.
            :param str field_name: Field name.
            :param int index: Index of the item being validated, if validating a collection,
                otherwise `None`.
            
        """
        pass


code Schema___serialize:
  body: |
    def _serialize(self, obj: _T | typing.Iterable[_T], *, many: bool=False):
        """Serialize ``obj``.
    
            :param obj: The object(s) to serialize.
            :param bool many: `True` if ``data`` should be serialized as a collection.
            :return: A dictionary of the serialized data
    
            .. versionchanged:: 1.0.0
                Renamed from ``marshal``.
            
        """
        pass


code Schema__dump:
  body: |
    def dump(self, obj: typing.Any, *, many: bool | None=None):
        """Serialize an object to native Python data types according to this
            Schema's fields.
    
            :param obj: The object to serialize.
            :param many: Whether to serialize `obj` as a collection. If `None`, the value
                for `self.many` is used.
            :return: Serialized data
    
            .. versionadded:: 1.0.0
            .. versionchanged:: 3.0.0b7
                This method returns the serialized data rather than a ``(data, errors)`` duple.
                A :exc:`ValidationError <marshmallow.exceptions.ValidationError>` is raised
                if ``obj`` is invalid.
            .. versionchanged:: 3.0.0rc9
                Validation no longer occurs upon serialization.
            
        """
        pass


code Schema__dumps:
  body: |
    def dumps(self, obj: typing.Any, *args, many: bool | None=None, **kwargs):
        """Same as :meth:`dump`, except return a JSON-encoded string.
    
            :param obj: The object to serialize.
            :param many: Whether to serialize `obj` as a collection. If `None`, the value
                for `self.many` is used.
            :return: A ``json`` string
    
            .. versionadded:: 1.0.0
            .. versionchanged:: 3.0.0b7
                This method returns the serialized data rather than a ``(data, errors)`` duple.
                A :exc:`ValidationError <marshmallow.exceptions.ValidationError>` is raised
                if ``obj`` is invalid.
            
        """
        pass


code Schema___deserialize:
  body: |
    def _deserialize(self, data: typing.Mapping[str, typing.Any] | typing.Iterable[typing.Mapping[str, typing.Any]], *, error_store: ErrorStore, many: bool=False, partial=None, unknown=RAISE, index=None):
        """Deserialize ``data``.
    
            :param dict data: The data to deserialize.
            :param ErrorStore error_store: Structure to store errors.
            :param bool many: `True` if ``data`` should be deserialized as a collection.
            :param bool|tuple partial: Whether to ignore missing fields and not require
                any fields declared. Propagates down to ``Nested`` fields as well. If
                its value is an iterable, only missing fields listed in that iterable
                will be ignored. Use dot delimiters to specify nested fields.
            :param unknown: Whether to exclude, include, or raise an error for unknown
                fields in the data. Use `EXCLUDE`, `INCLUDE` or `RAISE`.
            :param int index: Index of the item being serialized (for storing errors) if
                serializing a collection, otherwise `None`.
            :return: A dictionary of the deserialized data.
            
        """
        pass


code Schema__load:
  body: |
    def load(self, data: typing.Mapping[str, typing.Any] | typing.Iterable[typing.Mapping[str, typing.Any]], *, many: bool | None=None, partial: bool | types.StrSequenceOrSet | None=None, unknown: str | None=None):
        """Deserialize a data structure to an object defined by this Schema's fields.
    
            :param data: The data to deserialize.
            :param many: Whether to deserialize `data` as a collection. If `None`, the
                value for `self.many` is used.
            :param partial: Whether to ignore missing fields and not require
                any fields declared. Propagates down to ``Nested`` fields as well. If
                its value is an iterable, only missing fields listed in that iterable
                will be ignored. Use dot delimiters to specify nested fields.
            :param unknown: Whether to exclude, include, or raise an error for unknown
                fields in the data. Use `EXCLUDE`, `INCLUDE` or `RAISE`.
                If `None`, the value for `self.unknown` is used.
            :return: Deserialized data
    
            .. versionadded:: 1.0.0
            .. versionchanged:: 3.0.0b7
                This method returns the deserialized data rather than a ``(data, errors)`` duple.
                A :exc:`ValidationError <marshmallow.exceptions.ValidationError>` is raised
                if invalid data are passed.
            
        """
        pass


code Schema__loads:
  body: |
    def loads(self, json_data: str, *, many: bool | None=None, partial: bool | types.StrSequenceOrSet | None=None, unknown: str | None=None, **kwargs):
        """Same as :meth:`load`, except it takes a JSON string as input.
    
            :param json_data: A JSON string of the data to deserialize.
            :param many: Whether to deserialize `obj` as a collection. If `None`, the
                value for `self.many` is used.
            :param partial: Whether to ignore missing fields and not require
                any fields declared. Propagates down to ``Nested`` fields as well. If
                its value is an iterable, only missing fields listed in that iterable
                will be ignored. Use dot delimiters to specify nested fields.
            :param unknown: Whether to exclude, include, or raise an error for unknown
                fields in the data. Use `EXCLUDE`, `INCLUDE` or `RAISE`.
                If `None`, the value for `self.unknown` is used.
            :return: Deserialized data
    
            .. versionadded:: 1.0.0
            .. versionchanged:: 3.0.0b7
                This method returns the deserialized data rather than a ``(data, errors)`` duple.
                A :exc:`ValidationError <marshmallow.exceptions.ValidationError>` is raised
                if invalid data are passed.
            
        """
        pass


code Schema__validate:
  body: |
    def validate(self, data: typing.Mapping[str, typing.Any] | typing.Iterable[typing.Mapping[str, typing.Any]], *, many: bool | None=None, partial: bool | types.StrSequenceOrSet | None=None):
        """Validate `data` against the schema, returning a dictionary of
            validation errors.
    
            :param data: The data to validate.
            :param many: Whether to validate `data` as a collection. If `None`, the
                value for `self.many` is used.
            :param partial: Whether to ignore missing fields and not require
                any fields declared. Propagates down to ``Nested`` fields as well. If
                its value is an iterable, only missing fields listed in that iterable
                will be ignored. Use dot delimiters to specify nested fields.
            :return: A dictionary of validation errors.
    
            .. versionadded:: 1.1.0
            
        """
        pass


code Schema___do_load:
  body: |
    def _do_load(self, data: typing.Mapping[str, typing.Any] | typing.Iterable[typing.Mapping[str, typing.Any]], *, many: bool | None=None, partial: bool | types.StrSequenceOrSet | None=None, unknown: str | None=None, postprocess: bool=True):
        """Deserialize `data`, returning the deserialized result.
            This method is private API.
    
            :param data: The data to deserialize.
            :param many: Whether to deserialize `data` as a collection. If `None`, the
                value for `self.many` is used.
            :param partial: Whether to validate required fields. If its
                value is an iterable, only fields listed in that iterable will be
                ignored will be allowed missing. If `True`, all fields will be allowed missing.
                If `None`, the value for `self.partial` is used.
            :param unknown: Whether to exclude, include, or raise an error for unknown
                fields in the data. Use `EXCLUDE`, `INCLUDE` or `RAISE`.
                If `None`, the value for `self.unknown` is used.
            :param postprocess: Whether to run post_load methods..
            :return: Deserialized data
            
        """
        pass


code Schema___normalize_nested_options:
  body: |
    def _normalize_nested_options(self):
        """Apply then flatten nested schema options.
            This method is private API.
            
        """
        pass


code Schema____apply_nested_option:
  body: |
    def __apply_nested_option(self, option_name, field_names, set_operation):
        """Apply nested options to nested fields"""
        pass


code Schema___init_fields:
  body: |
    def _init_fields(self):
        """Update self.fields, self.load_fields, and self.dump_fields based on schema options.
            This method is private API.
            
        """
        pass


code Schema__on_bind_field:
  body: |
    def on_bind_field(self, field_name: str, field_obj: ma_fields.Field):
        """Hook to modify a field when it is bound to the `Schema`.
    
            No-op by default.
            
        """
        pass


code Schema___bind_field:
  body: |
    def _bind_field(self, field_name: str, field_obj: ma_fields.Field):
        """Bind field to the schema, setting any necessary attributes on the
            field (e.g. parent and name).
    
            Also set field load_only and dump_only values if field_name was
            specified in ``class Meta``.
            
        """
        pass


code is_generator:
  body: |
    def is_generator(obj):
        """Return True if ``obj`` is a generator"""
        pass


code is_iterable_but_not_string:
  body: |
    def is_iterable_but_not_string(obj):
        """Return True if ``obj`` is an iterable object that isn't a string."""
        pass


code is_collection:
  body: |
    def is_collection(obj):
        """Return True if ``obj`` is a collection type, e.g list, tuple, queryset."""
        pass


code is_instance_or_subclass:
  body: |
    def is_instance_or_subclass(val, class_):
        """Return True if ``val`` is either a subclass or instance of ``class_``."""
        pass


code is_keyed_tuple:
  body: |
    def is_keyed_tuple(obj):
        """Return True if ``obj`` has keyed tuple behavior, such as
        namedtuples or SQLAlchemy's KeyedTuples.
        
        """
        pass


code pprint:
  body: |
    def pprint(obj, *args, **kwargs):
        """Pretty-printing function that can pretty-print OrderedDicts
        like regular dictionaries. Useful for printing the output of
        :meth:`marshmallow.Schema.dump`.
    
        .. deprecated:: 3.7.0
            marshmallow.pprint will be removed in marshmallow 4.
        
        """
        pass


code from_rfc:
  body: |
    def from_rfc(datestring: str):
        """Parse a RFC822-formatted datetime string and return a datetime object.
    
        https://stackoverflow.com/questions/885015/how-to-parse-a-rfc-2822-date-time-into-a-python-datetime  # noqa: B950
        
        """
        pass


code rfcformat:
  body: |
    def rfcformat(datetime: dt.datetime):
        """Return the RFC822-formatted representation of a datetime object.
    
        :param datetime datetime: The datetime.
        
        """
        pass


code get_fixed_timezone:
  body: |
    def get_fixed_timezone(offset: int | float | dt.timedelta):
        """Return a tzinfo instance with a fixed offset from UTC."""
        pass


code from_iso_datetime:
  body: |
    def from_iso_datetime(value):
        """Parse a string and return a datetime.datetime.
    
        This function supports time zone offsets. When the input contains one,
        the output uses a timezone with a fixed offset from UTC.
        
        """
        pass


code from_iso_time:
  body: |
    def from_iso_time(value):
        """Parse a string and return a datetime.time.
    
        This function doesn't support time zone offsets.
        
        """
        pass


code from_iso_date:
  body: |
    def from_iso_date(value):
        """Parse a string and return a datetime.date."""
        pass


code isoformat:
  body: |
    def isoformat(datetime: dt.datetime):
        """Return the ISO8601-formatted representation of a datetime object.
    
        :param datetime datetime: The datetime.
        
        """
        pass


code pluck:
  body: |
    def pluck(dictlist: list[dict[str, typing.Any]], key: str):
        """Extracts a list of dictionary values from a list of dictionaries.
        ::
    
            >>> dlist = [{'id': 1, 'name': 'foo'}, {'id': 2, 'name': 'bar'}]
            >>> pluck(dlist, 'id')
            [1, 2]
        
        """
        pass


code get_value:
  body: |
    def get_value(obj, key: int | str, default=missing):
        """Helper for pulling a keyed value off various types of objects. Fields use
        this method by default to access attributes of the source object. For object `x`
        and attribute `i`, this method first tries to access `x[i]`, and then falls back to
        `x.i` if an exception is raised.
    
        .. warning::
            If an object `x` does not raise an exception when `x[i]` does not exist,
            `get_value` will never check the value `x.i`. Consider overriding
            `marshmallow.fields.Field.get_value` in this case.
        
        """
        pass


code set_value:
  body: |
    def set_value(dct: dict[str, typing.Any], key: str, value: typing.Any):
        """Set a value in a dict. If `key` contains a '.', it is assumed
        be a path (i.e. dot-delimited string) to the value's location.
    
        ::
    
            >>> d = {}
            >>> set_value(d, 'foo.bar', 42)
            >>> d
            {'foo': {'bar': 42}}
        
        """
        pass


code callable_or_raise:
  body: |
    def callable_or_raise(obj):
        """Check that an object is callable, else raise a :exc:`TypeError`."""
        pass


code get_func_args:
  body: |
    def get_func_args(func: typing.Callable):
        """Given a callable, return a list of argument names. Handles
        `functools.partial` objects and class-based callables.
    
        .. versionchanged:: 3.0.0a1
            Do not return bound arguments, eg. ``self``.
        
        """
        pass


code resolve_field_instance:
  body: |
    def resolve_field_instance(cls_or_instance):
        """Return a Schema instance from a Schema class or instance.
    
        :param type|Schema cls_or_instance: Marshmallow Schema class or instance.
        
        """
        pass


code timedelta_to_microseconds:
  body: |
    def timedelta_to_microseconds(value: dt.timedelta):
        """Compute the total microseconds of a timedelta
    
        https://github.com/python/cpython/blob/bb3e0c240bc60fe08d332ff5955d54197f79751c/Lib/datetime.py#L665-L667  # noqa: B950
        
        """
        pass


code Validator___repr_args:
  body: |
    def _repr_args(self):
        """A string representation of the args passed to this validator. Used by
            `__repr__`.
            
        """
        pass


code OneOf__options:
  body: |
    def options(self, valuegetter: str | typing.Callable[[typing.Any], typing.Any]=str):
        """Return a generator over the (value, label) pairs, where value
            is a string associated with each choice. This convenience method
            is useful to populate, for instance, a form select field.
    
            :param valuegetter: Can be a callable or a string. In the former case, it must
                be a one-argument callable which returns the value of a
                choice. In the latter case, the string specifies the name
                of an attribute of the choice objects. Defaults to `str()`
                or `str()`.
            
        """
        pass
