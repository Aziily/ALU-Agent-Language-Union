preamble __init__:
  source: voluptuous/__init__.py
  body: |
    "Schema validation for Python data structures.\n\nGiven eg. a nested data structure like this:\n\n    {\n        'exclude': ['Users', 'Uptime'],\n        'include': [],\n        'set': {\n            'snmp_community': 'public',\n            'snmp_timeout': 15,\n            'snmp_version': '2c',\n        },\n        'targets': {\n            'localhost': {\n                'exclude': ['Uptime'],\n                'features': {\n                    'Uptime': {\n                        'retries': 3,\n                    },\n                    'Users': {\n                        'snmp_community': 'monkey',\n                        'snmp_port': 15,\n                    },\n                },\n                'include': ['Users'],\n                'set': {\n                    'snmp_community': 'monkeys',\n                },\n            },\n        },\n    }\n\nA schema like this:\n\n    >>> settings = {\n    ...   'snmp_community': str,\n    ...   'retries': int,\n    ...   'snmp_version': All(Coerce(str), Any('3', '2c', '1')),\n    ... }\n    >>> features = ['Ping', 'Uptime', 'Http']\n    >>> schema = Schema({\n    ...    'exclude': features,\n    ...    'include': features,\n    ...    'set': settings,\n    ...    'targets': {\n    ...      'exclude': features,\n    ...      'include': features,\n    ...      'features': {\n    ...        str: settings,\n    ...      },\n    ...    },\n    ... })\n\nValidate like so:\n\n    >>> schema({\n    ...   'set': {\n    ...     'snmp_community': 'public',\n    ...     'snmp_version': '2c',\n    ...   },\n    ...   'targets': {\n    ...     'exclude': ['Ping'],\n    ...     'features': {\n    ...       'Uptime': {'retries': 3},\n    ...       'Users': {'snmp_community': 'monkey'},\n    ...     },\n    ...   },\n    ... }) == {\n    ...   'set': {'snmp_version': '2c', 'snmp_community': 'public'},\n    ...   'targets': {\n    ...     'exclude': ['Ping'],\n    ...     'features': {'Uptime': {'retries': 3},\n    ...                  'Users': {'snmp_community': 'monkey'}}}}\n    True\n"
    from voluptuous.schema_builder import *
    from voluptuous.util import *
    from voluptuous.validators import *
    from voluptuous.error import *
    __version__ = '0.15.2'
    __author__ = 'alecthomas'


preamble error:
  source: voluptuous/error.py
  body: |
    import typing
    class Error(Exception):
        """Base validation exception."""
    class SchemaError(Error):
        """An error was encountered in the schema."""
    class Invalid(Error):
        """The data was invalid.

        :attr msg: The error message.
        :attr path: The path to the error, as a list of keys in the source data.
        :attr error_message: The actual error message that was raised, as a
            string.

        """

        def __init__(self, message: str, path: typing.Optional[typing.List[typing.Hashable]]=None, error_message: typing.Optional[str]=None, error_type: typing.Optional[str]=None) -> None:
            Error.__init__(self, message)
            self._path = path or []
            self._error_message = error_message or message
            self.error_type = error_type

        def __str__(self) -> str:
            path = ' @ data[%s]' % ']['.join(map(repr, self.path)) if self.path else ''
            output = Exception.__str__(self)
            if self.error_type:
                output += ' for ' + self.error_type
            return output + path
    class MultipleInvalid(Invalid):

        def __init__(self, errors: typing.Optional[typing.List[Invalid]]=None) -> None:
            self.errors = errors[:] if errors else []

        def __repr__(self) -> str:
            return 'MultipleInvalid(%r)' % self.errors

        def __str__(self) -> str:
            return str(self.errors[0])
    class RequiredFieldInvalid(Invalid):
        """Required field was missing."""
    class ObjectInvalid(Invalid):
        """The value we found was not an object."""
    class DictInvalid(Invalid):
        """The value found was not a dict."""
    class ExclusiveInvalid(Invalid):
        """More than one value found in exclusion group."""
    class InclusiveInvalid(Invalid):
        """Not all values found in inclusion group."""
    class SequenceTypeInvalid(Invalid):
        """The type found is not a sequence type."""
    class TypeInvalid(Invalid):
        """The value was not of required type."""
    class ValueInvalid(Invalid):
        """The value was found invalid by evaluation function."""
    class ContainsInvalid(Invalid):
        """List does not contain item"""
    class ScalarInvalid(Invalid):
        """Scalars did not match."""
    class CoerceInvalid(Invalid):
        """Impossible to coerce value to type."""
    class AnyInvalid(Invalid):
        """The value did not pass any validator."""
    class AllInvalid(Invalid):
        """The value did not pass all validators."""
    class MatchInvalid(Invalid):
        """The value does not match the given regular expression."""
    class RangeInvalid(Invalid):
        """The value is not in given range."""
    class TrueInvalid(Invalid):
        """The value is not True."""
    class FalseInvalid(Invalid):
        """The value is not False."""
    class BooleanInvalid(Invalid):
        """The value is not a boolean."""
    class UrlInvalid(Invalid):
        """The value is not a URL."""
    class EmailInvalid(Invalid):
        """The value is not an email address."""
    class FileInvalid(Invalid):
        """The value is not a file."""
    class DirInvalid(Invalid):
        """The value is not a directory."""
    class PathInvalid(Invalid):
        """The value is not a path."""
    class LiteralInvalid(Invalid):
        """The literal values do not match."""
    class LengthInvalid(Invalid):
        pass
    class DatetimeInvalid(Invalid):
        """The value is not a formatted datetime string."""
    class DateInvalid(Invalid):
        """The value is not a formatted date string."""
    class InInvalid(Invalid):
        pass
    class NotInInvalid(Invalid):
        pass
    class ExactSequenceInvalid(Invalid):
        pass
    class NotEnoughValid(Invalid):
        """The value did not pass enough validations."""
        pass
    class TooManyValid(Invalid):
        """The value passed more than expected validations."""
        pass


preamble humanize:
  source: voluptuous/humanize.py
  body: |
    import typing
    from voluptuous import Invalid, MultipleInvalid
    from voluptuous.error import Error
    from voluptuous.schema_builder import Schema
    MAX_VALIDATION_ERROR_ITEM_LENGTH = 500


preamble schema_builder:
  source: voluptuous/schema_builder.py
  body: |
    from __future__ import annotations
    import collections
    import inspect
    import itertools
    import re
    import sys
    import typing
    from collections.abc import Generator
    from contextlib import contextmanager
    from functools import cache, wraps
    from voluptuous import error as er
    from voluptuous.error import Error
    PREVENT_EXTRA = 0
    ALLOW_EXTRA = 1
    REMOVE_EXTRA = 2
    class Undefined(object):

        def __nonzero__(self):
            return False

        def __repr__(self):
            return '...'
    UNDEFINED = Undefined()
    DefaultFactory = typing.Union[Undefined, typing.Callable[[], typing.Any]]
    extra = Extra
    primitive_types = (bool, bytes, int, str, float, complex)
    Schemable = typing.Union['Schema', 'Object', collections.abc.Mapping, list, tuple, frozenset, set, bool, bytes, int, str, float, complex, type, object, dict, None, typing.Callable]
    class Schema(object):
        """A validation schema.

        The schema is a Python tree-like structure where nodes are pattern
        matched against corresponding trees of values.

        Nodes can be values, in which case a direct comparison is used, types,
        in which case an isinstance() check is performed, or callables, which will
        validate and optionally convert the value.

        We can equate schemas also.

        For Example:

                >>> v = Schema({Required('a'): str})
                >>> v1 = Schema({Required('a'): str})
                >>> v2 = Schema({Required('b'): str})
                >>> assert v == v1
                >>> assert v != v2

        """
        _extra_to_name = {REMOVE_EXTRA: 'REMOVE_EXTRA', ALLOW_EXTRA: 'ALLOW_EXTRA', PREVENT_EXTRA: 'PREVENT_EXTRA'}

        def __init__(self, schema: Schemable, required: bool=False, extra: int=PREVENT_EXTRA) -> None:
            """Create a new Schema.

            :param schema: Validation schema. See :module:`voluptuous` for details.
            :param required: Keys defined in the schema must be in the data.
            :param extra: Specify how extra keys in the data are treated:
                - :const:`~voluptuous.PREVENT_EXTRA`: to disallow any undefined
                  extra keys (raise ``Invalid``).
                - :const:`~voluptuous.ALLOW_EXTRA`: to include undefined extra
                  keys in the output.
                - :const:`~voluptuous.REMOVE_EXTRA`: to exclude undefined extra keys
                  from the output.
                - Any value other than the above defaults to
                  :const:`~voluptuous.PREVENT_EXTRA`
            """
            self.schema: typing.Any = schema
            self.required = required
            self.extra = int(extra)
            self._compiled = self._compile(schema)

        @classmethod
        def infer(cls, data, **kwargs) -> Schema:
            """Create a Schema from concrete data (e.g. an API response).

            For example, this will take a dict like:

            {
                'foo': 1,
                'bar': {
                    'a': True,
                    'b': False
                },
                'baz': ['purple', 'monkey', 'dishwasher']
            }

            And return a Schema:

            {
                'foo': int,
                'bar': {
                    'a': bool,
                    'b': bool
                },
                'baz': [str]
            }

            Note: only very basic inference is supported.
            """
            pass

        def __eq__(self, other):
            if not isinstance(other, Schema):
                return False
            return other.schema == self.schema

        def __ne__(self, other):
            return not self == other

        def __str__(self):
            return str(self.schema)

        def __repr__(self):
            return '<Schema(%s, extra=%s, required=%s) object at 0x%x>' % (self.schema, self._extra_to_name.get(self.extra, '??'), self.required, id(self))

        def __call__(self, data):
            """Validate data against this schema."""
            try:
                return self._compiled([], data)
            except er.MultipleInvalid:
                raise
            except er.Invalid as e:
                raise er.MultipleInvalid([e])

        def _compile_mapping(self, schema, invalid_msg=None):
            """Create validator for given mapping."""
            pass

        def _compile_object(self, schema):
            """Validate an object.

            Has the same behavior as dictionary validator but work with object
            attributes.

            For example:

                >>> class Structure(object):
                ...     def __init__(self, one=None, three=None):
                ...         self.one = one
                ...         self.three = three
                ...
                >>> validate = Schema(Object({'one': 'two', 'three': 'four'}, cls=Structure))
                >>> with raises(er.MultipleInvalid, "not a valid value for object value @ data['one']"):
                ...   validate(Structure(one='three'))

            """
            pass

        def _compile_dict(self, schema):
            """Validate a dictionary.

            A dictionary schema can contain a set of values, or at most one
            validator function/type.

            A dictionary schema will only validate a dictionary:

                >>> validate = Schema({})
                >>> with raises(er.MultipleInvalid, 'expected a dictionary'):
                ...   validate([])

            An invalid dictionary value:

                >>> validate = Schema({'one': 'two', 'three': 'four'})
                >>> with raises(er.MultipleInvalid, "not a valid value for dictionary value @ data['one']"):
                ...   validate({'one': 'three'})

            An invalid key:

                >>> with raises(er.MultipleInvalid, "extra keys not allowed @ data['two']"):
                ...   validate({'two': 'three'})


            Validation function, in this case the "int" type:

                >>> validate = Schema({'one': 'two', 'three': 'four', int: str})

            Valid integer input:

                >>> validate({10: 'twenty'})
                {10: 'twenty'}

            By default, a "type" in the schema (in this case "int") will be used
            purely to validate that the corresponding value is of that type. It
            will not Coerce the value:

                >>> with raises(er.MultipleInvalid, "extra keys not allowed @ data['10']"):
                ...   validate({'10': 'twenty'})

            Wrap them in the Coerce() function to achieve this:
                >>> from voluptuous import Coerce
                >>> validate = Schema({'one': 'two', 'three': 'four',
                ...                    Coerce(int): str})
                >>> validate({'10': 'twenty'})
                {10: 'twenty'}

            Custom message for required key

                >>> validate = Schema({Required('one', 'required'): 'two'})
                >>> with raises(er.MultipleInvalid, "required @ data['one']"):
                ...   validate({})

            (This is to avoid unexpected surprises.)

            Multiple errors for nested field in a dict:

            >>> validate = Schema({
            ...     'adict': {
            ...         'strfield': str,
            ...         'intfield': int
            ...     }
            ... })
            >>> try:
            ...     validate({
            ...         'adict': {
            ...             'strfield': 123,
            ...             'intfield': 'one'
            ...         }
            ...     })
            ... except er.MultipleInvalid as e:
            ...     print(sorted(str(i) for i in e.errors)) # doctest: +NORMALIZE_WHITESPACE
            ["expected int for dictionary value @ data['adict']['intfield']",
             "expected str for dictionary value @ data['adict']['strfield']"]

            """
            pass

        def _compile_sequence(self, schema, seq_type):
            """Validate a sequence type.

            This is a sequence of valid values or validators tried in order.

            >>> validator = Schema(['one', 'two', int])
            >>> validator(['one'])
            ['one']
            >>> with raises(er.MultipleInvalid, 'expected int @ data[0]'):
            ...   validator([3.5])
            >>> validator([1])
            [1]
            """
            pass

        def _compile_tuple(self, schema):
            """Validate a tuple.

            A tuple is a sequence of valid values or validators tried in order.

            >>> validator = Schema(('one', 'two', int))
            >>> validator(('one',))
            ('one',)
            >>> with raises(er.MultipleInvalid, 'expected int @ data[0]'):
            ...   validator((3.5,))
            >>> validator((1,))
            (1,)
            """
            pass

        def _compile_list(self, schema):
            """Validate a list.

            A list is a sequence of valid values or validators tried in order.

            >>> validator = Schema(['one', 'two', int])
            >>> validator(['one'])
            ['one']
            >>> with raises(er.MultipleInvalid, 'expected int @ data[0]'):
            ...   validator([3.5])
            >>> validator([1])
            [1]
            """
            pass

        def _compile_set(self, schema):
            """Validate a set.

            A set is an unordered collection of unique elements.

            >>> validator = Schema({int})
            >>> validator(set([42])) == set([42])
            True
            >>> with raises(er.Invalid, 'expected a set'):
            ...   validator(42)
            >>> with raises(er.MultipleInvalid, 'invalid value in set'):
            ...   validator(set(['a']))
            """
            pass

        def extend(self, schema: Schemable, required: typing.Optional[bool]=None, extra: typing.Optional[int]=None) -> Schema:
            """Create a new `Schema` by merging this and the provided `schema`.

            Neither this `Schema` nor the provided `schema` are modified. The
            resulting `Schema` inherits the `required` and `extra` parameters of
            this, unless overridden.

            Both schemas must be dictionary-based.

            :param schema: dictionary to extend this `Schema` with
            :param required: if set, overrides `required` of this `Schema`
            :param extra: if set, overrides `extra` of this `Schema`
            """
            pass
    _sort_item = _compile_itemsort()
    class Msg(object):
        """Report a user-friendly message if a schema fails to validate.

        >>> validate = Schema(
        ...   Msg(['one', 'two', int],
        ...       'should be one of "one", "two" or an integer'))
        >>> with raises(er.MultipleInvalid, 'should be one of "one", "two" or an integer'):
        ...   validate(['three'])

        Messages are only applied to invalid direct descendants of the schema:

        >>> validate = Schema(Msg([['one', 'two', int]], 'not okay!'))
        >>> with raises(er.MultipleInvalid, 'expected int @ data[0][0]'):
        ...   validate([['three']])

        The type which is thrown can be overridden but needs to be a subclass of Invalid

        >>> with raises(er.SchemaError, 'Msg can only use subclases of Invalid as custom class'):
        ...   validate = Schema(Msg([int], 'should be int', cls=KeyError))

        If you do use a subclass of Invalid, that error will be thrown (wrapped in a MultipleInvalid)

        >>> validate = Schema(Msg([['one', 'two', int]], 'not okay!', cls=er.RangeInvalid))
        >>> try:
        ...  validate(['three'])
        ... except er.MultipleInvalid as e:
        ...   assert isinstance(e.errors[0], er.RangeInvalid)
        """

        def __init__(self, schema: Schemable, msg: str, cls: typing.Optional[typing.Type[Error]]=None) -> None:
            if cls and (not issubclass(cls, er.Invalid)):
                raise er.SchemaError('Msg can only use subclases of Invalid as custom class')
            self._schema = schema
            self.schema = Schema(schema)
            self.msg = msg
            self.cls = cls

        def __call__(self, v):
            try:
                return self.schema(v)
            except er.Invalid as e:
                if len(e.path) > 1:
                    raise e
                else:
                    raise (self.cls or er.Invalid)(self.msg)

        def __repr__(self):
            return 'Msg(%s, %s, cls=%s)' % (self._schema, self.msg, self.cls)
    class Object(dict):
        """Indicate that we should work with attributes, not keys."""

        def __init__(self, schema: typing.Any, cls: object=UNDEFINED) -> None:
            self.cls = cls
            super(Object, self).__init__(schema)
    class VirtualPathComponent(str):

        def __str__(self):
            return '<' + self + '>'

        def __repr__(self):
            return self.__str__()
    class Marker(object):
        """Mark nodes for special treatment.

        `description` is an optional field, unused by Voluptuous itself, but can be
        introspected by any external tool, for example to generate schema documentation.
        """
        __slots__ = ('schema', '_schema', 'msg', 'description', '__hash__')

        def __init__(self, schema_: Schemable, msg: typing.Optional[str]=None, description: typing.Any | None=None) -> None:
            self.schema: typing.Any = schema_
            self._schema = Schema(schema_)
            self.msg = msg
            self.description = description
            self.__hash__ = cache(lambda: hash(schema_))

        def __call__(self, v):
            try:
                return self._schema(v)
            except er.Invalid as e:
                if not self.msg or len(e.path) > 1:
                    raise
                raise er.Invalid(self.msg)

        def __str__(self):
            return str(self.schema)

        def __repr__(self):
            return repr(self.schema)

        def __lt__(self, other):
            if isinstance(other, Marker):
                return self.schema < other.schema
            return self.schema < other

        def __eq__(self, other):
            return self.schema == other

        def __ne__(self, other):
            return not self.schema == other
    class Optional(Marker):
        """Mark a node in the schema as optional, and optionally provide a default

        >>> schema = Schema({Optional('key'): str})
        >>> schema({})
        {}
        >>> schema = Schema({Optional('key', default='value'): str})
        >>> schema({})
        {'key': 'value'}
        >>> schema = Schema({Optional('key', default=list): list})
        >>> schema({})
        {'key': []}

        If 'required' flag is set for an entire schema, optional keys aren't required

        >>> schema = Schema({
        ...    Optional('key'): str,
        ...    'key2': str
        ... }, required=True)
        >>> schema({'key2':'value'})
        {'key2': 'value'}
        """

        def __init__(self, schema: Schemable, msg: typing.Optional[str]=None, default: typing.Any=UNDEFINED, description: typing.Any | None=None) -> None:
            super(Optional, self).__init__(schema, msg=msg, description=description)
            self.default = default_factory(default)
    class Exclusive(Optional):
        """Mark a node in the schema as exclusive.

        Exclusive keys inherited from Optional:

        >>> schema = Schema({Exclusive('alpha', 'angles'): int, Exclusive('beta', 'angles'): int})
        >>> schema({'alpha': 30})
        {'alpha': 30}

        Keys inside a same group of exclusion cannot be together, it only makes sense for dictionaries:

        >>> with raises(er.MultipleInvalid, "two or more values in the same group of exclusion 'angles' @ data[<angles>]"):
        ...   schema({'alpha': 30, 'beta': 45})

        For example, API can provides multiple types of authentication, but only one works in the same time:

        >>> msg = 'Please, use only one type of authentication at the same time.'
        >>> schema = Schema({
        ... Exclusive('classic', 'auth', msg=msg):{
        ...     Required('email'): str,
        ...     Required('password'): str
        ...     },
        ... Exclusive('internal', 'auth', msg=msg):{
        ...     Required('secret_key'): str
        ...     },
        ... Exclusive('social', 'auth', msg=msg):{
        ...     Required('social_network'): str,
        ...     Required('token'): str
        ...     }
        ... })

        >>> with raises(er.MultipleInvalid, "Please, use only one type of authentication at the same time. @ data[<auth>]"):
        ...     schema({'classic': {'email': 'foo@example.com', 'password': 'bar'},
        ...             'social': {'social_network': 'barfoo', 'token': 'tEMp'}})
        """

        def __init__(self, schema: Schemable, group_of_exclusion: str, msg: typing.Optional[str]=None, description: typing.Any | None=None) -> None:
            super(Exclusive, self).__init__(schema, msg=msg, description=description)
            self.group_of_exclusion = group_of_exclusion
    class Inclusive(Optional):
        """Mark a node in the schema as inclusive.

        Inclusive keys inherited from Optional:

        >>> schema = Schema({
        ...     Inclusive('filename', 'file'): str,
        ...     Inclusive('mimetype', 'file'): str
        ... })
        >>> data = {'filename': 'dog.jpg', 'mimetype': 'image/jpeg'}
        >>> data == schema(data)
        True

        Keys inside a same group of inclusive must exist together, it only makes sense for dictionaries:

        >>> with raises(er.MultipleInvalid, "some but not all values in the same group of inclusion 'file' @ data[<file>]"):
        ...     schema({'filename': 'dog.jpg'})

        If none of the keys in the group are present, it is accepted:

        >>> schema({})
        {}

        For example, API can return 'height' and 'width' together, but not separately.

        >>> msg = "Height and width must exist together"
        >>> schema = Schema({
        ...     Inclusive('height', 'size', msg=msg): int,
        ...     Inclusive('width', 'size', msg=msg): int
        ... })

        >>> with raises(er.MultipleInvalid, msg + " @ data[<size>]"):
        ...     schema({'height': 100})

        >>> with raises(er.MultipleInvalid, msg + " @ data[<size>]"):
        ...     schema({'width': 100})

        >>> data = {'height': 100, 'width': 100}
        >>> data == schema(data)
        True
        """

        def __init__(self, schema: Schemable, group_of_inclusion: str, msg: typing.Optional[str]=None, description: typing.Any | None=None, default: typing.Any=UNDEFINED) -> None:
            super(Inclusive, self).__init__(schema, msg=msg, default=default, description=description)
            self.group_of_inclusion = group_of_inclusion
    class Required(Marker):
        """Mark a node in the schema as being required, and optionally provide a default value.

        >>> schema = Schema({Required('key'): str})
        >>> with raises(er.MultipleInvalid, "required key not provided @ data['key']"):
        ...   schema({})

        >>> schema = Schema({Required('key', default='value'): str})
        >>> schema({})
        {'key': 'value'}
        >>> schema = Schema({Required('key', default=list): list})
        >>> schema({})
        {'key': []}
        """

        def __init__(self, schema: Schemable, msg: typing.Optional[str]=None, default: typing.Any=UNDEFINED, description: typing.Any | None=None) -> None:
            super(Required, self).__init__(schema, msg=msg, description=description)
            self.default = default_factory(default)
    class Remove(Marker):
        """Mark a node in the schema to be removed and excluded from the validated
        output. Keys that fail validation will not raise ``Invalid``. Instead, these
        keys will be treated as extras.

        >>> schema = Schema({str: int, Remove(int): str})
        >>> with raises(er.MultipleInvalid, "extra keys not allowed @ data[1]"):
        ...    schema({'keep': 1, 1: 1.0})
        >>> schema({1: 'red', 'red': 1, 2: 'green'})
        {'red': 1}
        >>> schema = Schema([int, Remove(float), Extra])
        >>> schema([1, 2, 3, 4.0, 5, 6.0, '7'])
        [1, 2, 3, 5, '7']
        """

        def __init__(self, schema_: Schemable, msg: typing.Optional[str]=None, description: typing.Any | None=None) -> None:
            super().__init__(schema_, msg, description)
            self.__hash__ = cache(lambda: object.__hash__(self))

        def __call__(self, schema: Schemable):
            super(Remove, self).__call__(schema)
            return self.__class__

        def __repr__(self):
            return 'Remove(%r)' % (self.schema,)


preamble util:
  source: voluptuous/util.py
  body: |
    import typing
    from voluptuous import validators
    from voluptuous.error import Invalid, LiteralInvalid, TypeInvalid
    from voluptuous.schema_builder import DefaultFactory
    from voluptuous.schema_builder import Schema, default_factory, raises
    __author__ = 'tusharmakkar08'
    class DefaultTo(object):
        """Sets a value to default_value if none provided.

        >>> s = Schema(DefaultTo(42))
        >>> s(None)
        42
        >>> s = Schema(DefaultTo(list))
        >>> s(None)
        []
        """

        def __init__(self, default_value, msg: typing.Optional[str]=None) -> None:
            self.default_value = default_factory(default_value)
            self.msg = msg

        def __call__(self, v):
            if v is None:
                v = self.default_value()
            return v

        def __repr__(self):
            return 'DefaultTo(%s)' % (self.default_value(),)
    class SetTo(object):
        """Set a value, ignoring any previous value.

        >>> s = Schema(validators.Any(int, SetTo(42)))
        >>> s(2)
        2
        >>> s("foo")
        42
        """

        def __init__(self, value) -> None:
            self.value = default_factory(value)

        def __call__(self, v):
            return self.value()

        def __repr__(self):
            return 'SetTo(%s)' % (self.value(),)
    class Set(object):
        """Convert a list into a set.

        >>> s = Schema(Set())
        >>> s([]) == set([])
        True
        >>> s([1, 2]) == set([1, 2])
        True
        >>> with raises(Invalid, regex="^cannot be presented as set: "):
        ...   s([set([1, 2]), set([3, 4])])
        """

        def __init__(self, msg: typing.Optional[str]=None) -> None:
            self.msg = msg

        def __call__(self, v):
            try:
                set_v = set(v)
            except Exception as e:
                raise TypeInvalid(self.msg or 'cannot be presented as set: {0}'.format(e))
            return set_v

        def __repr__(self):
            return 'Set()'
    class Literal(object):

        def __init__(self, lit) -> None:
            self.lit = lit

        def __call__(self, value, msg: typing.Optional[str]=None):
            if self.lit != value:
                raise LiteralInvalid(msg or '%s not match for %s' % (value, self.lit))
            else:
                return self.lit

        def __str__(self):
            return str(self.lit)

        def __repr__(self):
            return repr(self.lit)


preamble validators:
  source: voluptuous/validators.py
  body: |
    from __future__ import annotations
    import datetime
    import os
    import re
    import sys
    import typing
    from decimal import Decimal, InvalidOperation
    from functools import wraps
    from voluptuous.error import AllInvalid, AnyInvalid, BooleanInvalid, CoerceInvalid, ContainsInvalid, DateInvalid, DatetimeInvalid, DirInvalid, EmailInvalid, ExactSequenceInvalid, FalseInvalid, FileInvalid, InInvalid, Invalid, LengthInvalid, MatchInvalid, MultipleInvalid, NotEnoughValid, NotInInvalid, PathInvalid, RangeInvalid, TooManyValid, TrueInvalid, TypeInvalid, UrlInvalid
    from voluptuous.schema_builder import Schema, Schemable, message, raises
    if typing.TYPE_CHECKING:
        from _typeshed import SupportsAllComparisons
    Enum: typing.Union[type, None]
    try:
        from enum import Enum
    except ImportError:
        Enum = None
    if sys.version_info >= (3,):
        import urllib.parse as urlparse
        basestring = str
    else:
        import urlparse
    USER_REGEX = re.compile('(?:(^[-!#$%&\'*+/=?^_`{}|~0-9A-Z]+(\\.[-!#$%&\'*+/=?^_`{}|~0-9A-Z]+)*$|^"([\\001-\\010\\013\\014\\016-\\037!#-\\[\\]-\\177]|\\\\[\\001-\\011\\013\\014\\016-\\177])*"$))\\Z', re.IGNORECASE)
    DOMAIN_REGEX = re.compile('(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\\.)+(?:[A-Z]{2,6}\\.?|[A-Z0-9-]{2,}\\.?$)|^\\[(25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)(\\.(25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)){3}\\]$)\\Z', re.IGNORECASE)
    __author__ = 'tusharmakkar08'
    class Coerce(object):
        """Coerce a value to a type.

        If the type constructor throws a ValueError or TypeError, the value
        will be marked as Invalid.

        Default behavior:

            >>> validate = Schema(Coerce(int))
            >>> with raises(MultipleInvalid, 'expected int'):
            ...   validate(None)
            >>> with raises(MultipleInvalid, 'expected int'):
            ...   validate('foo')

        With custom message:

            >>> validate = Schema(Coerce(int, "moo"))
            >>> with raises(MultipleInvalid, 'moo'):
            ...   validate('foo')
        """

        def __init__(self, type: typing.Union[type, typing.Callable], msg: typing.Optional[str]=None) -> None:
            self.type = type
            self.msg = msg
            self.type_name = type.__name__

        def __call__(self, v):
            try:
                return self.type(v)
            except (ValueError, TypeError, InvalidOperation):
                msg = self.msg or 'expected %s' % self.type_name
                if not self.msg and Enum and issubclass(self.type, Enum):
                    msg += ' or one of %s' % str([e.value for e in self.type])[1:-1]
                raise CoerceInvalid(msg)

        def __repr__(self):
            return 'Coerce(%s, msg=%r)' % (self.type_name, self.msg)
    class _WithSubValidators(object):
        """Base class for validators that use sub-validators.

        Special class to use as a parent class for validators using sub-validators.
        This class provides the `__voluptuous_compile__` method so the
        sub-validators are compiled by the parent `Schema`.
        """

        def __init__(self, *validators, msg=None, required=False, discriminant=None, **kwargs) -> None:
            self.validators = validators
            self.msg = msg
            self.required = required
            self.discriminant = discriminant

        def __voluptuous_compile__(self, schema: Schema) -> typing.Callable:
            self._compiled = []
            old_required = schema.required
            self.schema = schema
            for v in self.validators:
                schema.required = self.required
                self._compiled.append(schema._compile(v))
            schema.required = old_required
            return self._run

        def __call__(self, v):
            return self._exec((Schema(val) for val in self.validators), v)

        def __repr__(self):
            return '%s(%s, msg=%r)' % (self.__class__.__name__, ', '.join((repr(v) for v in self.validators)), self.msg)
    class Any(_WithSubValidators):
        """Use the first validated value.

        :param msg: Message to deliver to user if validation fails.
        :param kwargs: All other keyword arguments are passed to the sub-schema constructors.
        :returns: Return value of the first validator that passes.

        >>> validate = Schema(Any('true', 'false',
        ...                       All(Any(int, bool), Coerce(bool))))
        >>> validate('true')
        'true'
        >>> validate(1)
        True
        >>> with raises(MultipleInvalid, "not a valid value"):
        ...   validate('moo')

        msg argument is used

        >>> validate = Schema(Any(1, 2, 3, msg="Expected 1 2 or 3"))
        >>> validate(1)
        1
        >>> with raises(MultipleInvalid, "Expected 1 2 or 3"):
        ...   validate(4)
        """
    Or = Any
    class Union(_WithSubValidators):
        """Use the first validated value among those selected by discriminant.

        :param msg: Message to deliver to user if validation fails.
        :param discriminant(value, validators): Returns the filtered list of validators based on the value.
        :param kwargs: All other keyword arguments are passed to the sub-schema constructors.
        :returns: Return value of the first validator that passes.

        >>> validate = Schema(Union({'type':'a', 'a_val':'1'},{'type':'b', 'b_val':'2'},
        ...                         discriminant=lambda val, alt: filter(
        ...                         lambda v : v['type'] == val['type'] , alt)))
        >>> validate({'type':'a', 'a_val':'1'}) == {'type':'a', 'a_val':'1'}
        True
        >>> with raises(MultipleInvalid, "not a valid value for dictionary value @ data['b_val']"):
        ...   validate({'type':'b', 'b_val':'5'})

        ```discriminant({'type':'b', 'a_val':'5'}, [{'type':'a', 'a_val':'1'},{'type':'b', 'b_val':'2'}])``` is invoked

        Without the discriminant, the exception would be "extra keys not allowed @ data['b_val']"
        """
    Switch = Union
    class All(_WithSubValidators):
        """Value must pass all validators.

        The output of each validator is passed as input to the next.

        :param msg: Message to deliver to user if validation fails.
        :param kwargs: All other keyword arguments are passed to the sub-schema constructors.

        >>> validate = Schema(All('10', Coerce(int)))
        >>> validate('10')
        10
        """
    And = All
    class Match(object):
        """Value must be a string that matches the regular expression.

        >>> validate = Schema(Match(r'^0x[A-F0-9]+$'))
        >>> validate('0x123EF4')
        '0x123EF4'
        >>> with raises(MultipleInvalid, 'does not match regular expression ^0x[A-F0-9]+$'):
        ...   validate('123EF4')

        >>> with raises(MultipleInvalid, 'expected string or buffer'):
        ...   validate(123)

        Pattern may also be a compiled regular expression:

        >>> validate = Schema(Match(re.compile(r'0x[A-F0-9]+', re.I)))
        >>> validate('0x123ef4')
        '0x123ef4'
        """

        def __init__(self, pattern: typing.Union[re.Pattern, str], msg: typing.Optional[str]=None) -> None:
            if isinstance(pattern, basestring):
                pattern = re.compile(pattern)
            self.pattern = pattern
            self.msg = msg

        def __call__(self, v):
            try:
                match = self.pattern.match(v)
            except TypeError:
                raise MatchInvalid('expected string or buffer')
            if not match:
                raise MatchInvalid(self.msg or 'does not match regular expression {}'.format(self.pattern.pattern))
            return v

        def __repr__(self):
            return 'Match(%r, msg=%r)' % (self.pattern.pattern, self.msg)
    class Replace(object):
        """Regex substitution.

        >>> validate = Schema(All(Replace('you', 'I'),
        ...                       Replace('hello', 'goodbye')))
        >>> validate('you say hello')
        'I say goodbye'
        """

        def __init__(self, pattern: typing.Union[re.Pattern, str], substitution: str, msg: typing.Optional[str]=None) -> None:
            if isinstance(pattern, basestring):
                pattern = re.compile(pattern)
            self.pattern = pattern
            self.substitution = substitution
            self.msg = msg

        def __call__(self, v):
            return self.pattern.sub(self.substitution, v)

        def __repr__(self):
            return 'Replace(%r, %r, msg=%r)' % (self.pattern.pattern, self.substitution, self.msg)
    class Range(object):
        """Limit a value to a range.

        Either min or max may be omitted.
        Either min or max can be excluded from the range of accepted values.

        :raises Invalid: If the value is outside the range.

        >>> s = Schema(Range(min=1, max=10, min_included=False))
        >>> s(5)
        5
        >>> s(10)
        10
        >>> with raises(MultipleInvalid, 'value must be at most 10'):
        ...   s(20)
        >>> with raises(MultipleInvalid, 'value must be higher than 1'):
        ...   s(1)
        >>> with raises(MultipleInvalid, 'value must be lower than 10'):
        ...   Schema(Range(max=10, max_included=False))(20)
        """

        def __init__(self, min: SupportsAllComparisons | None=None, max: SupportsAllComparisons | None=None, min_included: bool=True, max_included: bool=True, msg: typing.Optional[str]=None) -> None:
            self.min = min
            self.max = max
            self.min_included = min_included
            self.max_included = max_included
            self.msg = msg

        def __call__(self, v):
            try:
                if self.min_included:
                    if self.min is not None and (not v >= self.min):
                        raise RangeInvalid(self.msg or 'value must be at least %s' % self.min)
                elif self.min is not None and (not v > self.min):
                    raise RangeInvalid(self.msg or 'value must be higher than %s' % self.min)
                if self.max_included:
                    if self.max is not None and (not v <= self.max):
                        raise RangeInvalid(self.msg or 'value must be at most %s' % self.max)
                elif self.max is not None and (not v < self.max):
                    raise RangeInvalid(self.msg or 'value must be lower than %s' % self.max)
                return v
            except TypeError:
                raise RangeInvalid(self.msg or 'invalid value or type (must have a partial ordering)')

        def __repr__(self):
            return 'Range(min=%r, max=%r, min_included=%r, max_included=%r, msg=%r)' % (self.min, self.max, self.min_included, self.max_included, self.msg)
    class Clamp(object):
        """Clamp a value to a range.

        Either min or max may be omitted.

        >>> s = Schema(Clamp(min=0, max=1))
        >>> s(0.5)
        0.5
        >>> s(5)
        1
        >>> s(-1)
        0
        """

        def __init__(self, min: SupportsAllComparisons | None=None, max: SupportsAllComparisons | None=None, msg: typing.Optional[str]=None) -> None:
            self.min = min
            self.max = max
            self.msg = msg

        def __call__(self, v):
            try:
                if self.min is not None and v < self.min:
                    v = self.min
                if self.max is not None and v > self.max:
                    v = self.max
                return v
            except TypeError:
                raise RangeInvalid(self.msg or 'invalid value or type (must have a partial ordering)')

        def __repr__(self):
            return 'Clamp(min=%s, max=%s)' % (self.min, self.max)
    class Length(object):
        """The length of a value must be in a certain range."""

        def __init__(self, min: SupportsAllComparisons | None=None, max: SupportsAllComparisons | None=None, msg: typing.Optional[str]=None) -> None:
            self.min = min
            self.max = max
            self.msg = msg

        def __call__(self, v):
            try:
                if self.min is not None and len(v) < self.min:
                    raise LengthInvalid(self.msg or 'length of value must be at least %s' % self.min)
                if self.max is not None and len(v) > self.max:
                    raise LengthInvalid(self.msg or 'length of value must be at most %s' % self.max)
                return v
            except TypeError:
                raise RangeInvalid(self.msg or 'invalid value or type')

        def __repr__(self):
            return 'Length(min=%s, max=%s)' % (self.min, self.max)
    class Datetime(object):
        """Validate that the value matches the datetime format."""
        DEFAULT_FORMAT = '%Y-%m-%dT%H:%M:%S.%fZ'

        def __init__(self, format: typing.Optional[str]=None, msg: typing.Optional[str]=None) -> None:
            self.format = format or self.DEFAULT_FORMAT
            self.msg = msg

        def __call__(self, v):
            try:
                datetime.datetime.strptime(v, self.format)
            except (TypeError, ValueError):
                raise DatetimeInvalid(self.msg or 'value does not match expected format %s' % self.format)
            return v

        def __repr__(self):
            return 'Datetime(format=%s)' % self.format
    class Date(Datetime):
        """Validate that the value matches the date format."""
        DEFAULT_FORMAT = '%Y-%m-%d'

        def __call__(self, v):
            try:
                datetime.datetime.strptime(v, self.format)
            except (TypeError, ValueError):
                raise DateInvalid(self.msg or 'value does not match expected format %s' % self.format)
            return v

        def __repr__(self):
            return 'Date(format=%s)' % self.format
    class In(object):
        """Validate that a value is in a collection."""

        def __init__(self, container: typing.Container, msg: typing.Optional[str]=None) -> None:
            self.container = container
            self.msg = msg

        def __call__(self, v):
            try:
                check = v not in self.container
            except TypeError:
                check = True
            if check:
                try:
                    raise InInvalid(self.msg or f'value must be one of {sorted(self.container)}')
                except TypeError:
                    raise InInvalid(self.msg or f'value must be one of {sorted(self.container, key=str)}')
            return v

        def __repr__(self):
            return 'In(%s)' % (self.container,)
    class NotIn(object):
        """Validate that a value is not in a collection."""

        def __init__(self, container: typing.Iterable, msg: typing.Optional[str]=None) -> None:
            self.container = container
            self.msg = msg

        def __call__(self, v):
            try:
                check = v in self.container
            except TypeError:
                check = True
            if check:
                try:
                    raise NotInInvalid(self.msg or f'value must not be one of {sorted(self.container)}')
                except TypeError:
                    raise NotInInvalid(self.msg or f'value must not be one of {sorted(self.container, key=str)}')
            return v

        def __repr__(self):
            return 'NotIn(%s)' % (self.container,)
    class Contains(object):
        """Validate that the given schema element is in the sequence being validated.

        >>> s = Contains(1)
        >>> s([3, 2, 1])
        [3, 2, 1]
        >>> with raises(ContainsInvalid, 'value is not allowed'):
        ...   s([3, 2])
        """

        def __init__(self, item, msg: typing.Optional[str]=None) -> None:
            self.item = item
            self.msg = msg

        def __call__(self, v):
            try:
                check = self.item not in v
            except TypeError:
                check = True
            if check:
                raise ContainsInvalid(self.msg or 'value is not allowed')
            return v

        def __repr__(self):
            return 'Contains(%s)' % (self.item,)
    class ExactSequence(object):
        """Matches each element in a sequence against the corresponding element in
        the validators.

        :param msg: Message to deliver to user if validation fails.
        :param kwargs: All other keyword arguments are passed to the sub-schema
            constructors.

        >>> from voluptuous import Schema, ExactSequence
        >>> validate = Schema(ExactSequence([str, int, list, list]))
        >>> validate(['hourly_report', 10, [], []])
        ['hourly_report', 10, [], []]
        >>> validate(('hourly_report', 10, [], []))
        ('hourly_report', 10, [], [])
        """

        def __init__(self, validators: typing.Iterable[Schemable], msg: typing.Optional[str]=None, **kwargs) -> None:
            self.validators = validators
            self.msg = msg
            self._schemas = [Schema(val, **kwargs) for val in validators]

        def __call__(self, v):
            if not isinstance(v, (list, tuple)) or len(v) != len(self._schemas):
                raise ExactSequenceInvalid(self.msg)
            try:
                v = type(v)((schema(x) for x, schema in zip(v, self._schemas)))
            except Invalid as e:
                raise e if self.msg is None else ExactSequenceInvalid(self.msg)
            return v

        def __repr__(self):
            return 'ExactSequence([%s])' % ', '.join((repr(v) for v in self.validators))
    class Unique(object):
        """Ensure an iterable does not contain duplicate items.

        Only iterables convertible to a set are supported (native types and
        objects with correct __eq__).

        JSON does not support set, so they need to be presented as arrays.
        Unique allows ensuring that such array does not contain dupes.

        >>> s = Schema(Unique())
        >>> s([])
        []
        >>> s([1, 2])
        [1, 2]
        >>> with raises(Invalid, 'contains duplicate items: [1]'):
        ...   s([1, 1, 2])
        >>> with raises(Invalid, "contains duplicate items: ['one']"):
        ...   s(['one', 'two', 'one'])
        >>> with raises(Invalid, regex="^contains unhashable elements: "):
        ...   s([set([1, 2]), set([3, 4])])
        >>> s('abc')
        'abc'
        >>> with raises(Invalid, regex="^contains duplicate items: "):
        ...   s('aabbc')
        """

        def __init__(self, msg: typing.Optional[str]=None) -> None:
            self.msg = msg

        def __call__(self, v):
            try:
                set_v = set(v)
            except TypeError as e:
                raise TypeInvalid(self.msg or 'contains unhashable elements: {0}'.format(e))
            if len(set_v) != len(v):
                seen = set()
                dupes = list(set((x for x in v if x in seen or seen.add(x))))
                raise Invalid(self.msg or 'contains duplicate items: {0}'.format(dupes))
            return v

        def __repr__(self):
            return 'Unique()'
    class Equal(object):
        """Ensure that value matches target.

        >>> s = Schema(Equal(1))
        >>> s(1)
        1
        >>> with raises(Invalid):
        ...    s(2)

        Validators are not supported, match must be exact:

        >>> s = Schema(Equal(str))
        >>> with raises(Invalid):
        ...     s('foo')
        """

        def __init__(self, target, msg: typing.Optional[str]=None) -> None:
            self.target = target
            self.msg = msg

        def __call__(self, v):
            if v != self.target:
                raise Invalid(self.msg or 'Values are not equal: value:{} != target:{}'.format(v, self.target))
            return v

        def __repr__(self):
            return 'Equal({})'.format(self.target)
    class Unordered(object):
        """Ensures sequence contains values in unspecified order.

        >>> s = Schema(Unordered([2, 1]))
        >>> s([2, 1])
        [2, 1]
        >>> s([1, 2])
        [1, 2]
        >>> s = Schema(Unordered([str, int]))
        >>> s(['foo', 1])
        ['foo', 1]
        >>> s([1, 'foo'])
        [1, 'foo']
        """

        def __init__(self, validators: typing.Iterable[Schemable], msg: typing.Optional[str]=None, **kwargs) -> None:
            self.validators = validators
            self.msg = msg
            self._schemas = [Schema(val, **kwargs) for val in validators]

        def __call__(self, v):
            if not isinstance(v, (list, tuple)):
                raise Invalid(self.msg or 'Value {} is not sequence!'.format(v))
            if len(v) != len(self._schemas):
                raise Invalid(self.msg or 'List lengths differ, value:{} != target:{}'.format(len(v), len(self._schemas)))
            consumed = set()
            missing = []
            for index, value in enumerate(v):
                found = False
                for i, s in enumerate(self._schemas):
                    if i in consumed:
                        continue
                    try:
                        s(value)
                    except Invalid:
                        pass
                    else:
                        found = True
                        consumed.add(i)
                        break
                if not found:
                    missing.append((index, value))
            if len(missing) == 1:
                el = missing[0]
                raise Invalid(self.msg or 'Element #{} ({}) is not valid against any validator'.format(el[0], el[1]))
            elif missing:
                raise MultipleInvalid([Invalid(self.msg or 'Element #{} ({}) is not valid against any validator'.format(el[0], el[1])) for el in missing])
            return v

        def __repr__(self):
            return 'Unordered([{}])'.format(', '.join((repr(v) for v in self.validators)))
    class Number(object):
        """
        Verify the number of digits that are present in the number(Precision),
        and the decimal places(Scale).

        :raises Invalid: If the value does not match the provided Precision and Scale.

        >>> schema = Schema(Number(precision=6, scale=2))
        >>> schema('1234.01')
        '1234.01'
        >>> schema = Schema(Number(precision=6, scale=2, yield_decimal=True))
        >>> schema('1234.01')
        Decimal('1234.01')
        """

        def __init__(self, precision: typing.Optional[int]=None, scale: typing.Optional[int]=None, msg: typing.Optional[str]=None, yield_decimal: bool=False) -> None:
            self.precision = precision
            self.scale = scale
            self.msg = msg
            self.yield_decimal = yield_decimal

        def __call__(self, v):
            """
            :param v: is a number enclosed with string
            :return: Decimal number
            """
            precision, scale, decimal_num = self._get_precision_scale(v)
            if self.precision is not None and self.scale is not None and (precision != self.precision) and (scale != self.scale):
                raise Invalid(self.msg or 'Precision must be equal to %s, and Scale must be equal to %s' % (self.precision, self.scale))
            else:
                if self.precision is not None and precision != self.precision:
                    raise Invalid(self.msg or 'Precision must be equal to %s' % self.precision)
                if self.scale is not None and scale != self.scale:
                    raise Invalid(self.msg or 'Scale must be equal to %s' % self.scale)
            if self.yield_decimal:
                return decimal_num
            else:
                return v

        def __repr__(self):
            return 'Number(precision=%s, scale=%s, msg=%s)' % (self.precision, self.scale, self.msg)

        def _get_precision_scale(self, number) -> typing.Tuple[int, int, Decimal]:
            """
            :param number:
            :return: tuple(precision, scale, decimal_number)
            """
            pass
    class SomeOf(_WithSubValidators):
        """Value must pass at least some validations, determined by the given parameter.
        Optionally, number of passed validations can be capped.

        The output of each validator is passed as input to the next.

        :param min_valid: Minimum number of valid schemas.
        :param validators: List of schemas or validators to match input against.
        :param max_valid: Maximum number of valid schemas.
        :param msg: Message to deliver to user if validation fails.
        :param kwargs: All other keyword arguments are passed to the sub-schema constructors.

        :raises NotEnoughValid: If the minimum number of validations isn't met.
        :raises TooManyValid: If the maximum number of validations is exceeded.

        >>> validate = Schema(SomeOf(min_valid=2, validators=[Range(1, 5), Any(float, int), 6.6]))
        >>> validate(6.6)
        6.6
        >>> validate(3)
        3
        >>> with raises(MultipleInvalid, 'value must be at most 5, not a valid value'):
        ...     validate(6.2)
        """

        def __init__(self, validators: typing.List[Schemable], min_valid: typing.Optional[int]=None, max_valid: typing.Optional[int]=None, **kwargs) -> None:
            assert min_valid is not None or max_valid is not None, 'when using "%s" you should specify at least one of min_valid and max_valid' % (type(self).__name__,)
            self.min_valid = min_valid or 0
            self.max_valid = max_valid or len(validators)
            super(SomeOf, self).__init__(*validators, **kwargs)

        def __repr__(self):
            return 'SomeOf(min_valid=%s, validators=[%s], max_valid=%s, msg=%r)' % (self.min_valid, ', '.join((repr(v) for v in self.validators)), self.max_valid, self.msg)


flow voluptuous_lib:
  steps:
    - humanize_group
    - schema_builder_group
    - util_group
    - validators_group


flow humanize_group:
  steps:
    - humanize_error


flow schema_builder_group:
  steps:
    - Extra
    - Schema__infer
    - Schema___compile_mapping
    - Schema___compile_object
    - Schema___compile_dict
    - Schema___compile_sequence
    - Schema___compile_tuple
    - Schema___compile_list
    - Schema___compile_set
    - Schema__extend
    - _compile_scalar
    - _compile_itemsort
    - _iterate_mapping_candidates
    - _iterate_object
    - message
    - _args_to_dict
    - _merge_args_with_kwargs
    - validate


flow util_group:
  steps:
    - Lower
    - Upper
    - Capitalize
    - Title
    - Strip


flow validators_group:
  steps:
    - truth
    - IsTrue
    - IsFalse
    - Boolean
    - Email
    - FqdnUrl
    - Url
    - IsFile
    - IsDir
    - PathExists
    - Maybe
    - Number___get_precision_scale


code humanize_error:
  body: |
    def humanize_error(data, validation_error: Invalid, max_sub_error_length: int=MAX_VALIDATION_ERROR_ITEM_LENGTH):
        """Provide a more helpful + complete validation error message than that provided automatically
        Invalid and MultipleInvalid do not include the offending value in error messages,
        and MultipleInvalid.__str__ only provides the first error.
        
        """
        pass


code Extra:
  body: |
    def Extra(_):
        """Allow keys in the data that are not present in the schema."""
        pass


code Schema__infer:
  body: |
    def infer(cls, data, **kwargs):
        """Create a Schema from concrete data (e.g. an API response).
    
            For example, this will take a dict like:
    
            {
                'foo': 1,
                'bar': {
                    'a': True,
                    'b': False
                },
                'baz': ['purple', 'monkey', 'dishwasher']
            }
    
            And return a Schema:
    
            {
                'foo': int,
                'bar': {
                    'a': bool,
                    'b': bool
                },
                'baz': [str]
            }
    
            Note: only very basic inference is supported.
            
        """
        pass


code Schema___compile_mapping:
  body: |
    def _compile_mapping(self, schema, invalid_msg=None):
        """Create validator for given mapping."""
        pass


code Schema___compile_object:
  body: |
    def _compile_object(self, schema):
        """Validate an object.
    
            Has the same behavior as dictionary validator but work with object
            attributes.
    
            For example:
    
                >>> class Structure(object):
                ...     def __init__(self, one=None, three=None):
                ...         self.one = one
                ...         self.three = three
                ...
                >>> validate = Schema(Object({'one': 'two', 'three': 'four'}, cls=Structure))
                >>> with raises(er.MultipleInvalid, "not a valid value for object value @ data['one']"):
                ...   validate(Structure(one='three'))
    
            
        """
        pass


code Schema___compile_dict:
  body: |
    def _compile_dict(self, schema):
        """Validate a dictionary.
    
            A dictionary schema can contain a set of values, or at most one
            validator function/type.
    
            A dictionary schema will only validate a dictionary:
    
                >>> validate = Schema({})
                >>> with raises(er.MultipleInvalid, 'expected a dictionary'):
                ...   validate([])
    
            An invalid dictionary value:
    
                >>> validate = Schema({'one': 'two', 'three': 'four'})
                >>> with raises(er.MultipleInvalid, "not a valid value for dictionary value @ data['one']"):
                ...   validate({'one': 'three'})
    
            An invalid key:
    
                >>> with raises(er.MultipleInvalid, "extra keys not allowed @ data['two']"):
                ...   validate({'two': 'three'})
    
    
            Validation function, in this case the "int" type:
    
                >>> validate = Schema({'one': 'two', 'three': 'four', int: str})
    
            Valid integer input:
    
                >>> validate({10: 'twenty'})
                {10: 'twenty'}
    
            By default, a "type" in the schema (in this case "int") will be used
            purely to validate that the corresponding value is of that type. It
            will not Coerce the value:
    
                >>> with raises(er.MultipleInvalid, "extra keys not allowed @ data['10']"):
                ...   validate({'10': 'twenty'})
    
            Wrap them in the Coerce() function to achieve this:
                >>> from voluptuous import Coerce
                >>> validate = Schema({'one': 'two', 'three': 'four',
                ...                    Coerce(int): str})
                >>> validate({'10': 'twenty'})
                {10: 'twenty'}
    
            Custom message for required key
    
                >>> validate = Schema({Required('one', 'required'): 'two'})
                >>> with raises(er.MultipleInvalid, "required @ data['one']"):
                ...   validate({})
    
            (This is to avoid unexpected surprises.)
    
            Multiple errors for nested field in a dict:
    
            >>> validate = Schema({
            ...     'adict': {
            ...         'strfield': str,
            ...         'intfield': int
            ...     }
            ... })
            >>> try:
            ...     validate({
            ...         'adict': {
            ...             'strfield': 123,
            ...             'intfield': 'one'
            ...         }
            ...     })
            ... except er.MultipleInvalid as e:
            ...     print(sorted(str(i) for i in e.errors)) # doctest: +NORMALIZE_WHITESPACE
            ["expected int for dictionary value @ data['adict']['intfield']",
             "expected str for dictionary value @ data['adict']['strfield']"]
    
            
        """
        pass


code Schema___compile_sequence:
  body: |
    def _compile_sequence(self, schema, seq_type):
        """Validate a sequence type.
    
            This is a sequence of valid values or validators tried in order.
    
            >>> validator = Schema(['one', 'two', int])
            >>> validator(['one'])
            ['one']
            >>> with raises(er.MultipleInvalid, 'expected int @ data[0]'):
            ...   validator([3.5])
            >>> validator([1])
            [1]
            
        """
        pass


code Schema___compile_tuple:
  body: |
    def _compile_tuple(self, schema):
        """Validate a tuple.
    
            A tuple is a sequence of valid values or validators tried in order.
    
            >>> validator = Schema(('one', 'two', int))
            >>> validator(('one',))
            ('one',)
            >>> with raises(er.MultipleInvalid, 'expected int @ data[0]'):
            ...   validator((3.5,))
            >>> validator((1,))
            (1,)
            
        """
        pass


code Schema___compile_list:
  body: |
    def _compile_list(self, schema):
        """Validate a list.
    
            A list is a sequence of valid values or validators tried in order.
    
            >>> validator = Schema(['one', 'two', int])
            >>> validator(['one'])
            ['one']
            >>> with raises(er.MultipleInvalid, 'expected int @ data[0]'):
            ...   validator([3.5])
            >>> validator([1])
            [1]
            
        """
        pass


code Schema___compile_set:
  body: |
    def _compile_set(self, schema):
        """Validate a set.
    
            A set is an unordered collection of unique elements.
    
            >>> validator = Schema({int})
            >>> validator(set([42])) == set([42])
            True
            >>> with raises(er.Invalid, 'expected a set'):
            ...   validator(42)
            >>> with raises(er.MultipleInvalid, 'invalid value in set'):
            ...   validator(set(['a']))
            
        """
        pass


code Schema__extend:
  body: |
    def extend(self, schema: Schemable, required: typing.Optional[bool]=None, extra: typing.Optional[int]=None):
        """Create a new `Schema` by merging this and the provided `schema`.
    
            Neither this `Schema` nor the provided `schema` are modified. The
            resulting `Schema` inherits the `required` and `extra` parameters of
            this, unless overridden.
    
            Both schemas must be dictionary-based.
    
            :param schema: dictionary to extend this `Schema` with
            :param required: if set, overrides `required` of this `Schema`
            :param extra: if set, overrides `extra` of this `Schema`
            
        """
        pass


code _compile_scalar:
  body: |
    def _compile_scalar(schema):
        """A scalar value.
    
        The schema can either be a value or a type.
    
        >>> _compile_scalar(int)([], 1)
        1
        >>> with raises(er.Invalid, 'expected float'):
        ...   _compile_scalar(float)([], '1')
    
        Callables have
        >>> _compile_scalar(lambda v: float(v))([], '1')
        1.0
    
        As a convenience, ValueError's are trapped:
    
        >>> with raises(er.Invalid, 'not a valid value'):
        ...   _compile_scalar(lambda v: float(v))([], 'a')
        
        """
        pass


code _compile_itemsort:
  body: |
    def _compile_itemsort():
        """return sort function of mappings"""
        pass


code _iterate_mapping_candidates:
  body: |
    def _iterate_mapping_candidates(schema):
        """Iterate over schema in a meaningful order."""
        pass


code _iterate_object:
  body: |
    def _iterate_object(obj):
        """Return iterator over object attributes. Respect objects with
        defined __slots__.
    
        
        """
        pass


code message:
  body: |
    def message(default: typing.Optional[str]=None, cls: typing.Optional[typing.Type[Error]]=None):
        """Convenience decorator to allow functions to provide a message.
    
        Set a default message:
    
            >>> @message('not an integer')
            ... def isint(v):
            ...   return int(v)
    
            >>> validate = Schema(isint())
            >>> with raises(er.MultipleInvalid, 'not an integer'):
            ...   validate('a')
    
        The message can be overridden on a per validator basis:
    
            >>> validate = Schema(isint('bad'))
            >>> with raises(er.MultipleInvalid, 'bad'):
            ...   validate('a')
    
        The class thrown too:
    
            >>> class IntegerInvalid(er.Invalid): pass
            >>> validate = Schema(isint('bad', clsoverride=IntegerInvalid))
            >>> try:
            ...  validate('a')
            ... except er.MultipleInvalid as e:
            ...   assert isinstance(e.errors[0], IntegerInvalid)
        
        """
        pass


code _args_to_dict:
  body: |
    def _args_to_dict(func, args):
        """Returns argument names as values as key-value pairs."""
        pass


code _merge_args_with_kwargs:
  body: |
    def _merge_args_with_kwargs(args_dict, kwargs_dict):
        """Merge args with kwargs."""
        pass


code validate:
  body: |
    def validate(*a, **kw):
        """Decorator for validating arguments of a function against a given schema.
    
        Set restrictions for arguments:
    
            >>> @validate(arg1=int, arg2=int)
            ... def foo(arg1, arg2):
            ...   return arg1 * arg2
    
        Set restriction for returned value:
    
            >>> @validate(arg=int, __return__=int)
            ... def bar(arg1):
            ...   return arg1 * 2
    
        
        """
        pass


code Lower:
  body: |
    def Lower(v: str):
        """Transform a string to lower case.
    
        >>> s = Schema(Lower)
        >>> s('HI')
        'hi'
        
        """
        pass


code Upper:
  body: |
    def Upper(v: str):
        """Transform a string to upper case.
    
        >>> s = Schema(Upper)
        >>> s('hi')
        'HI'
        
        """
        pass


code Capitalize:
  body: |
    def Capitalize(v: str):
        """Capitalise a string.
    
        >>> s = Schema(Capitalize)
        >>> s('hello world')
        'Hello world'
        
        """
        pass


code Title:
  body: |
    def Title(v: str):
        """Title case a string.
    
        >>> s = Schema(Title)
        >>> s('hello world')
        'Hello World'
        
        """
        pass


code Strip:
  body: |
    def Strip(v: str):
        """Strip whitespace from a string.
    
        >>> s = Schema(Strip)
        >>> s('  hello world  ')
        'hello world'
        
        """
        pass


code truth:
  body: |
    def truth(f: typing.Callable):
        """Convenience decorator to convert truth functions into validators.
    
        >>> @truth
        ... def isdir(v):
        ...   return os.path.isdir(v)
        >>> validate = Schema(isdir)
        >>> validate('/')
        '/'
        >>> with raises(MultipleInvalid, 'not a valid value'):
        ...   validate('/notavaliddir')
        
        """
        pass


code IsTrue:
  body: |
    def IsTrue(v):
        """Assert that a value is true, in the Python sense.
    
        >>> validate = Schema(IsTrue())
    
        "In the Python sense" means that implicitly false values, such as empty
        lists, dictionaries, etc. are treated as "false":
    
        >>> with raises(MultipleInvalid, "value was not true"):
        ...   validate([])
        >>> validate([1])
        [1]
        >>> with raises(MultipleInvalid, "value was not true"):
        ...   validate(False)
    
        ...and so on.
    
        >>> try:
        ...  validate([])
        ... except MultipleInvalid as e:
        ...   assert isinstance(e.errors[0], TrueInvalid)
        
        """
        pass


code IsFalse:
  body: |
    def IsFalse(v):
        """Assert that a value is false, in the Python sense.
    
        (see :func:`IsTrue` for more detail)
    
        >>> validate = Schema(IsFalse())
        >>> validate([])
        []
        >>> with raises(MultipleInvalid, "value was not false"):
        ...   validate(True)
    
        >>> try:
        ...  validate(True)
        ... except MultipleInvalid as e:
        ...   assert isinstance(e.errors[0], FalseInvalid)
        
        """
        pass


code Boolean:
  body: |
    def Boolean(v):
        """Convert human-readable boolean values to a bool.
    
        Accepted values are 1, true, yes, on, enable, and their negatives.
        Non-string values are cast to bool.
    
        >>> validate = Schema(Boolean())
        >>> validate(True)
        True
        >>> validate("1")
        True
        >>> validate("0")
        False
        >>> with raises(MultipleInvalid, "expected boolean"):
        ...   validate('moo')
        >>> try:
        ...  validate('moo')
        ... except MultipleInvalid as e:
        ...   assert isinstance(e.errors[0], BooleanInvalid)
        
        """
        pass


code Email:
  body: |
    def Email(v):
        """Verify that the value is an email address or not.
    
        >>> s = Schema(Email())
        >>> with raises(MultipleInvalid, 'expected an email address'):
        ...   s("a.com")
        >>> with raises(MultipleInvalid, 'expected an email address'):
        ...   s("a@.com")
        >>> with raises(MultipleInvalid, 'expected an email address'):
        ...   s("a@.com")
        >>> s('t@x.com')
        't@x.com'
        
        """
        pass


code FqdnUrl:
  body: |
    def FqdnUrl(v):
        """Verify that the value is a fully qualified domain name URL.
    
        >>> s = Schema(FqdnUrl())
        >>> with raises(MultipleInvalid, 'expected a fully qualified domain name URL'):
        ...   s("http://localhost/")
        >>> s('http://w3.org')
        'http://w3.org'
        
        """
        pass


code Url:
  body: |
    def Url(v):
        """Verify that the value is a URL.
    
        >>> s = Schema(Url())
        >>> with raises(MultipleInvalid, 'expected a URL'):
        ...   s(1)
        >>> s('http://w3.org')
        'http://w3.org'
        
        """
        pass


code IsFile:
  body: |
    def IsFile(v):
        """Verify the file exists.
    
        >>> os.path.basename(IsFile()(__file__)).startswith('validators.py')
        True
        >>> with raises(FileInvalid, 'Not a file'):
        ...   IsFile()("random_filename_goes_here.py")
        >>> with raises(FileInvalid, 'Not a file'):
        ...   IsFile()(None)
        
        """
        pass


code IsDir:
  body: |
    def IsDir(v):
        """Verify the directory exists.
    
        >>> IsDir()('/')
        '/'
        >>> with raises(DirInvalid, 'Not a directory'):
        ...   IsDir()(None)
        
        """
        pass


code PathExists:
  body: |
    def PathExists(v):
        """Verify the path exists, regardless of its type.
    
        >>> os.path.basename(PathExists()(__file__)).startswith('validators.py')
        True
        >>> with raises(Invalid, 'path does not exist'):
        ...   PathExists()("random_filename_goes_here.py")
        >>> with raises(PathInvalid, 'Not a Path'):
        ...   PathExists()(None)
        
        """
        pass


code Maybe:
  body: |
    def Maybe(validator: Schemable, msg: typing.Optional[str]=None):
        """Validate that the object matches given validator or is None.
    
        :raises Invalid: If the value does not match the given validator and is not
            None.
    
        >>> s = Schema(Maybe(int))
        >>> s(10)
        10
        >>> with raises(Invalid):
        ...  s("string")
    
        
        """
        pass


code Number___get_precision_scale:
  body: |
    def _get_precision_scale(self, number):
        """
            :param number:
            :return: tuple(precision, scale, decimal_number)
            
        """
        pass
