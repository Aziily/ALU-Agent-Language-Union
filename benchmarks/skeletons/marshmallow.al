preamble __init__:
  source: marshmallow/__init__.py
  imports: |
    from __future__ import annotations
    import importlib.metadata
    import typing
    from packaging.version import Version
    from marshmallow.decorators import post_dump, post_load, pre_dump, pre_load, validates, validates_schema
    from marshmallow.exceptions import ValidationError
    from marshmallow.schema import Schema, SchemaOpts
    from marshmallow.utils import EXCLUDE, INCLUDE, RAISE, missing, pprint
    from . import fields
  constants: |
    __all__ = ['EXCLUDE', 'INCLUDE', 'RAISE', 'Schema', 'SchemaOpts', 'fields', 'validates', 'validates_schema', 'pre_dump', 'post_dump', 'pre_load', 'post_load', 'pprint', 'ValidationError', 'missing']


preamble base:
  source: marshmallow/base.py
  imports: |
    from __future__ import annotations
    from abc import ABC, abstractmethod
  body: |
    'Abstract base classes.\n\nThese are necessary to avoid circular imports between schema.py and fields.py.\n\n.. warning::\n\n    This module is treated as private API.\n    Users should not need to use this module directly.\n'
    class FieldABC(ABC):
        """Abstract base class from which all Field classes inherit."""
        parent = None
        name = None
        root = None
    class SchemaABC(ABC):
        """Abstract base class from which all Schemas inherit."""


preamble class_registry:
  source: marshmallow/class_registry.py
  imports: |
    from __future__ import annotations
    import typing
    from marshmallow.exceptions import RegistryError
  constants: |
    _registry = {}
  body: |
    'A registry of :class:`Schema <marshmallow.Schema>` classes. This allows for string\nlookup of schemas, which may be used with\nclass:`fields.Nested <marshmallow.fields.Nested>`.\n\n.. warning::\n\n    This module is treated as private API.\n    Users should not need to use this module directly.\n'
    if typing.TYPE_CHECKING:
        from marshmallow import Schema
        SchemaType = typing.Type[Schema]


preamble decorators:
  source: marshmallow/decorators.py
  imports: |
    from __future__ import annotations
    import functools
    from typing import Any, Callable, cast
  constants: |
    PRE_DUMP = 'pre_dump'
    POST_DUMP = 'post_dump'
    PRE_LOAD = 'pre_load'
    POST_LOAD = 'post_load'
    VALIDATES = 'validates'
    VALIDATES_SCHEMA = 'validates_schema'
  body: |
    'Decorators for registering schema pre-processing and post-processing methods.\nThese should be imported from the top-level `marshmallow` module.\n\nMethods decorated with\n`pre_load <marshmallow.decorators.pre_load>`, `post_load <marshmallow.decorators.post_load>`,\n`pre_dump <marshmallow.decorators.pre_dump>`, `post_dump <marshmallow.decorators.post_dump>`,\nand `validates_schema <marshmallow.decorators.validates_schema>` receive\n``many`` as a keyword argument. In addition, `pre_load <marshmallow.decorators.pre_load>`,\n`post_load <marshmallow.decorators.post_load>`,\nand `validates_schema <marshmallow.decorators.validates_schema>` receive\n``partial``. If you don\'t need these arguments, add ``**kwargs`` to your method\nsignature.\n\n\nExample: ::\n\n    from marshmallow import (\n        Schema,\n        pre_load,\n        pre_dump,\n        post_load,\n        validates_schema,\n        validates,\n        fields,\n        ValidationError,\n    )\n\n\n    class UserSchema(Schema):\n        email = fields.Str(required=True)\n        age = fields.Integer(required=True)\n\n        @post_load\n        def lowerstrip_email(self, item, many, **kwargs):\n            item["email"] = item["email"].lower().strip()\n            return item\n\n        @pre_load(pass_many=True)\n        def remove_envelope(self, data, many, **kwargs):\n            namespace = "results" if many else "result"\n            return data[namespace]\n\n        @post_dump(pass_many=True)\n        def add_envelope(self, data, many, **kwargs):\n            namespace = "results" if many else "result"\n            return {namespace: data}\n\n        @validates_schema\n        def validate_email(self, data, **kwargs):\n            if len(data["email"]) < 3:\n                raise ValidationError("Email must be more than 3 characters", "email")\n\n        @validates("age")\n        def validate_age(self, data, **kwargs):\n            if data < 14:\n                raise ValidationError("Too young!")\n\n.. note::\n    These decorators only work with instance methods. Class and static\n    methods are not supported.\n\n.. warning::\n    The invocation order of decorated methods of the same type is not guaranteed.\n    If you need to guarantee order of different processing steps, you should put\n    them in the same processing method.\n'
    class MarshmallowHook:
        __marshmallow_hook__: dict[tuple[str, bool] | str, Any] | None = None


preamble error_store:
  source: marshmallow/error_store.py
  imports: |
    from marshmallow.exceptions import SCHEMA
  body: |
    'Utilities for storing collections of error messages.\n\n.. warning::\n\n    This module is treated as private API.\n    Users should not need to use this module directly.\n'
    class ErrorStore:

        def __init__(self):
            self.errors = {}


preamble exceptions:
  source: marshmallow/exceptions.py
  imports: |
    from __future__ import annotations
    import typing
  constants: |
    SCHEMA = '_schema'
  body: |
    'Exception classes for marshmallow-related errors.'
    class MarshmallowError(Exception):
        """Base class for all marshmallow-related errors."""
    class ValidationError(MarshmallowError):
        """Raised when validation fails on a field or schema.

        Validators and custom fields should raise this exception.

        :param message: An error message, list of error messages, or dict of
            error messages. If a dict, the keys are subitems and the values are error messages.
        :param field_name: Field name to store the error on.
            If `None`, the error is stored as schema-level error.
        :param data: Raw input data.
        :param valid_data: Valid (de)serialized data.
        """

        def __init__(self, message: str | list | dict, field_name: str=SCHEMA, data: typing.Mapping[str, typing.Any] | typing.Iterable[typing.Mapping[str, typing.Any]] | None=None, valid_data: list[dict[str, typing.Any]] | dict[str, typing.Any] | None=None, **kwargs):
            self.messages = [message] if isinstance(message, (str, bytes)) else message
            self.field_name = field_name
            self.data = data
            self.valid_data = valid_data
            self.kwargs = kwargs
            super().__init__(message)
    class RegistryError(NameError):
        """Raised when an invalid operation is performed on the serializer
        class registry.
        """
    class StringNotCollectionError(MarshmallowError, TypeError):
        """Raised when a string is passed when a list of strings is expected."""
    class FieldInstanceResolutionError(MarshmallowError, TypeError):
        """Raised when schema to instantiate is neither a Schema class nor an instance."""


preamble fields:
  source: marshmallow/fields.py
  imports: |
    from __future__ import annotations
    import collections
    import copy
    import datetime as dt
    import decimal
    import ipaddress
    import math
    import numbers
    import typing
    import uuid
    import warnings
    from collections.abc import Mapping as _Mapping
    from enum import Enum as EnumType
    from marshmallow import class_registry, types, utils, validate
    from marshmallow.base import FieldABC, SchemaABC
    from marshmallow.exceptions import FieldInstanceResolutionError, StringNotCollectionError, ValidationError
    from marshmallow.utils import is_aware, is_collection, resolve_field_instance
    from marshmallow.utils import missing as missing_
    from marshmallow.validate import And, Length
    from marshmallow.warnings import RemovedInMarshmallow4Warning
  constants: |
    __all__ = ['Field', 'Raw', 'Nested', 'Mapping', 'Dict', 'List', 'Tuple', 'String', 'UUID', 'Number', 'Integer', 'Decimal', 'Boolean', 'Float', 'DateTime', 'NaiveDateTime', 'AwareDateTime', 'Time', 'Date', 'TimeDelta', 'Url', 'URL', 'Email', 'IP', 'IPv4', 'IPv6', 'IPInterface', 'IPv4Interface', 'IPv6Interface', 'Enum', 'Method', 'Function', 'Str', 'Bool', 'Int', 'Constant', 'Pluck']
    _T = typing.TypeVar('_T')
    URL = Url
    Str = String
    Bool = Boolean
    Int = Integer
  body: |
    'Field classes for various types of data.'
    class Field(FieldABC):
        """Basic field from which other fields should extend. It applies no
        formatting by default, and should only be used in cases where
        data does not need to be formatted before being serialized or deserialized.
        On error, the name of the field will be returned.

        :param dump_default: If set, this value will be used during serialization if the
            input value is missing. If not set, the field will be excluded from the
            serialized output if the input value is missing. May be a value or a callable.
        :param load_default: Default deserialization value for the field if the field is not
            found in the input data. May be a value or a callable.
        :param data_key: The name of the dict key in the external representation, i.e.
            the input of `load` and the output of `dump`.
            If `None`, the key will match the name of the field.
        :param attribute: The name of the key/attribute in the internal representation, i.e.
            the output of `load` and the input of `dump`.
            If `None`, the key/attribute will match the name of the field.
            Note: This should only be used for very specific use cases such as
            outputting multiple fields for a single attribute, or using keys/attributes
            that are invalid variable names, unsuitable for field names. In most cases,
            you should use ``data_key`` instead.
        :param validate: Validator or collection of validators that are called
            during deserialization. Validator takes a field's input value as
            its only parameter and returns a boolean.
            If it returns `False`, an :exc:`ValidationError` is raised.
        :param required: Raise a :exc:`ValidationError` if the field value
            is not supplied during deserialization.
        :param allow_none: Set this to `True` if `None` should be considered a valid value during
            validation/deserialization. If ``load_default=None`` and ``allow_none`` is unset,
            will default to ``True``. Otherwise, the default is ``False``.
        :param load_only: If `True` skip this field during serialization, otherwise
            its value will be present in the serialized data.
        :param dump_only: If `True` skip this field during deserialization, otherwise
            its value will be present in the deserialized object. In the context of an
            HTTP API, this effectively marks the field as "read-only".
        :param dict error_messages: Overrides for `Field.default_error_messages`.
        :param metadata: Extra information to be stored as field metadata.

        .. versionchanged:: 2.0.0
            Removed `error` parameter. Use ``error_messages`` instead.

        .. versionchanged:: 2.0.0
            Added `allow_none` parameter, which makes validation/deserialization of `None`
            consistent across fields.

        .. versionchanged:: 2.0.0
            Added `load_only` and `dump_only` parameters, which allow field skipping
            during the (de)serialization process.

        .. versionchanged:: 2.0.0
            Added `missing` parameter, which indicates the value for a field if the field
            is not found during deserialization.

        .. versionchanged:: 2.0.0
            ``default`` value is only used if explicitly set. Otherwise, missing values
            inputs are excluded from serialized output.

        .. versionchanged:: 3.0.0b8
            Add ``data_key`` parameter for the specifying the key in the input and
            output data. This parameter replaced both ``load_from`` and ``dump_to``.
        """
        _CHECK_ATTRIBUTE = True
        default_error_messages = {'required': 'Missing data for required field.', 'null': 'Field may not be null.', 'validator_failed': 'Invalid value.'}

        def __init__(self, *, load_default: typing.Any=missing_, missing: typing.Any=missing_, dump_default: typing.Any=missing_, default: typing.Any=missing_, data_key: str | None=None, attribute: str | None=None, validate: None | typing.Callable[[typing.Any], typing.Any] | typing.Iterable[typing.Callable[[typing.Any], typing.Any]]=None, required: bool=False, allow_none: bool | None=None, load_only: bool=False, dump_only: bool=False, error_messages: dict[str, str] | None=None, metadata: typing.Mapping[str, typing.Any] | None=None, **additional_metadata) -> None:
            if default is not missing_:
                warnings.warn("The 'default' argument to fields is deprecated. Use 'dump_default' instead.", RemovedInMarshmallow4Warning, stacklevel=2)
                if dump_default is missing_:
                    dump_default = default
            if missing is not missing_:
                warnings.warn("The 'missing' argument to fields is deprecated. Use 'load_default' instead.", RemovedInMarshmallow4Warning, stacklevel=2)
                if load_default is missing_:
                    load_default = missing
            self.dump_default = dump_default
            self.load_default = load_default
            self.attribute = attribute
            self.data_key = data_key
            self.validate = validate
            if validate is None:
                self.validators = []
            elif callable(validate):
                self.validators = [validate]
            elif utils.is_iterable_but_not_string(validate):
                self.validators = list(validate)
            else:
                raise ValueError("The 'validate' parameter must be a callable or a collection of callables.")
            self.allow_none = load_default is None if allow_none is None else allow_none
            self.load_only = load_only
            self.dump_only = dump_only
            if required is True and load_default is not missing_:
                raise ValueError("'load_default' must not be set for required fields.")
            self.required = required
            metadata = metadata or {}
            self.metadata = {**metadata, **additional_metadata}
            if additional_metadata:
                warnings.warn(f'Passing field metadata as keyword arguments is deprecated. Use the explicit `metadata=...` argument instead. Additional metadata: {additional_metadata}', RemovedInMarshmallow4Warning, stacklevel=2)
            messages = {}
            for cls in reversed(self.__class__.__mro__):
                messages.update(getattr(cls, 'default_error_messages', {}))
            messages.update(error_messages or {})
            self.error_messages = messages

        def __repr__(self) -> str:
            return f'<fields.{self.__class__.__name__}(dump_default={self.dump_default!r}, attribute={self.attribute!r}, validate={self.validate}, required={self.required}, load_only={self.load_only}, dump_only={self.dump_only}, load_default={self.load_default}, allow_none={self.allow_none}, error_messages={self.error_messages})>'

        def __deepcopy__(self, memo):
            return copy.copy(self)

        def get_value(self, obj, attr, accessor=None, default=missing_):
            ...

        def _validate(self, value):
            ...

        def make_error(self, key: str, **kwargs) -> ValidationError:
            ...

        def fail(self, key: str, **kwargs):
            ...

        def _validate_missing(self, value):
            ...

        def serialize(self, attr: str, obj: typing.Any, accessor: typing.Callable[[typing.Any, str, typing.Any], typing.Any] | None=None, **kwargs):
            ...

        def deserialize(self, value: typing.Any, attr: str | None=None, data: typing.Mapping[str, typing.Any] | None=None, **kwargs):
            ...

        def _bind_to_schema(self, field_name, schema):
            ...

        def _serialize(self, value: typing.Any, attr: str | None, obj: typing.Any, **kwargs):
            ...

        def _deserialize(self, value: typing.Any, attr: str | None, data: typing.Mapping[str, typing.Any] | None, **kwargs):
            ...

        @property
        def context(self):
            ...
    class Raw(Field):
        """Field that applies no formatting."""
    class Nested(Field):
        """Allows you to nest a :class:`Schema <marshmallow.Schema>`
        inside a field.

        Examples: ::

            class ChildSchema(Schema):
                id = fields.Str()
                name = fields.Str()
                # Use lambda functions when you need two-way nesting or self-nesting
                parent = fields.Nested(lambda: ParentSchema(only=("id",)), dump_only=True)
                siblings = fields.List(fields.Nested(lambda: ChildSchema(only=("id", "name"))))


            class ParentSchema(Schema):
                id = fields.Str()
                children = fields.List(
                    fields.Nested(ChildSchema(only=("id", "parent", "siblings")))
                )
                spouse = fields.Nested(lambda: ParentSchema(only=("id",)))

        When passing a `Schema <marshmallow.Schema>` instance as the first argument,
        the instance's ``exclude``, ``only``, and ``many`` attributes will be respected.

        Therefore, when passing the ``exclude``, ``only``, or ``many`` arguments to `fields.Nested`,
        you should pass a `Schema <marshmallow.Schema>` class (not an instance) as the first argument.

        ::

            # Yes
            author = fields.Nested(UserSchema, only=("id", "name"))

            # No
            author = fields.Nested(UserSchema(), only=("id", "name"))

        :param nested: `Schema` instance, class, class name (string), dictionary, or callable that
            returns a `Schema` or dictionary. Dictionaries are converted with `Schema.from_dict`.
        :param exclude: A list or tuple of fields to exclude.
        :param only: A list or tuple of fields to marshal. If `None`, all fields are marshalled.
            This parameter takes precedence over ``exclude``.
        :param many: Whether the field is a collection of objects.
        :param unknown: Whether to exclude, include, or raise an error for unknown
            fields in the data. Use `EXCLUDE`, `INCLUDE` or `RAISE`.
        :param kwargs: The same keyword arguments that :class:`Field` receives.
        """
        default_error_messages = {'type': 'Invalid type.'}

        def __init__(self, nested: SchemaABC | type | str | dict[str, Field | type] | typing.Callable[[], SchemaABC | type | dict[str, Field | type]], *, dump_default: typing.Any=missing_, default: typing.Any=missing_, only: types.StrSequenceOrSet | None=None, exclude: types.StrSequenceOrSet=(), many: bool=False, unknown: str | None=None, **kwargs):
            if only is not None and (not is_collection(only)):
                raise StringNotCollectionError('"only" should be a collection of strings.')
            if not is_collection(exclude):
                raise StringNotCollectionError('"exclude" should be a collection of strings.')
            if nested == 'self':
                warnings.warn("Passing 'self' to `Nested` is deprecated. Use `Nested(lambda: MySchema(...))` instead.", RemovedInMarshmallow4Warning, stacklevel=2)
            self.nested = nested
            self.only = only
            self.exclude = exclude
            self.many = many
            self.unknown = unknown
            self._schema = None
            super().__init__(default=default, dump_default=dump_default, **kwargs)

        @property
        def schema(self):
            ...

        def _deserialize(self, value, attr, data, partial=None, **kwargs):
            ...
    class Pluck(Nested):
        """Allows you to replace nested data with one of the data's fields.

        Example: ::

            from marshmallow import Schema, fields


            class ArtistSchema(Schema):
                id = fields.Int()
                name = fields.Str()


            class AlbumSchema(Schema):
                artist = fields.Pluck(ArtistSchema, "id")


            in_data = {"artist": 42}
            loaded = AlbumSchema().load(in_data)  # => {'artist': {'id': 42}}
            dumped = AlbumSchema().dump(loaded)  # => {'artist': 42}

        :param Schema nested: The Schema class or class name (string)
            to nest, or ``"self"`` to nest the :class:`Schema` within itself.
        :param str field_name: The key to pluck a value from.
        :param kwargs: The same keyword arguments that :class:`Nested` receives.
        """

        def __init__(self, nested: SchemaABC | type | str | typing.Callable[[], SchemaABC], field_name: str, **kwargs):
            super().__init__(nested, only=(field_name,), **kwargs)
            self.field_name = field_name
    class List(Field):
        """A list field, composed with another `Field` class or
        instance.

        Example: ::

            numbers = fields.List(fields.Float())

        :param cls_or_instance: A field class or instance.
        :param kwargs: The same keyword arguments that :class:`Field` receives.

        .. versionchanged:: 2.0.0
            The ``allow_none`` parameter now applies to deserialization and
            has the same semantics as the other fields.

        .. versionchanged:: 3.0.0rc9
            Does not serialize scalar values to single-item lists.
        """
        default_error_messages = {'invalid': 'Not a valid list.'}

        def __init__(self, cls_or_instance: Field | type, **kwargs):
            super().__init__(**kwargs)
            try:
                self.inner = resolve_field_instance(cls_or_instance)
            except FieldInstanceResolutionError as error:
                raise ValueError('The list elements must be a subclass or instance of marshmallow.base.FieldABC.') from error
            if isinstance(self.inner, Nested):
                self.only = self.inner.only
                self.exclude = self.inner.exclude
    class Tuple(Field):
        """A tuple field, composed of a fixed number of other `Field` classes or
        instances

        Example: ::

            row = Tuple((fields.String(), fields.Integer(), fields.Float()))

        .. note::
            Because of the structured nature of `collections.namedtuple` and
            `typing.NamedTuple`, using a Schema within a Nested field for them is
            more appropriate than using a `Tuple` field.

        :param Iterable[Field] tuple_fields: An iterable of field classes or
            instances.
        :param kwargs: The same keyword arguments that :class:`Field` receives.

        .. versionadded:: 3.0.0rc4
        """
        default_error_messages = {'invalid': 'Not a valid tuple.'}

        def __init__(self, tuple_fields, *args, **kwargs):
            super().__init__(*args, **kwargs)
            if not utils.is_collection(tuple_fields):
                raise ValueError('tuple_fields must be an iterable of Field classes or instances.')
            try:
                self.tuple_fields = [resolve_field_instance(cls_or_instance) for cls_or_instance in tuple_fields]
            except FieldInstanceResolutionError as error:
                raise ValueError('Elements of "tuple_fields" must be subclasses or instances of marshmallow.base.FieldABC.') from error
            self.validate_length = Length(equal=len(self.tuple_fields))
    class String(Field):
        """A string field.

        :param kwargs: The same keyword arguments that :class:`Field` receives.
        """
        default_error_messages = {'invalid': 'Not a valid string.', 'invalid_utf8': 'Not a valid utf-8 string.'}
    class UUID(String):
        """A UUID field."""
        default_error_messages = {'invalid_uuid': 'Not a valid UUID.'}

        def _validated(self, value) -> uuid.UUID | None:
            ...
    class Number(Field):
        """Base class for number fields.

        :param bool as_string: If `True`, format the serialized value as a string.
        :param kwargs: The same keyword arguments that :class:`Field` receives.
        """
        num_type = float
        default_error_messages = {'invalid': 'Not a valid number.', 'too_large': 'Number too large.'}

        def __init__(self, *, as_string: bool=False, **kwargs):
            self.as_string = as_string
            super().__init__(**kwargs)

        def _format_num(self, value) -> typing.Any:
            ...

        def _validated(self, value) -> _T | None:
            ...

        def _serialize(self, value, attr, obj, **kwargs) -> str | _T | None:
            ...
    class Integer(Number):
        """An integer field.

        :param strict: If `True`, only integer types are valid.
            Otherwise, any value castable to `int` is valid.
        :param kwargs: The same keyword arguments that :class:`Number` receives.
        """
        num_type = int
        default_error_messages = {'invalid': 'Not a valid integer.'}

        def __init__(self, *, strict: bool=False, **kwargs):
            self.strict = strict
            super().__init__(**kwargs)
    class Float(Number):
        """A double as an IEEE-754 double precision string.

        :param bool allow_nan: If `True`, `NaN`, `Infinity` and `-Infinity` are allowed,
            even though they are illegal according to the JSON specification.
        :param bool as_string: If `True`, format the value as a string.
        :param kwargs: The same keyword arguments that :class:`Number` receives.
        """
        num_type = float
        default_error_messages = {'special': 'Special numeric values (nan or infinity) are not permitted.'}

        def __init__(self, *, allow_nan: bool=False, as_string: bool=False, **kwargs):
            self.allow_nan = allow_nan
            super().__init__(as_string=as_string, **kwargs)
    class Decimal(Number):
        """A field that (de)serializes to the Python ``decimal.Decimal`` type.
        It's safe to use when dealing with money values, percentages, ratios
        or other numbers where precision is critical.

        .. warning::

            This field serializes to a `decimal.Decimal` object by default. If you need
            to render your data as JSON, keep in mind that the `json` module from the
            standard library does not encode `decimal.Decimal`. Therefore, you must use
            a JSON library that can handle decimals, such as `simplejson`, or serialize
            to a string by passing ``as_string=True``.

        .. warning::

            If a JSON `float` value is passed to this field for deserialization it will
            first be cast to its corresponding `string` value before being deserialized
            to a `decimal.Decimal` object. The default `__str__` implementation of the
            built-in Python `float` type may apply a destructive transformation upon
            its input data and therefore cannot be relied upon to preserve precision.
            To avoid this, you can instead pass a JSON `string` to be deserialized
            directly.

        :param places: How many decimal places to quantize the value. If `None`, does
            not quantize the value.
        :param rounding: How to round the value during quantize, for example
            `decimal.ROUND_UP`. If `None`, uses the rounding value from
            the current thread's context.
        :param allow_nan: If `True`, `NaN`, `Infinity` and `-Infinity` are allowed,
            even though they are illegal according to the JSON specification.
        :param as_string: If `True`, serialize to a string instead of a Python
            `decimal.Decimal` type.
        :param kwargs: The same keyword arguments that :class:`Number` receives.

        .. versionadded:: 1.2.0
        """
        num_type = decimal.Decimal
        default_error_messages = {'special': 'Special numeric values (nan or infinity) are not permitted.'}

        def __init__(self, places: int | None=None, rounding: str | None=None, *, allow_nan: bool=False, as_string: bool=False, **kwargs):
            self.places = decimal.Decimal((0, (1,), -places)) if places is not None else None
            self.rounding = rounding
            self.allow_nan = allow_nan
            super().__init__(as_string=as_string, **kwargs)
    class Boolean(Field):
        """A boolean field.

        :param truthy: Values that will (de)serialize to `True`. If an empty
            set, any non-falsy value will deserialize to `True`. If `None`,
            `marshmallow.fields.Boolean.truthy` will be used.
        :param falsy: Values that will (de)serialize to `False`. If `None`,
            `marshmallow.fields.Boolean.falsy` will be used.
        :param kwargs: The same keyword arguments that :class:`Field` receives.
        """
        truthy = {'t', 'T', 'true', 'True', 'TRUE', 'on', 'On', 'ON', 'y', 'Y', 'yes', 'Yes', 'YES', '1', 1}
        falsy = {'f', 'F', 'false', 'False', 'FALSE', 'off', 'Off', 'OFF', 'n', 'N', 'no', 'No', 'NO', '0', 0}
        default_error_messages = {'invalid': 'Not a valid boolean.'}

        def __init__(self, *, truthy: set | None=None, falsy: set | None=None, **kwargs):
            super().__init__(**kwargs)
            if truthy is not None:
                self.truthy = set(truthy)
            if falsy is not None:
                self.falsy = set(falsy)
    class DateTime(Field):
        """A formatted datetime string.

        Example: ``'2014-12-22T03:12:58.019077+00:00'``

        :param format: Either ``"rfc"`` (for RFC822), ``"iso"`` (for ISO8601),
            ``"timestamp"``, ``"timestamp_ms"`` (for a POSIX timestamp) or a date format string.
            If `None`, defaults to "iso".
        :param kwargs: The same keyword arguments that :class:`Field` receives.

        .. versionchanged:: 3.0.0rc9
            Does not modify timezone information on (de)serialization.
        .. versionchanged:: 3.19
            Add timestamp as a format.
        """
        SERIALIZATION_FUNCS = {'iso': utils.isoformat, 'iso8601': utils.isoformat, 'rfc': utils.rfcformat, 'rfc822': utils.rfcformat, 'timestamp': utils.timestamp, 'timestamp_ms': utils.timestamp_ms}
        DESERIALIZATION_FUNCS = {'iso': utils.from_iso_datetime, 'iso8601': utils.from_iso_datetime, 'rfc': utils.from_rfc, 'rfc822': utils.from_rfc, 'timestamp': utils.from_timestamp, 'timestamp_ms': utils.from_timestamp_ms}
        DEFAULT_FORMAT = 'iso'
        OBJ_TYPE = 'datetime'
        SCHEMA_OPTS_VAR_NAME = 'datetimeformat'
        default_error_messages = {'invalid': 'Not a valid {obj_type}.', 'invalid_awareness': 'Not a valid {awareness} {obj_type}.', 'format': '"{input}" cannot be formatted as a {obj_type}.'}

        def __init__(self, format: str | None=None, **kwargs) -> None:
            super().__init__(**kwargs)
            self.format = format
    class NaiveDateTime(DateTime):
        """A formatted naive datetime string.

        :param format: See :class:`DateTime`.
        :param timezone: Used on deserialization. If `None`,
            aware datetimes are rejected. If not `None`, aware datetimes are
            converted to this timezone before their timezone information is
            removed.
        :param kwargs: The same keyword arguments that :class:`Field` receives.

        .. versionadded:: 3.0.0rc9
        """
        AWARENESS = 'naive'

        def __init__(self, format: str | None=None, *, timezone: dt.timezone | None=None, **kwargs) -> None:
            super().__init__(format=format, **kwargs)
            self.timezone = timezone
    class AwareDateTime(DateTime):
        """A formatted aware datetime string.

        :param format: See :class:`DateTime`.
        :param default_timezone: Used on deserialization. If `None`, naive
            datetimes are rejected. If not `None`, naive datetimes are set this
            timezone.
        :param kwargs: The same keyword arguments that :class:`Field` receives.

        .. versionadded:: 3.0.0rc9
        """
        AWARENESS = 'aware'

        def __init__(self, format: str | None=None, *, default_timezone: dt.tzinfo | None=None, **kwargs) -> None:
            super().__init__(format=format, **kwargs)
            self.default_timezone = default_timezone
    class Time(DateTime):
        """A formatted time string.

        Example: ``'03:12:58.019077'``

        :param format: Either ``"iso"`` (for ISO8601) or a date format string.
            If `None`, defaults to "iso".
        :param kwargs: The same keyword arguments that :class:`Field` receives.
        """
        SERIALIZATION_FUNCS = {'iso': utils.to_iso_time, 'iso8601': utils.to_iso_time}
        DESERIALIZATION_FUNCS = {'iso': utils.from_iso_time, 'iso8601': utils.from_iso_time}
        DEFAULT_FORMAT = 'iso'
        OBJ_TYPE = 'time'
        SCHEMA_OPTS_VAR_NAME = 'timeformat'
    class Date(DateTime):
        """ISO8601-formatted date string.

        :param format: Either ``"iso"`` (for ISO8601) or a date format string.
            If `None`, defaults to "iso".
        :param kwargs: The same keyword arguments that :class:`Field` receives.
        """
        default_error_messages = {'invalid': 'Not a valid date.', 'format': '"{input}" cannot be formatted as a date.'}
        SERIALIZATION_FUNCS = {'iso': utils.to_iso_date, 'iso8601': utils.to_iso_date}
        DESERIALIZATION_FUNCS = {'iso': utils.from_iso_date, 'iso8601': utils.from_iso_date}
        DEFAULT_FORMAT = 'iso'
        OBJ_TYPE = 'date'
        SCHEMA_OPTS_VAR_NAME = 'dateformat'
    class TimeDelta(Field):
        """A field that (de)serializes a :class:`datetime.timedelta` object to an
        integer or float and vice versa. The integer or float can represent the
        number of days, seconds or microseconds.

        :param precision: Influences how the integer or float is interpreted during
            (de)serialization. Must be 'days', 'seconds', 'microseconds',
            'milliseconds', 'minutes', 'hours' or 'weeks'.
        :param serialization_type: Whether to (de)serialize to a `int` or `float`.
        :param kwargs: The same keyword arguments that :class:`Field` receives.

        Integer Caveats
        ---------------
        Any fractional parts (which depends on the precision used) will be truncated
        when serializing using `int`.

        Float Caveats
        -------------
        Use of `float` when (de)serializing may result in data precision loss due
        to the way machines handle floating point values.

        Regardless of the precision chosen, the fractional part when using `float`
        will always be truncated to microseconds.
        For example, `1.12345` interpreted as microseconds will result in `timedelta(microseconds=1)`.

        .. versionchanged:: 2.0.0
            Always serializes to an integer value to avoid rounding errors.
            Add `precision` parameter.
        .. versionchanged:: 3.17.0
            Allow (de)serialization to `float` through use of a new `serialization_type` parameter.
            `int` is the default to retain previous behaviour.
        """
        DAYS = 'days'
        SECONDS = 'seconds'
        MICROSECONDS = 'microseconds'
        MILLISECONDS = 'milliseconds'
        MINUTES = 'minutes'
        HOURS = 'hours'
        WEEKS = 'weeks'
        default_error_messages = {'invalid': 'Not a valid period of time.', 'format': '{input!r} cannot be formatted as a timedelta.'}

        def __init__(self, precision: str=SECONDS, serialization_type: type[int | float]=int, **kwargs):
            precision = precision.lower()
            units = (self.DAYS, self.SECONDS, self.MICROSECONDS, self.MILLISECONDS, self.MINUTES, self.HOURS, self.WEEKS)
            if precision not in units:
                msg = 'The precision must be {} or "{}".'.format(', '.join([f'"{each}"' for each in units[:-1]]), units[-1])
                raise ValueError(msg)
            if serialization_type not in (int, float):
                raise ValueError('The serialization type must be one of int or float')
            self.precision = precision
            self.serialization_type = serialization_type
            super().__init__(**kwargs)
    class Mapping(Field):
        """An abstract class for objects with key-value pairs.

        :param keys: A field class or instance for dict keys.
        :param values: A field class or instance for dict values.
        :param kwargs: The same keyword arguments that :class:`Field` receives.

        .. note::
            When the structure of nested data is not known, you may omit the
            `keys` and `values` arguments to prevent content validation.

        .. versionadded:: 3.0.0rc4
        """
        mapping_type = dict
        default_error_messages = {'invalid': 'Not a valid mapping type.'}

        def __init__(self, keys: Field | type | None=None, values: Field | type | None=None, **kwargs):
            super().__init__(**kwargs)
            if keys is None:
                self.key_field = None
            else:
                try:
                    self.key_field = resolve_field_instance(keys)
                except FieldInstanceResolutionError as error:
                    raise ValueError('"keys" must be a subclass or instance of marshmallow.base.FieldABC.') from error
            if values is None:
                self.value_field = None
            else:
                try:
                    self.value_field = resolve_field_instance(values)
                except FieldInstanceResolutionError as error:
                    raise ValueError('"values" must be a subclass or instance of marshmallow.base.FieldABC.') from error
                if isinstance(self.value_field, Nested):
                    self.only = self.value_field.only
                    self.exclude = self.value_field.exclude
    class Dict(Mapping):
        """A dict field. Supports dicts and dict-like objects. Extends
        Mapping with dict as the mapping_type.

        Example: ::

            numbers = fields.Dict(keys=fields.Str(), values=fields.Float())

        :param kwargs: The same keyword arguments that :class:`Mapping` receives.

        .. versionadded:: 2.1.0
        """
        mapping_type = dict
    class Url(String):
        """An URL field.

        :param default: Default value for the field if the attribute is not set.
        :param relative: Whether to allow relative URLs.
        :param require_tld: Whether to reject non-FQDN hostnames.
        :param schemes: Valid schemes. By default, ``http``, ``https``,
            ``ftp``, and ``ftps`` are allowed.
        :param kwargs: The same keyword arguments that :class:`String` receives.
        """
        default_error_messages = {'invalid': 'Not a valid URL.'}

        def __init__(self, *, relative: bool=False, absolute: bool=True, schemes: types.StrSequenceOrSet | None=None, require_tld: bool=True, **kwargs):
            super().__init__(**kwargs)
            self.relative = relative
            self.absolute = absolute
            self.require_tld = require_tld
            validator = validate.URL(relative=self.relative, absolute=self.absolute, schemes=schemes, require_tld=self.require_tld, error=self.error_messages['invalid'])
            self.validators.insert(0, validator)
    class Email(String):
        """An email field.

        :param args: The same positional arguments that :class:`String` receives.
        :param kwargs: The same keyword arguments that :class:`String` receives.
        """
        default_error_messages = {'invalid': 'Not a valid email address.'}

        def __init__(self, *args, **kwargs) -> None:
            super().__init__(*args, **kwargs)
            validator = validate.Email(error=self.error_messages['invalid'])
            self.validators.insert(0, validator)
    class IP(Field):
        """A IP address field.

        :param bool exploded: If `True`, serialize ipv6 address in long form, ie. with groups
            consisting entirely of zeros included.

        .. versionadded:: 3.8.0
        """
        default_error_messages = {'invalid_ip': 'Not a valid IP address.'}
        DESERIALIZATION_CLASS = None

        def __init__(self, *args, exploded=False, **kwargs):
            super().__init__(*args, **kwargs)
            self.exploded = exploded
    class IPv4(IP):
        """A IPv4 address field.

        .. versionadded:: 3.8.0
        """
        default_error_messages = {'invalid_ip': 'Not a valid IPv4 address.'}
        DESERIALIZATION_CLASS = ipaddress.IPv4Address
    class IPv6(IP):
        """A IPv6 address field.

        .. versionadded:: 3.8.0
        """
        default_error_messages = {'invalid_ip': 'Not a valid IPv6 address.'}
        DESERIALIZATION_CLASS = ipaddress.IPv6Address
    class IPInterface(Field):
        """A IPInterface field.

        IP interface is the non-strict form of the IPNetwork type where arbitrary host
        addresses are always accepted.

        IPAddress and mask e.g. '192.168.0.2/24' or '192.168.0.2/255.255.255.0'

        see https://python.readthedocs.io/en/latest/library/ipaddress.html#interface-objects

        :param bool exploded: If `True`, serialize ipv6 interface in long form, ie. with groups
            consisting entirely of zeros included.
        """
        default_error_messages = {'invalid_ip_interface': 'Not a valid IP interface.'}
        DESERIALIZATION_CLASS = None

        def __init__(self, *args, exploded: bool=False, **kwargs):
            super().__init__(*args, **kwargs)
            self.exploded = exploded
    class IPv4Interface(IPInterface):
        """A IPv4 Network Interface field."""
        default_error_messages = {'invalid_ip_interface': 'Not a valid IPv4 interface.'}
        DESERIALIZATION_CLASS = ipaddress.IPv4Interface
    class IPv6Interface(IPInterface):
        """A IPv6 Network Interface field."""
        default_error_messages = {'invalid_ip_interface': 'Not a valid IPv6 interface.'}
        DESERIALIZATION_CLASS = ipaddress.IPv6Interface
    class Enum(Field):
        """An Enum field (de)serializing enum members by symbol (name) or by value.

        :param enum Enum: Enum class
        :param boolean|Schema|Field by_value: Whether to (de)serialize by value or by name,
            or Field class or instance to use to (de)serialize by value. Defaults to False.

        If `by_value` is `False` (default), enum members are (de)serialized by symbol (name).
        If it is `True`, they are (de)serialized by value using :class:`Field`.
        If it is a field instance or class, they are (de)serialized by value using this field.

        .. versionadded:: 3.18.0
        """
        default_error_messages = {'unknown': 'Must be one of: {choices}.'}

        def __init__(self, enum: type[EnumType], *, by_value: bool | Field | type=False, **kwargs):
            super().__init__(**kwargs)
            self.enum = enum
            self.by_value = by_value
            if by_value is False:
                self.field: Field = String()
                self.choices_text = ', '.join((str(self.field._serialize(m, None, None)) for m in enum.__members__))
            else:
                if by_value is True:
                    self.field = Field()
                else:
                    try:
                        self.field = resolve_field_instance(by_value)
                    except FieldInstanceResolutionError as error:
                        raise ValueError('"by_value" must be either a bool or a subclass or instance of marshmallow.base.FieldABC.') from error
                self.choices_text = ', '.join((str(self.field._serialize(m.value, None, None)) for m in enum))
    class Method(Field):
        """A field that takes the value returned by a `Schema` method.

        :param str serialize: The name of the Schema method from which
            to retrieve the value. The method must take an argument ``obj``
            (in addition to self) that is the object to be serialized.
        :param str deserialize: Optional name of the Schema method for deserializing
            a value The method must take a single argument ``value``, which is the
            value to deserialize.

        .. versionchanged:: 2.0.0
            Removed optional ``context`` parameter on methods. Use ``self.context`` instead.

        .. versionchanged:: 2.3.0
            Deprecated ``method_name`` parameter in favor of ``serialize`` and allow
            ``serialize`` to not be passed at all.

        .. versionchanged:: 3.0.0
            Removed ``method_name`` parameter.
        """
        _CHECK_ATTRIBUTE = False

        def __init__(self, serialize: str | None=None, deserialize: str | None=None, **kwargs):
            kwargs['dump_only'] = bool(serialize) and (not bool(deserialize))
            kwargs['load_only'] = bool(deserialize) and (not bool(serialize))
            super().__init__(**kwargs)
            self.serialize_method_name = serialize
            self.deserialize_method_name = deserialize
            self._serialize_method = None
            self._deserialize_method = None
    class Function(Field):
        """A field that takes the value returned by a function.

        :param serialize: A callable from which to retrieve the value.
            The function must take a single argument ``obj`` which is the object
            to be serialized. It can also optionally take a ``context`` argument,
            which is a dictionary of context variables passed to the serializer.
            If no callable is provided then the ```load_only``` flag will be set
            to True.
        :param deserialize: A callable from which to retrieve the value.
            The function must take a single argument ``value`` which is the value
            to be deserialized. It can also optionally take a ``context`` argument,
            which is a dictionary of context variables passed to the deserializer.
            If no callable is provided then ```value``` will be passed through
            unchanged.

        .. versionchanged:: 2.3.0
            Deprecated ``func`` parameter in favor of ``serialize``.

        .. versionchanged:: 3.0.0a1
            Removed ``func`` parameter.
        """
        _CHECK_ATTRIBUTE = False

        def __init__(self, serialize: None | typing.Callable[[typing.Any], typing.Any] | typing.Callable[[typing.Any, dict], typing.Any]=None, deserialize: None | typing.Callable[[typing.Any], typing.Any] | typing.Callable[[typing.Any, dict], typing.Any]=None, **kwargs):
            kwargs['dump_only'] = bool(serialize) and (not bool(deserialize))
            kwargs['load_only'] = bool(deserialize) and (not bool(serialize))
            super().__init__(**kwargs)
            self.serialize_func = serialize and utils.callable_or_raise(serialize)
            self.deserialize_func = deserialize and utils.callable_or_raise(deserialize)
    class Constant(Field):
        """A field that (de)serializes to a preset constant.  If you only want the
        constant added for serialization or deserialization, you should use
        ``dump_only=True`` or ``load_only=True`` respectively.

        :param constant: The constant to return for the field attribute.

        .. versionadded:: 2.0.0
        """
        _CHECK_ATTRIBUTE = False

        def __init__(self, constant: typing.Any, **kwargs):
            super().__init__(**kwargs)
            self.constant = constant
            self.load_default = constant
            self.dump_default = constant
    class Inferred(Field):
        """A field that infers how to serialize, based on the value type.

        .. warning::

            This class is treated as private API.
            Users should not need to use this class directly.
        """

        def __init__(self):
            super().__init__()
            self._field_cache = {}


preamble orderedset:
  source: marshmallow/orderedset.py
  imports: |
    from collections.abc import MutableSet
  body: |
    class OrderedSet(MutableSet):

        def __init__(self, iterable=None):
            self.end = end = []
            end += [None, end, end]
            self.map = {}
            if iterable is not None:
                self |= iterable

        def __len__(self):
            return len(self.map)

        def __contains__(self, key):
            return key in self.map

        def __iter__(self):
            end = self.end
            curr = end[2]
            while curr is not end:
                yield curr[0]
                curr = curr[2]

        def __reversed__(self):
            end = self.end
            curr = end[1]
            while curr is not end:
                yield curr[0]
                curr = curr[1]

        def __repr__(self):
            if not self:
                return f'{self.__class__.__name__}()'
            return f'{self.__class__.__name__}({list(self)!r})'

        def __eq__(self, other):
            if isinstance(other, OrderedSet):
                return len(self) == len(other) and list(self) == list(other)
            return set(self) == set(other)
    if __name__ == '__main__':
        s = OrderedSet('abracadaba')
        t = OrderedSet('simsalabim')
        print(s | t)
        print(s & t)
        print(s - t)


preamble schema:
  source: marshmallow/schema.py
  imports: |
    from __future__ import annotations
    import copy
    import datetime as dt
    import decimal
    import inspect
    import json
    import typing
    import uuid
    import warnings
    from abc import ABCMeta
    from collections import OrderedDict, defaultdict
    from collections.abc import Mapping
    from marshmallow import base, class_registry, types
    from marshmallow import fields as ma_fields
    from marshmallow.decorators import POST_DUMP, POST_LOAD, PRE_DUMP, PRE_LOAD, VALIDATES, VALIDATES_SCHEMA
    from marshmallow.error_store import ErrorStore
    from marshmallow.exceptions import StringNotCollectionError, ValidationError
    from marshmallow.orderedset import OrderedSet
    from marshmallow.utils import EXCLUDE, INCLUDE, RAISE, get_value, is_collection, is_instance_or_subclass, missing, set_value, validate_unknown_parameter_value
    from marshmallow.warnings import RemovedInMarshmallow4Warning
  constants: |
    _T = typing.TypeVar('_T')
    BaseSchema = Schema
  body: |
    'The :class:`Schema` class, including its metaclass and options (class Meta).'
    class SchemaMeta(ABCMeta):
        """Metaclass for the Schema class. Binds the declared fields to
        a ``_declared_fields`` attribute, which is a dictionary mapping attribute
        names to field objects. Also sets the ``opts`` class attribute, which is
        the Schema class's ``class Meta`` options.
        """

        def __new__(mcs, name, bases, attrs):
            meta = attrs.get('Meta')
            ordered = getattr(meta, 'ordered', False)
            if not ordered:
                for base_ in bases:
                    if hasattr(base_, 'Meta') and hasattr(base_.Meta, 'ordered'):
                        ordered = base_.Meta.ordered
                        break
                else:
                    ordered = False
            cls_fields = _get_fields(attrs)
            for field_name, _ in cls_fields:
                del attrs[field_name]
            klass = super().__new__(mcs, name, bases, attrs)
            inherited_fields = _get_fields_by_mro(klass)
            meta = klass.Meta
            klass.opts = klass.OPTIONS_CLASS(meta, ordered=ordered)
            cls_fields += list(klass.opts.include.items())
            klass._declared_fields = mcs.get_declared_fields(klass=klass, cls_fields=cls_fields, inherited_fields=inherited_fields, dict_cls=dict)
            return klass

        @classmethod
        def get_declared_fields(mcs, klass: type, cls_fields: list, inherited_fields: list, dict_cls: type=dict):
            ...

        def __init__(cls, name, bases, attrs):
            super().__init__(name, bases, attrs)
            if name and cls.opts.register:
                class_registry.register(name, cls)
            cls._hooks = cls.resolve_hooks()

        def resolve_hooks(cls) -> dict[types.Tag, list[str]]:
            ...
    class SchemaOpts:
        """class Meta options for the :class:`Schema`. Defines defaults."""

        def __init__(self, meta, ordered: bool=False):
            self.fields = getattr(meta, 'fields', ())
            if not isinstance(self.fields, (list, tuple)):
                raise ValueError('`fields` option must be a list or tuple.')
            self.additional = getattr(meta, 'additional', ())
            if not isinstance(self.additional, (list, tuple)):
                raise ValueError('`additional` option must be a list or tuple.')
            if self.fields and self.additional:
                raise ValueError('Cannot set both `fields` and `additional` options for the same Schema.')
            self.exclude = getattr(meta, 'exclude', ())
            if not isinstance(self.exclude, (list, tuple)):
                raise ValueError('`exclude` must be a list or tuple.')
            self.dateformat = getattr(meta, 'dateformat', None)
            self.datetimeformat = getattr(meta, 'datetimeformat', None)
            self.timeformat = getattr(meta, 'timeformat', None)
            if hasattr(meta, 'json_module'):
                warnings.warn('The json_module class Meta option is deprecated. Use render_module instead.', RemovedInMarshmallow4Warning, stacklevel=2)
                render_module = getattr(meta, 'json_module', json)
            else:
                render_module = json
            self.render_module = getattr(meta, 'render_module', render_module)
            self.ordered = getattr(meta, 'ordered', ordered)
            self.index_errors = getattr(meta, 'index_errors', True)
            self.include = getattr(meta, 'include', {})
            self.load_only = getattr(meta, 'load_only', ())
            self.dump_only = getattr(meta, 'dump_only', ())
            self.unknown = validate_unknown_parameter_value(getattr(meta, 'unknown', RAISE))
            self.register = getattr(meta, 'register', True)
    class Schema(base.SchemaABC, metaclass=SchemaMeta):
        """Base schema class with which to define custom schemas.

        Example usage:

        .. code-block:: python

            import datetime as dt
            from dataclasses import dataclass

            from marshmallow import Schema, fields


            @dataclass
            class Album:
                title: str
                release_date: dt.date


            class AlbumSchema(Schema):
                title = fields.Str()
                release_date = fields.Date()


            album = Album("Beggars Banquet", dt.date(1968, 12, 6))
            schema = AlbumSchema()
            data = schema.dump(album)
            data  # {'release_date': '1968-12-06', 'title': 'Beggars Banquet'}

        :param only: Whitelist of the declared fields to select when
            instantiating the Schema. If None, all fields are used. Nested fields
            can be represented with dot delimiters.
        :param exclude: Blacklist of the declared fields to exclude
            when instantiating the Schema. If a field appears in both `only` and
            `exclude`, it is not used. Nested fields can be represented with dot
            delimiters.
        :param many: Should be set to `True` if ``obj`` is a collection
            so that the object will be serialized to a list.
        :param context: Optional context passed to :class:`fields.Method` and
            :class:`fields.Function` fields.
        :param load_only: Fields to skip during serialization (write-only fields)
        :param dump_only: Fields to skip during deserialization (read-only fields)
        :param partial: Whether to ignore missing fields and not require
            any fields declared. Propagates down to ``Nested`` fields as well. If
            its value is an iterable, only missing fields listed in that iterable
            will be ignored. Use dot delimiters to specify nested fields.
        :param unknown: Whether to exclude, include, or raise an error for unknown
            fields in the data. Use `EXCLUDE`, `INCLUDE` or `RAISE`.

        .. versionchanged:: 3.0.0
            `prefix` parameter removed.

        .. versionchanged:: 2.0.0
            `__validators__`, `__preprocessors__`, and `__data_handlers__` are removed in favor of
            `marshmallow.decorators.validates_schema`,
            `marshmallow.decorators.pre_load` and `marshmallow.decorators.post_dump`.
            `__accessor__` and `__error_handler__` are deprecated. Implement the
            `handle_error` and `get_attribute` methods instead.
        """
        TYPE_MAPPING = {str: ma_fields.String, bytes: ma_fields.String, dt.datetime: ma_fields.DateTime, float: ma_fields.Float, bool: ma_fields.Boolean, tuple: ma_fields.Raw, list: ma_fields.Raw, set: ma_fields.Raw, int: ma_fields.Integer, uuid.UUID: ma_fields.UUID, dt.time: ma_fields.Time, dt.date: ma_fields.Date, dt.timedelta: ma_fields.TimeDelta, decimal.Decimal: ma_fields.Decimal}
        error_messages = {}
        _default_error_messages = {'type': 'Invalid input type.', 'unknown': 'Unknown field.'}
        OPTIONS_CLASS = SchemaOpts
        set_class = OrderedSet
        opts = None
        _declared_fields = {}
        _hooks = {}

        class Meta:
            """Options object for a Schema.

            Example usage: ::

                class Meta:
                    fields = ("id", "email", "date_created")
                    exclude = ("password", "secret_attribute")

            Available options:

            - ``fields``: Tuple or list of fields to include in the serialized result.
            - ``additional``: Tuple or list of fields to include *in addition* to the
                explicitly declared fields. ``additional`` and ``fields`` are
                mutually-exclusive options.
            - ``include``: Dictionary of additional fields to include in the schema. It is
                usually better to define fields as class variables, but you may need to
                use this option, e.g., if your fields are Python keywords. May be an
                `OrderedDict`.
            - ``exclude``: Tuple or list of fields to exclude in the serialized result.
                Nested fields can be represented with dot delimiters.
            - ``dateformat``: Default format for `Date <fields.Date>` fields.
            - ``datetimeformat``: Default format for `DateTime <fields.DateTime>` fields.
            - ``timeformat``: Default format for `Time <fields.Time>` fields.
            - ``render_module``: Module to use for `loads <Schema.loads>` and `dumps <Schema.dumps>`.
                Defaults to `json` from the standard library.
            - ``ordered``: If `True`, output of `Schema.dump` will be a `collections.OrderedDict`.
            - ``index_errors``: If `True`, errors dictionaries will include the index
                of invalid items in a collection.
            - ``load_only``: Tuple or list of fields to exclude from serialized results.
            - ``dump_only``: Tuple or list of fields to exclude from deserialization
            - ``unknown``: Whether to exclude, include, or raise an error for unknown
                fields in the data. Use `EXCLUDE`, `INCLUDE` or `RAISE`.
            - ``register``: Whether to register the `Schema` with marshmallow's internal
                class registry. Must be `True` if you intend to refer to this `Schema`
                by class name in `Nested` fields. Only set this to `False` when memory
                usage is critical. Defaults to `True`.
            """

        def __init__(self, *, only: types.StrSequenceOrSet | None=None, exclude: types.StrSequenceOrSet=(), many: bool=False, context: dict | None=None, load_only: types.StrSequenceOrSet=(), dump_only: types.StrSequenceOrSet=(), partial: bool | types.StrSequenceOrSet | None=None, unknown: str | None=None):
            if only is not None and (not is_collection(only)):
                raise StringNotCollectionError('"only" should be a list of strings')
            if not is_collection(exclude):
                raise StringNotCollectionError('"exclude" should be a list of strings')
            self.declared_fields = copy.deepcopy(self._declared_fields)
            self.many = many
            self.only = only
            self.exclude: set[typing.Any] | typing.MutableSet[typing.Any] = set(self.opts.exclude) | set(exclude)
            self.ordered = self.opts.ordered
            self.load_only = set(load_only) or set(self.opts.load_only)
            self.dump_only = set(dump_only) or set(self.opts.dump_only)
            self.partial = partial
            self.unknown = self.opts.unknown if unknown is None else validate_unknown_parameter_value(unknown)
            self.context = context or {}
            self._normalize_nested_options()
            self.fields = {}
            self.load_fields = {}
            self.dump_fields = {}
            self._init_fields()
            messages = {}
            messages.update(self._default_error_messages)
            for cls in reversed(self.__class__.__mro__):
                messages.update(getattr(cls, 'error_messages', {}))
            messages.update(self.error_messages or {})
            self.error_messages = messages

        def __repr__(self) -> str:
            return f'<{self.__class__.__name__}(many={self.many})>'

        @classmethod
        def from_dict(cls, fields: dict[str, ma_fields.Field | type], *, name: str='GeneratedSchema') -> type:
            ...

        def handle_error(self, error: ValidationError, data: typing.Any, *, many: bool, **kwargs):
            ...

        def get_attribute(self, obj: typing.Any, attr: str, default: typing.Any):
            ...

        @staticmethod
        def _call_and_store(getter_func, data, *, field_name, error_store, index=None):
            ...

        def _serialize(self, obj: _T | typing.Iterable[_T], *, many: bool=False):
            ...

        def dump(self, obj: typing.Any, *, many: bool | None=None):
            ...

        def dumps(self, obj: typing.Any, *args, many: bool | None=None, **kwargs):
            ...

        def _deserialize(self, data: typing.Mapping[str, typing.Any] | typing.Iterable[typing.Mapping[str, typing.Any]], *, error_store: ErrorStore, many: bool=False, partial=None, unknown=RAISE, index=None) -> _T | list[_T]:
            ...

        def load(self, data: typing.Mapping[str, typing.Any] | typing.Iterable[typing.Mapping[str, typing.Any]], *, many: bool | None=None, partial: bool | types.StrSequenceOrSet | None=None, unknown: str | None=None):
            ...

        def loads(self, json_data: str, *, many: bool | None=None, partial: bool | types.StrSequenceOrSet | None=None, unknown: str | None=None, **kwargs):
            ...

        def validate(self, data: typing.Mapping[str, typing.Any] | typing.Iterable[typing.Mapping[str, typing.Any]], *, many: bool | None=None, partial: bool | types.StrSequenceOrSet | None=None) -> dict[str, list[str]]:
            ...

        def _do_load(self, data: typing.Mapping[str, typing.Any] | typing.Iterable[typing.Mapping[str, typing.Any]], *, many: bool | None=None, partial: bool | types.StrSequenceOrSet | None=None, unknown: str | None=None, postprocess: bool=True):
            ...

        def _normalize_nested_options(self) -> None:
            ...

        def __apply_nested_option(self, option_name, field_names, set_operation) -> None:
            ...

        def _init_fields(self) -> None:
            ...

        def on_bind_field(self, field_name: str, field_obj: ma_fields.Field) -> None:
            ...

        def _bind_field(self, field_name: str, field_obj: ma_fields.Field) -> None:
            ...


preamble types:
  source: marshmallow/types.py
  imports: |
    import typing
  constants: |
    StrSequenceOrSet = typing.Union[typing.Sequence[str], typing.AbstractSet[str]]
    Tag = typing.Union[str, typing.Tuple[str, bool]]
    Validator = typing.Callable[[typing.Any], typing.Any]
  body: |
    'Type aliases.\n\n.. warning::\n\n    This module is provisional. Types may be modified, added, and removed between minor releases.\n'


preamble utils:
  source: marshmallow/utils.py
  imports: |
    from __future__ import annotations
    import collections
    import datetime as dt
    import functools
    import inspect
    import json
    import re
    import typing
    import warnings
    from collections.abc import Mapping
    from email.utils import format_datetime, parsedate_to_datetime
    from pprint import pprint as py_pprint
    from marshmallow.base import FieldABC
    from marshmallow.exceptions import FieldInstanceResolutionError
    from marshmallow.warnings import RemovedInMarshmallow4Warning
  constants: |
    EXCLUDE = 'exclude'
    INCLUDE = 'include'
    RAISE = 'raise'
    _UNKNOWN_VALUES = {EXCLUDE, INCLUDE, RAISE}
    missing = _Missing()
    _iso8601_datetime_re = re.compile('(?P<year>\\d{4})-(?P<month>\\d{1,2})-(?P<day>\\d{1,2})[T ](?P<hour>\\d{1,2}):(?P<minute>\\d{1,2})(?::(?P<second>\\d{1,2})(?:\\.(?P<microsecond>\\d{1,6})\\d{0,6})?)?(?P<tzinfo>Z|[+-]\\d{2}(?::?\\d{2})?)?$')
    _iso8601_date_re = re.compile('(?P<year>\\d{4})-(?P<month>\\d{1,2})-(?P<day>\\d{1,2})$')
    _iso8601_time_re = re.compile('(?P<hour>\\d{1,2}):(?P<minute>\\d{1,2})(?::(?P<second>\\d{1,2})(?:\\.(?P<microsecond>\\d{1,6})\\d{0,6})?)?')
  body: |
    'Utility methods for marshmallow.'
    class _Missing:

        def __bool__(self):
            return False

        def __copy__(self):
            return self

        def __deepcopy__(self, _):
            return self

        def __repr__(self):
            return '<marshmallow.missing>'


preamble validate:
  source: marshmallow/validate.py
  imports: |
    from __future__ import annotations
    import re
    import typing
    from abc import ABC, abstractmethod
    from itertools import zip_longest
    from operator import attrgetter
    from marshmallow import types
    from marshmallow.exceptions import ValidationError
  constants: |
    _T = typing.TypeVar('_T')
  body: |
    'Validation classes for various types of data.'
    class Validator(ABC):
        """Abstract base class for validators.

        .. note::
            This class does not provide any validation behavior. It is only used to
            add a useful `__repr__` implementation for validators.
        """
        error = None

        def __repr__(self) -> str:
            args = self._repr_args()
            args = f'{args}, ' if args else ''
            return f'<{self.__class__.__name__}({args}error={self.error!r})>'

        def _repr_args(self) -> str:
            ...

        @abstractmethod
        def __call__(self, value: typing.Any) -> typing.Any:
            ...
    class And(Validator):
        """Compose multiple validators and combine their error messages.

        Example: ::

            from marshmallow import validate, ValidationError


            def is_even(value):
                if value % 2 != 0:
                    raise ValidationError("Not an even value.")


            validator = validate.And(validate.Range(min=0), is_even)
            validator(-1)
            # ValidationError: ['Must be greater than or equal to 0.', 'Not an even value.']

        :param validators: Validators to combine.
        :param error: Error message to use when a validator returns ``False``.
        """
        default_error_message = 'Invalid value.'

        def __init__(self, *validators: types.Validator, error: str | None=None):
            self.validators = tuple(validators)
            self.error = error or self.default_error_message

        def __call__(self, value: typing.Any) -> typing.Any:
            errors = []
            kwargs = {}
            for validator in self.validators:
                try:
                    r = validator(value)
                    if not isinstance(validator, Validator) and r is False:
                        raise ValidationError(self.error)
                except ValidationError as err:
                    kwargs.update(err.kwargs)
                    if isinstance(err.messages, dict):
                        errors.append(err.messages)
                    else:
                        errors.extend(typing.cast(list, err.messages))
            if errors:
                raise ValidationError(errors, **kwargs)
            return value
    class URL(Validator):
        """Validate a URL.

        :param relative: Whether to allow relative URLs.
        :param absolute: Whether to allow absolute URLs.
        :param error: Error message to raise in case of a validation error.
            Can be interpolated with `{input}`.
        :param schemes: Valid schemes. By default, ``http``, ``https``,
            ``ftp``, and ``ftps`` are allowed.
        :param require_tld: Whether to reject non-FQDN hostnames.
        """

        class RegexMemoizer:

            def __init__(self):
                self._memoized = {}

            def __call__(self, relative: bool, absolute: bool, require_tld: bool) -> typing.Pattern:
                key = (relative, absolute, require_tld)
                if key not in self._memoized:
                    self._memoized[key] = self._regex_generator(relative, absolute, require_tld)
                return self._memoized[key]
        _regex = RegexMemoizer()
        default_message = 'Not a valid URL.'
        default_schemes = {'http', 'https', 'ftp', 'ftps'}

        def __init__(self, *, relative: bool=False, absolute: bool=True, schemes: types.StrSequenceOrSet | None=None, require_tld: bool=True, error: str | None=None):
            if not relative and (not absolute):
                raise ValueError('URL validation cannot set both relative and absolute to False.')
            self.relative = relative
            self.absolute = absolute
            self.error = error or self.default_message
            self.schemes = schemes or self.default_schemes
            self.require_tld = require_tld

        def __call__(self, value: str) -> str:
            message = self._format_error(value)
            if not value:
                raise ValidationError(message)
            if '://' in value:
                scheme = value.split('://')[0].lower()
                if scheme not in self.schemes:
                    raise ValidationError(message)
            regex = self._regex(self.relative, self.absolute, self.require_tld)
            if not regex.search(value):
                raise ValidationError(message)
            return value
    class Email(Validator):
        """Validate an email address.

        :param error: Error message to raise in case of a validation error. Can be
            interpolated with `{input}`.
        """
        USER_REGEX = re.compile('(^[-!#$%&\'*+/=?^`{}|~\\w]+(\\.[-!#$%&\'*+/=?^`{}|~\\w]+)*\\Z|^"([\\001-\\010\\013\\014\\016-\\037!#-\\[\\]-\\177]|\\\\[\\001-\\011\\013\\014\\016-\\177])*"\\Z)', re.IGNORECASE | re.UNICODE)
        DOMAIN_REGEX = re.compile('(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\\.)+(?:[A-Z]{2,6}|[A-Z0-9-]{2,})\\Z|^\\[(25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)(\\.(25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)){3}\\]\\Z', re.IGNORECASE | re.UNICODE)
        DOMAIN_WHITELIST = ('localhost',)
        default_message = 'Not a valid email address.'

        def __init__(self, *, error: str | None=None):
            self.error = error or self.default_message

        def __call__(self, value: str) -> str:
            message = self._format_error(value)
            if not value or '@' not in value:
                raise ValidationError(message)
            user_part, domain_part = value.rsplit('@', 1)
            if not self.USER_REGEX.match(user_part):
                raise ValidationError(message)
            if domain_part not in self.DOMAIN_WHITELIST:
                if not self.DOMAIN_REGEX.match(domain_part):
                    try:
                        domain_part = domain_part.encode('idna').decode('ascii')
                    except UnicodeError:
                        pass
                    else:
                        if self.DOMAIN_REGEX.match(domain_part):
                            return value
                    raise ValidationError(message)
            return value
    class Range(Validator):
        """Validator which succeeds if the value passed to it is within the specified
        range. If ``min`` is not specified, or is specified as `None`,
        no lower bound exists. If ``max`` is not specified, or is specified as `None`,
        no upper bound exists. The inclusivity of the bounds (if they exist) is configurable.
        If ``min_inclusive`` is not specified, or is specified as `True`, then
        the ``min`` bound is included in the range. If ``max_inclusive`` is not specified,
        or is specified as `True`, then the ``max`` bound is included in the range.

        :param min: The minimum value (lower bound). If not provided, minimum
            value will not be checked.
        :param max: The maximum value (upper bound). If not provided, maximum
            value will not be checked.
        :param min_inclusive: Whether the `min` bound is included in the range.
        :param max_inclusive: Whether the `max` bound is included in the range.
        :param error: Error message to raise in case of a validation error.
            Can be interpolated with `{input}`, `{min}` and `{max}`.
        """
        message_min = 'Must be {min_op} {{min}}.'
        message_max = 'Must be {max_op} {{max}}.'
        message_all = 'Must be {min_op} {{min}} and {max_op} {{max}}.'
        message_gte = 'greater than or equal to'
        message_gt = 'greater than'
        message_lte = 'less than or equal to'
        message_lt = 'less than'

        def __init__(self, min=None, max=None, *, min_inclusive: bool=True, max_inclusive: bool=True, error: str | None=None):
            self.min = min
            self.max = max
            self.error = error
            self.min_inclusive = min_inclusive
            self.max_inclusive = max_inclusive
            self.message_min = self.message_min.format(min_op=self.message_gte if self.min_inclusive else self.message_gt)
            self.message_max = self.message_max.format(max_op=self.message_lte if self.max_inclusive else self.message_lt)
            self.message_all = self.message_all.format(min_op=self.message_gte if self.min_inclusive else self.message_gt, max_op=self.message_lte if self.max_inclusive else self.message_lt)

        def __call__(self, value: _T) -> _T:
            if self.min is not None and (value < self.min if self.min_inclusive else value <= self.min):
                message = self.message_min if self.max is None else self.message_all
                raise ValidationError(self._format_error(value, message))
            if self.max is not None and (value > self.max if self.max_inclusive else value >= self.max):
                message = self.message_max if self.min is None else self.message_all
                raise ValidationError(self._format_error(value, message))
            return value
    class Length(Validator):
        """Validator which succeeds if the value passed to it has a
        length between a minimum and maximum. Uses len(), so it
        can work for strings, lists, or anything with length.

        :param min: The minimum length. If not provided, minimum length
            will not be checked.
        :param max: The maximum length. If not provided, maximum length
            will not be checked.
        :param equal: The exact length. If provided, maximum and minimum
            length will not be checked.
        :param error: Error message to raise in case of a validation error.
            Can be interpolated with `{input}`, `{min}` and `{max}`.
        """
        message_min = 'Shorter than minimum length {min}.'
        message_max = 'Longer than maximum length {max}.'
        message_all = 'Length must be between {min} and {max}.'
        message_equal = 'Length must be {equal}.'

        def __init__(self, min: int | None=None, max: int | None=None, *, equal: int | None=None, error: str | None=None):
            if equal is not None and any([min, max]):
                raise ValueError('The `equal` parameter was provided, maximum or minimum parameter must not be provided.')
            self.min = min
            self.max = max
            self.error = error
            self.equal = equal

        def __call__(self, value: typing.Sized) -> typing.Sized:
            length = len(value)
            if self.equal is not None:
                if length != self.equal:
                    raise ValidationError(self._format_error(value, self.message_equal))
                return value
            if self.min is not None and length < self.min:
                message = self.message_min if self.max is None else self.message_all
                raise ValidationError(self._format_error(value, message))
            if self.max is not None and length > self.max:
                message = self.message_max if self.min is None else self.message_all
                raise ValidationError(self._format_error(value, message))
            return value
    class Equal(Validator):
        """Validator which succeeds if the ``value`` passed to it is
        equal to ``comparable``.

        :param comparable: The object to compare to.
        :param error: Error message to raise in case of a validation error.
            Can be interpolated with `{input}` and `{other}`.
        """
        default_message = 'Must be equal to {other}.'

        def __init__(self, comparable, *, error: str | None=None):
            self.comparable = comparable
            self.error = error or self.default_message

        def __call__(self, value: _T) -> _T:
            if value != self.comparable:
                raise ValidationError(self._format_error(value))
            return value
    class Regexp(Validator):
        """Validator which succeeds if the ``value`` matches ``regex``.

        .. note::

            Uses `re.match`, which searches for a match at the beginning of a string.

        :param regex: The regular expression string to use. Can also be a compiled
            regular expression pattern.
        :param flags: The regexp flags to use, for example re.IGNORECASE. Ignored
            if ``regex`` is not a string.
        :param error: Error message to raise in case of a validation error.
            Can be interpolated with `{input}` and `{regex}`.
        """
        default_message = 'String does not match expected pattern.'

        def __init__(self, regex: str | bytes | typing.Pattern, flags: int=0, *, error: str | None=None):
            self.regex = re.compile(regex, flags) if isinstance(regex, (str, bytes)) else regex
            self.error = error or self.default_message

        @typing.overload
        def __call__(self, value: str) -> str:
            ...

        @typing.overload
        def __call__(self, value: bytes) -> bytes:
            ...

        def __call__(self, value):
            if self.regex.match(value) is None:
                raise ValidationError(self._format_error(value))
            return value
    class Predicate(Validator):
        """Call the specified ``method`` of the ``value`` object. The
        validator succeeds if the invoked method returns an object that
        evaluates to True in a Boolean context. Any additional keyword
        argument will be passed to the method.

        :param method: The name of the method to invoke.
        :param error: Error message to raise in case of a validation error.
            Can be interpolated with `{input}` and `{method}`.
        :param kwargs: Additional keyword arguments to pass to the method.
        """
        default_message = 'Invalid input.'

        def __init__(self, method: str, *, error: str | None=None, **kwargs):
            self.method = method
            self.error = error or self.default_message
            self.kwargs = kwargs

        def __call__(self, value: typing.Any) -> typing.Any:
            method = getattr(value, self.method)
            if not method(**self.kwargs):
                raise ValidationError(self._format_error(value))
            return value
    class NoneOf(Validator):
        """Validator which fails if ``value`` is a member of ``iterable``.

        :param iterable: A sequence of invalid values.
        :param error: Error message to raise in case of a validation error. Can be
            interpolated using `{input}` and `{values}`.
        """
        default_message = 'Invalid input.'

        def __init__(self, iterable: typing.Iterable, *, error: str | None=None):
            self.iterable = iterable
            self.values_text = ', '.join((str(each) for each in self.iterable))
            self.error = error or self.default_message

        def __call__(self, value: typing.Any) -> typing.Any:
            try:
                if value in self.iterable:
                    raise ValidationError(self._format_error(value))
            except TypeError:
                pass
            return value
    class OneOf(Validator):
        """Validator which succeeds if ``value`` is a member of ``choices``.

        :param choices: A sequence of valid values.
        :param labels: Optional sequence of labels to pair with the choices.
        :param error: Error message to raise in case of a validation error. Can be
            interpolated with `{input}`, `{choices}` and `{labels}`.
        """
        default_message = 'Must be one of: {choices}.'

        def __init__(self, choices: typing.Iterable, labels: typing.Iterable[str] | None=None, *, error: str | None=None):
            self.choices = choices
            self.choices_text = ', '.join((str(choice) for choice in self.choices))
            self.labels = labels if labels is not None else []
            self.labels_text = ', '.join((str(label) for label in self.labels))
            self.error = error or self.default_message

        def __call__(self, value: typing.Any) -> typing.Any:
            try:
                if value not in self.choices:
                    raise ValidationError(self._format_error(value))
            except TypeError as error:
                raise ValidationError(self._format_error(value)) from error
            return value

        def options(self, valuegetter: str | typing.Callable[[typing.Any], typing.Any]=str) -> typing.Iterable[tuple[typing.Any, str]]:
            ...
    class ContainsOnly(OneOf):
        """Validator which succeeds if ``value`` is a sequence and each element
        in the sequence is also in the sequence passed as ``choices``. Empty input
        is considered valid.

        :param iterable choices: Same as :class:`OneOf`.
        :param iterable labels: Same as :class:`OneOf`.
        :param str error: Same as :class:`OneOf`.

        .. versionchanged:: 3.0.0b2
            Duplicate values are considered valid.
        .. versionchanged:: 3.0.0b2
            Empty input is considered valid. Use `validate.Length(min=1) <marshmallow.validate.Length>`
            to validate against empty inputs.
        """
        default_message = 'One or more of the choices you made was not in: {choices}.'

        def __call__(self, value: typing.Sequence[_T]) -> typing.Sequence[_T]:
            for val in value:
                if val not in self.choices:
                    raise ValidationError(self._format_error(value))
            return value
    class ContainsNoneOf(NoneOf):
        """Validator which fails if ``value`` is a sequence and any element
        in the sequence is a member of the sequence passed as ``iterable``. Empty input
        is considered valid.

        :param iterable iterable: Same as :class:`NoneOf`.
        :param str error: Same as :class:`NoneOf`.

        .. versionadded:: 3.6.0
        """
        default_message = 'One or more of the choices you made was in: {values}.'

        def __call__(self, value: typing.Sequence[_T]) -> typing.Sequence[_T]:
            for val in value:
                if val in self.iterable:
                    raise ValidationError(self._format_error(value))
            return value


preamble warnings:
  source: marshmallow/warnings.py
  body: |
    class RemovedInMarshmallow4Warning(DeprecationWarning):
        pass


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
