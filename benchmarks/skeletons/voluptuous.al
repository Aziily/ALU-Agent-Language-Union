flow voluptuous_lib:
  steps:
    - schema_builder_group
    - schema_class_methods
    - validators_group
    - util_group
    - humanize_group


flow schema_builder_group:
  steps:
    - Extra
    - _compile_scalar
    - _compile_itemsort
    - _iterate_mapping_candidates
    - _iterate_object
    - message
    - _args_to_dict
    - _merge_args_with_kwargs
    - validate


flow schema_class_methods:
  steps:
    - Schema__infer
    - Schema___compile_mapping
    - Schema___compile_object
    - Schema___compile_dict
    - Schema___compile_sequence
    - Schema___compile_tuple
    - Schema___compile_list
    - Schema___compile_set
    - Schema__extend
    - Number___get_precision_scale


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


flow util_group:
  steps:
    - Lower
    - Upper
    - Capitalize
    - Title
    - Strip


flow humanize_group:
  steps:
    - humanize_error


code Extra:
  body: |
    def Extra(_):
        """Allow keys in the data that are not present in the schema."""
        pass


code _compile_scalar:
  body: |
    def _compile_scalar(schema):
        """A scalar value.

        The schema can either be a value or a type. In either case, the value is
        checked to ensure that it matches.
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

        Set a default message, and a custom Error class.
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
        """Decorator for validating arguments of a function against a given schema."""
        pass


code truth:
  body: |
    def truth(f: typing.Callable):
        """Convenience decorator to convert truth functions into validators."""
        pass


code IsTrue:
  body: |
    def IsTrue(v):
        """Assert that a value is true, in the Python sense."""
        pass


code IsFalse:
  body: |
    def IsFalse(v):
        """Assert that a value is false, in the Python sense."""
        pass


code Boolean:
  body: |
    def Boolean(v):
        """Convert human-readable boolean values to a bool.

        Accepted values for true: y, yes, true, t, 1, on, enabled.
        Accepted values for false: n, no, false, f, 0, off, disabled.
        Anything else raises Invalid.
        """
        pass


code Email:
  body: |
    def Email(v):
        """Verify that the value is an email address or not."""
        pass


code FqdnUrl:
  body: |
    def FqdnUrl(v):
        """Verify that the value is a fully qualified domain name URL."""
        pass


code Url:
  body: |
    def Url(v):
        """Verify that the value is a URL."""
        pass


code IsFile:
  body: |
    def IsFile(v):
        """Verify the file exists."""
        pass


code IsDir:
  body: |
    def IsDir(v):
        """Verify the directory exists."""
        pass


code PathExists:
  body: |
    def PathExists(v):
        """Verify the path exists, regardless of its type."""
        pass


code Maybe:
  body: |
    def Maybe(validator: Schemable, msg: typing.Optional[str]=None):
        """Validate that the object matches given validator or is None.

        :raises Invalid: if the value does not match the given validator and is not None.
        """
        pass


code Lower:
  body: |
    def Lower(v: str):
        """Transform a string to lower case."""
        pass


code Upper:
  body: |
    def Upper(v: str):
        """Transform a string to upper case."""
        pass


code Capitalize:
  body: |
    def Capitalize(v: str):
        """Capitalise a string."""
        pass


code Title:
  body: |
    def Title(v: str):
        """Title case a string."""
        pass


code Strip:
  body: |
    def Strip(v: str):
        """Strip whitespace from a string."""
        pass


code humanize_error:
  body: |
    def humanize_error(data, validation_error: Invalid, max_sub_error_length: int=MAX_VALIDATION_ERROR_ITEM_LENGTH):
        """Provide a more helpful + complete validation error message than that provided automatically.

        Invalid and MultipleInvalid do not include the offending value in error
        messages, and MultipleInvalid.__str__ only provides the first error.
        """
        pass


code Schema__infer:
  body: |
    @classmethod
    def infer(cls, data, **kwargs):
        """Create a Schema from concrete data (e.g. an API response).

        For each `key, value` pair of the data, infer the value type using
        the value type as type spec for the Schema.
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

        Has Mapping logic, but object attributes are matched instead of dict keys.
        """
        pass


code Schema___compile_dict:
  body: |
    def _compile_dict(self, schema):
        """Validate a dictionary.

        A dictionary schema can contain a set of values, or at most one
        validator function/type.
        """
        pass


code Schema___compile_sequence:
  body: |
    def _compile_sequence(self, schema, seq_type):
        """Validate a sequence type.

        This is a sequence of valid values or validators tried in order.
        """
        pass


code Schema___compile_tuple:
  body: |
    def _compile_tuple(self, schema):
        """Validate a tuple.

        A tuple is a sequence of valid values or validators tried in order.
        """
        pass


code Schema___compile_list:
  body: |
    def _compile_list(self, schema):
        """Validate a list.

        A list is a sequence of valid values or validators tried in order.
        """
        pass


code Schema___compile_set:
  body: |
    def _compile_set(self, schema):
        """Validate a set."""
        pass


code Schema__extend:
  body: |
    def extend(self, schema: Schemable, required: typing.Optional[bool]=None, extra: typing.Optional[int]=None):
        """Create a new `Schema` by merging this and the provided `schema`.

        Some optional parameters can be inherited or overridden:
          ``required``: required setting (None = inherit)
          ``extra``: extra setting (None = inherit)
        """
        pass


code Number___get_precision_scale:
  body: |
    def _get_precision_scale(self, number):
        pass
