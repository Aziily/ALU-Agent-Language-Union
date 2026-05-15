preamble __init__:
  source: jinja2/__init__.py
  imports: |
    from .bccache import BytecodeCache as BytecodeCache
    from .bccache import FileSystemBytecodeCache as FileSystemBytecodeCache
    from .bccache import MemcachedBytecodeCache as MemcachedBytecodeCache
    from .environment import Environment as Environment
    from .environment import Template as Template
    from .exceptions import TemplateAssertionError as TemplateAssertionError
    from .exceptions import TemplateError as TemplateError
    from .exceptions import TemplateNotFound as TemplateNotFound
    from .exceptions import TemplateRuntimeError as TemplateRuntimeError
    from .exceptions import TemplatesNotFound as TemplatesNotFound
    from .exceptions import TemplateSyntaxError as TemplateSyntaxError
    from .exceptions import UndefinedError as UndefinedError
    from .loaders import BaseLoader as BaseLoader
    from .loaders import ChoiceLoader as ChoiceLoader
    from .loaders import DictLoader as DictLoader
    from .loaders import FileSystemLoader as FileSystemLoader
    from .loaders import FunctionLoader as FunctionLoader
    from .loaders import ModuleLoader as ModuleLoader
    from .loaders import PackageLoader as PackageLoader
    from .loaders import PrefixLoader as PrefixLoader
    from .runtime import ChainableUndefined as ChainableUndefined
    from .runtime import DebugUndefined as DebugUndefined
    from .runtime import make_logging_undefined as make_logging_undefined
    from .runtime import StrictUndefined as StrictUndefined
    from .runtime import Undefined as Undefined
    from .utils import clear_caches as clear_caches
    from .utils import is_undefined as is_undefined
    from .utils import pass_context as pass_context
    from .utils import pass_environment as pass_environment
    from .utils import pass_eval_context as pass_eval_context
    from .utils import select_autoescape as select_autoescape
  constants: |
    __version__ = '3.1.4'
  body: |
    'Jinja is a template engine written in pure Python. It provides a\nnon-XML syntax that supports inline expressions and an optional\nsandboxed environment.\n'


preamble _identifier:
  source: jinja2/_identifier.py
  imports: |
    import re
  constants: |
    pattern = re.compile('[\\w·̀-ͯ·҃-֑҇-ׇֽֿׁׂׅׄؐ-ًؚ-ٰٟۖ-ۜ۟-۪ۤۧۨ-ܑۭܰ-݊ަ-ް߫-߽߳ࠖ-࠙ࠛ-ࠣࠥ-ࠧࠩ-࡙࠭-࡛࣓-ࣣ࣡-ःऺ-़ा-ॏ॑-ॗॢॣঁ-ঃ়া-ৄেৈো-্ৗৢৣ৾ਁ-ਃ਼ਾ-ੂੇੈੋ-੍ੑੰੱੵઁ-ઃ઼ા-ૅે-ૉો-્ૢૣૺ-૿ଁ-ଃ଼ା-ୄେୈୋ-୍ୖୗୢୣஂா-ூெ-ைொ-்ௗఀ-ఄా-ౄె-ైొ-్ౕౖౢౣಁ-ಃ಼ಾ-ೄೆ-ೈೊ-್ೕೖೢೣഀ-ഃ഻഼ാ-ൄെ-ൈൊ-്ൗൢൣංඃ්ා-ුූෘ-ෟෲෳัิ-ฺ็-๎ັິ-ູົຼ່-ໍ༹༘༙༵༷༾༿ཱ-྄྆྇ྍ-ྗྙ-ྼ࿆ါ-ှၖ-ၙၞ-ၠၢ-ၤၧ-ၭၱ-ၴႂ-ႍႏႚ-ႝ፝-፟ᜒ-᜔ᜲ-᜴ᝒᝓᝲᝳ឴-៓៝᠋-᠍ᢅᢆᢩᤠ-ᤫᤰ-᤻ᨗ-ᨛᩕ-ᩞ᩠-᩿᩼᪰-᪽ᬀ-ᬄ᬴-᭄᭫-᭳ᮀ-ᮂᮡ-ᮭ᯦-᯳ᰤ-᰷᳐-᳔᳒-᳨᳭ᳲ-᳴᳷-᳹᷀-᷹᷻-᷿‿⁀⁔⃐-⃥⃜⃡-⃰℘℮⳯-⵿⳱ⷠ-〪ⷿ-゙゚〯꙯ꙴ-꙽ꚞꚟ꛰꛱ꠂ꠆ꠋꠣ-ꠧꢀꢁꢴ-ꣅ꣠-꣱ꣿꤦ-꤭ꥇ-꥓ꦀ-ꦃ꦳-꧀ꧥꨩ-ꨶꩃꩌꩍꩻ-ꩽꪰꪲ-ꪴꪷꪸꪾ꪿꫁ꫫ-ꫯꫵ꫶ꯣ-ꯪ꯬꯭ﬞ︀-️︠-︯︳︴﹍-﹏＿𐇽𐋠𐍶-𐍺𐨁-𐨃𐨅𐨆𐨌-𐨏𐨸-𐨿𐨺𐫦𐫥𐴤-𐽆𐴧-𐽐𑀀-𑀂𑀸-𑁆𑁿-𑂂𑂰-𑂺𑄀-𑄂𑄧-𑄴𑅅𑅆𑅳𑆀-𑆂𑆳-𑇀𑇉-𑇌𑈬-𑈷𑈾𑋟-𑋪𑌀-𑌃𑌻𑌼𑌾-𑍄𑍇𑍈𑍋-𑍍𑍗𑍢𑍣𑍦-𑍬𑍰-𑍴𑐵-𑑆𑑞𑒰-𑓃𑖯-𑖵𑖸-𑗀𑗜𑗝𑘰-𑙀𑚫-𑚷𑜝-𑜫𑠬-𑠺𑨁-𑨊𑨳-𑨹𑨻-𑨾𑩇𑩑-𑩛𑪊-𑪙𑰯-𑰶𑰸-𑰿𑲒-𑲧𑲩-𑲶𑴱-𑴶𑴺𑴼𑴽𑴿-𑵅𑵇𑶊-𑶎𑶐𑶑𑶓-𑶗𑻳-𑻶𖫰-𖫴𖬰-𖬶𖽑-𖽾𖾏-𖾒𛲝𛲞𝅥-𝅩𝅭-𝅲𝅻-𝆂𝆅-𝆋𝆪-𝆭𝉂-𝉄𝨀-𝨶𝨻-𝩬𝩵𝪄𝪛-𝪟𝪡-𝪯𞀀-𞀆𞀈-𞀘𞀛-𞀡𞀣𞀤𞀦-𞣐𞀪-𞣖𞥄-𞥊󠄀-󠇯]+')


preamble async_utils:
  source: jinja2/async_utils.py
  imports: |
    import inspect
    import typing as t
    from functools import WRAPPER_ASSIGNMENTS
    from functools import wraps
    from .utils import _PassArg
    from .utils import pass_eval_context
  constants: |
    V = t.TypeVar('V')
    _common_primitives = {int, float, bool, str, list, dict, tuple, type(None)}


preamble bccache:
  source: jinja2/bccache.py
  imports: |
    import errno
    import fnmatch
    import marshal
    import os
    import pickle
    import stat
    import sys
    import tempfile
    import typing as t
    from hashlib import sha1
    from io import BytesIO
    from types import CodeType
  constants: |
    bc_version = 5
    bc_magic = b'j2' + pickle.dumps(bc_version, 2) + pickle.dumps(sys.version_info[0] << 24 | sys.version_info[1], 2)
  body: |
    'The optional bytecode cache system. This is useful if you have very\ncomplex template situations and the compilation of all those templates\nslows down your application too much.\n\nSituations where this is useful are often forking web applications that\nare initialized on the first request.\n'
    if t.TYPE_CHECKING:
        import typing_extensions as te
        from .environment import Environment

        class _MemcachedClient(te.Protocol):
            pass
    class Bucket:
        """Buckets are used to store the bytecode for one template.  It's created
        and initialized by the bytecode cache and passed to the loading functions.

        The buckets get an internal checksum from the cache assigned and use this
        to automatically reject outdated cache material.  Individual bytecode
        cache subclasses don't have to care about cache invalidation.
        """

        def __init__(self, environment: 'Environment', key: str, checksum: str) -> None:
            self.environment = environment
            self.key = key
            self.checksum = checksum
            self.reset()

        def reset(self) -> None:
            """Resets the bucket (unloads the bytecode)."""
            pass

        def load_bytecode(self, f: t.BinaryIO) -> None:
            """Loads bytecode from a file or file like object."""
            pass

        def write_bytecode(self, f: t.IO[bytes]) -> None:
            """Dump the bytecode into the file or file like object passed."""
            pass

        def bytecode_from_string(self, string: bytes) -> None:
            """Load bytecode from bytes."""
            pass

        def bytecode_to_string(self) -> bytes:
            """Return the bytecode as bytes."""
            pass
    class BytecodeCache:
        """To implement your own bytecode cache you have to subclass this class
        and override :meth:`load_bytecode` and :meth:`dump_bytecode`.  Both of
        these methods are passed a :class:`~jinja2.bccache.Bucket`.

        A very basic bytecode cache that saves the bytecode on the file system::

            from os import path

            class MyCache(BytecodeCache):

                def __init__(self, directory):
                    self.directory = directory

                def load_bytecode(self, bucket):
                    filename = path.join(self.directory, bucket.key)
                    if path.exists(filename):
                        with open(filename, 'rb') as f:
                            bucket.load_bytecode(f)

                def dump_bytecode(self, bucket):
                    filename = path.join(self.directory, bucket.key)
                    with open(filename, 'wb') as f:
                        bucket.write_bytecode(f)

        A more advanced version of a filesystem based bytecode cache is part of
        Jinja.
        """

        def load_bytecode(self, bucket: Bucket) -> None:
            """Subclasses have to override this method to load bytecode into a
            bucket.  If they are not able to find code in the cache for the
            bucket, it must not do anything.
            """
            pass

        def dump_bytecode(self, bucket: Bucket) -> None:
            """Subclasses have to override this method to write the bytecode
            from a bucket back to the cache.  If it unable to do so it must not
            fail silently but raise an exception.
            """
            pass

        def clear(self) -> None:
            """Clears the cache.  This method is not used by Jinja but should be
            implemented to allow applications to clear the bytecode cache used
            by a particular environment.
            """
            pass

        def get_cache_key(self, name: str, filename: t.Optional[t.Union[str]]=None) -> str:
            """Returns the unique hash key for this template name."""
            pass

        def get_source_checksum(self, source: str) -> str:
            """Returns a checksum for the source."""
            pass

        def get_bucket(self, environment: 'Environment', name: str, filename: t.Optional[str], source: str) -> Bucket:
            """Return a cache bucket for the given template.  All arguments are
            mandatory but filename may be `None`.
            """
            pass

        def set_bucket(self, bucket: Bucket) -> None:
            """Put the bucket into the cache."""
            pass
    class FileSystemBytecodeCache(BytecodeCache):
        """A bytecode cache that stores bytecode on the filesystem.  It accepts
        two arguments: The directory where the cache items are stored and a
        pattern string that is used to build the filename.

        If no directory is specified a default cache directory is selected.  On
        Windows the user's temp directory is used, on UNIX systems a directory
        is created for the user in the system temp directory.

        The pattern can be used to have multiple separate caches operate on the
        same directory.  The default pattern is ``'__jinja2_%s.cache'``.  ``%s``
        is replaced with the cache key.

        >>> bcc = FileSystemBytecodeCache('/tmp/jinja_cache', '%s.cache')

        This bytecode cache supports clearing of the cache using the clear method.
        """

        def __init__(self, directory: t.Optional[str]=None, pattern: str='__jinja2_%s.cache') -> None:
            if directory is None:
                directory = self._get_default_cache_dir()
            self.directory = directory
            self.pattern = pattern
    class MemcachedBytecodeCache(BytecodeCache):
        """This class implements a bytecode cache that uses a memcache cache for
        storing the information.  It does not enforce a specific memcache library
        (tummy's memcache or cmemcache) but will accept any class that provides
        the minimal interface required.

        Libraries compatible with this class:

        -   `cachelib <https://github.com/pallets/cachelib>`_
        -   `python-memcached <https://pypi.org/project/python-memcached/>`_

        (Unfortunately the django cache interface is not compatible because it
        does not support storing binary data, only text. You can however pass
        the underlying cache client to the bytecode cache which is available
        as `django.core.cache.cache._client`.)

        The minimal interface for the client passed to the constructor is this:

        .. class:: MinimalClientInterface

            .. method:: set(key, value[, timeout])

                Stores the bytecode in the cache.  `value` is a string and
                `timeout` the timeout of the key.  If timeout is not provided
                a default timeout or no timeout should be assumed, if it's
                provided it's an integer with the number of seconds the cache
                item should exist.

            .. method:: get(key)

                Returns the value for the cache key.  If the item does not
                exist in the cache the return value must be `None`.

        The other arguments to the constructor are the prefix for all keys that
        is added before the actual cache key and the timeout for the bytecode in
        the cache system.  We recommend a high (or no) timeout.

        This bytecode cache does not support clearing of used items in the cache.
        The clear method is a no-operation function.

        .. versionadded:: 2.7
           Added support for ignoring memcache errors through the
           `ignore_memcache_errors` parameter.
        """

        def __init__(self, client: '_MemcachedClient', prefix: str='jinja2/bytecode/', timeout: t.Optional[int]=None, ignore_memcache_errors: bool=True):
            self.client = client
            self.prefix = prefix
            self.timeout = timeout
            self.ignore_memcache_errors = ignore_memcache_errors


preamble compiler:
  source: jinja2/compiler.py
  imports: |
    import typing as t
    from contextlib import contextmanager
    from functools import update_wrapper
    from io import StringIO
    from itertools import chain
    from keyword import iskeyword as is_python_keyword
    from markupsafe import escape
    from markupsafe import Markup
    from . import nodes
    from .exceptions import TemplateAssertionError
    from .idtracking import Symbols
    from .idtracking import VAR_LOAD_ALIAS
    from .idtracking import VAR_LOAD_PARAMETER
    from .idtracking import VAR_LOAD_RESOLVE
    from .idtracking import VAR_LOAD_UNDEFINED
    from .nodes import EvalContext
    from .optimizer import Optimizer
    from .utils import _PassArg
    from .utils import concat
    from .visitor import NodeVisitor
  constants: |
    F = t.TypeVar('F', bound=t.Callable[..., t.Any])
    operators = {'eq': '==', 'ne': '!=', 'gt': '>', 'gteq': '>=', 'lt': '<', 'lteq': '<=', 'in': 'in', 'notin': 'not in'}
  body: |
    'Compiles nodes from the parser into Python code.'
    if t.TYPE_CHECKING:
        import typing_extensions as te
        from .environment import Environment
    class MacroRef:

        def __init__(self, node: t.Union[nodes.Macro, nodes.CallBlock]) -> None:
            self.node = node
            self.accesses_caller = False
            self.accesses_kwargs = False
            self.accesses_varargs = False
    class Frame:
        """Holds compile time information for us."""

        def __init__(self, eval_ctx: EvalContext, parent: t.Optional['Frame']=None, level: t.Optional[int]=None) -> None:
            self.eval_ctx = eval_ctx
            self.parent = parent
            if parent is None:
                self.symbols = Symbols(level=level)
                self.require_output_check = False
                self.buffer: t.Optional[str] = None
                self.block: t.Optional[str] = None
            else:
                self.symbols = Symbols(parent.symbols, level=level)
                self.require_output_check = parent.require_output_check
                self.buffer = parent.buffer
                self.block = parent.block
            self.toplevel = False
            self.rootlevel = False
            self.loop_frame = False
            self.block_frame = False
            self.soft_frame = False

        def copy(self) -> 'Frame':
            """Create a copy of the current one."""
            pass

        def inner(self, isolated: bool=False) -> 'Frame':
            """Return an inner frame."""
            pass

        def soft(self) -> 'Frame':
            """Return a soft frame.  A soft frame may not be modified as
            standalone thing as it shares the resources with the frame it
            was created of, but it's not a rootlevel frame any longer.

            This is only used to implement if-statements and conditional
            expressions.
            """
            pass
        __copy__ = copy
    class VisitorExit(RuntimeError):
        """Exception used by the `UndeclaredNameVisitor` to signal a stop."""
    class DependencyFinderVisitor(NodeVisitor):
        """A visitor that collects filter and test calls."""

        def __init__(self) -> None:
            self.filters: t.Set[str] = set()
            self.tests: t.Set[str] = set()

        def visit_Block(self, node: nodes.Block) -> None:
            """Stop visiting at blocks."""
            pass
    class UndeclaredNameVisitor(NodeVisitor):
        """A visitor that checks if a name is accessed without being
        declared.  This is different from the frame visitor as it will
        not stop at closure frames.
        """

        def __init__(self, names: t.Iterable[str]) -> None:
            self.names = set(names)
            self.undeclared: t.Set[str] = set()

        def visit_Block(self, node: nodes.Block) -> None:
            """Stop visiting a blocks."""
            pass
    class CompilerExit(Exception):
        """Raised if the compiler encountered a situation where it just
        doesn't make sense to further process the code.  Any block that
        raises such an exception is not further processed.
        """
    class CodeGenerator(NodeVisitor):

        def __init__(self, environment: 'Environment', name: t.Optional[str], filename: t.Optional[str], stream: t.Optional[t.TextIO]=None, defer_init: bool=False, optimized: bool=True) -> None:
            if stream is None:
                stream = StringIO()
            self.environment = environment
            self.name = name
            self.filename = filename
            self.stream = stream
            self.created_block_context = False
            self.defer_init = defer_init
            self.optimizer: t.Optional[Optimizer] = None
            if optimized:
                self.optimizer = Optimizer(environment)
            self.import_aliases: t.Dict[str, str] = {}
            self.blocks: t.Dict[str, nodes.Block] = {}
            self.extends_so_far = 0
            self.has_known_extends = False
            self.code_lineno = 1
            self.tests: t.Dict[str, str] = {}
            self.filters: t.Dict[str, str] = {}
            self.debug_info: t.List[t.Tuple[int, int]] = []
            self._write_debug_info: t.Optional[int] = None
            self._new_lines = 0
            self._last_line = 0
            self._first_write = True
            self._last_identifier = 0
            self._indentation = 0
            self._assign_stack: t.List[t.Set[str]] = []
            self._param_def_block: t.List[t.Set[str]] = []
            self._context_reference_stack = ['context']

        def fail(self, msg: str, lineno: int) -> 'te.NoReturn':
            """Fail with a :exc:`TemplateAssertionError`."""
            pass

        def temporary_identifier(self) -> str:
            """Get a new unique identifier."""
            pass

        def buffer(self, frame: Frame) -> None:
            """Enable buffering for the frame from that point onwards."""
            pass

        def return_buffer_contents(self, frame: Frame, force_unescaped: bool=False) -> None:
            """Return the buffer contents of the frame."""
            pass

        def indent(self) -> None:
            """Indent by one."""
            pass

        def outdent(self, step: int=1) -> None:
            """Outdent by step."""
            pass

        def start_write(self, frame: Frame, node: t.Optional[nodes.Node]=None) -> None:
            """Yield or write into the frame buffer."""
            pass

        def end_write(self, frame: Frame) -> None:
            """End the writing process started by `start_write`."""
            pass

        def simple_write(self, s: str, frame: Frame, node: t.Optional[nodes.Node]=None) -> None:
            """Simple shortcut for start_write + write + end_write."""
            pass

        def blockvisit(self, nodes: t.Iterable[nodes.Node], frame: Frame) -> None:
            """Visit a list of nodes as block in a frame.  If the current frame
            is no buffer a dummy ``if 0: yield None`` is written automatically.
            """
            pass

        def write(self, x: str) -> None:
            """Write a string into the output stream."""
            pass

        def writeline(self, x: str, node: t.Optional[nodes.Node]=None, extra: int=0) -> None:
            """Combination of newline and write."""
            pass

        def newline(self, node: t.Optional[nodes.Node]=None, extra: int=0) -> None:
            """Add one or more newlines before the next write."""
            pass

        def signature(self, node: t.Union[nodes.Call, nodes.Filter, nodes.Test], frame: Frame, extra_kwargs: t.Optional[t.Mapping[str, t.Any]]=None) -> None:
            """Writes a function call to the stream for the current node.
            A leading comma is added automatically.  The extra keyword
            arguments may not include python keywords otherwise a syntax
            error could occur.  The extra keyword arguments should be given
            as python dict.
            """
            pass

        def pull_dependencies(self, nodes: t.Iterable[nodes.Node]) -> None:
            """Find all filter and test names used in the template and
            assign them to variables in the compiled namespace. Checking
            that the names are registered with the environment is done when
            compiling the Filter and Test nodes. If the node is in an If or
            CondExpr node, the check is done at runtime instead.

            .. versionchanged:: 3.0
                Filters and tests in If and CondExpr nodes are checked at
                runtime instead of compile time.
            """
            pass

        def macro_body(self, node: t.Union[nodes.Macro, nodes.CallBlock], frame: Frame) -> t.Tuple[Frame, MacroRef]:
            """Dump the function def of a macro or call block."""
            pass

        def macro_def(self, macro_ref: MacroRef, frame: Frame) -> None:
            """Dump the macro definition for the def created by macro_body."""
            pass

        def position(self, node: nodes.Node) -> str:
            """Return a human readable position for the node."""
            pass

        def write_commons(self) -> None:
            """Writes a common preamble that is used by root and block functions.
            Primarily this sets up common local helpers and enforces a generator
            through a dead branch.
            """
            pass

        def push_parameter_definitions(self, frame: Frame) -> None:
            """Pushes all parameter targets from the given frame into a local
            stack that permits tracking of yet to be assigned parameters.  In
            particular this enables the optimization from `visit_Name` to skip
            undefined expressions for parameters in macros as macros can reference
            otherwise unbound parameters.
            """
            pass

        def pop_parameter_definitions(self) -> None:
            """Pops the current parameter definitions set."""
            pass

        def mark_parameter_stored(self, target: str) -> None:
            """Marks a parameter in the current parameter definitions as stored.
            This will skip the enforced undefined checks.
            """
            pass

        def parameter_is_undeclared(self, target: str) -> bool:
            """Checks if a given target is an undeclared parameter."""
            pass

        def push_assign_tracking(self) -> None:
            """Pushes a new layer for assignment tracking."""
            pass

        def pop_assign_tracking(self, frame: Frame) -> None:
            """Pops the topmost level for assignment tracking and updates the
            context variables if necessary.
            """
            pass

        def visit_Block(self, node: nodes.Block, frame: Frame) -> None:
            """Call a block and register it for the template."""
            pass

        def visit_Extends(self, node: nodes.Extends, frame: Frame) -> None:
            """Calls the extender."""
            pass

        def visit_Include(self, node: nodes.Include, frame: Frame) -> None:
            """Handles includes."""
            pass

        def visit_Import(self, node: nodes.Import, frame: Frame) -> None:
            """Visit regular imports."""
            pass

        def visit_FromImport(self, node: nodes.FromImport, frame: Frame) -> None:
            """Visit named imports."""
            pass

        class _FinalizeInfo(t.NamedTuple):
            const: t.Optional[t.Callable[..., str]]
            src: t.Optional[str]

        @staticmethod
        def _default_finalize(value: t.Any) -> t.Any:
            """The default finalize function if the environment isn't
            configured with one. Or, if the environment has one, this is
            called on that function's output for constants.
            """
            pass
        _finalize: t.Optional[_FinalizeInfo] = None

        def _make_finalize(self) -> _FinalizeInfo:
            """Build the finalize function to be used on constants and at
            runtime. Cached so it's only created once for all output nodes.

            Returns a ``namedtuple`` with the following attributes:

            ``const``
                A function to finalize constant data at compile time.

            ``src``
                Source code to output around nodes to be evaluated at
                runtime.
            """
            pass

        def _output_const_repr(self, group: t.Iterable[t.Any]) -> str:
            """Given a group of constant values converted from ``Output``
            child nodes, produce a string to write to the template module
            source.
            """
            pass

        def _output_child_to_const(self, node: nodes.Expr, frame: Frame, finalize: _FinalizeInfo) -> str:
            """Try to optimize a child of an ``Output`` node by trying to
            convert it to constant, finalized data at compile time.

            If :exc:`Impossible` is raised, the node is not constant and
            will be evaluated at runtime. Any other exception will also be
            evaluated at runtime for easier debugging.
            """
            pass

        def _output_child_pre(self, node: nodes.Expr, frame: Frame, finalize: _FinalizeInfo) -> None:
            """Output extra source code before visiting a child of an
            ``Output`` node.
            """
            pass

        def _output_child_post(self, node: nodes.Expr, frame: Frame, finalize: _FinalizeInfo) -> None:
            """Output extra source code after visiting a child of an
            ``Output`` node.
            """
            pass
        visit_Add = _make_binop('+')
        visit_Sub = _make_binop('-')
        visit_Mul = _make_binop('*')
        visit_Div = _make_binop('/')
        visit_FloorDiv = _make_binop('//')
        visit_Pow = _make_binop('**')
        visit_Mod = _make_binop('%')
        visit_And = _make_binop('and')
        visit_Or = _make_binop('or')
        visit_Pos = _make_unop('+')
        visit_Neg = _make_unop('-')
        visit_Not = _make_unop('not ')


preamble constants:
  source: jinja2/constants.py
  constants: |
    LOREM_IPSUM_WORDS = 'a ac accumsan ad adipiscing aenean aliquam aliquet amet ante aptent arcu at\nauctor augue bibendum blandit class commodo condimentum congue consectetuer\nconsequat conubia convallis cras cubilia cum curabitur curae cursus dapibus\ndiam dictum dictumst dignissim dis dolor donec dui duis egestas eget eleifend\nelementum elit enim erat eros est et etiam eu euismod facilisi facilisis fames\nfaucibus felis fermentum feugiat fringilla fusce gravida habitant habitasse hac\nhendrerit hymenaeos iaculis id imperdiet in inceptos integer interdum ipsum\njusto lacinia lacus laoreet lectus leo libero ligula litora lobortis lorem\nluctus maecenas magna magnis malesuada massa mattis mauris metus mi molestie\nmollis montes morbi mus nam nascetur natoque nec neque netus nibh nisi nisl non\nnonummy nostra nulla nullam nunc odio orci ornare parturient pede pellentesque\npenatibus per pharetra phasellus placerat platea porta porttitor posuere\npotenti praesent pretium primis proin pulvinar purus quam quis quisque rhoncus\nridiculus risus rutrum sagittis sapien scelerisque sed sem semper senectus sit\nsociis sociosqu sodales sollicitudin suscipit suspendisse taciti tellus tempor\ntempus tincidunt torquent tortor tristique turpis ullamcorper ultrices\nultricies urna ut varius vehicula vel velit venenatis vestibulum vitae vivamus\nviverra volutpat vulputate'


preamble debug:
  source: jinja2/debug.py
  imports: |
    import sys
    import typing as t
    from types import CodeType
    from types import TracebackType
    from .exceptions import TemplateSyntaxError
    from .utils import internal_code
    from .utils import missing
  body: |
    if t.TYPE_CHECKING:
        from .runtime import Context


preamble defaults:
  source: jinja2/defaults.py
  imports: |
    import typing as t
    from .filters import FILTERS as DEFAULT_FILTERS
    from .tests import TESTS as DEFAULT_TESTS
    from .utils import Cycler
    from .utils import generate_lorem_ipsum
    from .utils import Joiner
    from .utils import Namespace
  constants: |
    BLOCK_START_STRING = '{%'
    BLOCK_END_STRING = '%}'
    VARIABLE_START_STRING = '{{'
    VARIABLE_END_STRING = '}}'
    COMMENT_START_STRING = '{#'
    COMMENT_END_STRING = '#}'
    LINE_STATEMENT_PREFIX: t.Optional[str] = None
    LINE_COMMENT_PREFIX: t.Optional[str] = None
    TRIM_BLOCKS = False
    LSTRIP_BLOCKS = False
    NEWLINE_SEQUENCE: "te.Literal['\\n', '\\r\\n', '\\r']" = '\n'
    KEEP_TRAILING_NEWLINE = False
    DEFAULT_NAMESPACE = {'range': range, 'dict': dict, 'lipsum': generate_lorem_ipsum, 'cycler': Cycler, 'joiner': Joiner, 'namespace': Namespace}
    DEFAULT_POLICIES: t.Dict[str, t.Any] = {'compiler.ascii_str': True, 'urlize.rel': 'noopener', 'urlize.target': None, 'urlize.extra_schemes': None, 'truncate.leeway': 5, 'json.dumps_function': None, 'json.dumps_kwargs': {'sort_keys': True}, 'ext.i18n.trimmed': False}
  body: |
    if t.TYPE_CHECKING:
        import typing_extensions as te


preamble environment:
  source: jinja2/environment.py
  imports: |
    import os
    import typing
    import typing as t
    import weakref
    from collections import ChainMap
    from functools import lru_cache
    from functools import partial
    from functools import reduce
    from types import CodeType
    from markupsafe import Markup
    from . import nodes
    from .compiler import CodeGenerator
    from .compiler import generate
    from .defaults import BLOCK_END_STRING
    from .defaults import BLOCK_START_STRING
    from .defaults import COMMENT_END_STRING
    from .defaults import COMMENT_START_STRING
    from .defaults import DEFAULT_FILTERS
    from .defaults import DEFAULT_NAMESPACE
    from .defaults import DEFAULT_POLICIES
    from .defaults import DEFAULT_TESTS
    from .defaults import KEEP_TRAILING_NEWLINE
    from .defaults import LINE_COMMENT_PREFIX
    from .defaults import LINE_STATEMENT_PREFIX
    from .defaults import LSTRIP_BLOCKS
    from .defaults import NEWLINE_SEQUENCE
    from .defaults import TRIM_BLOCKS
    from .defaults import VARIABLE_END_STRING
    from .defaults import VARIABLE_START_STRING
    from .exceptions import TemplateNotFound
    from .exceptions import TemplateRuntimeError
    from .exceptions import TemplatesNotFound
    from .exceptions import TemplateSyntaxError
    from .exceptions import UndefinedError
    from .lexer import get_lexer
    from .lexer import Lexer
    from .lexer import TokenStream
    from .nodes import EvalContext
    from .parser import Parser
    from .runtime import Context
    from .runtime import new_context
    from .runtime import Undefined
    from .utils import _PassArg
    from .utils import concat
    from .utils import consume
    from .utils import import_string
    from .utils import internalcode
    from .utils import LRUCache
    from .utils import missing
  constants: |
    _env_bound = t.TypeVar('_env_bound', bound='Environment')
  body: |
    'Classes for managing templates and their runtime and compile time\noptions.\n'
    if t.TYPE_CHECKING:
        import typing_extensions as te
        from .bccache import BytecodeCache
        from .ext import Extension
        from .loaders import BaseLoader
    class Environment:
        """The core component of Jinja is the `Environment`.  It contains
        important shared variables like configuration, filters, tests,
        globals and others.  Instances of this class may be modified if
        they are not shared and if no template was loaded so far.
        Modifications on environments after the first template was loaded
        will lead to surprising effects and undefined behavior.

        Here are the possible initialization parameters:

            `block_start_string`
                The string marking the beginning of a block.  Defaults to ``'{%'``.

            `block_end_string`
                The string marking the end of a block.  Defaults to ``'%}'``.

            `variable_start_string`
                The string marking the beginning of a print statement.
                Defaults to ``'{{'``.

            `variable_end_string`
                The string marking the end of a print statement.  Defaults to
                ``'}}'``.

            `comment_start_string`
                The string marking the beginning of a comment.  Defaults to ``'{#'``.

            `comment_end_string`
                The string marking the end of a comment.  Defaults to ``'#}'``.

            `line_statement_prefix`
                If given and a string, this will be used as prefix for line based
                statements.  See also :ref:`line-statements`.

            `line_comment_prefix`
                If given and a string, this will be used as prefix for line based
                comments.  See also :ref:`line-statements`.

                .. versionadded:: 2.2

            `trim_blocks`
                If this is set to ``True`` the first newline after a block is
                removed (block, not variable tag!).  Defaults to `False`.

            `lstrip_blocks`
                If this is set to ``True`` leading spaces and tabs are stripped
                from the start of a line to a block.  Defaults to `False`.

            `newline_sequence`
                The sequence that starts a newline.  Must be one of ``'\\r'``,
                ``'\\n'`` or ``'\\r\\n'``.  The default is ``'\\n'`` which is a
                useful default for Linux and OS X systems as well as web
                applications.

            `keep_trailing_newline`
                Preserve the trailing newline when rendering templates.
                The default is ``False``, which causes a single newline,
                if present, to be stripped from the end of the template.

                .. versionadded:: 2.7

            `extensions`
                List of Jinja extensions to use.  This can either be import paths
                as strings or extension classes.  For more information have a
                look at :ref:`the extensions documentation <jinja-extensions>`.

            `optimized`
                should the optimizer be enabled?  Default is ``True``.

            `undefined`
                :class:`Undefined` or a subclass of it that is used to represent
                undefined values in the template.

            `finalize`
                A callable that can be used to process the result of a variable
                expression before it is output.  For example one can convert
                ``None`` implicitly into an empty string here.

            `autoescape`
                If set to ``True`` the XML/HTML autoescaping feature is enabled by
                default.  For more details about autoescaping see
                :class:`~markupsafe.Markup`.  As of Jinja 2.4 this can also
                be a callable that is passed the template name and has to
                return ``True`` or ``False`` depending on autoescape should be
                enabled by default.

                .. versionchanged:: 2.4
                   `autoescape` can now be a function

            `loader`
                The template loader for this environment.

            `cache_size`
                The size of the cache.  Per default this is ``400`` which means
                that if more than 400 templates are loaded the loader will clean
                out the least recently used template.  If the cache size is set to
                ``0`` templates are recompiled all the time, if the cache size is
                ``-1`` the cache will not be cleaned.

                .. versionchanged:: 2.8
                   The cache size was increased to 400 from a low 50.

            `auto_reload`
                Some loaders load templates from locations where the template
                sources may change (ie: file system or database).  If
                ``auto_reload`` is set to ``True`` (default) every time a template is
                requested the loader checks if the source changed and if yes, it
                will reload the template.  For higher performance it's possible to
                disable that.

            `bytecode_cache`
                If set to a bytecode cache object, this object will provide a
                cache for the internal Jinja bytecode so that templates don't
                have to be parsed if they were not changed.

                See :ref:`bytecode-cache` for more information.

            `enable_async`
                If set to true this enables async template execution which
                allows using async functions and generators.
        """
        sandboxed = False
        overlayed = False
        linked_to: t.Optional['Environment'] = None
        shared = False
        code_generator_class: t.Type['CodeGenerator'] = CodeGenerator
        concat = ''.join
        context_class: t.Type[Context] = Context
        template_class: t.Type['Template']

        def __init__(self, block_start_string: str=BLOCK_START_STRING, block_end_string: str=BLOCK_END_STRING, variable_start_string: str=VARIABLE_START_STRING, variable_end_string: str=VARIABLE_END_STRING, comment_start_string: str=COMMENT_START_STRING, comment_end_string: str=COMMENT_END_STRING, line_statement_prefix: t.Optional[str]=LINE_STATEMENT_PREFIX, line_comment_prefix: t.Optional[str]=LINE_COMMENT_PREFIX, trim_blocks: bool=TRIM_BLOCKS, lstrip_blocks: bool=LSTRIP_BLOCKS, newline_sequence: "te.Literal['\\n', '\\r\\n', '\\r']"=NEWLINE_SEQUENCE, keep_trailing_newline: bool=KEEP_TRAILING_NEWLINE, extensions: t.Sequence[t.Union[str, t.Type['Extension']]]=(), optimized: bool=True, undefined: t.Type[Undefined]=Undefined, finalize: t.Optional[t.Callable[..., t.Any]]=None, autoescape: t.Union[bool, t.Callable[[t.Optional[str]], bool]]=False, loader: t.Optional['BaseLoader']=None, cache_size: int=400, auto_reload: bool=True, bytecode_cache: t.Optional['BytecodeCache']=None, enable_async: bool=False):
            self.block_start_string = block_start_string
            self.block_end_string = block_end_string
            self.variable_start_string = variable_start_string
            self.variable_end_string = variable_end_string
            self.comment_start_string = comment_start_string
            self.comment_end_string = comment_end_string
            self.line_statement_prefix = line_statement_prefix
            self.line_comment_prefix = line_comment_prefix
            self.trim_blocks = trim_blocks
            self.lstrip_blocks = lstrip_blocks
            self.newline_sequence = newline_sequence
            self.keep_trailing_newline = keep_trailing_newline
            self.undefined: t.Type[Undefined] = undefined
            self.optimized = optimized
            self.finalize = finalize
            self.autoescape = autoescape
            self.filters = DEFAULT_FILTERS.copy()
            self.tests = DEFAULT_TESTS.copy()
            self.globals = DEFAULT_NAMESPACE.copy()
            self.loader = loader
            self.cache = create_cache(cache_size)
            self.bytecode_cache = bytecode_cache
            self.auto_reload = auto_reload
            self.policies = DEFAULT_POLICIES.copy()
            self.extensions = load_extensions(self, extensions)
            self.is_async = enable_async
            _environment_config_check(self)

        def add_extension(self, extension: t.Union[str, t.Type['Extension']]) -> None:
            """Adds an extension after the environment was created.

            .. versionadded:: 2.5
            """
            pass

        def extend(self, **attributes: t.Any) -> None:
            """Add the items to the instance of the environment if they do not exist
            yet.  This is used by :ref:`extensions <writing-extensions>` to register
            callbacks and configuration values without breaking inheritance.
            """
            pass

        def overlay(self, block_start_string: str=missing, block_end_string: str=missing, variable_start_string: str=missing, variable_end_string: str=missing, comment_start_string: str=missing, comment_end_string: str=missing, line_statement_prefix: t.Optional[str]=missing, line_comment_prefix: t.Optional[str]=missing, trim_blocks: bool=missing, lstrip_blocks: bool=missing, newline_sequence: "te.Literal['\\n', '\\r\\n', '\\r']"=missing, keep_trailing_newline: bool=missing, extensions: t.Sequence[t.Union[str, t.Type['Extension']]]=missing, optimized: bool=missing, undefined: t.Type[Undefined]=missing, finalize: t.Optional[t.Callable[..., t.Any]]=missing, autoescape: t.Union[bool, t.Callable[[t.Optional[str]], bool]]=missing, loader: t.Optional['BaseLoader']=missing, cache_size: int=missing, auto_reload: bool=missing, bytecode_cache: t.Optional['BytecodeCache']=missing, enable_async: bool=False) -> 'Environment':
            """Create a new overlay environment that shares all the data with the
            current environment except for cache and the overridden attributes.
            Extensions cannot be removed for an overlayed environment.  An overlayed
            environment automatically gets all the extensions of the environment it
            is linked to plus optional extra extensions.

            Creating overlays should happen after the initial environment was set
            up completely.  Not all attributes are truly linked, some are just
            copied over so modifications on the original environment may not shine
            through.

            .. versionchanged:: 3.1.2
                Added the ``newline_sequence``,, ``keep_trailing_newline``,
                and ``enable_async`` parameters to match ``__init__``.
            """
            pass

        @property
        def lexer(self) -> Lexer:
            """The lexer for this environment."""
            pass

        def iter_extensions(self) -> t.Iterator['Extension']:
            """Iterates over the extensions by priority."""
            pass

        def getitem(self, obj: t.Any, argument: t.Union[str, t.Any]) -> t.Union[t.Any, Undefined]:
            """Get an item or attribute of an object but prefer the item."""
            pass

        def getattr(self, obj: t.Any, attribute: str) -> t.Any:
            """Get an item or attribute of an object but prefer the attribute.
            Unlike :meth:`getitem` the attribute *must* be a string.
            """
            pass

        def call_filter(self, name: str, value: t.Any, args: t.Optional[t.Sequence[t.Any]]=None, kwargs: t.Optional[t.Mapping[str, t.Any]]=None, context: t.Optional[Context]=None, eval_ctx: t.Optional[EvalContext]=None) -> t.Any:
            """Invoke a filter on a value the same way the compiler does.

            This might return a coroutine if the filter is running from an
            environment in async mode and the filter supports async
            execution. It's your responsibility to await this if needed.

            .. versionadded:: 2.7
            """
            pass

        def call_test(self, name: str, value: t.Any, args: t.Optional[t.Sequence[t.Any]]=None, kwargs: t.Optional[t.Mapping[str, t.Any]]=None, context: t.Optional[Context]=None, eval_ctx: t.Optional[EvalContext]=None) -> t.Any:
            """Invoke a test on a value the same way the compiler does.

            This might return a coroutine if the test is running from an
            environment in async mode and the test supports async execution.
            It's your responsibility to await this if needed.

            .. versionchanged:: 3.0
                Tests support ``@pass_context``, etc. decorators. Added
                the ``context`` and ``eval_ctx`` parameters.

            .. versionadded:: 2.7
            """
            pass

        @internalcode
        def parse(self, source: str, name: t.Optional[str]=None, filename: t.Optional[str]=None) -> nodes.Template:
            """Parse the sourcecode and return the abstract syntax tree.  This
            tree of nodes is used by the compiler to convert the template into
            executable source- or bytecode.  This is useful for debugging or to
            extract information from templates.

            If you are :ref:`developing Jinja extensions <writing-extensions>`
            this gives you a good overview of the node tree generated.
            """
            pass

        def _parse(self, source: str, name: t.Optional[str], filename: t.Optional[str]) -> nodes.Template:
            """Internal parsing function used by `parse` and `compile`."""
            pass

        def lex(self, source: str, name: t.Optional[str]=None, filename: t.Optional[str]=None) -> t.Iterator[t.Tuple[int, str, str]]:
            """Lex the given sourcecode and return a generator that yields
            tokens as tuples in the form ``(lineno, token_type, value)``.
            This can be useful for :ref:`extension development <writing-extensions>`
            and debugging templates.

            This does not perform preprocessing.  If you want the preprocessing
            of the extensions to be applied you have to filter source through
            the :meth:`preprocess` method.
            """
            pass

        def preprocess(self, source: str, name: t.Optional[str]=None, filename: t.Optional[str]=None) -> str:
            """Preprocesses the source with all extensions.  This is automatically
            called for all parsing and compiling methods but *not* for :meth:`lex`
            because there you usually only want the actual source tokenized.
            """
            pass

        def _tokenize(self, source: str, name: t.Optional[str], filename: t.Optional[str]=None, state: t.Optional[str]=None) -> TokenStream:
            """Called by the parser to do the preprocessing and filtering
            for all the extensions.  Returns a :class:`~jinja2.lexer.TokenStream`.
            """
            pass

        def _generate(self, source: nodes.Template, name: t.Optional[str], filename: t.Optional[str], defer_init: bool=False) -> str:
            """Internal hook that can be overridden to hook a different generate
            method in.

            .. versionadded:: 2.5
            """
            pass

        def _compile(self, source: str, filename: str) -> CodeType:
            """Internal hook that can be overridden to hook a different compile
            method in.

            .. versionadded:: 2.5
            """
            pass

        @internalcode
        def compile(self, source: t.Union[str, nodes.Template], name: t.Optional[str]=None, filename: t.Optional[str]=None, raw: bool=False, defer_init: bool=False) -> t.Union[str, CodeType]:
            """Compile a node or template source code.  The `name` parameter is
            the load name of the template after it was joined using
            :meth:`join_path` if necessary, not the filename on the file system.
            the `filename` parameter is the estimated filename of the template on
            the file system.  If the template came from a database or memory this
            can be omitted.

            The return value of this method is a python code object.  If the `raw`
            parameter is `True` the return value will be a string with python
            code equivalent to the bytecode returned otherwise.  This method is
            mainly used internally.

            `defer_init` is use internally to aid the module code generator.  This
            causes the generated code to be able to import without the global
            environment variable to be set.

            .. versionadded:: 2.4
               `defer_init` parameter added.
            """
            pass

        def compile_expression(self, source: str, undefined_to_none: bool=True) -> 'TemplateExpression':
            """A handy helper method that returns a callable that accepts keyword
            arguments that appear as variables in the expression.  If called it
            returns the result of the expression.

            This is useful if applications want to use the same rules as Jinja
            in template "configuration files" or similar situations.

            Example usage:

            >>> env = Environment()
            >>> expr = env.compile_expression('foo == 42')
            >>> expr(foo=23)
            False
            >>> expr(foo=42)
            True

            Per default the return value is converted to `None` if the
            expression returns an undefined value.  This can be changed
            by setting `undefined_to_none` to `False`.

            >>> env.compile_expression('var')() is None
            True
            >>> env.compile_expression('var', undefined_to_none=False)()
            Undefined

            .. versionadded:: 2.1
            """
            pass

        def compile_templates(self, target: t.Union[str, 'os.PathLike[str]'], extensions: t.Optional[t.Collection[str]]=None, filter_func: t.Optional[t.Callable[[str], bool]]=None, zip: t.Optional[str]='deflated', log_function: t.Optional[t.Callable[[str], None]]=None, ignore_errors: bool=True) -> None:
            """Finds all the templates the loader can find, compiles them
            and stores them in `target`.  If `zip` is `None`, instead of in a
            zipfile, the templates will be stored in a directory.
            By default a deflate zip algorithm is used. To switch to
            the stored algorithm, `zip` can be set to ``'stored'``.

            `extensions` and `filter_func` are passed to :meth:`list_templates`.
            Each template returned will be compiled to the target folder or
            zipfile.

            By default template compilation errors are ignored.  In case a
            log function is provided, errors are logged.  If you want template
            syntax errors to abort the compilation you can set `ignore_errors`
            to `False` and you will get an exception on syntax errors.

            .. versionadded:: 2.4
            """
            pass

        def list_templates(self, extensions: t.Optional[t.Collection[str]]=None, filter_func: t.Optional[t.Callable[[str], bool]]=None) -> t.List[str]:
            """Returns a list of templates for this environment.  This requires
            that the loader supports the loader's
            :meth:`~BaseLoader.list_templates` method.

            If there are other files in the template folder besides the
            actual templates, the returned list can be filtered.  There are two
            ways: either `extensions` is set to a list of file extensions for
            templates, or a `filter_func` can be provided which is a callable that
            is passed a template name and should return `True` if it should end up
            in the result list.

            If the loader does not support that, a :exc:`TypeError` is raised.

            .. versionadded:: 2.4
            """
            pass

        def handle_exception(self, source: t.Optional[str]=None) -> 'te.NoReturn':
            """Exception handling helper.  This is used internally to either raise
            rewritten exceptions or return a rendered traceback for the template.
            """
            pass

        def join_path(self, template: str, parent: str) -> str:
            """Join a template with the parent.  By default all the lookups are
            relative to the loader root so this method returns the `template`
            parameter unchanged, but if the paths should be relative to the
            parent template, this function can be used to calculate the real
            template name.

            Subclasses may override this method and implement template path
            joining here.
            """
            pass

        @internalcode
        def get_template(self, name: t.Union[str, 'Template'], parent: t.Optional[str]=None, globals: t.Optional[t.MutableMapping[str, t.Any]]=None) -> 'Template':
            """Load a template by name with :attr:`loader` and return a
            :class:`Template`. If the template does not exist a
            :exc:`TemplateNotFound` exception is raised.

            :param name: Name of the template to load. When loading
                templates from the filesystem, "/" is used as the path
                separator, even on Windows.
            :param parent: The name of the parent template importing this
                template. :meth:`join_path` can be used to implement name
                transformations with this.
            :param globals: Extend the environment :attr:`globals` with
                these extra variables available for all renders of this
                template. If the template has already been loaded and
                cached, its globals are updated with any new items.

            .. versionchanged:: 3.0
                If a template is loaded from cache, ``globals`` will update
                the template's globals instead of ignoring the new values.

            .. versionchanged:: 2.4
                If ``name`` is a :class:`Template` object it is returned
                unchanged.
            """
            pass

        @internalcode
        def select_template(self, names: t.Iterable[t.Union[str, 'Template']], parent: t.Optional[str]=None, globals: t.Optional[t.MutableMapping[str, t.Any]]=None) -> 'Template':
            """Like :meth:`get_template`, but tries loading multiple names.
            If none of the names can be loaded a :exc:`TemplatesNotFound`
            exception is raised.

            :param names: List of template names to try loading in order.
            :param parent: The name of the parent template importing this
                template. :meth:`join_path` can be used to implement name
                transformations with this.
            :param globals: Extend the environment :attr:`globals` with
                these extra variables available for all renders of this
                template. If the template has already been loaded and
                cached, its globals are updated with any new items.

            .. versionchanged:: 3.0
                If a template is loaded from cache, ``globals`` will update
                the template's globals instead of ignoring the new values.

            .. versionchanged:: 2.11
                If ``names`` is :class:`Undefined`, an :exc:`UndefinedError`
                is raised instead. If no templates were found and ``names``
                contains :class:`Undefined`, the message is more helpful.

            .. versionchanged:: 2.4
                If ``names`` contains a :class:`Template` object it is
                returned unchanged.

            .. versionadded:: 2.3
            """
            pass

        @internalcode
        def get_or_select_template(self, template_name_or_list: t.Union[str, 'Template', t.List[t.Union[str, 'Template']]], parent: t.Optional[str]=None, globals: t.Optional[t.MutableMapping[str, t.Any]]=None) -> 'Template':
            """Use :meth:`select_template` if an iterable of template names
            is given, or :meth:`get_template` if one name is given.

            .. versionadded:: 2.3
            """
            pass

        def from_string(self, source: t.Union[str, nodes.Template], globals: t.Optional[t.MutableMapping[str, t.Any]]=None, template_class: t.Optional[t.Type['Template']]=None) -> 'Template':
            """Load a template from a source string without using
            :attr:`loader`.

            :param source: Jinja source to compile into a template.
            :param globals: Extend the environment :attr:`globals` with
                these extra variables available for all renders of this
                template. If the template has already been loaded and
                cached, its globals are updated with any new items.
            :param template_class: Return an instance of this
                :class:`Template` class.
            """
            pass

        def make_globals(self, d: t.Optional[t.MutableMapping[str, t.Any]]) -> t.MutableMapping[str, t.Any]:
            """Make the globals map for a template. Any given template
            globals overlay the environment :attr:`globals`.

            Returns a :class:`collections.ChainMap`. This allows any changes
            to a template's globals to only affect that template, while
            changes to the environment's globals are still reflected.
            However, avoid modifying any globals after a template is loaded.

            :param d: Dict of template-specific globals.

            .. versionchanged:: 3.0
                Use :class:`collections.ChainMap` to always prevent mutating
                environment globals.
            """
            pass
    class Template:
        """A compiled template that can be rendered.

        Use the methods on :class:`Environment` to create or load templates.
        The environment is used to configure how templates are compiled and
        behave.

        It is also possible to create a template object directly. This is
        not usually recommended. The constructor takes most of the same
        arguments as :class:`Environment`. All templates created with the
        same environment arguments share the same ephemeral ``Environment``
        instance behind the scenes.

        A template object should be considered immutable. Modifications on
        the object are not supported.
        """
        environment_class: t.Type[Environment] = Environment
        environment: Environment
        globals: t.MutableMapping[str, t.Any]
        name: t.Optional[str]
        filename: t.Optional[str]
        blocks: t.Dict[str, t.Callable[[Context], t.Iterator[str]]]
        root_render_func: t.Callable[[Context], t.Iterator[str]]
        _module: t.Optional['TemplateModule']
        _debug_info: str
        _uptodate: t.Optional[t.Callable[[], bool]]

        def __new__(cls, source: t.Union[str, nodes.Template], block_start_string: str=BLOCK_START_STRING, block_end_string: str=BLOCK_END_STRING, variable_start_string: str=VARIABLE_START_STRING, variable_end_string: str=VARIABLE_END_STRING, comment_start_string: str=COMMENT_START_STRING, comment_end_string: str=COMMENT_END_STRING, line_statement_prefix: t.Optional[str]=LINE_STATEMENT_PREFIX, line_comment_prefix: t.Optional[str]=LINE_COMMENT_PREFIX, trim_blocks: bool=TRIM_BLOCKS, lstrip_blocks: bool=LSTRIP_BLOCKS, newline_sequence: "te.Literal['\\n', '\\r\\n', '\\r']"=NEWLINE_SEQUENCE, keep_trailing_newline: bool=KEEP_TRAILING_NEWLINE, extensions: t.Sequence[t.Union[str, t.Type['Extension']]]=(), optimized: bool=True, undefined: t.Type[Undefined]=Undefined, finalize: t.Optional[t.Callable[..., t.Any]]=None, autoescape: t.Union[bool, t.Callable[[t.Optional[str]], bool]]=False, enable_async: bool=False) -> t.Any:
            env = get_spontaneous_environment(cls.environment_class, block_start_string, block_end_string, variable_start_string, variable_end_string, comment_start_string, comment_end_string, line_statement_prefix, line_comment_prefix, trim_blocks, lstrip_blocks, newline_sequence, keep_trailing_newline, frozenset(extensions), optimized, undefined, finalize, autoescape, None, 0, False, None, enable_async)
            return env.from_string(source, template_class=cls)

        @classmethod
        def from_code(cls, environment: Environment, code: CodeType, globals: t.MutableMapping[str, t.Any], uptodate: t.Optional[t.Callable[[], bool]]=None) -> 'Template':
            """Creates a template object from compiled code and the globals.  This
            is used by the loaders and environment to create a template object.
            """
            pass

        @classmethod
        def from_module_dict(cls, environment: Environment, module_dict: t.MutableMapping[str, t.Any], globals: t.MutableMapping[str, t.Any]) -> 'Template':
            """Creates a template object from a module.  This is used by the
            module loader to create a template object.

            .. versionadded:: 2.4
            """
            pass

        def render(self, *args: t.Any, **kwargs: t.Any) -> str:
            """This method accepts the same arguments as the `dict` constructor:
            A dict, a dict subclass or some keyword arguments.  If no arguments
            are given the context will be empty.  These two calls do the same::

                template.render(knights='that say nih')
                template.render({'knights': 'that say nih'})

            This will return the rendered template as a string.
            """
            pass

        async def render_async(self, *args: t.Any, **kwargs: t.Any) -> str:
            """This works similar to :meth:`render` but returns a coroutine
            that when awaited returns the entire rendered template string.  This
            requires the async feature to be enabled.

            Example usage::

                await template.render_async(knights='that say nih; asynchronously')
            """
            pass

        def stream(self, *args: t.Any, **kwargs: t.Any) -> 'TemplateStream':
            """Works exactly like :meth:`generate` but returns a
            :class:`TemplateStream`.
            """
            pass

        def generate(self, *args: t.Any, **kwargs: t.Any) -> t.Iterator[str]:
            """For very large templates it can be useful to not render the whole
            template at once but evaluate each statement after another and yield
            piece for piece.  This method basically does exactly that and returns
            a generator that yields one item after another as strings.

            It accepts the same arguments as :meth:`render`.
            """
            pass

        async def generate_async(self, *args: t.Any, **kwargs: t.Any) -> t.AsyncIterator[str]:
            """An async version of :meth:`generate`.  Works very similarly but
            returns an async iterator instead.
            """
            pass

        def new_context(self, vars: t.Optional[t.Dict[str, t.Any]]=None, shared: bool=False, locals: t.Optional[t.Mapping[str, t.Any]]=None) -> Context:
            """Create a new :class:`Context` for this template.  The vars
            provided will be passed to the template.  Per default the globals
            are added to the context.  If shared is set to `True` the data
            is passed as is to the context without adding the globals.

            `locals` can be a dict of local variables for internal usage.
            """
            pass

        def make_module(self, vars: t.Optional[t.Dict[str, t.Any]]=None, shared: bool=False, locals: t.Optional[t.Mapping[str, t.Any]]=None) -> 'TemplateModule':
            """This method works like the :attr:`module` attribute when called
            without arguments but it will evaluate the template on every call
            rather than caching it.  It's also possible to provide
            a dict which is then used as context.  The arguments are the same
            as for the :meth:`new_context` method.
            """
            pass

        async def make_module_async(self, vars: t.Optional[t.Dict[str, t.Any]]=None, shared: bool=False, locals: t.Optional[t.Mapping[str, t.Any]]=None) -> 'TemplateModule':
            """As template module creation can invoke template code for
            asynchronous executions this method must be used instead of the
            normal :meth:`make_module` one.  Likewise the module attribute
            becomes unavailable in async mode.
            """
            pass

        @internalcode
        def _get_default_module(self, ctx: t.Optional[Context]=None) -> 'TemplateModule':
            """If a context is passed in, this means that the template was
            imported. Imported templates have access to the current
            template's globals by default, but they can only be accessed via
            the context during runtime.

            If there are new globals, we need to create a new module because
            the cached module is already rendered and will not have access
            to globals from the current context. This new module is not
            cached because the template can be imported elsewhere, and it
            should have access to only the current template's globals.
            """
            pass

        @property
        def module(self) -> 'TemplateModule':
            """The template as module.  This is used for imports in the
            template runtime but is also useful if one wants to access
            exported template variables from the Python layer:

            >>> t = Template('{% macro foo() %}42{% endmacro %}23')
            >>> str(t.module)
            '23'
            >>> t.module.foo() == u'42'
            True

            This attribute is not available if async mode is enabled.
            """
            pass

        def get_corresponding_lineno(self, lineno: int) -> int:
            """Return the source line number of a line number in the
            generated bytecode as they are not in sync.
            """
            pass

        @property
        def is_up_to_date(self) -> bool:
            """If this variable is `False` there is a newer version available."""
            pass

        @property
        def debug_info(self) -> t.List[t.Tuple[int, int]]:
            """The debug info mapping."""
            pass

        def __repr__(self) -> str:
            if self.name is None:
                name = f'memory:{id(self):x}'
            else:
                name = repr(self.name)
            return f'<{type(self).__name__} {name}>'
    class TemplateModule:
        """Represents an imported template.  All the exported names of the
        template are available as attributes on this object.  Additionally
        converting it into a string renders the contents.
        """

        def __init__(self, template: Template, context: Context, body_stream: t.Optional[t.Iterable[str]]=None) -> None:
            if body_stream is None:
                if context.environment.is_async:
                    raise RuntimeError('Async mode requires a body stream to be passed to a template module. Use the async methods of the API you are using.')
                body_stream = list(template.root_render_func(context))
            self._body_stream = body_stream
            self.__dict__.update(context.get_exported())
            self.__name__ = template.name

        def __html__(self) -> Markup:
            return Markup(concat(self._body_stream))

        def __str__(self) -> str:
            return concat(self._body_stream)

        def __repr__(self) -> str:
            if self.__name__ is None:
                name = f'memory:{id(self):x}'
            else:
                name = repr(self.__name__)
            return f'<{type(self).__name__} {name}>'
    class TemplateExpression:
        """The :meth:`jinja2.Environment.compile_expression` method returns an
        instance of this object.  It encapsulates the expression-like access
        to the template with an expression it wraps.
        """

        def __init__(self, template: Template, undefined_to_none: bool) -> None:
            self._template = template
            self._undefined_to_none = undefined_to_none

        def __call__(self, *args: t.Any, **kwargs: t.Any) -> t.Optional[t.Any]:
            context = self._template.new_context(dict(*args, **kwargs))
            consume(self._template.root_render_func(context))
            rv = context.vars['result']
            if self._undefined_to_none and isinstance(rv, Undefined):
                rv = None
            return rv
    class TemplateStream:
        """A template stream works pretty much like an ordinary python generator
        but it can buffer multiple items to reduce the number of total iterations.
        Per default the output is unbuffered which means that for every unbuffered
        instruction in the template one string is yielded.

        If buffering is enabled with a buffer size of 5, five items are combined
        into a new string.  This is mainly useful if you are streaming
        big templates to a client via WSGI which flushes after each iteration.
        """

        def __init__(self, gen: t.Iterator[str]) -> None:
            self._gen = gen
            self.disable_buffering()

        def dump(self, fp: t.Union[str, t.IO[bytes]], encoding: t.Optional[str]=None, errors: t.Optional[str]='strict') -> None:
            """Dump the complete stream into a file or file-like object.
            Per default strings are written, if you want to encode
            before writing specify an `encoding`.

            Example usage::

                Template('Hello {{ name }}!').stream(name='foo').dump('hello.html')
            """
            pass

        def disable_buffering(self) -> None:
            """Disable the output buffering."""
            pass

        def enable_buffering(self, size: int=5) -> None:
            """Enable buffering.  Buffer `size` items before yielding them."""
            pass

        def __iter__(self) -> 'TemplateStream':
            return self

        def __next__(self) -> str:
            return self._next()
    Environment.template_class = Template


preamble exceptions:
  source: jinja2/exceptions.py
  imports: |
    import typing as t
  body: |
    if t.TYPE_CHECKING:
        from .runtime import Undefined
    class TemplateError(Exception):
        """Baseclass for all template errors."""

        def __init__(self, message: t.Optional[str]=None) -> None:
            super().__init__(message)
    class TemplateNotFound(IOError, LookupError, TemplateError):
        """Raised if a template does not exist.

        .. versionchanged:: 2.11
            If the given name is :class:`Undefined` and no message was
            provided, an :exc:`UndefinedError` is raised.
        """
        message: t.Optional[str] = None

        def __init__(self, name: t.Optional[t.Union[str, 'Undefined']], message: t.Optional[str]=None) -> None:
            IOError.__init__(self, name)
            if message is None:
                from .runtime import Undefined
                if isinstance(name, Undefined):
                    name._fail_with_undefined_error()
                message = name
            self.message = message
            self.name = name
            self.templates = [name]

        def __str__(self) -> str:
            return str(self.message)
    class TemplatesNotFound(TemplateNotFound):
        """Like :class:`TemplateNotFound` but raised if multiple templates
        are selected.  This is a subclass of :class:`TemplateNotFound`
        exception, so just catching the base exception will catch both.

        .. versionchanged:: 2.11
            If a name in the list of names is :class:`Undefined`, a message
            about it being undefined is shown rather than the empty string.

        .. versionadded:: 2.2
        """

        def __init__(self, names: t.Sequence[t.Union[str, 'Undefined']]=(), message: t.Optional[str]=None) -> None:
            if message is None:
                from .runtime import Undefined
                parts = []
                for name in names:
                    if isinstance(name, Undefined):
                        parts.append(name._undefined_message)
                    else:
                        parts.append(name)
                parts_str = ', '.join(map(str, parts))
                message = f'none of the templates given were found: {parts_str}'
            super().__init__(names[-1] if names else None, message)
            self.templates = list(names)
    class TemplateSyntaxError(TemplateError):
        """Raised to tell the user that there is a problem with the template."""

        def __init__(self, message: str, lineno: int, name: t.Optional[str]=None, filename: t.Optional[str]=None) -> None:
            super().__init__(message)
            self.lineno = lineno
            self.name = name
            self.filename = filename
            self.source: t.Optional[str] = None
            self.translated = False

        def __str__(self) -> str:
            if self.translated:
                return t.cast(str, self.message)
            location = f'line {self.lineno}'
            name = self.filename or self.name
            if name:
                location = f'File "{name}", {location}'
            lines = [t.cast(str, self.message), '  ' + location]
            if self.source is not None:
                try:
                    line = self.source.splitlines()[self.lineno - 1]
                except IndexError:
                    pass
                else:
                    lines.append('    ' + line.strip())
            return '\n'.join(lines)

        def __reduce__(self):
            return (self.__class__, (self.message, self.lineno, self.name, self.filename))
    class TemplateAssertionError(TemplateSyntaxError):
        """Like a template syntax error, but covers cases where something in the
        template caused an error at compile time that wasn't necessarily caused
        by a syntax error.  However it's a direct subclass of
        :exc:`TemplateSyntaxError` and has the same attributes.
        """
    class TemplateRuntimeError(TemplateError):
        """A generic runtime error in the template engine.  Under some situations
        Jinja may raise this exception.
        """
    class UndefinedError(TemplateRuntimeError):
        """Raised if a template tries to operate on :class:`Undefined`."""
    class SecurityError(TemplateRuntimeError):
        """Raised if a template tries to do something insecure if the
        sandbox is enabled.
        """
    class FilterArgumentError(TemplateRuntimeError):
        """This error is raised if a filter was called with inappropriate
        arguments
        """


preamble ext:
  source: jinja2/ext.py
  imports: |
    import pprint
    import re
    import typing as t
    from markupsafe import Markup
    from . import defaults
    from . import nodes
    from .environment import Environment
    from .exceptions import TemplateAssertionError
    from .exceptions import TemplateSyntaxError
    from .runtime import concat
    from .runtime import Context
    from .runtime import Undefined
    from .utils import import_string
    from .utils import pass_context
  constants: |
    GETTEXT_FUNCTIONS: t.Tuple[str, ...] = ('_', 'gettext', 'ngettext', 'pgettext', 'npgettext')
    _ws_re = re.compile('\\s*\\n\\s*')
    i18n = InternationalizationExtension
    do = ExprStmtExtension
    loopcontrols = LoopControlExtension
    debug = DebugExtension
  body: |
    'Extension API for adding custom tags and behavior.'
    if t.TYPE_CHECKING:
        import typing_extensions as te
        from .lexer import Token
        from .lexer import TokenStream
        from .parser import Parser

        class _TranslationsBasic(te.Protocol):
            pass

        class _TranslationsContext(_TranslationsBasic):
            pass
        _SupportedTranslations = t.Union[_TranslationsBasic, _TranslationsContext]
    class Extension:
        """Extensions can be used to add extra functionality to the Jinja template
        system at the parser level.  Custom extensions are bound to an environment
        but may not store environment specific data on `self`.  The reason for
        this is that an extension can be bound to another environment (for
        overlays) by creating a copy and reassigning the `environment` attribute.

        As extensions are created by the environment they cannot accept any
        arguments for configuration.  One may want to work around that by using
        a factory function, but that is not possible as extensions are identified
        by their import name.  The correct way to configure the extension is
        storing the configuration values on the environment.  Because this way the
        environment ends up acting as central configuration storage the
        attributes may clash which is why extensions have to ensure that the names
        they choose for configuration are not too generic.  ``prefix`` for example
        is a terrible name, ``fragment_cache_prefix`` on the other hand is a good
        name as includes the name of the extension (fragment cache).
        """
        identifier: t.ClassVar[str]

        def __init_subclass__(cls) -> None:
            cls.identifier = f'{cls.__module__}.{cls.__name__}'
        tags: t.Set[str] = set()
        priority = 100

        def __init__(self, environment: Environment) -> None:
            self.environment = environment

        def bind(self, environment: Environment) -> 'Extension':
            """Create a copy of this extension bound to another environment."""
            pass

        def preprocess(self, source: str, name: t.Optional[str], filename: t.Optional[str]=None) -> str:
            """This method is called before the actual lexing and can be used to
            preprocess the source.  The `filename` is optional.  The return value
            must be the preprocessed source.
            """
            pass

        def filter_stream(self, stream: 'TokenStream') -> t.Union['TokenStream', t.Iterable['Token']]:
            """It's passed a :class:`~jinja2.lexer.TokenStream` that can be used
            to filter tokens returned.  This method has to return an iterable of
            :class:`~jinja2.lexer.Token`\\s, but it doesn't have to return a
            :class:`~jinja2.lexer.TokenStream`.
            """
            pass

        def parse(self, parser: 'Parser') -> t.Union[nodes.Node, t.List[nodes.Node]]:
            """If any of the :attr:`tags` matched this method is called with the
            parser as first argument.  The token the parser stream is pointing at
            is the name token that matched.  This method has to return one or a
            list of multiple nodes.
            """
            pass

        def attr(self, name: str, lineno: t.Optional[int]=None) -> nodes.ExtensionAttribute:
            """Return an attribute node for the current extension.  This is useful
            to pass constants on extensions to generated template code.

            ::

                self.attr('_my_attribute', lineno=lineno)
            """
            pass

        def call_method(self, name: str, args: t.Optional[t.List[nodes.Expr]]=None, kwargs: t.Optional[t.List[nodes.Keyword]]=None, dyn_args: t.Optional[nodes.Expr]=None, dyn_kwargs: t.Optional[nodes.Expr]=None, lineno: t.Optional[int]=None) -> nodes.Call:
            """Call a method of the extension.  This is a shortcut for
            :meth:`attr` + :class:`jinja2.nodes.Call`.
            """
            pass
    class InternationalizationExtension(Extension):
        """This extension adds gettext support to Jinja."""
        tags = {'trans'}

        def __init__(self, environment: Environment) -> None:
            super().__init__(environment)
            environment.globals['_'] = _gettext_alias
            environment.extend(install_gettext_translations=self._install, install_null_translations=self._install_null, install_gettext_callables=self._install_callables, uninstall_gettext_translations=self._uninstall, extract_translations=self._extract, newstyle_gettext=False)

        def parse(self, parser: 'Parser') -> t.Union[nodes.Node, t.List[nodes.Node]]:
            """Parse a translatable tag."""
            pass

        def _parse_block(self, parser: 'Parser', allow_pluralize: bool) -> t.Tuple[t.List[str], str]:
            """Parse until the next block tag with a given name."""
            pass

        def _make_node(self, singular: str, plural: t.Optional[str], context: t.Optional[str], variables: t.Dict[str, nodes.Expr], plural_expr: t.Optional[nodes.Expr], vars_referenced: bool, num_called_num: bool) -> nodes.Output:
            """Generates a useful node from the data provided."""
            pass
    class ExprStmtExtension(Extension):
        """Adds a `do` tag to Jinja that works like the print statement just
        that it doesn't print the return value.
        """
        tags = {'do'}
    class LoopControlExtension(Extension):
        """Adds break and continue to the template engine."""
        tags = {'break', 'continue'}
    class DebugExtension(Extension):
        """A ``{% debug %}`` tag that dumps the available variables,
        filters, and tests.

        .. code-block:: html+jinja

            <pre>{% debug %}</pre>

        .. code-block:: text

            {'context': {'cycler': <class 'jinja2.utils.Cycler'>,
                         ...,
                         'namespace': <class 'jinja2.utils.Namespace'>},
             'filters': ['abs', 'attr', 'batch', 'capitalize', 'center', 'count', 'd',
                         ..., 'urlencode', 'urlize', 'wordcount', 'wordwrap', 'xmlattr'],
             'tests': ['!=', '<', '<=', '==', '>', '>=', 'callable', 'defined',
                       ..., 'odd', 'sameas', 'sequence', 'string', 'undefined', 'upper']}

        .. versionadded:: 2.11.0
        """
        tags = {'debug'}
    class _CommentFinder:
        """Helper class to find comments in a token stream.  Can only
        find comments for gettext calls forwards.  Once the comment
        from line 4 is found, a comment for line 1 will not return a
        usable value.
        """

        def __init__(self, tokens: t.Sequence[t.Tuple[int, str, str]], comment_tags: t.Sequence[str]) -> None:
            self.tokens = tokens
            self.comment_tags = comment_tags
            self.offset = 0
            self.last_lineno = 0


preamble filters:
  source: jinja2/filters.py
  imports: |
    import math
    import random
    import re
    import typing
    import typing as t
    from collections import abc
    from itertools import chain
    from itertools import groupby
    from markupsafe import escape
    from markupsafe import Markup
    from markupsafe import soft_str
    from .async_utils import async_variant
    from .async_utils import auto_aiter
    from .async_utils import auto_await
    from .async_utils import auto_to_list
    from .exceptions import FilterArgumentError
    from .runtime import Undefined
    from .utils import htmlsafe_json_dumps
    from .utils import pass_context
    from .utils import pass_environment
    from .utils import pass_eval_context
    from .utils import pformat
    from .utils import url_quote
    from .utils import urlize
  constants: |
    F = t.TypeVar('F', bound=t.Callable[..., t.Any])
    K = t.TypeVar('K')
    V = t.TypeVar('V')
    _attr_key_re = re.compile('[\\s/>=]', flags=re.ASCII)
    _word_beginning_split_re = re.compile('([-\\s({\\[<]+)')
    _uri_scheme_re = re.compile('^([\\w.+-]{2,}:(/){0,2})$')
    _word_re = re.compile('\\w+')
    FILTERS = {'abs': abs, 'attr': do_attr, 'batch': do_batch, 'capitalize': do_capitalize, 'center': do_center, 'count': len, 'd': do_default, 'default': do_default, 'dictsort': do_dictsort, 'e': escape, 'escape': escape, 'filesizeformat': do_filesizeformat, 'first': do_first, 'float': do_float, 'forceescape': do_forceescape, 'format': do_format, 'groupby': do_groupby, 'indent': do_indent, 'int': do_int, 'join': do_join, 'last': do_last, 'length': len, 'list': do_list, 'lower': do_lower, 'items': do_items, 'map': do_map, 'min': do_min, 'max': do_max, 'pprint': do_pprint, 'random': do_random, 'reject': do_reject, 'rejectattr': do_rejectattr, 'replace': do_replace, 'reverse': do_reverse, 'round': do_round, 'safe': do_mark_safe, 'select': do_select, 'selectattr': do_selectattr, 'slice': do_slice, 'sort': do_sort, 'string': soft_str, 'striptags': do_striptags, 'sum': do_sum, 'title': do_title, 'trim': do_trim, 'truncate': do_truncate, 'unique': do_unique, 'upper': do_upper, 'urlencode': do_urlencode, 'urlize': do_urlize, 'wordcount': do_wordcount, 'wordwrap': do_wordwrap, 'xmlattr': do_xmlattr, 'tojson': do_tojson}
  body: |
    'Built-in template filters used with the ``|`` operator.'
    if t.TYPE_CHECKING:
        import typing_extensions as te
        from .environment import Environment
        from .nodes import EvalContext
        from .runtime import Context
        from .sandbox import SandboxedEnvironment

        class HasHTML(te.Protocol):

            def __html__(self) -> str:
                pass
    class _GroupTuple(t.NamedTuple):
        grouper: t.Any
        list: t.List[t.Any]

        def __repr__(self) -> str:
            return tuple.__repr__(self)

        def __str__(self) -> str:
            return tuple.__str__(self)


preamble idtracking:
  source: jinja2/idtracking.py
  imports: |
    import typing as t
    from . import nodes
    from .visitor import NodeVisitor
  constants: |
    VAR_LOAD_PARAMETER = 'param'
    VAR_LOAD_RESOLVE = 'resolve'
    VAR_LOAD_ALIAS = 'alias'
    VAR_LOAD_UNDEFINED = 'undefined'
  body: |
    class Symbols:

        def __init__(self, parent: t.Optional['Symbols']=None, level: t.Optional[int]=None) -> None:
            if level is None:
                if parent is None:
                    level = 0
                else:
                    level = parent.level + 1
            self.level: int = level
            self.parent = parent
            self.refs: t.Dict[str, str] = {}
            self.loads: t.Dict[str, t.Any] = {}
            self.stores: t.Set[str] = set()
    class RootVisitor(NodeVisitor):

        def __init__(self, symbols: 'Symbols') -> None:
            self.sym_visitor = FrameSymbolVisitor(symbols)
        visit_Template = _simple_visit
        visit_Block = _simple_visit
        visit_Macro = _simple_visit
        visit_FilterBlock = _simple_visit
        visit_Scope = _simple_visit
        visit_If = _simple_visit
        visit_ScopedEvalContextModifier = _simple_visit
    class FrameSymbolVisitor(NodeVisitor):
        """A visitor for `Frame.inspect`."""

        def __init__(self, symbols: 'Symbols') -> None:
            self.symbols = symbols

        def visit_Name(self, node: nodes.Name, store_as_param: bool=False, **kwargs: t.Any) -> None:
            """All assignments to names go through this function."""
            pass

        def visit_Assign(self, node: nodes.Assign, **kwargs: t.Any) -> None:
            """Visit assignments in the correct order."""
            pass

        def visit_For(self, node: nodes.For, **kwargs: t.Any) -> None:
            """Visiting stops at for blocks.  However the block sequence
            is visited as part of the outer scope.
            """
            pass

        def visit_AssignBlock(self, node: nodes.AssignBlock, **kwargs: t.Any) -> None:
            """Stop visiting at block assigns."""
            pass

        def visit_Scope(self, node: nodes.Scope, **kwargs: t.Any) -> None:
            """Stop visiting at scopes."""
            pass

        def visit_Block(self, node: nodes.Block, **kwargs: t.Any) -> None:
            """Stop visiting at blocks."""
            pass

        def visit_OverlayScope(self, node: nodes.OverlayScope, **kwargs: t.Any) -> None:
            """Do not visit into overlay scopes."""
            pass


preamble loaders:
  source: jinja2/loaders.py
  imports: |
    import importlib.util
    import os
    import posixpath
    import sys
    import typing as t
    import weakref
    import zipimport
    from collections import abc
    from hashlib import sha1
    from importlib import import_module
    from types import ModuleType
    from .exceptions import TemplateNotFound
    from .utils import internalcode
  body: |
    'API and implementations for loading templates from different data\nsources.\n'
    if t.TYPE_CHECKING:
        from .environment import Environment
        from .environment import Template
    class BaseLoader:
        """Baseclass for all loaders.  Subclass this and override `get_source` to
        implement a custom loading mechanism.  The environment provides a
        `get_template` method that calls the loader's `load` method to get the
        :class:`Template` object.

        A very basic example for a loader that looks up templates on the file
        system could look like this::

            from jinja2 import BaseLoader, TemplateNotFound
            from os.path import join, exists, getmtime

            class MyLoader(BaseLoader):

                def __init__(self, path):
                    self.path = path

                def get_source(self, environment, template):
                    path = join(self.path, template)
                    if not exists(path):
                        raise TemplateNotFound(template)
                    mtime = getmtime(path)
                    with open(path) as f:
                        source = f.read()
                    return source, path, lambda: mtime == getmtime(path)
        """
        has_source_access = True

        def get_source(self, environment: 'Environment', template: str) -> t.Tuple[str, t.Optional[str], t.Optional[t.Callable[[], bool]]]:
            """Get the template source, filename and reload helper for a template.
            It's passed the environment and template name and has to return a
            tuple in the form ``(source, filename, uptodate)`` or raise a
            `TemplateNotFound` error if it can't locate the template.

            The source part of the returned tuple must be the source of the
            template as a string. The filename should be the name of the
            file on the filesystem if it was loaded from there, otherwise
            ``None``. The filename is used by Python for the tracebacks
            if no loader extension is used.

            The last item in the tuple is the `uptodate` function.  If auto
            reloading is enabled it's always called to check if the template
            changed.  No arguments are passed so the function must store the
            old state somewhere (for example in a closure).  If it returns `False`
            the template will be reloaded.
            """
            pass

        def list_templates(self) -> t.List[str]:
            """Iterates over all templates.  If the loader does not support that
            it should raise a :exc:`TypeError` which is the default behavior.
            """
            pass

        @internalcode
        def load(self, environment: 'Environment', name: str, globals: t.Optional[t.MutableMapping[str, t.Any]]=None) -> 'Template':
            """Loads a template.  This method looks up the template in the cache
            or loads one by calling :meth:`get_source`.  Subclasses should not
            override this method as loaders working on collections of other
            loaders (such as :class:`PrefixLoader` or :class:`ChoiceLoader`)
            will not call this method but `get_source` directly.
            """
            pass
    class FileSystemLoader(BaseLoader):
        """Load templates from a directory in the file system.

        The path can be relative or absolute. Relative paths are relative to
        the current working directory.

        .. code-block:: python

            loader = FileSystemLoader("templates")

        A list of paths can be given. The directories will be searched in
        order, stopping at the first matching template.

        .. code-block:: python

            loader = FileSystemLoader(["/override/templates", "/default/templates"])

        :param searchpath: A path, or list of paths, to the directory that
            contains the templates.
        :param encoding: Use this encoding to read the text from template
            files.
        :param followlinks: Follow symbolic links in the path.

        .. versionchanged:: 2.8
            Added the ``followlinks`` parameter.
        """

        def __init__(self, searchpath: t.Union[str, 'os.PathLike[str]', t.Sequence[t.Union[str, 'os.PathLike[str]']]], encoding: str='utf-8', followlinks: bool=False) -> None:
            if not isinstance(searchpath, abc.Iterable) or isinstance(searchpath, str):
                searchpath = [searchpath]
            self.searchpath = [os.fspath(p) for p in searchpath]
            self.encoding = encoding
            self.followlinks = followlinks
    class PackageLoader(BaseLoader):
        """Load templates from a directory in a Python package.

        :param package_name: Import name of the package that contains the
            template directory.
        :param package_path: Directory within the imported package that
            contains the templates.
        :param encoding: Encoding of template files.

        The following example looks up templates in the ``pages`` directory
        within the ``project.ui`` package.

        .. code-block:: python

            loader = PackageLoader("project.ui", "pages")

        Only packages installed as directories (standard pip behavior) or
        zip/egg files (less common) are supported. The Python API for
        introspecting data in packages is too limited to support other
        installation methods the way this loader requires.

        There is limited support for :pep:`420` namespace packages. The
        template directory is assumed to only be in one namespace
        contributor. Zip files contributing to a namespace are not
        supported.

        .. versionchanged:: 3.0
            No longer uses ``setuptools`` as a dependency.

        .. versionchanged:: 3.0
            Limited PEP 420 namespace package support.
        """

        def __init__(self, package_name: str, package_path: 'str'='templates', encoding: str='utf-8') -> None:
            package_path = os.path.normpath(package_path).rstrip(os.path.sep)
            if package_path == os.path.curdir:
                package_path = ''
            elif package_path[:2] == os.path.curdir + os.path.sep:
                package_path = package_path[2:]
            self.package_path = package_path
            self.package_name = package_name
            self.encoding = encoding
            import_module(package_name)
            spec = importlib.util.find_spec(package_name)
            assert spec is not None, 'An import spec was not found for the package.'
            loader = spec.loader
            assert loader is not None, 'A loader was not found for the package.'
            self._loader = loader
            self._archive = None
            template_root = None
            if isinstance(loader, zipimport.zipimporter):
                self._archive = loader.archive
                pkgdir = next(iter(spec.submodule_search_locations))
                template_root = os.path.join(pkgdir, package_path).rstrip(os.path.sep)
            else:
                roots: t.List[str] = []
                if spec.submodule_search_locations:
                    roots.extend(spec.submodule_search_locations)
                elif spec.origin is not None:
                    roots.append(os.path.dirname(spec.origin))
                for root in roots:
                    root = os.path.join(root, package_path)
                    if os.path.isdir(root):
                        template_root = root
                        break
            if template_root is None:
                raise ValueError(f'The {package_name!r} package was not installed in a way that PackageLoader understands.')
            self._template_root = template_root
    class DictLoader(BaseLoader):
        """Loads a template from a Python dict mapping template names to
        template source.  This loader is useful for unittesting:

        >>> loader = DictLoader({'index.html': 'source here'})

        Because auto reloading is rarely useful this is disabled per default.
        """

        def __init__(self, mapping: t.Mapping[str, str]) -> None:
            self.mapping = mapping
    class FunctionLoader(BaseLoader):
        """A loader that is passed a function which does the loading.  The
        function receives the name of the template and has to return either
        a string with the template source, a tuple in the form ``(source,
        filename, uptodatefunc)`` or `None` if the template does not exist.

        >>> def load_template(name):
        ...     if name == 'index.html':
        ...         return '...'
        ...
        >>> loader = FunctionLoader(load_template)

        The `uptodatefunc` is a function that is called if autoreload is enabled
        and has to return `True` if the template is still up to date.  For more
        details have a look at :meth:`BaseLoader.get_source` which has the same
        return value.
        """

        def __init__(self, load_func: t.Callable[[str], t.Optional[t.Union[str, t.Tuple[str, t.Optional[str], t.Optional[t.Callable[[], bool]]]]]]) -> None:
            self.load_func = load_func
    class PrefixLoader(BaseLoader):
        """A loader that is passed a dict of loaders where each loader is bound
        to a prefix.  The prefix is delimited from the template by a slash per
        default, which can be changed by setting the `delimiter` argument to
        something else::

            loader = PrefixLoader({
                'app1':     PackageLoader('mypackage.app1'),
                'app2':     PackageLoader('mypackage.app2')
            })

        By loading ``'app1/index.html'`` the file from the app1 package is loaded,
        by loading ``'app2/index.html'`` the file from the second.
        """

        def __init__(self, mapping: t.Mapping[str, BaseLoader], delimiter: str='/') -> None:
            self.mapping = mapping
            self.delimiter = delimiter
    class ChoiceLoader(BaseLoader):
        """This loader works like the `PrefixLoader` just that no prefix is
        specified.  If a template could not be found by one loader the next one
        is tried.

        >>> loader = ChoiceLoader([
        ...     FileSystemLoader('/path/to/user/templates'),
        ...     FileSystemLoader('/path/to/system/templates')
        ... ])

        This is useful if you want to allow users to override builtin templates
        from a different location.
        """

        def __init__(self, loaders: t.Sequence[BaseLoader]) -> None:
            self.loaders = loaders
    class _TemplateModule(ModuleType):
        """Like a normal module but with support for weak references"""
    class ModuleLoader(BaseLoader):
        """This loader loads templates from precompiled templates.

        Example usage:

        >>> loader = ChoiceLoader([
        ...     ModuleLoader('/path/to/compiled/templates'),
        ...     FileSystemLoader('/path/to/templates')
        ... ])

        Templates can be precompiled with :meth:`Environment.compile_templates`.
        """
        has_source_access = False

        def __init__(self, path: t.Union[str, 'os.PathLike[str]', t.Sequence[t.Union[str, 'os.PathLike[str]']]]) -> None:
            package_name = f'_jinja2_module_templates_{id(self):x}'
            mod = _TemplateModule(package_name)
            if not isinstance(path, abc.Iterable) or isinstance(path, str):
                path = [path]
            mod.__path__ = [os.fspath(p) for p in path]
            sys.modules[package_name] = weakref.proxy(mod, lambda x: sys.modules.pop(package_name, None))
            self.module = mod
            self.package_name = package_name


preamble meta:
  source: jinja2/meta.py
  imports: |
    import typing as t
    from . import nodes
    from .compiler import CodeGenerator
    from .compiler import Frame
  constants: |
    _ref_types = (nodes.Extends, nodes.FromImport, nodes.Import, nodes.Include)
    _RefType = t.Union[nodes.Extends, nodes.FromImport, nodes.Import, nodes.Include]
  body: |
    'Functions that expose information about templates that might be\ninteresting for introspection.\n'
    if t.TYPE_CHECKING:
        from .environment import Environment
    class TrackingCodeGenerator(CodeGenerator):
        """We abuse the code generator for introspection."""

        def __init__(self, environment: 'Environment') -> None:
            super().__init__(environment, '<introspection>', '<introspection>')
            self.undeclared_identifiers: t.Set[str] = set()

        def write(self, x: str) -> None:
            """Don't write."""
            pass

        def enter_frame(self, frame: Frame) -> None:
            """Remember all undeclared identifiers."""
            pass


preamble nativetypes:
  source: jinja2/nativetypes.py
  imports: |
    import typing as t
    from ast import literal_eval
    from ast import parse
    from itertools import chain
    from itertools import islice
    from types import GeneratorType
    from . import nodes
    from .compiler import CodeGenerator
    from .compiler import Frame
    from .compiler import has_safe_repr
    from .environment import Environment
    from .environment import Template
  body: |
    class NativeCodeGenerator(CodeGenerator):
        """A code generator which renders Python types by not adding
        ``str()`` around output nodes.
        """
    class NativeEnvironment(Environment):
        """An environment that renders templates to native Python types."""
        code_generator_class = NativeCodeGenerator
        concat = staticmethod(native_concat)
    class NativeTemplate(Template):
        environment_class = NativeEnvironment

        def render(self, *args: t.Any, **kwargs: t.Any) -> t.Any:
            """Render the template to produce a native Python type. If the
            result is a single node, its value is returned. Otherwise, the
            nodes are concatenated as strings. If the result can be parsed
            with :func:`ast.literal_eval`, the parsed value is returned.
            Otherwise, the string is returned.
            """
            pass
    NativeEnvironment.template_class = NativeTemplate


preamble optimizer:
  source: jinja2/optimizer.py
  imports: |
    import typing as t
    from . import nodes
    from .visitor import NodeTransformer
  body: |
    "The optimizer tries to constant fold expressions and modify the AST\nin place so that it should be faster to evaluate.\n\nBecause the AST does not contain all the scoping information and the\ncompiler has to find that out, we cannot do all the optimizations we\nwant. For example, loop unrolling doesn't work because unrolled loops\nwould have a different scope. The solution would be a second syntax tree\nthat stored the scoping rules.\n"
    if t.TYPE_CHECKING:
        from .environment import Environment
    class Optimizer(NodeTransformer):

        def __init__(self, environment: 't.Optional[Environment]') -> None:
            self.environment = environment


preamble parser:
  source: jinja2/parser.py
  imports: |
    import typing
    import typing as t
    from . import nodes
    from .exceptions import TemplateAssertionError
    from .exceptions import TemplateSyntaxError
    from .lexer import describe_token
    from .lexer import describe_token_expr
  constants: |
    _ImportInclude = t.TypeVar('_ImportInclude', nodes.Import, nodes.Include)
    _MacroCall = t.TypeVar('_MacroCall', nodes.Macro, nodes.CallBlock)
    _statement_keywords = frozenset(['for', 'if', 'block', 'extends', 'print', 'macro', 'include', 'from', 'import', 'set', 'with', 'autoescape'])
    _compare_operators = frozenset(['eq', 'ne', 'lt', 'lteq', 'gt', 'gteq'])
    _math_nodes: t.Dict[str, t.Type[nodes.Expr]] = {'add': nodes.Add, 'sub': nodes.Sub, 'mul': nodes.Mul, 'div': nodes.Div, 'floordiv': nodes.FloorDiv, 'mod': nodes.Mod}
  body: |
    'Parse tokens from the lexer into nodes for the compiler.'
    if t.TYPE_CHECKING:
        import typing_extensions as te
        from .environment import Environment
    class Parser:
        """This is the central parsing class Jinja uses.  It's passed to
        extensions and can be used to parse expressions or statements.
        """

        def __init__(self, environment: 'Environment', source: str, name: t.Optional[str]=None, filename: t.Optional[str]=None, state: t.Optional[str]=None) -> None:
            self.environment = environment
            self.stream = environment._tokenize(source, name, filename, state)
            self.name = name
            self.filename = filename
            self.closed = False
            self.extensions: t.Dict[str, t.Callable[['Parser'], t.Union[nodes.Node, t.List[nodes.Node]]]] = {}
            for extension in environment.iter_extensions():
                for tag in extension.tags:
                    self.extensions[tag] = extension.parse
            self._last_identifier = 0
            self._tag_stack: t.List[str] = []
            self._end_token_stack: t.List[t.Tuple[str, ...]] = []

        def fail(self, msg: str, lineno: t.Optional[int]=None, exc: t.Type[TemplateSyntaxError]=TemplateSyntaxError) -> 'te.NoReturn':
            """Convenience method that raises `exc` with the message, passed
            line number or last line number as well as the current name and
            filename.
            """
            pass

        def fail_unknown_tag(self, name: str, lineno: t.Optional[int]=None) -> 'te.NoReturn':
            """Called if the parser encounters an unknown tag.  Tries to fail
            with a human readable error message that could help to identify
            the problem.
            """
            pass

        def fail_eof(self, end_tokens: t.Optional[t.Tuple[str, ...]]=None, lineno: t.Optional[int]=None) -> 'te.NoReturn':
            """Like fail_unknown_tag but for end of template situations."""
            pass

        def is_tuple_end(self, extra_end_rules: t.Optional[t.Tuple[str, ...]]=None) -> bool:
            """Are we at the end of a tuple?"""
            pass

        def free_identifier(self, lineno: t.Optional[int]=None) -> nodes.InternalName:
            """Return a new free identifier as :class:`~jinja2.nodes.InternalName`."""
            pass

        def parse_statement(self) -> t.Union[nodes.Node, t.List[nodes.Node]]:
            """Parse a single statement."""
            pass

        def parse_statements(self, end_tokens: t.Tuple[str, ...], drop_needle: bool=False) -> t.List[nodes.Node]:
            """Parse multiple statements into a list until one of the end tokens
            is reached.  This is used to parse the body of statements as it also
            parses template data if appropriate.  The parser checks first if the
            current token is a colon and skips it if there is one.  Then it checks
            for the block end and parses until if one of the `end_tokens` is
            reached.  Per default the active token in the stream at the end of
            the call is the matched end token.  If this is not wanted `drop_needle`
            can be set to `True` and the end token is removed.
            """
            pass

        def parse_set(self) -> t.Union[nodes.Assign, nodes.AssignBlock]:
            """Parse an assign statement."""
            pass

        def parse_for(self) -> nodes.For:
            """Parse a for loop."""
            pass

        def parse_if(self) -> nodes.If:
            """Parse an if construct."""
            pass

        def parse_assign_target(self, with_tuple: bool=True, name_only: bool=False, extra_end_rules: t.Optional[t.Tuple[str, ...]]=None, with_namespace: bool=False) -> t.Union[nodes.NSRef, nodes.Name, nodes.Tuple]:
            """Parse an assignment target.  As Jinja allows assignments to
            tuples, this function can parse all allowed assignment targets.  Per
            default assignments to tuples are parsed, that can be disable however
            by setting `with_tuple` to `False`.  If only assignments to names are
            wanted `name_only` can be set to `True`.  The `extra_end_rules`
            parameter is forwarded to the tuple parsing function.  If
            `with_namespace` is enabled, a namespace assignment may be parsed.
            """
            pass

        def parse_expression(self, with_condexpr: bool=True) -> nodes.Expr:
            """Parse an expression.  Per default all expressions are parsed, if
            the optional `with_condexpr` parameter is set to `False` conditional
            expressions are not parsed.
            """
            pass

        def parse_tuple(self, simplified: bool=False, with_condexpr: bool=True, extra_end_rules: t.Optional[t.Tuple[str, ...]]=None, explicit_parentheses: bool=False) -> t.Union[nodes.Tuple, nodes.Expr]:
            """Works like `parse_expression` but if multiple expressions are
            delimited by a comma a :class:`~jinja2.nodes.Tuple` node is created.
            This method could also return a regular expression instead of a tuple
            if no commas where found.

            The default parsing mode is a full tuple.  If `simplified` is `True`
            only names and literals are parsed.  The `no_condexpr` parameter is
            forwarded to :meth:`parse_expression`.

            Because tuples do not require delimiters and may end in a bogus comma
            an extra hint is needed that marks the end of a tuple.  For example
            for loops support tuples between `for` and `in`.  In that case the
            `extra_end_rules` is set to ``['name:in']``.

            `explicit_parentheses` is true if the parsing was triggered by an
            expression in parentheses.  This is used to figure out if an empty
            tuple is a valid expression or not.
            """
            pass

        def parse(self) -> nodes.Template:
            """Parse the whole template into a `Template` node."""
            pass


preamble runtime:
  source: jinja2/runtime.py
  imports: |
    import functools
    import sys
    import typing as t
    from collections import abc
    from itertools import chain
    from markupsafe import escape
    from markupsafe import Markup
    from markupsafe import soft_str
    from .async_utils import auto_aiter
    from .async_utils import auto_await
    from .exceptions import TemplateNotFound
    from .exceptions import TemplateRuntimeError
    from .exceptions import UndefinedError
    from .nodes import EvalContext
    from .utils import _PassArg
    from .utils import concat
    from .utils import internalcode
    from .utils import missing
    from .utils import Namespace
    from .utils import object_type_repr
    from .utils import pass_eval_context
  constants: |
    V = t.TypeVar('V')
    F = t.TypeVar('F', bound=t.Callable[..., t.Any])
    exported = ['LoopContext', 'TemplateReference', 'Macro', 'Markup', 'TemplateRuntimeError', 'missing', 'escape', 'markup_join', 'str_join', 'identity', 'TemplateNotFound', 'Namespace', 'Undefined', 'internalcode']
    async_exported = ['AsyncLoopContext', 'auto_aiter', 'auto_await']
  body: |
    'The runtime functions and state used by compiled templates.'
    if t.TYPE_CHECKING:
        import logging
        import typing_extensions as te
        from .environment import Environment

        class LoopRenderFunc(te.Protocol):

            def __call__(self, reciter: t.Iterable[V], loop_render_func: 'LoopRenderFunc', depth: int=0) -> str:
                ...
    class TemplateReference:
        """The `self` in templates."""

        def __init__(self, context: 'Context') -> None:
            self.__context = context

        def __getitem__(self, name: str) -> t.Any:
            blocks = self.__context.blocks[name]
            return BlockReference(name, self.__context, blocks, 0)

        def __repr__(self) -> str:
            return f'<{type(self).__name__} {self.__context.name!r}>'
    @abc.Mapping.register
    class Context:
        """The template context holds the variables of a template.  It stores the
        values passed to the template and also the names the template exports.
        Creating instances is neither supported nor useful as it's created
        automatically at various stages of the template evaluation and should not
        be created by hand.

        The context is immutable.  Modifications on :attr:`parent` **must not**
        happen and modifications on :attr:`vars` are allowed from generated
        template code only.  Template filters and global functions marked as
        :func:`pass_context` get the active context passed as first argument
        and are allowed to access the context read-only.

        The template context supports read only dict operations (`get`,
        `keys`, `values`, `items`, `iterkeys`, `itervalues`, `iteritems`,
        `__getitem__`, `__contains__`).  Additionally there is a :meth:`resolve`
        method that doesn't fail with a `KeyError` but returns an
        :class:`Undefined` object for missing variables.
        """

        def __init__(self, environment: 'Environment', parent: t.Dict[str, t.Any], name: t.Optional[str], blocks: t.Dict[str, t.Callable[['Context'], t.Iterator[str]]], globals: t.Optional[t.MutableMapping[str, t.Any]]=None):
            self.parent = parent
            self.vars: t.Dict[str, t.Any] = {}
            self.environment: 'Environment' = environment
            self.eval_ctx = EvalContext(self.environment, name)
            self.exported_vars: t.Set[str] = set()
            self.name = name
            self.globals_keys = set() if globals is None else set(globals)
            self.blocks = {k: [v] for k, v in blocks.items()}

        def super(self, name: str, current: t.Callable[['Context'], t.Iterator[str]]) -> t.Union['BlockReference', 'Undefined']:
            """Render a parent block."""
            pass

        def get(self, key: str, default: t.Any=None) -> t.Any:
            """Look up a variable by name, or return a default if the key is
            not found.

            :param key: The variable name to look up.
            :param default: The value to return if the key is not found.
            """
            pass

        def resolve(self, key: str) -> t.Union[t.Any, 'Undefined']:
            """Look up a variable by name, or return an :class:`Undefined`
            object if the key is not found.

            If you need to add custom behavior, override
            :meth:`resolve_or_missing`, not this method. The various lookup
            functions use that method, not this one.

            :param key: The variable name to look up.
            """
            pass

        def resolve_or_missing(self, key: str) -> t.Any:
            """Look up a variable by name, or return a ``missing`` sentinel
            if the key is not found.

            Override this method to add custom lookup behavior.
            :meth:`resolve`, :meth:`get`, and :meth:`__getitem__` use this
            method. Don't call this method directly.

            :param key: The variable name to look up.
            """
            pass

        def get_exported(self) -> t.Dict[str, t.Any]:
            """Get a new dict with the exported variables."""
            pass

        def get_all(self) -> t.Dict[str, t.Any]:
            """Return the complete context as dict including the exported
            variables.  For optimizations reasons this might not return an
            actual copy so be careful with using it.
            """
            pass

        @internalcode
        def call(__self, __obj: t.Callable[..., t.Any], *args: t.Any, **kwargs: t.Any) -> t.Union[t.Any, 'Undefined']:
            """Call the callable with the arguments and keyword arguments
            provided but inject the active context or environment as first
            argument if the callable has :func:`pass_context` or
            :func:`pass_environment`.
            """
            pass

        def derived(self, locals: t.Optional[t.Dict[str, t.Any]]=None) -> 'Context':
            """Internal helper function to create a derived context.  This is
            used in situations where the system needs a new context in the same
            template that is independent.
            """
            pass
        keys = _dict_method_all(dict.keys)
        values = _dict_method_all(dict.values)
        items = _dict_method_all(dict.items)

        def __contains__(self, name: str) -> bool:
            return name in self.vars or name in self.parent

        def __getitem__(self, key: str) -> t.Any:
            """Look up a variable by name with ``[]`` syntax, or raise a
            ``KeyError`` if the key is not found.
            """
            item = self.resolve_or_missing(key)
            if item is missing:
                raise KeyError(key)
            return item

        def __repr__(self) -> str:
            return f'<{type(self).__name__} {self.get_all()!r} of {self.name!r}>'
    class BlockReference:
        """One block on a template reference."""

        def __init__(self, name: str, context: 'Context', stack: t.List[t.Callable[['Context'], t.Iterator[str]]], depth: int) -> None:
            self.name = name
            self._context = context
            self._stack = stack
            self._depth = depth

        @property
        def super(self) -> t.Union['BlockReference', 'Undefined']:
            """Super the block."""
            pass

        @internalcode
        def __call__(self) -> str:
            if self._context.environment.is_async:
                return self._async_call()
            rv = concat(self._stack[self._depth](self._context))
            if self._context.eval_ctx.autoescape:
                return Markup(rv)
            return rv
    class LoopContext:
        """A wrapper iterable for dynamic ``for`` loops, with information
        about the loop and iteration.
        """
        index0 = -1
        _length: t.Optional[int] = None
        _after: t.Any = missing
        _current: t.Any = missing
        _before: t.Any = missing
        _last_changed_value: t.Any = missing

        def __init__(self, iterable: t.Iterable[V], undefined: t.Type['Undefined'], recurse: t.Optional['LoopRenderFunc']=None, depth0: int=0) -> None:
            """
            :param iterable: Iterable to wrap.
            :param undefined: :class:`Undefined` class to use for next and
                previous items.
            :param recurse: The function to render the loop body when the
                loop is marked recursive.
            :param depth0: Incremented when looping recursively.
            """
            self._iterable = iterable
            self._iterator = self._to_iterator(iterable)
            self._undefined = undefined
            self._recurse = recurse
            self.depth0 = depth0

        @property
        def length(self) -> int:
            """Length of the iterable.

            If the iterable is a generator or otherwise does not have a
            size, it is eagerly evaluated to get a size.
            """
            pass

        def __len__(self) -> int:
            return self.length

        @property
        def depth(self) -> int:
            """How many levels deep a recursive loop currently is, starting at 1."""
            pass

        @property
        def index(self) -> int:
            """Current iteration of the loop, starting at 1."""
            pass

        @property
        def revindex0(self) -> int:
            """Number of iterations from the end of the loop, ending at 0.

            Requires calculating :attr:`length`.
            """
            pass

        @property
        def revindex(self) -> int:
            """Number of iterations from the end of the loop, ending at 1.

            Requires calculating :attr:`length`.
            """
            pass

        @property
        def first(self) -> bool:
            """Whether this is the first iteration of the loop."""
            pass

        def _peek_next(self) -> t.Any:
            """Return the next element in the iterable, or :data:`missing`
            if the iterable is exhausted. Only peeks one item ahead, caching
            the result in :attr:`_last` for use in subsequent checks. The
            cache is reset when :meth:`__next__` is called.
            """
            pass

        @property
        def last(self) -> bool:
            """Whether this is the last iteration of the loop.

            Causes the iterable to advance early. See
            :func:`itertools.groupby` for issues this can cause.
            The :func:`groupby` filter avoids that issue.
            """
            pass

        @property
        def previtem(self) -> t.Union[t.Any, 'Undefined']:
            """The item in the previous iteration. Undefined during the
            first iteration.
            """
            pass

        @property
        def nextitem(self) -> t.Union[t.Any, 'Undefined']:
            """The item in the next iteration. Undefined during the last
            iteration.

            Causes the iterable to advance early. See
            :func:`itertools.groupby` for issues this can cause.
            The :func:`jinja-filters.groupby` filter avoids that issue.
            """
            pass

        def cycle(self, *args: V) -> V:
            """Return a value from the given args, cycling through based on
            the current :attr:`index0`.

            :param args: One or more values to cycle through.
            """
            pass

        def changed(self, *value: t.Any) -> bool:
            """Return ``True`` if previously called with a different value
            (including when called for the first time).

            :param value: One or more values to compare to the last call.
            """
            pass

        def __iter__(self) -> 'LoopContext':
            return self

        def __next__(self) -> t.Tuple[t.Any, 'LoopContext']:
            if self._after is not missing:
                rv = self._after
                self._after = missing
            else:
                rv = next(self._iterator)
            self.index0 += 1
            self._before = self._current
            self._current = rv
            return (rv, self)

        @internalcode
        def __call__(self, iterable: t.Iterable[V]) -> str:
            """When iterating over nested data, render the body of the loop
            recursively with the given inner iterable data.

            The loop must have the ``recursive`` marker for this to work.
            """
            if self._recurse is None:
                raise TypeError("The loop must have the 'recursive' marker to be called recursively.")
            return self._recurse(iterable, self._recurse, depth=self.depth)

        def __repr__(self) -> str:
            return f'<{type(self).__name__} {self.index}/{self.length}>'
    class AsyncLoopContext(LoopContext):
        _iterator: t.AsyncIterator[t.Any]

        def __aiter__(self) -> 'AsyncLoopContext':
            return self

        async def __anext__(self) -> t.Tuple[t.Any, 'AsyncLoopContext']:
            if self._after is not missing:
                rv = self._after
                self._after = missing
            else:
                rv = await self._iterator.__anext__()
            self.index0 += 1
            self._before = self._current
            self._current = rv
            return (rv, self)
    class Macro:
        """Wraps a macro function."""

        def __init__(self, environment: 'Environment', func: t.Callable[..., str], name: str, arguments: t.List[str], catch_kwargs: bool, catch_varargs: bool, caller: bool, default_autoescape: t.Optional[bool]=None):
            self._environment = environment
            self._func = func
            self._argument_count = len(arguments)
            self.name = name
            self.arguments = arguments
            self.catch_kwargs = catch_kwargs
            self.catch_varargs = catch_varargs
            self.caller = caller
            self.explicit_caller = 'caller' in arguments
            if default_autoescape is None:
                if callable(environment.autoescape):
                    default_autoescape = environment.autoescape(None)
                else:
                    default_autoescape = environment.autoescape
            self._default_autoescape = default_autoescape

        @internalcode
        @pass_eval_context
        def __call__(self, *args: t.Any, **kwargs: t.Any) -> str:
            if args and isinstance(args[0], EvalContext):
                autoescape = args[0].autoescape
                args = args[1:]
            else:
                autoescape = self._default_autoescape
            arguments = list(args[:self._argument_count])
            off = len(arguments)
            found_caller = False
            if off != self._argument_count:
                for name in self.arguments[len(arguments):]:
                    try:
                        value = kwargs.pop(name)
                    except KeyError:
                        value = missing
                    if name == 'caller':
                        found_caller = True
                    arguments.append(value)
            else:
                found_caller = self.explicit_caller
            if self.caller and (not found_caller):
                caller = kwargs.pop('caller', None)
                if caller is None:
                    caller = self._environment.undefined('No caller defined', name='caller')
                arguments.append(caller)
            if self.catch_kwargs:
                arguments.append(kwargs)
            elif kwargs:
                if 'caller' in kwargs:
                    raise TypeError(f'macro {self.name!r} was invoked with two values for the special caller argument. This is most likely a bug.')
                raise TypeError(f'macro {self.name!r} takes no keyword argument {next(iter(kwargs))!r}')
            if self.catch_varargs:
                arguments.append(args[self._argument_count:])
            elif len(args) > self._argument_count:
                raise TypeError(f'macro {self.name!r} takes not more than {len(self.arguments)} argument(s)')
            return self._invoke(arguments, autoescape)

        def __repr__(self) -> str:
            name = 'anonymous' if self.name is None else repr(self.name)
            return f'<{type(self).__name__} {name}>'
    class Undefined:
        """The default undefined type.  This undefined type can be printed and
        iterated over, but every other access will raise an :exc:`UndefinedError`:

        >>> foo = Undefined(name='foo')
        >>> str(foo)
        ''
        >>> not foo
        True
        >>> foo + 42
        Traceback (most recent call last):
          ...
        jinja2.exceptions.UndefinedError: 'foo' is undefined
        """
        __slots__ = ('_undefined_hint', '_undefined_obj', '_undefined_name', '_undefined_exception')

        def __init__(self, hint: t.Optional[str]=None, obj: t.Any=missing, name: t.Optional[str]=None, exc: t.Type[TemplateRuntimeError]=UndefinedError) -> None:
            self._undefined_hint = hint
            self._undefined_obj = obj
            self._undefined_name = name
            self._undefined_exception = exc

        @property
        def _undefined_message(self) -> str:
            """Build a message about the undefined value based on how it was
            accessed.
            """
            pass

        @internalcode
        def _fail_with_undefined_error(self, *args: t.Any, **kwargs: t.Any) -> 'te.NoReturn':
            """Raise an :exc:`UndefinedError` when operations are performed
            on the undefined value.
            """
            pass

        @internalcode
        def __getattr__(self, name: str) -> t.Any:
            if name[:2] == '__':
                raise AttributeError(name)
            return self._fail_with_undefined_error()
        __add__ = __radd__ = __sub__ = __rsub__ = _fail_with_undefined_error
        __mul__ = __rmul__ = __div__ = __rdiv__ = _fail_with_undefined_error
        __truediv__ = __rtruediv__ = _fail_with_undefined_error
        __floordiv__ = __rfloordiv__ = _fail_with_undefined_error
        __mod__ = __rmod__ = _fail_with_undefined_error
        __pos__ = __neg__ = _fail_with_undefined_error
        __call__ = __getitem__ = _fail_with_undefined_error
        __lt__ = __le__ = __gt__ = __ge__ = _fail_with_undefined_error
        __int__ = __float__ = __complex__ = _fail_with_undefined_error
        __pow__ = __rpow__ = _fail_with_undefined_error

        def __eq__(self, other: t.Any) -> bool:
            return type(self) is type(other)

        def __ne__(self, other: t.Any) -> bool:
            return not self.__eq__(other)

        def __hash__(self) -> int:
            return id(type(self))

        def __str__(self) -> str:
            return ''

        def __len__(self) -> int:
            return 0

        def __iter__(self) -> t.Iterator[t.Any]:
            yield from ()

        async def __aiter__(self) -> t.AsyncIterator[t.Any]:
            for _ in ():
                yield

        def __bool__(self) -> bool:
            return False

        def __repr__(self) -> str:
            return 'Undefined'
    class ChainableUndefined(Undefined):
        """An undefined that is chainable, where both ``__getattr__`` and
        ``__getitem__`` return itself rather than raising an
        :exc:`UndefinedError`.

        >>> foo = ChainableUndefined(name='foo')
        >>> str(foo.bar['baz'])
        ''
        >>> foo.bar['baz'] + 42
        Traceback (most recent call last):
          ...
        jinja2.exceptions.UndefinedError: 'foo' is undefined

        .. versionadded:: 2.11.0
        """
        __slots__ = ()

        def __html__(self) -> str:
            return str(self)

        def __getattr__(self, _: str) -> 'ChainableUndefined':
            return self
        __getitem__ = __getattr__
    class DebugUndefined(Undefined):
        """An undefined that returns the debug info when printed.

        >>> foo = DebugUndefined(name='foo')
        >>> str(foo)
        '{{ foo }}'
        >>> not foo
        True
        >>> foo + 42
        Traceback (most recent call last):
          ...
        jinja2.exceptions.UndefinedError: 'foo' is undefined
        """
        __slots__ = ()

        def __str__(self) -> str:
            if self._undefined_hint:
                message = f'undefined value printed: {self._undefined_hint}'
            elif self._undefined_obj is missing:
                message = self._undefined_name
            else:
                message = f'no such element: {object_type_repr(self._undefined_obj)}[{self._undefined_name!r}]'
            return f'{{{{ {message} }}}}'
    class StrictUndefined(Undefined):
        """An undefined that barks on print and iteration as well as boolean
        tests and all kinds of comparisons.  In other words: you can do nothing
        with it except checking if it's defined using the `defined` test.

        >>> foo = StrictUndefined(name='foo')
        >>> str(foo)
        Traceback (most recent call last):
          ...
        jinja2.exceptions.UndefinedError: 'foo' is undefined
        >>> not foo
        Traceback (most recent call last):
          ...
        jinja2.exceptions.UndefinedError: 'foo' is undefined
        >>> foo + 42
        Traceback (most recent call last):
          ...
        jinja2.exceptions.UndefinedError: 'foo' is undefined
        """
        __slots__ = ()
        __iter__ = __str__ = __len__ = Undefined._fail_with_undefined_error
        __eq__ = __ne__ = __bool__ = __hash__ = Undefined._fail_with_undefined_error
        __contains__ = Undefined._fail_with_undefined_error


preamble sandbox:
  source: jinja2/sandbox.py
  imports: |
    import operator
    import types
    import typing as t
    from collections import abc
    from collections import deque
    from string import Formatter
    from _string import formatter_field_name_split
    from markupsafe import EscapeFormatter
    from markupsafe import Markup
    from .environment import Environment
    from .exceptions import SecurityError
    from .runtime import Context
    from .runtime import Undefined
  constants: |
    F = t.TypeVar('F', bound=t.Callable[..., t.Any])
    MAX_RANGE = 100000
    UNSAFE_FUNCTION_ATTRIBUTES: t.Set[str] = set()
    UNSAFE_METHOD_ATTRIBUTES: t.Set[str] = set()
    UNSAFE_GENERATOR_ATTRIBUTES = {'gi_frame', 'gi_code'}
    UNSAFE_COROUTINE_ATTRIBUTES = {'cr_frame', 'cr_code'}
    UNSAFE_ASYNC_GENERATOR_ATTRIBUTES = {'ag_code', 'ag_frame'}
    _mutable_spec: t.Tuple[t.Tuple[t.Type[t.Any], t.FrozenSet[str]], ...] = ((abc.MutableSet, frozenset(['add', 'clear', 'difference_update', 'discard', 'pop', 'remove', 'symmetric_difference_update', 'update'])), (abc.MutableMapping, frozenset(['clear', 'pop', 'popitem', 'setdefault', 'update'])), (abc.MutableSequence, frozenset(['append', 'reverse', 'insert', 'sort', 'extend', 'remove'])), (deque, frozenset(['append', 'appendleft', 'clear', 'extend', 'extendleft', 'pop', 'popleft', 'remove', 'rotate'])))
  body: |
    'A sandbox layer that ensures unsafe operations cannot be performed.\nUseful when the template itself comes from an untrusted source.\n'
    class SandboxedEnvironment(Environment):
        """The sandboxed environment.  It works like the regular environment but
        tells the compiler to generate sandboxed code.  Additionally subclasses of
        this environment may override the methods that tell the runtime what
        attributes or functions are safe to access.

        If the template tries to access insecure code a :exc:`SecurityError` is
        raised.  However also other exceptions may occur during the rendering so
        the caller has to ensure that all exceptions are caught.
        """
        sandboxed = True
        default_binop_table: t.Dict[str, t.Callable[[t.Any, t.Any], t.Any]] = {'+': operator.add, '-': operator.sub, '*': operator.mul, '/': operator.truediv, '//': operator.floordiv, '**': operator.pow, '%': operator.mod}
        default_unop_table: t.Dict[str, t.Callable[[t.Any], t.Any]] = {'+': operator.pos, '-': operator.neg}
        intercepted_binops: t.FrozenSet[str] = frozenset()
        intercepted_unops: t.FrozenSet[str] = frozenset()

        def __init__(self, *args: t.Any, **kwargs: t.Any) -> None:
            super().__init__(*args, **kwargs)
            self.globals['range'] = safe_range
            self.binop_table = self.default_binop_table.copy()
            self.unop_table = self.default_unop_table.copy()

        def is_safe_attribute(self, obj: t.Any, attr: str, value: t.Any) -> bool:
            """The sandboxed environment will call this method to check if the
            attribute of an object is safe to access.  Per default all attributes
            starting with an underscore are considered private as well as the
            special attributes of internal python objects as returned by the
            :func:`is_internal_attribute` function.
            """
            pass

        def is_safe_callable(self, obj: t.Any) -> bool:
            """Check if an object is safely callable. By default callables
            are considered safe unless decorated with :func:`unsafe`.

            This also recognizes the Django convention of setting
            ``func.alters_data = True``.
            """
            pass

        def call_binop(self, context: Context, operator: str, left: t.Any, right: t.Any) -> t.Any:
            """For intercepted binary operator calls (:meth:`intercepted_binops`)
            this function is executed instead of the builtin operator.  This can
            be used to fine tune the behavior of certain operators.

            .. versionadded:: 2.6
            """
            pass

        def call_unop(self, context: Context, operator: str, arg: t.Any) -> t.Any:
            """For intercepted unary operator calls (:meth:`intercepted_unops`)
            this function is executed instead of the builtin operator.  This can
            be used to fine tune the behavior of certain operators.

            .. versionadded:: 2.6
            """
            pass

        def getitem(self, obj: t.Any, argument: t.Union[str, t.Any]) -> t.Union[t.Any, Undefined]:
            """Subscribe an object from sandboxed code."""
            pass

        def getattr(self, obj: t.Any, attribute: str) -> t.Union[t.Any, Undefined]:
            """Subscribe an object from sandboxed code and prefer the
            attribute.  The attribute passed *must* be a bytestring.
            """
            pass

        def unsafe_undefined(self, obj: t.Any, attribute: str) -> Undefined:
            """Return an undefined object for unsafe attributes."""
            pass

        def format_string(self, s: str, args: t.Tuple[t.Any, ...], kwargs: t.Dict[str, t.Any], format_func: t.Optional[t.Callable[..., t.Any]]=None) -> str:
            """If a format call is detected, then this is routed through this
            method so that our safety sandbox can be used for it.
            """
            pass

        def call(__self, __context: Context, __obj: t.Any, *args: t.Any, **kwargs: t.Any) -> t.Any:
            """Call an object from sandboxed code."""
            pass
    class ImmutableSandboxedEnvironment(SandboxedEnvironment):
        """Works exactly like the regular `SandboxedEnvironment` but does not
        permit modifications on the builtin mutable objects `list`, `set`, and
        `dict` by using the :func:`modifies_known_mutable` function.
        """
    class SandboxedFormatter(Formatter):

        def __init__(self, env: Environment, **kwargs: t.Any) -> None:
            self._env = env
            super().__init__(**kwargs)
    class SandboxedEscapeFormatter(SandboxedFormatter, EscapeFormatter):
        pass


preamble tests:
  source: jinja2/tests.py
  imports: |
    import operator
    import typing as t
    from collections import abc
    from numbers import Number
    from .runtime import Undefined
    from .utils import pass_environment
  constants: |
    TESTS = {'odd': test_odd, 'even': test_even, 'divisibleby': test_divisibleby, 'defined': test_defined, 'undefined': test_undefined, 'filter': test_filter, 'test': test_test, 'none': test_none, 'boolean': test_boolean, 'false': test_false, 'true': test_true, 'integer': test_integer, 'float': test_float, 'lower': test_lower, 'upper': test_upper, 'string': test_string, 'mapping': test_mapping, 'number': test_number, 'sequence': test_sequence, 'iterable': test_iterable, 'callable': callable, 'sameas': test_sameas, 'escaped': test_escaped, 'in': test_in, '==': operator.eq, 'eq': operator.eq, 'equalto': operator.eq, '!=': operator.ne, 'ne': operator.ne, '>': operator.gt, 'gt': operator.gt, 'greaterthan': operator.gt, 'ge': operator.ge, '>=': operator.ge, '<': operator.lt, 'lt': operator.lt, 'lessthan': operator.lt, '<=': operator.le, 'le': operator.le}
  body: |
    'Built-in template tests used with the ``is`` operator.'
    if t.TYPE_CHECKING:
        from .environment import Environment


preamble utils:
  source: jinja2/utils.py
  imports: |
    import enum
    import json
    import os
    import re
    import typing as t
    from collections import abc
    from collections import deque
    from random import choice
    from random import randrange
    from threading import Lock
    from types import CodeType
    from urllib.parse import quote_from_bytes
    import markupsafe
  constants: |
    F = t.TypeVar('F', bound=t.Callable[..., t.Any])
    missing: t.Any = type('MissingType', (), {'__repr__': lambda x: 'missing'})()
    internal_code: t.MutableSet[CodeType] = set()
    concat = ''.join
    _http_re = re.compile('\n    ^\n    (\n        (https?://|www\\.)  # scheme or www\n        (([\\w%-]+\\.)+)?  # subdomain\n        (\n            [a-z]{2,63}  # basic tld\n        |\n            xn--[\\w%]{2,59}  # idna tld\n        )\n    |\n        ([\\w%-]{2,63}\\.)+  # basic domain\n        (com|net|int|edu|gov|org|info|mil)  # basic tld\n    |\n        (https?://)  # scheme\n        (\n            (([\\d]{1,3})(\\.[\\d]{1,3}){3})  # IPv4\n        |\n            (\\[([\\da-f]{0,4}:){2}([\\da-f]{0,4}:?){1,6}])  # IPv6\n        )\n    )\n    (?::[\\d]{1,5})?  # port\n    (?:[/?#]\\S*)?  # path, query, and fragment\n    $\n    ', re.IGNORECASE | re.VERBOSE)
    _email_re = re.compile('^\\S+@\\w[\\w.-]*\\.\\w+$')
  body: |
    if t.TYPE_CHECKING:
        import typing_extensions as te
    class _PassArg(enum.Enum):
        context = enum.auto()
        eval_context = enum.auto()
        environment = enum.auto()
    @abc.MutableMapping.register
    class LRUCache:
        """A simple LRU Cache implementation."""

        def __init__(self, capacity: int) -> None:
            self.capacity = capacity
            self._mapping: t.Dict[t.Any, t.Any] = {}
            self._queue: 'te.Deque[t.Any]' = deque()
            self._postinit()

        def __getstate__(self) -> t.Mapping[str, t.Any]:
            return {'capacity': self.capacity, '_mapping': self._mapping, '_queue': self._queue}

        def __setstate__(self, d: t.Mapping[str, t.Any]) -> None:
            self.__dict__.update(d)
            self._postinit()

        def __getnewargs__(self) -> t.Tuple[t.Any, ...]:
            return (self.capacity,)

        def copy(self) -> 'LRUCache':
            """Return a shallow copy of the instance."""
            pass

        def get(self, key: t.Any, default: t.Any=None) -> t.Any:
            """Return an item from the cache dict or `default`"""
            pass

        def setdefault(self, key: t.Any, default: t.Any=None) -> t.Any:
            """Set `default` if the key is not in the cache otherwise
            leave unchanged. Return the value of this key.
            """
            pass

        def clear(self) -> None:
            """Clear the cache."""
            pass

        def __contains__(self, key: t.Any) -> bool:
            """Check if a key exists in this cache."""
            return key in self._mapping

        def __len__(self) -> int:
            """Return the current size of the cache."""
            return len(self._mapping)

        def __repr__(self) -> str:
            return f'<{type(self).__name__} {self._mapping!r}>'

        def __getitem__(self, key: t.Any) -> t.Any:
            """Get an item from the cache. Moves the item up so that it has the
            highest priority then.

            Raise a `KeyError` if it does not exist.
            """
            with self._wlock:
                rv = self._mapping[key]
                if self._queue[-1] != key:
                    try:
                        self._remove(key)
                    except ValueError:
                        pass
                    self._append(key)
                return rv

        def __setitem__(self, key: t.Any, value: t.Any) -> None:
            """Sets the value for an item. Moves the item up so that it
            has the highest priority then.
            """
            with self._wlock:
                if key in self._mapping:
                    self._remove(key)
                elif len(self._mapping) == self.capacity:
                    del self._mapping[self._popleft()]
                self._append(key)
                self._mapping[key] = value

        def __delitem__(self, key: t.Any) -> None:
            """Remove an item from the cache dict.
            Raise a `KeyError` if it does not exist.
            """
            with self._wlock:
                del self._mapping[key]
                try:
                    self._remove(key)
                except ValueError:
                    pass

        def items(self) -> t.Iterable[t.Tuple[t.Any, t.Any]]:
            """Return a list of items."""
            pass

        def values(self) -> t.Iterable[t.Any]:
            """Return a list of all values."""
            pass

        def keys(self) -> t.Iterable[t.Any]:
            """Return a list of all keys ordered by most recent usage."""
            pass

        def __iter__(self) -> t.Iterator[t.Any]:
            return reversed(tuple(self._queue))

        def __reversed__(self) -> t.Iterator[t.Any]:
            """Iterate over the keys in the cache dict, oldest items
            coming first.
            """
            return iter(tuple(self._queue))
        __copy__ = copy
    class Cycler:
        """Cycle through values by yield them one at a time, then restarting
        once the end is reached. Available as ``cycler`` in templates.

        Similar to ``loop.cycle``, but can be used outside loops or across
        multiple loops. For example, render a list of folders and files in a
        list, alternating giving them "odd" and "even" classes.

        .. code-block:: html+jinja

            {% set row_class = cycler("odd", "even") %}
            <ul class="browser">
            {% for folder in folders %}
              <li class="folder {{ row_class.next() }}">{{ folder }}
            {% endfor %}
            {% for file in files %}
              <li class="file {{ row_class.next() }}">{{ file }}
            {% endfor %}
            </ul>

        :param items: Each positional argument will be yielded in the order
            given for each cycle.

        .. versionadded:: 2.1
        """

        def __init__(self, *items: t.Any) -> None:
            if not items:
                raise RuntimeError('at least one item has to be provided')
            self.items = items
            self.pos = 0

        def reset(self) -> None:
            """Resets the current item to the first item."""
            pass

        @property
        def current(self) -> t.Any:
            """Return the current item. Equivalent to the item that will be
            returned next time :meth:`next` is called.
            """
            pass

        def next(self) -> t.Any:
            """Return the current item, then advance :attr:`current` to the
            next item.
            """
            pass
        __next__ = next
    class Joiner:
        """A joining helper for templates."""

        def __init__(self, sep: str=', ') -> None:
            self.sep = sep
            self.used = False

        def __call__(self) -> str:
            if not self.used:
                self.used = True
                return ''
            return self.sep
    class Namespace:
        """A namespace object that can hold arbitrary attributes.  It may be
        initialized from a dictionary or with keyword arguments."""

        def __init__(*args: t.Any, **kwargs: t.Any) -> None:
            self, args = (args[0], args[1:])
            self.__attrs = dict(*args, **kwargs)

        def __getattribute__(self, name: str) -> t.Any:
            if name in {'_Namespace__attrs', '__class__'}:
                return object.__getattribute__(self, name)
            try:
                return self.__attrs[name]
            except KeyError:
                raise AttributeError(name) from None

        def __setitem__(self, name: str, value: t.Any) -> None:
            self.__attrs[name] = value

        def __repr__(self) -> str:
            return f'<Namespace {self.__attrs!r}>'


preamble visitor:
  source: jinja2/visitor.py
  imports: |
    import typing as t
    from .nodes import Node
  body: |
    'API for traversing the AST nodes. Implemented by the compiler and\nmeta introspection.\n'
    if t.TYPE_CHECKING:
        import typing_extensions as te

        class VisitCallable(te.Protocol):

            def __call__(self, node: Node, *args: t.Any, **kwargs: t.Any) -> t.Any:
                ...
    class NodeVisitor:
        """Walks the abstract syntax tree and call visitor functions for every
        node found.  The visitor functions may return values which will be
        forwarded by the `visit` method.

        Per default the visitor functions for the nodes are ``'visit_'`` +
        class name of the node.  So a `TryFinally` node visit function would
        be `visit_TryFinally`.  This behavior can be changed by overriding
        the `get_visitor` function.  If no visitor function exists for a node
        (return value `None`) the `generic_visit` visitor is used instead.
        """

        def get_visitor(self, node: Node) -> 't.Optional[VisitCallable]':
            """Return the visitor function for this node or `None` if no visitor
            exists for this node.  In that case the generic visit function is
            used instead.
            """
            pass

        def visit(self, node: Node, *args: t.Any, **kwargs: t.Any) -> t.Any:
            """Visit a node."""
            pass

        def generic_visit(self, node: Node, *args: t.Any, **kwargs: t.Any) -> t.Any:
            """Called if no explicit visitor function exists for a node."""
            pass
    class NodeTransformer(NodeVisitor):
        """Walks the abstract syntax tree and allows modifications of nodes.

        The `NodeTransformer` will walk the AST and use the return value of the
        visitor functions to replace or remove the old node.  If the return
        value of the visitor function is `None` the node will be removed
        from the previous location otherwise it's replaced with the return
        value.  The return value may be the original node in which case no
        replacement takes place.
        """

        def visit_list(self, node: Node, *args: t.Any, **kwargs: t.Any) -> t.List[Node]:
            """As transformers may return lists in some places this method
            can be used to enforce a list as return value.
            """
            pass


flow jinja_lib:
  steps:
    - bccache_group
    - compiler_group
    - debug_group
    - environment_group
    - ext_group
    - filters_group
    - idtracking_group
    - loaders_group
    - meta_group
    - nativetypes_group
    - optimizer_group
    - parser_group
    - runtime_group
    - sandbox_group
    - tests_group
    - utils_group
    - visitor_group


flow bccache_group:
  steps:
    - Bucket__reset
    - Bucket__load_bytecode
    - Bucket__write_bytecode
    - Bucket__bytecode_from_string
    - Bucket__bytecode_to_string
    - BytecodeCache__load_bytecode
    - BytecodeCache__dump_bytecode
    - BytecodeCache__clear
    - BytecodeCache__get_cache_key
    - BytecodeCache__get_source_checksum
    - BytecodeCache__get_bucket
    - BytecodeCache__set_bucket


flow compiler_group:
  steps:
    - generate
    - has_safe_repr
    - find_undeclared
    - Frame__copy
    - Frame__inner
    - Frame__soft
    - DependencyFinderVisitor__visit_Block
    - UndeclaredNameVisitor__visit_Block
    - CodeGenerator__fail
    - CodeGenerator__temporary_identifier
    - CodeGenerator__buffer
    - CodeGenerator__return_buffer_contents
    - CodeGenerator__indent
    - CodeGenerator__outdent
    - CodeGenerator__start_write
    - CodeGenerator__end_write
    - CodeGenerator__simple_write
    - CodeGenerator__blockvisit
    - CodeGenerator__write
    - CodeGenerator__writeline
    - CodeGenerator__newline
    - CodeGenerator__signature
    - CodeGenerator__pull_dependencies
    - CodeGenerator__macro_body
    - CodeGenerator__macro_def
    - CodeGenerator__position
    - CodeGenerator__write_commons
    - CodeGenerator__push_parameter_definitions
    - CodeGenerator__pop_parameter_definitions
    - CodeGenerator__mark_parameter_stored
    - CodeGenerator__parameter_is_undeclared
    - CodeGenerator__push_assign_tracking
    - CodeGenerator__pop_assign_tracking
    - CodeGenerator__visit_Block
    - CodeGenerator__visit_Extends
    - CodeGenerator__visit_Include
    - CodeGenerator__visit_Import
    - CodeGenerator__visit_FromImport
    - CodeGenerator___default_finalize
    - CodeGenerator___make_finalize
    - CodeGenerator___output_const_repr
    - CodeGenerator___output_child_to_const
    - CodeGenerator___output_child_pre
    - CodeGenerator___output_child_post


flow debug_group:
  steps:
    - rewrite_traceback_stack
    - fake_traceback
    - get_template_locals


flow environment_group:
  steps:
    - get_spontaneous_environment
    - create_cache
    - copy_cache
    - load_extensions
    - _environment_config_check
    - Environment__add_extension
    - Environment__extend
    - Environment__overlay
    - Environment__lexer
    - Environment__iter_extensions
    - Environment__getitem
    - Environment__getattr
    - Environment__call_filter
    - Environment__call_test
    - Environment__parse
    - Environment___parse
    - Environment__lex
    - Environment__preprocess
    - Environment___tokenize
    - Environment___generate
    - Environment___compile
    - Environment__compile
    - Environment__compile_expression
    - Environment__compile_templates
    - Environment__list_templates
    - Environment__handle_exception
    - Environment__join_path
    - Environment__get_template
    - Environment__select_template
    - Environment__get_or_select_template
    - Environment__from_string
    - Environment__make_globals
    - Template__from_code
    - Template__from_module_dict
    - Template__render
    - Template__render_async
    - Template__stream
    - Template__generate
    - Template__generate_async
    - Template__new_context
    - Template__make_module
    - Template__make_module_async
    - Template___get_default_module
    - Template__module
    - Template__get_corresponding_lineno
    - Template__is_up_to_date
    - Template__debug_info
    - TemplateStream__dump
    - TemplateStream__disable_buffering
    - TemplateStream__enable_buffering


flow ext_group:
  steps:
    - Extension__bind
    - Extension__preprocess
    - Extension__filter_stream
    - Extension__parse
    - Extension__attr
    - Extension__call_method
    - InternationalizationExtension__parse
    - InternationalizationExtension___parse_block
    - InternationalizationExtension___make_node
    - extract_from_ast
    - babel_extract


flow filters_group:
  steps:
    - ignore_case
    - make_attrgetter
    - make_multi_attrgetter
    - do_forceescape
    - do_urlencode
    - do_replace
    - do_upper
    - do_lower
    - do_items
    - do_xmlattr
    - do_capitalize
    - do_title
    - do_dictsort
    - do_sort
    - do_unique
    - do_min
    - do_max
    - do_default
    - sync_do_join
    - do_center
    - sync_do_first
    - do_last
    - do_random
    - do_filesizeformat
    - do_pprint
    - do_urlize
    - do_indent
    - do_truncate
    - do_wordwrap
    - do_wordcount
    - do_int
    - do_float
    - do_format
    - do_trim
    - do_striptags
    - sync_do_slice
    - do_batch
    - do_round
    - sync_do_groupby
    - sync_do_sum
    - sync_do_list
    - do_mark_safe
    - do_mark_unsafe
    - do_reverse
    - do_attr
    - sync_do_map
    - sync_do_select
    - sync_do_reject
    - sync_do_selectattr
    - sync_do_rejectattr
    - do_tojson


flow idtracking_group:
  steps:
    - FrameSymbolVisitor__visit_Name
    - FrameSymbolVisitor__visit_Assign
    - FrameSymbolVisitor__visit_For
    - FrameSymbolVisitor__visit_AssignBlock
    - FrameSymbolVisitor__visit_Scope
    - FrameSymbolVisitor__visit_Block
    - FrameSymbolVisitor__visit_OverlayScope


flow loaders_group:
  steps:
    - split_template_path
    - BaseLoader__get_source
    - BaseLoader__list_templates
    - BaseLoader__load


flow meta_group:
  steps:
    - TrackingCodeGenerator__write
    - TrackingCodeGenerator__enter_frame
    - find_undeclared_variables
    - find_referenced_templates


flow nativetypes_group:
  steps:
    - native_concat
    - NativeTemplate__render


flow optimizer_group:
  steps:
    - optimize


flow parser_group:
  steps:
    - Parser__fail
    - Parser__fail_unknown_tag
    - Parser__fail_eof
    - Parser__is_tuple_end
    - Parser__free_identifier
    - Parser__parse_statement
    - Parser__parse_statements
    - Parser__parse_set
    - Parser__parse_for
    - Parser__parse_if
    - Parser__parse_assign_target
    - Parser__parse_expression
    - Parser__parse_tuple
    - Parser__parse


flow runtime_group:
  steps:
    - identity
    - markup_join
    - str_join
    - new_context
    - Context__super
    - Context__get
    - Context__resolve
    - Context__resolve_or_missing
    - Context__get_exported
    - Context__get_all
    - Context__call
    - Context__derived
    - BlockReference__super
    - LoopContext__length
    - LoopContext__depth
    - LoopContext__index
    - LoopContext__revindex0
    - LoopContext__revindex
    - LoopContext__first
    - LoopContext___peek_next
    - LoopContext__last
    - LoopContext__previtem
    - LoopContext__nextitem
    - LoopContext__cycle
    - LoopContext__changed
    - Undefined___undefined_message
    - Undefined___fail_with_undefined_error
    - make_logging_undefined


flow sandbox_group:
  steps:
    - safe_range
    - unsafe
    - is_internal_attribute
    - modifies_known_mutable
    - SandboxedEnvironment__is_safe_attribute
    - SandboxedEnvironment__is_safe_callable
    - SandboxedEnvironment__call_binop
    - SandboxedEnvironment__call_unop
    - SandboxedEnvironment__getitem
    - SandboxedEnvironment__getattr
    - SandboxedEnvironment__unsafe_undefined
    - SandboxedEnvironment__format_string
    - SandboxedEnvironment__call


flow tests_group:
  steps:
    - test_odd
    - test_even
    - test_divisibleby
    - test_defined
    - test_undefined
    - test_filter
    - test_test
    - test_none
    - test_boolean
    - test_false
    - test_true
    - test_integer
    - test_float
    - test_lower
    - test_upper
    - test_string
    - test_mapping
    - test_number
    - test_sequence
    - test_sameas
    - test_iterable
    - test_escaped
    - test_in


flow utils_group:
  steps:
    - pass_context
    - pass_eval_context
    - pass_environment
    - internalcode
    - is_undefined
    - consume
    - clear_caches
    - import_string
    - open_if_exists
    - object_type_repr
    - pformat
    - urlize
    - generate_lorem_ipsum
    - url_quote
    - LRUCache__copy
    - LRUCache__get
    - LRUCache__setdefault
    - LRUCache__clear
    - LRUCache__items
    - LRUCache__values
    - LRUCache__keys
    - select_autoescape
    - htmlsafe_json_dumps
    - Cycler__reset
    - Cycler__current
    - Cycler__next


flow visitor_group:
  steps:
    - NodeVisitor__get_visitor
    - NodeVisitor__visit
    - NodeVisitor__generic_visit
    - NodeTransformer__visit_list


code Bucket__reset:
  body: |
    def reset(self):
        """Resets the bucket (unloads the bytecode)."""
        pass


code Bucket__load_bytecode:
  body: |
    def load_bytecode(self, f: t.BinaryIO):
        """Loads bytecode from a file or file like object."""
        pass


code Bucket__write_bytecode:
  body: |
    def write_bytecode(self, f: t.IO[bytes]):
        """Dump the bytecode into the file or file like object passed."""
        pass


code Bucket__bytecode_from_string:
  body: |
    def bytecode_from_string(self, string: bytes):
        """Load bytecode from bytes."""
        pass


code Bucket__bytecode_to_string:
  body: |
    def bytecode_to_string(self):
        """Return the bytecode as bytes."""
        pass


code BytecodeCache__load_bytecode:
  body: |
    def load_bytecode(self, bucket: Bucket):
        """Subclasses have to override this method to load bytecode into a
            bucket.  If they are not able to find code in the cache for the
            bucket, it must not do anything.
            
        """
        pass


code BytecodeCache__dump_bytecode:
  body: |
    def dump_bytecode(self, bucket: Bucket):
        """Subclasses have to override this method to write the bytecode
            from a bucket back to the cache.  If it unable to do so it must not
            fail silently but raise an exception.
            
        """
        pass


code BytecodeCache__clear:
  body: |
    def clear(self):
        """Clears the cache.  This method is not used by Jinja but should be
            implemented to allow applications to clear the bytecode cache used
            by a particular environment.
            
        """
        pass


code BytecodeCache__get_cache_key:
  body: |
    def get_cache_key(self, name: str, filename: t.Optional[t.Union[str]]=None):
        """Returns the unique hash key for this template name."""
        pass


code BytecodeCache__get_source_checksum:
  body: |
    def get_source_checksum(self, source: str):
        """Returns a checksum for the source."""
        pass


code BytecodeCache__get_bucket:
  body: |
    def get_bucket(self, environment: 'Environment', name: str, filename: t.Optional[str], source: str):
        """Return a cache bucket for the given template.  All arguments are
            mandatory but filename may be `None`.
            
        """
        pass


code BytecodeCache__set_bucket:
  body: |
    def set_bucket(self, bucket: Bucket):
        """Put the bucket into the cache."""
        pass


code generate:
  body: |
    def generate(node: nodes.Template, environment: 'Environment', name: t.Optional[str], filename: t.Optional[str], stream: t.Optional[t.TextIO]=None, defer_init: bool=False, optimized: bool=True):
        """Generate the python source for a node tree."""
        pass


code has_safe_repr:
  body: |
    def has_safe_repr(value: t.Any):
        """Does the node have a safe representation?"""
        pass


code find_undeclared:
  body: |
    def find_undeclared(nodes: t.Iterable[nodes.Node], names: t.Iterable[str]):
        """Check if the names passed are accessed undeclared.  The return value
        is a set of all the undeclared names from the sequence of names found.
        
        """
        pass


code Frame__copy:
  body: |
    def copy(self):
        """Create a copy of the current one."""
        pass


code Frame__inner:
  body: |
    def inner(self, isolated: bool=False):
        """Return an inner frame."""
        pass


code Frame__soft:
  body: |
    def soft(self):
        """Return a soft frame.  A soft frame may not be modified as
            standalone thing as it shares the resources with the frame it
            was created of, but it's not a rootlevel frame any longer.
    
            This is only used to implement if-statements and conditional
            expressions.
            
        """
        pass


code DependencyFinderVisitor__visit_Block:
  body: |
    def visit_Block(self, node: nodes.Block):
        """Stop visiting at blocks."""
        pass


code UndeclaredNameVisitor__visit_Block:
  body: |
    def visit_Block(self, node: nodes.Block):
        """Stop visiting a blocks."""
        pass


code CodeGenerator__fail:
  body: |
    def fail(self, msg: str, lineno: int):
        """Fail with a :exc:`TemplateAssertionError`."""
        pass


code CodeGenerator__temporary_identifier:
  body: |
    def temporary_identifier(self):
        """Get a new unique identifier."""
        pass


code CodeGenerator__buffer:
  body: |
    def buffer(self, frame: Frame):
        """Enable buffering for the frame from that point onwards."""
        pass


code CodeGenerator__return_buffer_contents:
  body: |
    def return_buffer_contents(self, frame: Frame, force_unescaped: bool=False):
        """Return the buffer contents of the frame."""
        pass


code CodeGenerator__indent:
  body: |
    def indent(self):
        """Indent by one."""
        pass


code CodeGenerator__outdent:
  body: |
    def outdent(self, step: int=1):
        """Outdent by step."""
        pass


code CodeGenerator__start_write:
  body: |
    def start_write(self, frame: Frame, node: t.Optional[nodes.Node]=None):
        """Yield or write into the frame buffer."""
        pass


code CodeGenerator__end_write:
  body: |
    def end_write(self, frame: Frame):
        """End the writing process started by `start_write`."""
        pass


code CodeGenerator__simple_write:
  body: |
    def simple_write(self, s: str, frame: Frame, node: t.Optional[nodes.Node]=None):
        """Simple shortcut for start_write + write + end_write."""
        pass


code CodeGenerator__blockvisit:
  body: |
    def blockvisit(self, nodes: t.Iterable[nodes.Node], frame: Frame):
        """Visit a list of nodes as block in a frame.  If the current frame
            is no buffer a dummy ``if 0: yield None`` is written automatically.
            
        """
        pass


code CodeGenerator__write:
  body: |
    def write(self, x: str):
        """Write a string into the output stream."""
        pass


code CodeGenerator__writeline:
  body: |
    def writeline(self, x: str, node: t.Optional[nodes.Node]=None, extra: int=0):
        """Combination of newline and write."""
        pass


code CodeGenerator__newline:
  body: |
    def newline(self, node: t.Optional[nodes.Node]=None, extra: int=0):
        """Add one or more newlines before the next write."""
        pass


code CodeGenerator__signature:
  body: |
    def signature(self, node: t.Union[nodes.Call, nodes.Filter, nodes.Test], frame: Frame, extra_kwargs: t.Optional[t.Mapping[str, t.Any]]=None):
        """Writes a function call to the stream for the current node.
            A leading comma is added automatically.  The extra keyword
            arguments may not include python keywords otherwise a syntax
            error could occur.  The extra keyword arguments should be given
            as python dict.
            
        """
        pass


code CodeGenerator__pull_dependencies:
  body: |
    def pull_dependencies(self, nodes: t.Iterable[nodes.Node]):
        """Find all filter and test names used in the template and
            assign them to variables in the compiled namespace. Checking
            that the names are registered with the environment is done when
            compiling the Filter and Test nodes. If the node is in an If or
            CondExpr node, the check is done at runtime instead.
    
            .. versionchanged:: 3.0
                Filters and tests in If and CondExpr nodes are checked at
                runtime instead of compile time.
            
        """
        pass


code CodeGenerator__macro_body:
  body: |
    def macro_body(self, node: t.Union[nodes.Macro, nodes.CallBlock], frame: Frame):
        """Dump the function def of a macro or call block."""
        pass


code CodeGenerator__macro_def:
  body: |
    def macro_def(self, macro_ref: MacroRef, frame: Frame):
        """Dump the macro definition for the def created by macro_body."""
        pass


code CodeGenerator__position:
  body: |
    def position(self, node: nodes.Node):
        """Return a human readable position for the node."""
        pass


code CodeGenerator__write_commons:
  body: |
    def write_commons(self):
        """Writes a common preamble that is used by root and block functions.
            Primarily this sets up common local helpers and enforces a generator
            through a dead branch.
            
        """
        pass


code CodeGenerator__push_parameter_definitions:
  body: |
    def push_parameter_definitions(self, frame: Frame):
        """Pushes all parameter targets from the given frame into a local
            stack that permits tracking of yet to be assigned parameters.  In
            particular this enables the optimization from `visit_Name` to skip
            undefined expressions for parameters in macros as macros can reference
            otherwise unbound parameters.
            
        """
        pass


code CodeGenerator__pop_parameter_definitions:
  body: |
    def pop_parameter_definitions(self):
        """Pops the current parameter definitions set."""
        pass


code CodeGenerator__mark_parameter_stored:
  body: |
    def mark_parameter_stored(self, target: str):
        """Marks a parameter in the current parameter definitions as stored.
            This will skip the enforced undefined checks.
            
        """
        pass


code CodeGenerator__parameter_is_undeclared:
  body: |
    def parameter_is_undeclared(self, target: str):
        """Checks if a given target is an undeclared parameter."""
        pass


code CodeGenerator__push_assign_tracking:
  body: |
    def push_assign_tracking(self):
        """Pushes a new layer for assignment tracking."""
        pass


code CodeGenerator__pop_assign_tracking:
  body: |
    def pop_assign_tracking(self, frame: Frame):
        """Pops the topmost level for assignment tracking and updates the
            context variables if necessary.
            
        """
        pass


code CodeGenerator__visit_Block:
  body: |
    def visit_Block(self, node: nodes.Block, frame: Frame):
        """Call a block and register it for the template."""
        pass


code CodeGenerator__visit_Extends:
  body: |
    def visit_Extends(self, node: nodes.Extends, frame: Frame):
        """Calls the extender."""
        pass


code CodeGenerator__visit_Include:
  body: |
    def visit_Include(self, node: nodes.Include, frame: Frame):
        """Handles includes."""
        pass


code CodeGenerator__visit_Import:
  body: |
    def visit_Import(self, node: nodes.Import, frame: Frame):
        """Visit regular imports."""
        pass


code CodeGenerator__visit_FromImport:
  body: |
    def visit_FromImport(self, node: nodes.FromImport, frame: Frame):
        """Visit named imports."""
        pass


code CodeGenerator___default_finalize:
  body: |
    def _default_finalize(value: t.Any):
        """The default finalize function if the environment isn't
            configured with one. Or, if the environment has one, this is
            called on that function's output for constants.
            
        """
        pass


code CodeGenerator___make_finalize:
  body: |
    def _make_finalize(self):
        """Build the finalize function to be used on constants and at
            runtime. Cached so it's only created once for all output nodes.
    
            Returns a ``namedtuple`` with the following attributes:
    
            ``const``
                A function to finalize constant data at compile time.
    
            ``src``
                Source code to output around nodes to be evaluated at
                runtime.
            
        """
        pass


code CodeGenerator___output_const_repr:
  body: |
    def _output_const_repr(self, group: t.Iterable[t.Any]):
        """Given a group of constant values converted from ``Output``
            child nodes, produce a string to write to the template module
            source.
            
        """
        pass


code CodeGenerator___output_child_to_const:
  body: |
    def _output_child_to_const(self, node: nodes.Expr, frame: Frame, finalize: _FinalizeInfo):
        """Try to optimize a child of an ``Output`` node by trying to
            convert it to constant, finalized data at compile time.
    
            If :exc:`Impossible` is raised, the node is not constant and
            will be evaluated at runtime. Any other exception will also be
            evaluated at runtime for easier debugging.
            
        """
        pass


code CodeGenerator___output_child_pre:
  body: |
    def _output_child_pre(self, node: nodes.Expr, frame: Frame, finalize: _FinalizeInfo):
        """Output extra source code before visiting a child of an
            ``Output`` node.
            
        """
        pass


code CodeGenerator___output_child_post:
  body: |
    def _output_child_post(self, node: nodes.Expr, frame: Frame, finalize: _FinalizeInfo):
        """Output extra source code after visiting a child of an
            ``Output`` node.
            
        """
        pass


code rewrite_traceback_stack:
  body: |
    def rewrite_traceback_stack(source: t.Optional[str]=None):
        """Rewrite the current exception to replace any tracebacks from
        within compiled template code with tracebacks that look like they
        came from the template source.
    
        This must be called within an ``except`` block.
    
        :param source: For ``TemplateSyntaxError``, the original source if
            known.
        :return: The original exception with the rewritten traceback.
        
        """
        pass


code fake_traceback:
  body: |
    def fake_traceback(exc_value: BaseException, tb: t.Optional[TracebackType], filename: str, lineno: int):
        """Produce a new traceback object that looks like it came from the
        template source instead of the compiled code. The filename, line
        number, and location name will point to the template, and the local
        variables will be the current template context.
    
        :param exc_value: The original exception to be re-raised to create
            the new traceback.
        :param tb: The original traceback to get the local variables and
            code info from.
        :param filename: The template filename.
        :param lineno: The line number in the template source.
        
        """
        pass


code get_template_locals:
  body: |
    def get_template_locals(real_locals: t.Mapping[str, t.Any]):
        """Based on the runtime locals, get the context that would be
        available at that point in the template.
        
        """
        pass


code get_spontaneous_environment:
  body: |
    def get_spontaneous_environment(cls: t.Type[_env_bound], *args: t.Any):
        """Return a new spontaneous environment. A spontaneous environment
        is used for templates created directly rather than through an
        existing environment.
    
        :param cls: Environment class to create.
        :param args: Positional arguments passed to environment.
        
        """
        pass


code create_cache:
  body: |
    def create_cache(size: int):
        """Return the cache class for the given size."""
        pass


code copy_cache:
  body: |
    def copy_cache(cache: t.Optional[t.MutableMapping[t.Any, t.Any]]):
        """Create an empty copy of the given cache."""
        pass


code load_extensions:
  body: |
    def load_extensions(environment: 'Environment', extensions: t.Sequence[t.Union[str, t.Type['Extension']]]):
        """Load the extensions from the list and bind it to the environment.
        Returns a dict of instantiated extensions.
        
        """
        pass


code _environment_config_check:
  body: |
    def _environment_config_check(environment: 'Environment'):
        """Perform a sanity check on the environment."""
        pass


code Environment__add_extension:
  body: |
    def add_extension(self, extension: t.Union[str, t.Type['Extension']]):
        """Adds an extension after the environment was created.
    
            .. versionadded:: 2.5
            
        """
        pass


code Environment__extend:
  body: |
    def extend(self, **attributes: t.Any):
        """Add the items to the instance of the environment if they do not exist
            yet.  This is used by :ref:`extensions <writing-extensions>` to register
            callbacks and configuration values without breaking inheritance.
            
        """
        pass


code Environment__overlay:
  body: |
    def overlay(self, block_start_string: str=missing, block_end_string: str=missing, variable_start_string: str=missing, variable_end_string: str=missing, comment_start_string: str=missing, comment_end_string: str=missing, line_statement_prefix: t.Optional[str]=missing, line_comment_prefix: t.Optional[str]=missing, trim_blocks: bool=missing, lstrip_blocks: bool=missing, newline_sequence: "te.Literal['\\n', '\\r\\n', '\\r']"=missing, keep_trailing_newline: bool=missing, extensions: t.Sequence[t.Union[str, t.Type['Extension']]]=missing, optimized: bool=missing, undefined: t.Type[Undefined]=missing, finalize: t.Optional[t.Callable[..., t.Any]]=missing, autoescape: t.Union[bool, t.Callable[[t.Optional[str]], bool]]=missing, loader: t.Optional['BaseLoader']=missing, cache_size: int=missing, auto_reload: bool=missing, bytecode_cache: t.Optional['BytecodeCache']=missing, enable_async: bool=False):
        """Create a new overlay environment that shares all the data with the
            current environment except for cache and the overridden attributes.
            Extensions cannot be removed for an overlayed environment.  An overlayed
            environment automatically gets all the extensions of the environment it
            is linked to plus optional extra extensions.
    
            Creating overlays should happen after the initial environment was set
            up completely.  Not all attributes are truly linked, some are just
            copied over so modifications on the original environment may not shine
            through.
    
            .. versionchanged:: 3.1.2
                Added the ``newline_sequence``,, ``keep_trailing_newline``,
                and ``enable_async`` parameters to match ``__init__``.
            
        """
        pass


code Environment__lexer:
  body: |
    def lexer(self):
        """The lexer for this environment."""
        pass


code Environment__iter_extensions:
  body: |
    def iter_extensions(self):
        """Iterates over the extensions by priority."""
        pass


code Environment__getitem:
  body: |
    def getitem(self, obj: t.Any, argument: t.Union[str, t.Any]):
        """Get an item or attribute of an object but prefer the item."""
        pass


code Environment__getattr:
  body: |
    def getattr(self, obj: t.Any, attribute: str):
        """Get an item or attribute of an object but prefer the attribute.
            Unlike :meth:`getitem` the attribute *must* be a string.
            
        """
        pass


code Environment__call_filter:
  body: |
    def call_filter(self, name: str, value: t.Any, args: t.Optional[t.Sequence[t.Any]]=None, kwargs: t.Optional[t.Mapping[str, t.Any]]=None, context: t.Optional[Context]=None, eval_ctx: t.Optional[EvalContext]=None):
        """Invoke a filter on a value the same way the compiler does.
    
            This might return a coroutine if the filter is running from an
            environment in async mode and the filter supports async
            execution. It's your responsibility to await this if needed.
    
            .. versionadded:: 2.7
            
        """
        pass


code Environment__call_test:
  body: |
    def call_test(self, name: str, value: t.Any, args: t.Optional[t.Sequence[t.Any]]=None, kwargs: t.Optional[t.Mapping[str, t.Any]]=None, context: t.Optional[Context]=None, eval_ctx: t.Optional[EvalContext]=None):
        """Invoke a test on a value the same way the compiler does.
    
            This might return a coroutine if the test is running from an
            environment in async mode and the test supports async execution.
            It's your responsibility to await this if needed.
    
            .. versionchanged:: 3.0
                Tests support ``@pass_context``, etc. decorators. Added
                the ``context`` and ``eval_ctx`` parameters.
    
            .. versionadded:: 2.7
            
        """
        pass


code Environment__parse:
  body: |
    def parse(self, source: str, name: t.Optional[str]=None, filename: t.Optional[str]=None):
        """Parse the sourcecode and return the abstract syntax tree.  This
            tree of nodes is used by the compiler to convert the template into
            executable source- or bytecode.  This is useful for debugging or to
            extract information from templates.
    
            If you are :ref:`developing Jinja extensions <writing-extensions>`
            this gives you a good overview of the node tree generated.
            
        """
        pass


code Environment___parse:
  body: |
    def _parse(self, source: str, name: t.Optional[str], filename: t.Optional[str]):
        """Internal parsing function used by `parse` and `compile`."""
        pass


code Environment__lex:
  body: |
    def lex(self, source: str, name: t.Optional[str]=None, filename: t.Optional[str]=None):
        """Lex the given sourcecode and return a generator that yields
            tokens as tuples in the form ``(lineno, token_type, value)``.
            This can be useful for :ref:`extension development <writing-extensions>`
            and debugging templates.
    
            This does not perform preprocessing.  If you want the preprocessing
            of the extensions to be applied you have to filter source through
            the :meth:`preprocess` method.
            
        """
        pass


code Environment__preprocess:
  body: |
    def preprocess(self, source: str, name: t.Optional[str]=None, filename: t.Optional[str]=None):
        """Preprocesses the source with all extensions.  This is automatically
            called for all parsing and compiling methods but *not* for :meth:`lex`
            because there you usually only want the actual source tokenized.
            
        """
        pass


code Environment___tokenize:
  body: |
    def _tokenize(self, source: str, name: t.Optional[str], filename: t.Optional[str]=None, state: t.Optional[str]=None):
        """Called by the parser to do the preprocessing and filtering
            for all the extensions.  Returns a :class:`~jinja2.lexer.TokenStream`.
            
        """
        pass


code Environment___generate:
  body: |
    def _generate(self, source: nodes.Template, name: t.Optional[str], filename: t.Optional[str], defer_init: bool=False):
        """Internal hook that can be overridden to hook a different generate
            method in.
    
            .. versionadded:: 2.5
            
        """
        pass


code Environment___compile:
  body: |
    def _compile(self, source: str, filename: str):
        """Internal hook that can be overridden to hook a different compile
            method in.
    
            .. versionadded:: 2.5
            
        """
        pass


code Environment__compile:
  body: |
    def compile(self, source: t.Union[str, nodes.Template], name: t.Optional[str]=None, filename: t.Optional[str]=None, raw: bool=False, defer_init: bool=False):
        """Compile a node or template source code.  The `name` parameter is
            the load name of the template after it was joined using
            :meth:`join_path` if necessary, not the filename on the file system.
            the `filename` parameter is the estimated filename of the template on
            the file system.  If the template came from a database or memory this
            can be omitted.
    
            The return value of this method is a python code object.  If the `raw`
            parameter is `True` the return value will be a string with python
            code equivalent to the bytecode returned otherwise.  This method is
            mainly used internally.
    
            `defer_init` is use internally to aid the module code generator.  This
            causes the generated code to be able to import without the global
            environment variable to be set.
    
            .. versionadded:: 2.4
               `defer_init` parameter added.
            
        """
        pass


code Environment__compile_expression:
  body: |
    def compile_expression(self, source: str, undefined_to_none: bool=True):
        """A handy helper method that returns a callable that accepts keyword
            arguments that appear as variables in the expression.  If called it
            returns the result of the expression.
    
            This is useful if applications want to use the same rules as Jinja
            in template "configuration files" or similar situations.
    
            Example usage:
    
            >>> env = Environment()
            >>> expr = env.compile_expression('foo == 42')
            >>> expr(foo=23)
            False
            >>> expr(foo=42)
            True
    
            Per default the return value is converted to `None` if the
            expression returns an undefined value.  This can be changed
            by setting `undefined_to_none` to `False`.
    
            >>> env.compile_expression('var')() is None
            True
            >>> env.compile_expression('var', undefined_to_none=False)()
            Undefined
    
            .. versionadded:: 2.1
            
        """
        pass


code Environment__compile_templates:
  body: |
    def compile_templates(self, target: t.Union[str, 'os.PathLike[str]'], extensions: t.Optional[t.Collection[str]]=None, filter_func: t.Optional[t.Callable[[str], bool]]=None, zip: t.Optional[str]='deflated', log_function: t.Optional[t.Callable[[str], None]]=None, ignore_errors: bool=True):
        """Finds all the templates the loader can find, compiles them
            and stores them in `target`.  If `zip` is `None`, instead of in a
            zipfile, the templates will be stored in a directory.
            By default a deflate zip algorithm is used. To switch to
            the stored algorithm, `zip` can be set to ``'stored'``.
    
            `extensions` and `filter_func` are passed to :meth:`list_templates`.
            Each template returned will be compiled to the target folder or
            zipfile.
    
            By default template compilation errors are ignored.  In case a
            log function is provided, errors are logged.  If you want template
            syntax errors to abort the compilation you can set `ignore_errors`
            to `False` and you will get an exception on syntax errors.
    
            .. versionadded:: 2.4
            
        """
        pass


code Environment__list_templates:
  body: |
    def list_templates(self, extensions: t.Optional[t.Collection[str]]=None, filter_func: t.Optional[t.Callable[[str], bool]]=None):
        """Returns a list of templates for this environment.  This requires
            that the loader supports the loader's
            :meth:`~BaseLoader.list_templates` method.
    
            If there are other files in the template folder besides the
            actual templates, the returned list can be filtered.  There are two
            ways: either `extensions` is set to a list of file extensions for
            templates, or a `filter_func` can be provided which is a callable that
            is passed a template name and should return `True` if it should end up
            in the result list.
    
            If the loader does not support that, a :exc:`TypeError` is raised.
    
            .. versionadded:: 2.4
            
        """
        pass


code Environment__handle_exception:
  body: |
    def handle_exception(self, source: t.Optional[str]=None):
        """Exception handling helper.  This is used internally to either raise
            rewritten exceptions or return a rendered traceback for the template.
            
        """
        pass


code Environment__join_path:
  body: |
    def join_path(self, template: str, parent: str):
        """Join a template with the parent.  By default all the lookups are
            relative to the loader root so this method returns the `template`
            parameter unchanged, but if the paths should be relative to the
            parent template, this function can be used to calculate the real
            template name.
    
            Subclasses may override this method and implement template path
            joining here.
            
        """
        pass


code Environment__get_template:
  body: |
    def get_template(self, name: t.Union[str, 'Template'], parent: t.Optional[str]=None, globals: t.Optional[t.MutableMapping[str, t.Any]]=None):
        """Load a template by name with :attr:`loader` and return a
            :class:`Template`. If the template does not exist a
            :exc:`TemplateNotFound` exception is raised.
    
            :param name: Name of the template to load. When loading
                templates from the filesystem, "/" is used as the path
                separator, even on Windows.
            :param parent: The name of the parent template importing this
                template. :meth:`join_path` can be used to implement name
                transformations with this.
            :param globals: Extend the environment :attr:`globals` with
                these extra variables available for all renders of this
                template. If the template has already been loaded and
                cached, its globals are updated with any new items.
    
            .. versionchanged:: 3.0
                If a template is loaded from cache, ``globals`` will update
                the template's globals instead of ignoring the new values.
    
            .. versionchanged:: 2.4
                If ``name`` is a :class:`Template` object it is returned
                unchanged.
            
        """
        pass


code Environment__select_template:
  body: |
    def select_template(self, names: t.Iterable[t.Union[str, 'Template']], parent: t.Optional[str]=None, globals: t.Optional[t.MutableMapping[str, t.Any]]=None):
        """Like :meth:`get_template`, but tries loading multiple names.
            If none of the names can be loaded a :exc:`TemplatesNotFound`
            exception is raised.
    
            :param names: List of template names to try loading in order.
            :param parent: The name of the parent template importing this
                template. :meth:`join_path` can be used to implement name
                transformations with this.
            :param globals: Extend the environment :attr:`globals` with
                these extra variables available for all renders of this
                template. If the template has already been loaded and
                cached, its globals are updated with any new items.
    
            .. versionchanged:: 3.0
                If a template is loaded from cache, ``globals`` will update
                the template's globals instead of ignoring the new values.
    
            .. versionchanged:: 2.11
                If ``names`` is :class:`Undefined`, an :exc:`UndefinedError`
                is raised instead. If no templates were found and ``names``
                contains :class:`Undefined`, the message is more helpful.
    
            .. versionchanged:: 2.4
                If ``names`` contains a :class:`Template` object it is
                returned unchanged.
    
            .. versionadded:: 2.3
            
        """
        pass


code Environment__get_or_select_template:
  body: |
    def get_or_select_template(self, template_name_or_list: t.Union[str, 'Template', t.List[t.Union[str, 'Template']]], parent: t.Optional[str]=None, globals: t.Optional[t.MutableMapping[str, t.Any]]=None):
        """Use :meth:`select_template` if an iterable of template names
            is given, or :meth:`get_template` if one name is given.
    
            .. versionadded:: 2.3
            
        """
        pass


code Environment__from_string:
  body: |
    def from_string(self, source: t.Union[str, nodes.Template], globals: t.Optional[t.MutableMapping[str, t.Any]]=None, template_class: t.Optional[t.Type['Template']]=None):
        """Load a template from a source string without using
            :attr:`loader`.
    
            :param source: Jinja source to compile into a template.
            :param globals: Extend the environment :attr:`globals` with
                these extra variables available for all renders of this
                template. If the template has already been loaded and
                cached, its globals are updated with any new items.
            :param template_class: Return an instance of this
                :class:`Template` class.
            
        """
        pass


code Environment__make_globals:
  body: |
    def make_globals(self, d: t.Optional[t.MutableMapping[str, t.Any]]):
        """Make the globals map for a template. Any given template
            globals overlay the environment :attr:`globals`.
    
            Returns a :class:`collections.ChainMap`. This allows any changes
            to a template's globals to only affect that template, while
            changes to the environment's globals are still reflected.
            However, avoid modifying any globals after a template is loaded.
    
            :param d: Dict of template-specific globals.
    
            .. versionchanged:: 3.0
                Use :class:`collections.ChainMap` to always prevent mutating
                environment globals.
            
        """
        pass


code Template__from_code:
  body: |
    def from_code(cls, environment: Environment, code: CodeType, globals: t.MutableMapping[str, t.Any], uptodate: t.Optional[t.Callable[[], bool]]=None):
        """Creates a template object from compiled code and the globals.  This
            is used by the loaders and environment to create a template object.
            
        """
        pass


code Template__from_module_dict:
  body: |
    def from_module_dict(cls, environment: Environment, module_dict: t.MutableMapping[str, t.Any], globals: t.MutableMapping[str, t.Any]):
        """Creates a template object from a module.  This is used by the
            module loader to create a template object.
    
            .. versionadded:: 2.4
            
        """
        pass


code Template__render:
  body: |
    def render(self, *args: t.Any, **kwargs: t.Any):
        """This method accepts the same arguments as the `dict` constructor:
            A dict, a dict subclass or some keyword arguments.  If no arguments
            are given the context will be empty.  These two calls do the same::
    
                template.render(knights='that say nih')
                template.render({'knights': 'that say nih'})
    
            This will return the rendered template as a string.
            
        """
        pass


code Template__render_async:
  body: |
    def render_async(self, *args: t.Any, **kwargs: t.Any):
        """This works similar to :meth:`render` but returns a coroutine
            that when awaited returns the entire rendered template string.  This
            requires the async feature to be enabled.
    
            Example usage::
    
                await template.render_async(knights='that say nih; asynchronously')
            
        """
        pass


code Template__stream:
  body: |
    def stream(self, *args: t.Any, **kwargs: t.Any):
        """Works exactly like :meth:`generate` but returns a
            :class:`TemplateStream`.
            
        """
        pass


code Template__generate:
  body: |
    def generate(self, *args: t.Any, **kwargs: t.Any):
        """For very large templates it can be useful to not render the whole
            template at once but evaluate each statement after another and yield
            piece for piece.  This method basically does exactly that and returns
            a generator that yields one item after another as strings.
    
            It accepts the same arguments as :meth:`render`.
            
        """
        pass


code Template__generate_async:
  body: |
    def generate_async(self, *args: t.Any, **kwargs: t.Any):
        """An async version of :meth:`generate`.  Works very similarly but
            returns an async iterator instead.
            
        """
        pass


code Template__new_context:
  body: |
    def new_context(self, vars: t.Optional[t.Dict[str, t.Any]]=None, shared: bool=False, locals: t.Optional[t.Mapping[str, t.Any]]=None):
        """Create a new :class:`Context` for this template.  The vars
            provided will be passed to the template.  Per default the globals
            are added to the context.  If shared is set to `True` the data
            is passed as is to the context without adding the globals.
    
            `locals` can be a dict of local variables for internal usage.
            
        """
        pass


code Template__make_module:
  body: |
    def make_module(self, vars: t.Optional[t.Dict[str, t.Any]]=None, shared: bool=False, locals: t.Optional[t.Mapping[str, t.Any]]=None):
        """This method works like the :attr:`module` attribute when called
            without arguments but it will evaluate the template on every call
            rather than caching it.  It's also possible to provide
            a dict which is then used as context.  The arguments are the same
            as for the :meth:`new_context` method.
            
        """
        pass


code Template__make_module_async:
  body: |
    def make_module_async(self, vars: t.Optional[t.Dict[str, t.Any]]=None, shared: bool=False, locals: t.Optional[t.Mapping[str, t.Any]]=None):
        """As template module creation can invoke template code for
            asynchronous executions this method must be used instead of the
            normal :meth:`make_module` one.  Likewise the module attribute
            becomes unavailable in async mode.
            
        """
        pass


code Template___get_default_module:
  body: |
    def _get_default_module(self, ctx: t.Optional[Context]=None):
        """If a context is passed in, this means that the template was
            imported. Imported templates have access to the current
            template's globals by default, but they can only be accessed via
            the context during runtime.
    
            If there are new globals, we need to create a new module because
            the cached module is already rendered and will not have access
            to globals from the current context. This new module is not
            cached because the template can be imported elsewhere, and it
            should have access to only the current template's globals.
            
        """
        pass


code Template__module:
  body: |
    def module(self):
        """The template as module.  This is used for imports in the
            template runtime but is also useful if one wants to access
            exported template variables from the Python layer:
    
            >>> t = Template('{% macro foo() %}42{% endmacro %}23')
            >>> str(t.module)
            '23'
            >>> t.module.foo() == u'42'
            True
    
            This attribute is not available if async mode is enabled.
            
        """
        pass


code Template__get_corresponding_lineno:
  body: |
    def get_corresponding_lineno(self, lineno: int):
        """Return the source line number of a line number in the
            generated bytecode as they are not in sync.
            
        """
        pass


code Template__is_up_to_date:
  body: |
    def is_up_to_date(self):
        """If this variable is `False` there is a newer version available."""
        pass


code Template__debug_info:
  body: |
    def debug_info(self):
        """The debug info mapping."""
        pass


code TemplateStream__dump:
  body: |
    def dump(self, fp: t.Union[str, t.IO[bytes]], encoding: t.Optional[str]=None, errors: t.Optional[str]='strict'):
        """Dump the complete stream into a file or file-like object.
            Per default strings are written, if you want to encode
            before writing specify an `encoding`.
    
            Example usage::
    
                Template('Hello {{ name }}!').stream(name='foo').dump('hello.html')
            
        """
        pass


code TemplateStream__disable_buffering:
  body: |
    def disable_buffering(self):
        """Disable the output buffering."""
        pass


code TemplateStream__enable_buffering:
  body: |
    def enable_buffering(self, size: int=5):
        """Enable buffering.  Buffer `size` items before yielding them."""
        pass


code Extension__bind:
  body: |
    def bind(self, environment: Environment):
        """Create a copy of this extension bound to another environment."""
        pass


code Extension__preprocess:
  body: |
    def preprocess(self, source: str, name: t.Optional[str], filename: t.Optional[str]=None):
        """This method is called before the actual lexing and can be used to
            preprocess the source.  The `filename` is optional.  The return value
            must be the preprocessed source.
            
        """
        pass


code Extension__filter_stream:
  body: |
    def filter_stream(self, stream: 'TokenStream'):
        """It's passed a :class:`~jinja2.lexer.TokenStream` that can be used
            to filter tokens returned.  This method has to return an iterable of
            :class:`~jinja2.lexer.Token`\s, but it doesn't have to return a
            :class:`~jinja2.lexer.TokenStream`.
            
        """
        pass


code Extension__parse:
  body: |
    def parse(self, parser: 'Parser'):
        """If any of the :attr:`tags` matched this method is called with the
            parser as first argument.  The token the parser stream is pointing at
            is the name token that matched.  This method has to return one or a
            list of multiple nodes.
            
        """
        pass


code Extension__attr:
  body: |
    def attr(self, name: str, lineno: t.Optional[int]=None):
        """Return an attribute node for the current extension.  This is useful
            to pass constants on extensions to generated template code.
    
            ::
    
                self.attr('_my_attribute', lineno=lineno)
            
        """
        pass


code Extension__call_method:
  body: |
    def call_method(self, name: str, args: t.Optional[t.List[nodes.Expr]]=None, kwargs: t.Optional[t.List[nodes.Keyword]]=None, dyn_args: t.Optional[nodes.Expr]=None, dyn_kwargs: t.Optional[nodes.Expr]=None, lineno: t.Optional[int]=None):
        """Call a method of the extension.  This is a shortcut for
            :meth:`attr` + :class:`jinja2.nodes.Call`.
            
        """
        pass


code InternationalizationExtension__parse:
  body: |
    def parse(self, parser: 'Parser'):
        """Parse a translatable tag."""
        pass


code InternationalizationExtension___parse_block:
  body: |
    def _parse_block(self, parser: 'Parser', allow_pluralize: bool):
        """Parse until the next block tag with a given name."""
        pass


code InternationalizationExtension___make_node:
  body: |
    def _make_node(self, singular: str, plural: t.Optional[str], context: t.Optional[str], variables: t.Dict[str, nodes.Expr], plural_expr: t.Optional[nodes.Expr], vars_referenced: bool, num_called_num: bool):
        """Generates a useful node from the data provided."""
        pass


code extract_from_ast:
  body: |
    def extract_from_ast(ast: nodes.Template, gettext_functions: t.Sequence[str]=GETTEXT_FUNCTIONS, babel_style: bool=True):
        """Extract localizable strings from the given template node.  Per
        default this function returns matches in babel style that means non string
        parameters as well as keyword arguments are returned as `None`.  This
        allows Babel to figure out what you really meant if you are using
        gettext functions that allow keyword arguments for placeholder expansion.
        If you don't want that behavior set the `babel_style` parameter to `False`
        which causes only strings to be returned and parameters are always stored
        in tuples.  As a consequence invalid gettext calls (calls without a single
        string parameter or string parameters after non-string parameters) are
        skipped.
    
        This example explains the behavior:
    
        >>> from jinja2 import Environment
        >>> env = Environment()
        >>> node = env.parse('{{ (_("foo"), _(), ngettext("foo", "bar", 42)) }}')
        >>> list(extract_from_ast(node))
        [(1, '_', 'foo'), (1, '_', ()), (1, 'ngettext', ('foo', 'bar', None))]
        >>> list(extract_from_ast(node, babel_style=False))
        [(1, '_', ('foo',)), (1, 'ngettext', ('foo', 'bar'))]
    
        For every string found this function yields a ``(lineno, function,
        message)`` tuple, where:
    
        * ``lineno`` is the number of the line on which the string was found,
        * ``function`` is the name of the ``gettext`` function used (if the
          string was extracted from embedded Python code), and
        *   ``message`` is the string, or a tuple of strings for functions
             with multiple string arguments.
    
        This extraction function operates on the AST and is because of that unable
        to extract any comments.  For comment support you have to use the babel
        extraction interface or extract comments yourself.
        
        """
        pass


code babel_extract:
  body: |
    def babel_extract(fileobj: t.BinaryIO, keywords: t.Sequence[str], comment_tags: t.Sequence[str], options: t.Dict[str, t.Any]):
        """Babel extraction method for Jinja templates.
    
        .. versionchanged:: 2.3
           Basic support for translation comments was added.  If `comment_tags`
           is now set to a list of keywords for extraction, the extractor will
           try to find the best preceding comment that begins with one of the
           keywords.  For best results, make sure to not have more than one
           gettext call in one line of code and the matching comment in the
           same line or the line before.
    
        .. versionchanged:: 2.5.1
           The `newstyle_gettext` flag can be set to `True` to enable newstyle
           gettext calls.
    
        .. versionchanged:: 2.7
           A `silent` option can now be provided.  If set to `False` template
           syntax errors are propagated instead of being ignored.
    
        :param fileobj: the file-like object the messages should be extracted from
        :param keywords: a list of keywords (i.e. function names) that should be
                         recognized as translation functions
        :param comment_tags: a list of translator tags to search for and include
                             in the results.
        :param options: a dictionary of additional options (optional)
        :return: an iterator over ``(lineno, funcname, message, comments)`` tuples.
                 (comments will be empty currently)
        
        """
        pass


code ignore_case:
  body: |
    def ignore_case(value: V):
        """For use as a postprocessor for :func:`make_attrgetter`. Converts strings
        to lowercase and returns other types as-is.
        """
        pass


code make_attrgetter:
  body: |
    def make_attrgetter(environment: 'Environment', attribute: t.Optional[t.Union[str, int]], postprocess: t.Optional[t.Callable[[t.Any], t.Any]]=None, default: t.Optional[t.Any]=None):
        """Returns a callable that looks up the given attribute from a
        passed object with the rules of the environment.  Dots are allowed
        to access attributes of attributes.  Integer parts in paths are
        looked up as integers.
        
        """
        pass


code make_multi_attrgetter:
  body: |
    def make_multi_attrgetter(environment: 'Environment', attribute: t.Optional[t.Union[str, int]], postprocess: t.Optional[t.Callable[[t.Any], t.Any]]=None):
        """Returns a callable that looks up the given comma separated
        attributes from a passed object with the rules of the environment.
        Dots are allowed to access attributes of each attribute.  Integer
        parts in paths are looked up as integers.
    
        The value returned by the returned callable is a list of extracted
        attribute values.
    
        Examples of attribute: "attr1,attr2", "attr1.inner1.0,attr2.inner2.0", etc.
        
        """
        pass


code do_forceescape:
  body: |
    def do_forceescape(value: 't.Union[str, HasHTML]'):
        """Enforce HTML escaping.  This will probably double escape variables."""
        pass


code do_urlencode:
  body: |
    def do_urlencode(value: t.Union[str, t.Mapping[str, t.Any], t.Iterable[t.Tuple[str, t.Any]]]):
        """Quote data for use in a URL path or query using UTF-8.
    
        Basic wrapper around :func:`urllib.parse.quote` when given a
        string, or :func:`urllib.parse.urlencode` for a dict or iterable.
    
        :param value: Data to quote. A string will be quoted directly. A
            dict or iterable of ``(key, value)`` pairs will be joined as a
            query string.
    
        When given a string, "/" is not quoted. HTTP servers treat "/" and
        "%2F" equivalently in paths. If you need quoted slashes, use the
        ``|replace("/", "%2F")`` filter.
    
        .. versionadded:: 2.7
        
        """
        pass


code do_replace:
  body: |
    def do_replace(eval_ctx: 'EvalContext', s: str, old: str, new: str, count: t.Optional[int]=None):
        """Return a copy of the value with all occurrences of a substring
        replaced with a new one. The first argument is the substring
        that should be replaced, the second is the replacement string.
        If the optional third argument ``count`` is given, only the first
        ``count`` occurrences are replaced:
    
        .. sourcecode:: jinja
    
            {{ "Hello World"|replace("Hello", "Goodbye") }}
                -> Goodbye World
    
            {{ "aaaaargh"|replace("a", "d'oh, ", 2) }}
                -> d'oh, d'oh, aaargh
        
        """
        pass


code do_upper:
  body: |
    def do_upper(s: str):
        """Convert a value to uppercase."""
        pass


code do_lower:
  body: |
    def do_lower(s: str):
        """Convert a value to lowercase."""
        pass


code do_items:
  body: |
    def do_items(value: t.Union[t.Mapping[K, V], Undefined]):
        """Return an iterator over the ``(key, value)`` items of a mapping.
    
        ``x|items`` is the same as ``x.items()``, except if ``x`` is
        undefined an empty iterator is returned.
    
        This filter is useful if you expect the template to be rendered with
        an implementation of Jinja in another programming language that does
        not have a ``.items()`` method on its mapping type.
    
        .. code-block:: html+jinja
    
            <dl>
            {% for key, value in my_dict|items %}
                <dt>{{ key }}
                <dd>{{ value }}
            {% endfor %}
            </dl>
    
        .. versionadded:: 3.1
        
        """
        pass


code do_xmlattr:
  body: |
    def do_xmlattr(eval_ctx: 'EvalContext', d: t.Mapping[str, t.Any], autospace: bool=True):
        """Create an SGML/XML attribute string based on the items in a dict.
    
        **Values** that are neither ``none`` nor ``undefined`` are automatically
        escaped, safely allowing untrusted user input.
    
        User input should not be used as **keys** to this filter. If any key
        contains a space, ``/`` solidus, ``>`` greater-than sign, or ``=`` equals
        sign, this fails with a ``ValueError``. Regardless of this, user input
        should never be used as keys to this filter, or must be separately validated
        first.
    
        .. sourcecode:: html+jinja
    
            <ul{{ {'class': 'my_list', 'missing': none,
                    'id': 'list-%d'|format(variable)}|xmlattr }}>
            ...
            </ul>
    
        Results in something like this:
    
        .. sourcecode:: html
    
            <ul class="my_list" id="list-42">
            ...
            </ul>
    
        As you can see it automatically prepends a space in front of the item
        if the filter returned something unless the second parameter is false.
    
        .. versionchanged:: 3.1.4
            Keys with ``/`` solidus, ``>`` greater-than sign, or ``=`` equals sign
            are not allowed.
    
        .. versionchanged:: 3.1.3
            Keys with spaces are not allowed.
        
        """
        pass


code do_capitalize:
  body: |
    def do_capitalize(s: str):
        """Capitalize a value. The first character will be uppercase, all others
        lowercase.
        
        """
        pass


code do_title:
  body: |
    def do_title(s: str):
        """Return a titlecased version of the value. I.e. words will start with
        uppercase letters, all remaining characters are lowercase.
        
        """
        pass


code do_dictsort:
  body: |
    def do_dictsort(value: t.Mapping[K, V], case_sensitive: bool=False, by: 'te.Literal["key", "value"]'='key', reverse: bool=False):
        """Sort a dict and yield (key, value) pairs. Python dicts may not
        be in the order you want to display them in, so sort them first.
    
        .. sourcecode:: jinja
    
            {% for key, value in mydict|dictsort %}
                sort the dict by key, case insensitive
    
            {% for key, value in mydict|dictsort(reverse=true) %}
                sort the dict by key, case insensitive, reverse order
    
            {% for key, value in mydict|dictsort(true) %}
                sort the dict by key, case sensitive
    
            {% for key, value in mydict|dictsort(false, 'value') %}
                sort the dict by value, case insensitive
        
        """
        pass


code do_sort:
  body: |
    def do_sort(environment: 'Environment', value: 't.Iterable[V]', reverse: bool=False, case_sensitive: bool=False, attribute: t.Optional[t.Union[str, int]]=None):
        """Sort an iterable using Python's :func:`sorted`.
    
        .. sourcecode:: jinja
    
            {% for city in cities|sort %}
                ...
            {% endfor %}
    
        :param reverse: Sort descending instead of ascending.
        :param case_sensitive: When sorting strings, sort upper and lower
            case separately.
        :param attribute: When sorting objects or dicts, an attribute or
            key to sort by. Can use dot notation like ``"address.city"``.
            Can be a list of attributes like ``"age,name"``.
    
        The sort is stable, it does not change the relative order of
        elements that compare equal. This makes it is possible to chain
        sorts on different attributes and ordering.
    
        .. sourcecode:: jinja
    
            {% for user in users|sort(attribute="name")
                |sort(reverse=true, attribute="age") %}
                ...
            {% endfor %}
    
        As a shortcut to chaining when the direction is the same for all
        attributes, pass a comma separate list of attributes.
    
        .. sourcecode:: jinja
    
            {% for user in users|sort(attribute="age,name") %}
                ...
            {% endfor %}
    
        .. versionchanged:: 2.11.0
            The ``attribute`` parameter can be a comma separated list of
            attributes, e.g. ``"age,name"``.
    
        .. versionchanged:: 2.6
           The ``attribute`` parameter was added.
        
        """
        pass


code do_unique:
  body: |
    def do_unique(environment: 'Environment', value: 't.Iterable[V]', case_sensitive: bool=False, attribute: t.Optional[t.Union[str, int]]=None):
        """Returns a list of unique items from the given iterable.
    
        .. sourcecode:: jinja
    
            {{ ['foo', 'bar', 'foobar', 'FooBar']|unique|list }}
                -> ['foo', 'bar', 'foobar']
    
        The unique items are yielded in the same order as their first occurrence in
        the iterable passed to the filter.
    
        :param case_sensitive: Treat upper and lower case strings as distinct.
        :param attribute: Filter objects with unique values for this attribute.
        
        """
        pass


code do_min:
  body: |
    def do_min(environment: 'Environment', value: 't.Iterable[V]', case_sensitive: bool=False, attribute: t.Optional[t.Union[str, int]]=None):
        """Return the smallest item from the sequence.
    
        .. sourcecode:: jinja
    
            {{ [1, 2, 3]|min }}
                -> 1
    
        :param case_sensitive: Treat upper and lower case strings as distinct.
        :param attribute: Get the object with the min value of this attribute.
        
        """
        pass


code do_max:
  body: |
    def do_max(environment: 'Environment', value: 't.Iterable[V]', case_sensitive: bool=False, attribute: t.Optional[t.Union[str, int]]=None):
        """Return the largest item from the sequence.
    
        .. sourcecode:: jinja
    
            {{ [1, 2, 3]|max }}
                -> 3
    
        :param case_sensitive: Treat upper and lower case strings as distinct.
        :param attribute: Get the object with the max value of this attribute.
        
        """
        pass


code do_default:
  body: |
    def do_default(value: V, default_value: V='', boolean: bool=False):
        """If the value is undefined it will return the passed default value,
        otherwise the value of the variable:
    
        .. sourcecode:: jinja
    
            {{ my_variable|default('my_variable is not defined') }}
    
        This will output the value of ``my_variable`` if the variable was
        defined, otherwise ``'my_variable is not defined'``. If you want
        to use default with variables that evaluate to false you have to
        set the second parameter to `true`:
    
        .. sourcecode:: jinja
    
            {{ ''|default('the string was empty', true) }}
    
        .. versionchanged:: 2.11
           It's now possible to configure the :class:`~jinja2.Environment` with
           :class:`~jinja2.ChainableUndefined` to make the `default` filter work
           on nested elements and attributes that may contain undefined values
           in the chain without getting an :exc:`~jinja2.UndefinedError`.
        
        """
        pass


code sync_do_join:
  body: |
    def sync_do_join(eval_ctx: 'EvalContext', value: t.Iterable[t.Any], d: str='', attribute: t.Optional[t.Union[str, int]]=None):
        """Return a string which is the concatenation of the strings in the
        sequence. The separator between elements is an empty string per
        default, you can define it with the optional parameter:
    
        .. sourcecode:: jinja
    
            {{ [1, 2, 3]|join('|') }}
                -> 1|2|3
    
            {{ [1, 2, 3]|join }}
                -> 123
    
        It is also possible to join certain attributes of an object:
    
        .. sourcecode:: jinja
    
            {{ users|join(', ', attribute='username') }}
    
        .. versionadded:: 2.6
           The `attribute` parameter was added.
        
        """
        pass


code do_center:
  body: |
    def do_center(value: str, width: int=80):
        """Centers the value in a field of a given width."""
        pass


code sync_do_first:
  body: |
    def sync_do_first(environment: 'Environment', seq: 't.Iterable[V]'):
        """Return the first item of a sequence."""
        pass


code do_last:
  body: |
    def do_last(environment: 'Environment', seq: 't.Reversible[V]'):
        """Return the last item of a sequence.
    
        Note: Does not work with generators. You may want to explicitly
        convert it to a list:
    
        .. sourcecode:: jinja
    
            {{ data | selectattr('name', '==', 'Jinja') | list | last }}
        
        """
        pass


code do_random:
  body: |
    def do_random(context: 'Context', seq: 't.Sequence[V]'):
        """Return a random item from the sequence."""
        pass


code do_filesizeformat:
  body: |
    def do_filesizeformat(value: t.Union[str, float, int], binary: bool=False):
        """Format the value like a 'human-readable' file size (i.e. 13 kB,
        4.1 MB, 102 Bytes, etc).  Per default decimal prefixes are used (Mega,
        Giga, etc.), if the second parameter is set to `True` the binary
        prefixes are used (Mebi, Gibi).
        
        """
        pass


code do_pprint:
  body: |
    def do_pprint(value: t.Any):
        """Pretty print a variable. Useful for debugging."""
        pass


code do_urlize:
  body: |
    def do_urlize(eval_ctx: 'EvalContext', value: str, trim_url_limit: t.Optional[int]=None, nofollow: bool=False, target: t.Optional[str]=None, rel: t.Optional[str]=None, extra_schemes: t.Optional[t.Iterable[str]]=None):
        """Convert URLs in text into clickable links.
    
        This may not recognize links in some situations. Usually, a more
        comprehensive formatter, such as a Markdown library, is a better
        choice.
    
        Works on ``http://``, ``https://``, ``www.``, ``mailto:``, and email
        addresses. Links with trailing punctuation (periods, commas, closing
        parentheses) and leading punctuation (opening parentheses) are
        recognized excluding the punctuation. Email addresses that include
        header fields are not recognized (for example,
        ``mailto:address@example.com?cc=copy@example.com``).
    
        :param value: Original text containing URLs to link.
        :param trim_url_limit: Shorten displayed URL values to this length.
        :param nofollow: Add the ``rel=nofollow`` attribute to links.
        :param target: Add the ``target`` attribute to links.
        :param rel: Add the ``rel`` attribute to links.
        :param extra_schemes: Recognize URLs that start with these schemes
            in addition to the default behavior. Defaults to
            ``env.policies["urlize.extra_schemes"]``, which defaults to no
            extra schemes.
    
        .. versionchanged:: 3.0
            The ``extra_schemes`` parameter was added.
    
        .. versionchanged:: 3.0
            Generate ``https://`` links for URLs without a scheme.
    
        .. versionchanged:: 3.0
            The parsing rules were updated. Recognize email addresses with
            or without the ``mailto:`` scheme. Validate IP addresses. Ignore
            parentheses and brackets in more cases.
    
        .. versionchanged:: 2.8
           The ``target`` parameter was added.
        
        """
        pass


code do_indent:
  body: |
    def do_indent(s: str, width: t.Union[int, str]=4, first: bool=False, blank: bool=False):
        """Return a copy of the string with each line indented by 4 spaces. The
        first line and blank lines are not indented by default.
    
        :param width: Number of spaces, or a string, to indent by.
        :param first: Don't skip indenting the first line.
        :param blank: Don't skip indenting empty lines.
    
        .. versionchanged:: 3.0
            ``width`` can be a string.
    
        .. versionchanged:: 2.10
            Blank lines are not indented by default.
    
            Rename the ``indentfirst`` argument to ``first``.
        
        """
        pass


code do_truncate:
  body: |
    def do_truncate(env: 'Environment', s: str, length: int=255, killwords: bool=False, end: str='...', leeway: t.Optional[int]=None):
        """Return a truncated copy of the string. The length is specified
        with the first parameter which defaults to ``255``. If the second
        parameter is ``true`` the filter will cut the text at length. Otherwise
        it will discard the last word. If the text was in fact
        truncated it will append an ellipsis sign (``"..."``). If you want a
        different ellipsis sign than ``"..."`` you can specify it using the
        third parameter. Strings that only exceed the length by the tolerance
        margin given in the fourth parameter will not be truncated.
    
        .. sourcecode:: jinja
    
            {{ "foo bar baz qux"|truncate(9) }}
                -> "foo..."
            {{ "foo bar baz qux"|truncate(9, True) }}
                -> "foo ba..."
            {{ "foo bar baz qux"|truncate(11) }}
                -> "foo bar baz qux"
            {{ "foo bar baz qux"|truncate(11, False, '...', 0) }}
                -> "foo bar..."
    
        The default leeway on newer Jinja versions is 5 and was 0 before but
        can be reconfigured globally.
        
        """
        pass


code do_wordwrap:
  body: |
    def do_wordwrap(environment: 'Environment', s: str, width: int=79, break_long_words: bool=True, wrapstring: t.Optional[str]=None, break_on_hyphens: bool=True):
        """Wrap a string to the given width. Existing newlines are treated
        as paragraphs to be wrapped separately.
    
        :param s: Original text to wrap.
        :param width: Maximum length of wrapped lines.
        :param break_long_words: If a word is longer than ``width``, break
            it across lines.
        :param break_on_hyphens: If a word contains hyphens, it may be split
            across lines.
        :param wrapstring: String to join each wrapped line. Defaults to
            :attr:`Environment.newline_sequence`.
    
        .. versionchanged:: 2.11
            Existing newlines are treated as paragraphs wrapped separately.
    
        .. versionchanged:: 2.11
            Added the ``break_on_hyphens`` parameter.
    
        .. versionchanged:: 2.7
            Added the ``wrapstring`` parameter.
        
        """
        pass


code do_wordcount:
  body: |
    def do_wordcount(s: str):
        """Count the words in that string."""
        pass


code do_int:
  body: |
    def do_int(value: t.Any, default: int=0, base: int=10):
        """Convert the value into an integer. If the
        conversion doesn't work it will return ``0``. You can
        override this default using the first parameter. You
        can also override the default base (10) in the second
        parameter, which handles input with prefixes such as
        0b, 0o and 0x for bases 2, 8 and 16 respectively.
        The base is ignored for decimal numbers and non-string values.
        
        """
        pass


code do_float:
  body: |
    def do_float(value: t.Any, default: float=0.0):
        """Convert the value into a floating point number. If the
        conversion doesn't work it will return ``0.0``. You can
        override this default using the first parameter.
        
        """
        pass


code do_format:
  body: |
    def do_format(value: str, *args: t.Any, **kwargs: t.Any):
        """Apply the given values to a `printf-style`_ format string, like
        ``string % values``.
    
        .. sourcecode:: jinja
    
            {{ "%s, %s!"|format(greeting, name) }}
            Hello, World!
    
        In most cases it should be more convenient and efficient to use the
        ``%`` operator or :meth:`str.format`.
    
        .. code-block:: text
    
            {{ "%s, %s!" % (greeting, name) }}
            {{ "{}, {}!".format(greeting, name) }}
    
        .. _printf-style: https://docs.python.org/library/stdtypes.html
            #printf-style-string-formatting
        
        """
        pass


code do_trim:
  body: |
    def do_trim(value: str, chars: t.Optional[str]=None):
        """Strip leading and trailing characters, by default whitespace."""
        pass


code do_striptags:
  body: |
    def do_striptags(value: 't.Union[str, HasHTML]'):
        """Strip SGML/XML tags and replace adjacent whitespace by one space."""
        pass


code sync_do_slice:
  body: |
    def sync_do_slice(value: 't.Collection[V]', slices: int, fill_with: 't.Optional[V]'=None):
        """Slice an iterator and return a list of lists containing
        those items. Useful if you want to create a div containing
        three ul tags that represent columns:
    
        .. sourcecode:: html+jinja
    
            <div class="columnwrapper">
              {%- for column in items|slice(3) %}
                <ul class="column-{{ loop.index }}">
                {%- for item in column %}
                  <li>{{ item }}</li>
                {%- endfor %}
                </ul>
              {%- endfor %}
            </div>
    
        If you pass it a second argument it's used to fill missing
        values on the last iteration.
        
        """
        pass


code do_batch:
  body: |
    def do_batch(value: 't.Iterable[V]', linecount: int, fill_with: 't.Optional[V]'=None):
        """
        A filter that batches items. It works pretty much like `slice`
        just the other way round. It returns a list of lists with the
        given number of items. If you provide a second parameter this
        is used to fill up missing items. See this example:
    
        .. sourcecode:: html+jinja
    
            <table>
            {%- for row in items|batch(3, '&nbsp;') %}
              <tr>
              {%- for column in row %}
                <td>{{ column }}</td>
              {%- endfor %}
              </tr>
            {%- endfor %}
            </table>
        
        """
        pass


code do_round:
  body: |
    def do_round(value: float, precision: int=0, method: 'te.Literal["common", "ceil", "floor"]'='common'):
        """Round the number to a given precision. The first
        parameter specifies the precision (default is ``0``), the
        second the rounding method:
    
        - ``'common'`` rounds either up or down
        - ``'ceil'`` always rounds up
        - ``'floor'`` always rounds down
    
        If you don't specify a method ``'common'`` is used.
    
        .. sourcecode:: jinja
    
            {{ 42.55|round }}
                -> 43.0
            {{ 42.55|round(1, 'floor') }}
                -> 42.5
    
        Note that even if rounded to 0 precision, a float is returned.  If
        you need a real integer, pipe it through `int`:
    
        .. sourcecode:: jinja
    
            {{ 42.55|round|int }}
                -> 43
        
        """
        pass


code sync_do_groupby:
  body: |
    def sync_do_groupby(environment: 'Environment', value: 't.Iterable[V]', attribute: t.Union[str, int], default: t.Optional[t.Any]=None, case_sensitive: bool=False):
        """Group a sequence of objects by an attribute using Python's
        :func:`itertools.groupby`. The attribute can use dot notation for
        nested access, like ``"address.city"``. Unlike Python's ``groupby``,
        the values are sorted first so only one group is returned for each
        unique value.
    
        For example, a list of ``User`` objects with a ``city`` attribute
        can be rendered in groups. In this example, ``grouper`` refers to
        the ``city`` value of the group.
    
        .. sourcecode:: html+jinja
    
            <ul>{% for city, items in users|groupby("city") %}
              <li>{{ city }}
                <ul>{% for user in items %}
                  <li>{{ user.name }}
                {% endfor %}</ul>
              </li>
            {% endfor %}</ul>
    
        ``groupby`` yields namedtuples of ``(grouper, list)``, which
        can be used instead of the tuple unpacking above. ``grouper`` is the
        value of the attribute, and ``list`` is the items with that value.
    
        .. sourcecode:: html+jinja
    
            <ul>{% for group in users|groupby("city") %}
              <li>{{ group.grouper }}: {{ group.list|join(", ") }}
            {% endfor %}</ul>
    
        You can specify a ``default`` value to use if an object in the list
        does not have the given attribute.
    
        .. sourcecode:: jinja
    
            <ul>{% for city, items in users|groupby("city", default="NY") %}
              <li>{{ city }}: {{ items|map(attribute="name")|join(", ") }}</li>
            {% endfor %}</ul>
    
        Like the :func:`~jinja-filters.sort` filter, sorting and grouping is
        case-insensitive by default. The ``key`` for each group will have
        the case of the first item in that group of values. For example, if
        a list of users has cities ``["CA", "NY", "ca"]``, the "CA" group
        will have two values. This can be disabled by passing
        ``case_sensitive=True``.
    
        .. versionchanged:: 3.1
            Added the ``case_sensitive`` parameter. Sorting and grouping is
            case-insensitive by default, matching other filters that do
            comparisons.
    
        .. versionchanged:: 3.0
            Added the ``default`` parameter.
    
        .. versionchanged:: 2.6
            The attribute supports dot notation for nested access.
        
        """
        pass


code sync_do_sum:
  body: |
    def sync_do_sum(environment: 'Environment', iterable: 't.Iterable[V]', attribute: t.Optional[t.Union[str, int]]=None, start: V=0):
        """Returns the sum of a sequence of numbers plus the value of parameter
        'start' (which defaults to 0).  When the sequence is empty it returns
        start.
    
        It is also possible to sum up only certain attributes:
    
        .. sourcecode:: jinja
    
            Total: {{ items|sum(attribute='price') }}
    
        .. versionchanged:: 2.6
           The ``attribute`` parameter was added to allow summing up over
           attributes.  Also the ``start`` parameter was moved on to the right.
        
        """
        pass


code sync_do_list:
  body: |
    def sync_do_list(value: 't.Iterable[V]'):
        """Convert the value into a list.  If it was a string the returned list
        will be a list of characters.
        
        """
        pass


code do_mark_safe:
  body: |
    def do_mark_safe(value: str):
        """Mark the value as safe which means that in an environment with automatic
        escaping enabled this variable will not be escaped.
        
        """
        pass


code do_mark_unsafe:
  body: |
    def do_mark_unsafe(value: str):
        """Mark a value as unsafe.  This is the reverse operation for :func:`safe`."""
        pass


code do_reverse:
  body: |
    def do_reverse(value: t.Union[str, t.Iterable[V]]):
        """Reverse the object or return an iterator that iterates over it the other
        way round.
        
        """
        pass


code do_attr:
  body: |
    def do_attr(environment: 'Environment', obj: t.Any, name: str):
        """Get an attribute of an object.  ``foo|attr("bar")`` works like
        ``foo.bar`` just that always an attribute is returned and items are not
        looked up.
    
        See :ref:`Notes on subscriptions <notes-on-subscriptions>` for more details.
        
        """
        pass


code sync_do_map:
  body: |
    def sync_do_map(context: 'Context', value: t.Iterable[t.Any], *args: t.Any, **kwargs: t.Any):
        """Applies a filter on a sequence of objects or looks up an attribute.
        This is useful when dealing with lists of objects but you are really
        only interested in a certain value of it.
    
        The basic usage is mapping on an attribute.  Imagine you have a list
        of users but you are only interested in a list of usernames:
    
        .. sourcecode:: jinja
    
            Users on this page: {{ users|map(attribute='username')|join(', ') }}
    
        You can specify a ``default`` value to use if an object in the list
        does not have the given attribute.
    
        .. sourcecode:: jinja
    
            {{ users|map(attribute="username", default="Anonymous")|join(", ") }}
    
        Alternatively you can let it invoke a filter by passing the name of the
        filter and the arguments afterwards.  A good example would be applying a
        text conversion filter on a sequence:
    
        .. sourcecode:: jinja
    
            Users on this page: {{ titles|map('lower')|join(', ') }}
    
        Similar to a generator comprehension such as:
    
        .. code-block:: python
    
            (u.username for u in users)
            (getattr(u, "username", "Anonymous") for u in users)
            (do_lower(x) for x in titles)
    
        .. versionchanged:: 2.11.0
            Added the ``default`` parameter.
    
        .. versionadded:: 2.7
        
        """
        pass


code sync_do_select:
  body: |
    def sync_do_select(context: 'Context', value: 't.Iterable[V]', *args: t.Any, **kwargs: t.Any):
        """Filters a sequence of objects by applying a test to each object,
        and only selecting the objects with the test succeeding.
    
        If no test is specified, each object will be evaluated as a boolean.
    
        Example usage:
    
        .. sourcecode:: jinja
    
            {{ numbers|select("odd") }}
            {{ numbers|select("odd") }}
            {{ numbers|select("divisibleby", 3) }}
            {{ numbers|select("lessthan", 42) }}
            {{ strings|select("equalto", "mystring") }}
    
        Similar to a generator comprehension such as:
    
        .. code-block:: python
    
            (n for n in numbers if test_odd(n))
            (n for n in numbers if test_divisibleby(n, 3))
    
        .. versionadded:: 2.7
        
        """
        pass


code sync_do_reject:
  body: |
    def sync_do_reject(context: 'Context', value: 't.Iterable[V]', *args: t.Any, **kwargs: t.Any):
        """Filters a sequence of objects by applying a test to each object,
        and rejecting the objects with the test succeeding.
    
        If no test is specified, each object will be evaluated as a boolean.
    
        Example usage:
    
        .. sourcecode:: jinja
    
            {{ numbers|reject("odd") }}
    
        Similar to a generator comprehension such as:
    
        .. code-block:: python
    
            (n for n in numbers if not test_odd(n))
    
        .. versionadded:: 2.7
        
        """
        pass


code sync_do_selectattr:
  body: |
    def sync_do_selectattr(context: 'Context', value: 't.Iterable[V]', *args: t.Any, **kwargs: t.Any):
        """Filters a sequence of objects by applying a test to the specified
        attribute of each object, and only selecting the objects with the
        test succeeding.
    
        If no test is specified, the attribute's value will be evaluated as
        a boolean.
    
        Example usage:
    
        .. sourcecode:: jinja
    
            {{ users|selectattr("is_active") }}
            {{ users|selectattr("email", "none") }}
    
        Similar to a generator comprehension such as:
    
        .. code-block:: python
    
            (u for user in users if user.is_active)
            (u for user in users if test_none(user.email))
    
        .. versionadded:: 2.7
        
        """
        pass


code sync_do_rejectattr:
  body: |
    def sync_do_rejectattr(context: 'Context', value: 't.Iterable[V]', *args: t.Any, **kwargs: t.Any):
        """Filters a sequence of objects by applying a test to the specified
        attribute of each object, and rejecting the objects with the test
        succeeding.
    
        If no test is specified, the attribute's value will be evaluated as
        a boolean.
    
        .. sourcecode:: jinja
    
            {{ users|rejectattr("is_active") }}
            {{ users|rejectattr("email", "none") }}
    
        Similar to a generator comprehension such as:
    
        .. code-block:: python
    
            (u for user in users if not user.is_active)
            (u for user in users if not test_none(user.email))
    
        .. versionadded:: 2.7
        
        """
        pass


code do_tojson:
  body: |
    def do_tojson(eval_ctx: 'EvalContext', value: t.Any, indent: t.Optional[int]=None):
        """Serialize an object to a string of JSON, and mark it safe to
        render in HTML. This filter is only for use in HTML documents.
    
        The returned string is safe to render in HTML documents and
        ``<script>`` tags. The exception is in HTML attributes that are
        double quoted; either use single quotes or the ``|forceescape``
        filter.
    
        :param value: The object to serialize to JSON.
        :param indent: The ``indent`` parameter passed to ``dumps``, for
            pretty-printing the value.
    
        .. versionadded:: 2.9
        
        """
        pass


code FrameSymbolVisitor__visit_Name:
  body: |
    def visit_Name(self, node: nodes.Name, store_as_param: bool=False, **kwargs: t.Any):
        """All assignments to names go through this function."""
        pass


code FrameSymbolVisitor__visit_Assign:
  body: |
    def visit_Assign(self, node: nodes.Assign, **kwargs: t.Any):
        """Visit assignments in the correct order."""
        pass


code FrameSymbolVisitor__visit_For:
  body: |
    def visit_For(self, node: nodes.For, **kwargs: t.Any):
        """Visiting stops at for blocks.  However the block sequence
            is visited as part of the outer scope.
            
        """
        pass


code FrameSymbolVisitor__visit_AssignBlock:
  body: |
    def visit_AssignBlock(self, node: nodes.AssignBlock, **kwargs: t.Any):
        """Stop visiting at block assigns."""
        pass


code FrameSymbolVisitor__visit_Scope:
  body: |
    def visit_Scope(self, node: nodes.Scope, **kwargs: t.Any):
        """Stop visiting at scopes."""
        pass


code FrameSymbolVisitor__visit_Block:
  body: |
    def visit_Block(self, node: nodes.Block, **kwargs: t.Any):
        """Stop visiting at blocks."""
        pass


code FrameSymbolVisitor__visit_OverlayScope:
  body: |
    def visit_OverlayScope(self, node: nodes.OverlayScope, **kwargs: t.Any):
        """Do not visit into overlay scopes."""
        pass


code split_template_path:
  body: |
    def split_template_path(template: str):
        """Split a path into segments and perform a sanity check.  If it detects
        '..' in the path it will raise a `TemplateNotFound` error.
        
        """
        pass


code BaseLoader__get_source:
  body: |
    def get_source(self, environment: 'Environment', template: str):
        """Get the template source, filename and reload helper for a template.
            It's passed the environment and template name and has to return a
            tuple in the form ``(source, filename, uptodate)`` or raise a
            `TemplateNotFound` error if it can't locate the template.
    
            The source part of the returned tuple must be the source of the
            template as a string. The filename should be the name of the
            file on the filesystem if it was loaded from there, otherwise
            ``None``. The filename is used by Python for the tracebacks
            if no loader extension is used.
    
            The last item in the tuple is the `uptodate` function.  If auto
            reloading is enabled it's always called to check if the template
            changed.  No arguments are passed so the function must store the
            old state somewhere (for example in a closure).  If it returns `False`
            the template will be reloaded.
            
        """
        pass


code BaseLoader__list_templates:
  body: |
    def list_templates(self):
        """Iterates over all templates.  If the loader does not support that
            it should raise a :exc:`TypeError` which is the default behavior.
            
        """
        pass


code BaseLoader__load:
  body: |
    def load(self, environment: 'Environment', name: str, globals: t.Optional[t.MutableMapping[str, t.Any]]=None):
        """Loads a template.  This method looks up the template in the cache
            or loads one by calling :meth:`get_source`.  Subclasses should not
            override this method as loaders working on collections of other
            loaders (such as :class:`PrefixLoader` or :class:`ChoiceLoader`)
            will not call this method but `get_source` directly.
            
        """
        pass


code TrackingCodeGenerator__write:
  body: |
    def write(self, x: str):
        """Don't write."""
        pass


code TrackingCodeGenerator__enter_frame:
  body: |
    def enter_frame(self, frame: Frame):
        """Remember all undeclared identifiers."""
        pass


code find_undeclared_variables:
  body: |
    def find_undeclared_variables(ast: nodes.Template):
        """Returns a set of all variables in the AST that will be looked up from
        the context at runtime.  Because at compile time it's not known which
        variables will be used depending on the path the execution takes at
        runtime, all variables are returned.
    
        >>> from jinja2 import Environment, meta
        >>> env = Environment()
        >>> ast = env.parse('{% set foo = 42 %}{{ bar + foo }}')
        >>> meta.find_undeclared_variables(ast) == {'bar'}
        True
    
        .. admonition:: Implementation
    
           Internally the code generator is used for finding undeclared variables.
           This is good to know because the code generator might raise a
           :exc:`TemplateAssertionError` during compilation and as a matter of
           fact this function can currently raise that exception as well.
        
        """
        pass


code find_referenced_templates:
  body: |
    def find_referenced_templates(ast: nodes.Template):
        """Finds all the referenced templates from the AST.  This will return an
        iterator over all the hardcoded template extensions, inclusions and
        imports.  If dynamic inheritance or inclusion is used, `None` will be
        yielded.
    
        >>> from jinja2 import Environment, meta
        >>> env = Environment()
        >>> ast = env.parse('{% extends "layout.html" %}{% include helper %}')
        >>> list(meta.find_referenced_templates(ast))
        ['layout.html', None]
    
        This function is useful for dependency tracking.  For example if you want
        to rebuild parts of the website after a layout template has changed.
        
        """
        pass


code native_concat:
  body: |
    def native_concat(values: t.Iterable[t.Any]):
        """Return a native Python type from the list of compiled nodes. If
        the result is a single node, its value is returned. Otherwise, the
        nodes are concatenated as strings. If the result can be parsed with
        :func:`ast.literal_eval`, the parsed value is returned. Otherwise,
        the string is returned.
    
        :param values: Iterable of outputs to concatenate.
        
        """
        pass


code NativeTemplate__render:
  body: |
    def render(self, *args: t.Any, **kwargs: t.Any):
        """Render the template to produce a native Python type. If the
            result is a single node, its value is returned. Otherwise, the
            nodes are concatenated as strings. If the result can be parsed
            with :func:`ast.literal_eval`, the parsed value is returned.
            Otherwise, the string is returned.
            
        """
        pass


code optimize:
  body: |
    def optimize(node: nodes.Node, environment: 'Environment'):
        """The context hint can be used to perform an static optimization
        based on the context given.
        """
        pass


code Parser__fail:
  body: |
    def fail(self, msg: str, lineno: t.Optional[int]=None, exc: t.Type[TemplateSyntaxError]=TemplateSyntaxError):
        """Convenience method that raises `exc` with the message, passed
            line number or last line number as well as the current name and
            filename.
            
        """
        pass


code Parser__fail_unknown_tag:
  body: |
    def fail_unknown_tag(self, name: str, lineno: t.Optional[int]=None):
        """Called if the parser encounters an unknown tag.  Tries to fail
            with a human readable error message that could help to identify
            the problem.
            
        """
        pass


code Parser__fail_eof:
  body: |
    def fail_eof(self, end_tokens: t.Optional[t.Tuple[str, ...]]=None, lineno: t.Optional[int]=None):
        """Like fail_unknown_tag but for end of template situations."""
        pass


code Parser__is_tuple_end:
  body: |
    def is_tuple_end(self, extra_end_rules: t.Optional[t.Tuple[str, ...]]=None):
        """Are we at the end of a tuple?"""
        pass


code Parser__free_identifier:
  body: |
    def free_identifier(self, lineno: t.Optional[int]=None):
        """Return a new free identifier as :class:`~jinja2.nodes.InternalName`."""
        pass


code Parser__parse_statement:
  body: |
    def parse_statement(self):
        """Parse a single statement."""
        pass


code Parser__parse_statements:
  body: |
    def parse_statements(self, end_tokens: t.Tuple[str, ...], drop_needle: bool=False):
        """Parse multiple statements into a list until one of the end tokens
            is reached.  This is used to parse the body of statements as it also
            parses template data if appropriate.  The parser checks first if the
            current token is a colon and skips it if there is one.  Then it checks
            for the block end and parses until if one of the `end_tokens` is
            reached.  Per default the active token in the stream at the end of
            the call is the matched end token.  If this is not wanted `drop_needle`
            can be set to `True` and the end token is removed.
            
        """
        pass


code Parser__parse_set:
  body: |
    def parse_set(self):
        """Parse an assign statement."""
        pass


code Parser__parse_for:
  body: |
    def parse_for(self):
        """Parse a for loop."""
        pass


code Parser__parse_if:
  body: |
    def parse_if(self):
        """Parse an if construct."""
        pass


code Parser__parse_assign_target:
  body: |
    def parse_assign_target(self, with_tuple: bool=True, name_only: bool=False, extra_end_rules: t.Optional[t.Tuple[str, ...]]=None, with_namespace: bool=False):
        """Parse an assignment target.  As Jinja allows assignments to
            tuples, this function can parse all allowed assignment targets.  Per
            default assignments to tuples are parsed, that can be disable however
            by setting `with_tuple` to `False`.  If only assignments to names are
            wanted `name_only` can be set to `True`.  The `extra_end_rules`
            parameter is forwarded to the tuple parsing function.  If
            `with_namespace` is enabled, a namespace assignment may be parsed.
            
        """
        pass


code Parser__parse_expression:
  body: |
    def parse_expression(self, with_condexpr: bool=True):
        """Parse an expression.  Per default all expressions are parsed, if
            the optional `with_condexpr` parameter is set to `False` conditional
            expressions are not parsed.
            
        """
        pass


code Parser__parse_tuple:
  body: |
    def parse_tuple(self, simplified: bool=False, with_condexpr: bool=True, extra_end_rules: t.Optional[t.Tuple[str, ...]]=None, explicit_parentheses: bool=False):
        """Works like `parse_expression` but if multiple expressions are
            delimited by a comma a :class:`~jinja2.nodes.Tuple` node is created.
            This method could also return a regular expression instead of a tuple
            if no commas where found.
    
            The default parsing mode is a full tuple.  If `simplified` is `True`
            only names and literals are parsed.  The `no_condexpr` parameter is
            forwarded to :meth:`parse_expression`.
    
            Because tuples do not require delimiters and may end in a bogus comma
            an extra hint is needed that marks the end of a tuple.  For example
            for loops support tuples between `for` and `in`.  In that case the
            `extra_end_rules` is set to ``['name:in']``.
    
            `explicit_parentheses` is true if the parsing was triggered by an
            expression in parentheses.  This is used to figure out if an empty
            tuple is a valid expression or not.
            
        """
        pass


code Parser__parse:
  body: |
    def parse(self):
        """Parse the whole template into a `Template` node."""
        pass


code identity:
  body: |
    def identity(x: V):
        """Returns its argument. Useful for certain things in the
        environment.
        
        """
        pass


code markup_join:
  body: |
    def markup_join(seq: t.Iterable[t.Any]):
        """Concatenation that escapes if necessary and converts to string."""
        pass


code str_join:
  body: |
    def str_join(seq: t.Iterable[t.Any]):
        """Simple args to string conversion and concatenation."""
        pass


code new_context:
  body: |
    def new_context(environment: 'Environment', template_name: t.Optional[str], blocks: t.Dict[str, t.Callable[['Context'], t.Iterator[str]]], vars: t.Optional[t.Dict[str, t.Any]]=None, shared: bool=False, globals: t.Optional[t.MutableMapping[str, t.Any]]=None, locals: t.Optional[t.Mapping[str, t.Any]]=None):
        """Internal helper for context creation."""
        pass


code Context__super:
  body: |
    def super(self, name: str, current: t.Callable[['Context'], t.Iterator[str]]):
        """Render a parent block."""
        pass


code Context__get:
  body: |
    def get(self, key: str, default: t.Any=None):
        """Look up a variable by name, or return a default if the key is
            not found.
    
            :param key: The variable name to look up.
            :param default: The value to return if the key is not found.
            
        """
        pass


code Context__resolve:
  body: |
    def resolve(self, key: str):
        """Look up a variable by name, or return an :class:`Undefined`
            object if the key is not found.
    
            If you need to add custom behavior, override
            :meth:`resolve_or_missing`, not this method. The various lookup
            functions use that method, not this one.
    
            :param key: The variable name to look up.
            
        """
        pass


code Context__resolve_or_missing:
  body: |
    def resolve_or_missing(self, key: str):
        """Look up a variable by name, or return a ``missing`` sentinel
            if the key is not found.
    
            Override this method to add custom lookup behavior.
            :meth:`resolve`, :meth:`get`, and :meth:`__getitem__` use this
            method. Don't call this method directly.
    
            :param key: The variable name to look up.
            
        """
        pass


code Context__get_exported:
  body: |
    def get_exported(self):
        """Get a new dict with the exported variables."""
        pass


code Context__get_all:
  body: |
    def get_all(self):
        """Return the complete context as dict including the exported
            variables.  For optimizations reasons this might not return an
            actual copy so be careful with using it.
            
        """
        pass


code Context__call:
  body: |
    def call(__self, __obj: t.Callable[..., t.Any], *args: t.Any, **kwargs: t.Any):
        """Call the callable with the arguments and keyword arguments
            provided but inject the active context or environment as first
            argument if the callable has :func:`pass_context` or
            :func:`pass_environment`.
            
        """
        pass


code Context__derived:
  body: |
    def derived(self, locals: t.Optional[t.Dict[str, t.Any]]=None):
        """Internal helper function to create a derived context.  This is
            used in situations where the system needs a new context in the same
            template that is independent.
            
        """
        pass


code BlockReference__super:
  body: |
    def super(self):
        """Super the block."""
        pass


code LoopContext__length:
  body: |
    def length(self):
        """Length of the iterable.
    
            If the iterable is a generator or otherwise does not have a
            size, it is eagerly evaluated to get a size.
            
        """
        pass


code LoopContext__depth:
  body: |
    def depth(self):
        """How many levels deep a recursive loop currently is, starting at 1."""
        pass


code LoopContext__index:
  body: |
    def index(self):
        """Current iteration of the loop, starting at 1."""
        pass


code LoopContext__revindex0:
  body: |
    def revindex0(self):
        """Number of iterations from the end of the loop, ending at 0.
    
            Requires calculating :attr:`length`.
            
        """
        pass


code LoopContext__revindex:
  body: |
    def revindex(self):
        """Number of iterations from the end of the loop, ending at 1.
    
            Requires calculating :attr:`length`.
            
        """
        pass


code LoopContext__first:
  body: |
    def first(self):
        """Whether this is the first iteration of the loop."""
        pass


code LoopContext___peek_next:
  body: |
    def _peek_next(self):
        """Return the next element in the iterable, or :data:`missing`
            if the iterable is exhausted. Only peeks one item ahead, caching
            the result in :attr:`_last` for use in subsequent checks. The
            cache is reset when :meth:`__next__` is called.
            
        """
        pass


code LoopContext__last:
  body: |
    def last(self):
        """Whether this is the last iteration of the loop.
    
            Causes the iterable to advance early. See
            :func:`itertools.groupby` for issues this can cause.
            The :func:`groupby` filter avoids that issue.
            
        """
        pass


code LoopContext__previtem:
  body: |
    def previtem(self):
        """The item in the previous iteration. Undefined during the
            first iteration.
            
        """
        pass


code LoopContext__nextitem:
  body: |
    def nextitem(self):
        """The item in the next iteration. Undefined during the last
            iteration.
    
            Causes the iterable to advance early. See
            :func:`itertools.groupby` for issues this can cause.
            The :func:`jinja-filters.groupby` filter avoids that issue.
            
        """
        pass


code LoopContext__cycle:
  body: |
    def cycle(self, *args: V):
        """Return a value from the given args, cycling through based on
            the current :attr:`index0`.
    
            :param args: One or more values to cycle through.
            
        """
        pass


code LoopContext__changed:
  body: |
    def changed(self, *value: t.Any):
        """Return ``True`` if previously called with a different value
            (including when called for the first time).
    
            :param value: One or more values to compare to the last call.
            
        """
        pass


code Undefined___undefined_message:
  body: |
    def _undefined_message(self):
        """Build a message about the undefined value based on how it was
            accessed.
            
        """
        pass


code Undefined___fail_with_undefined_error:
  body: |
    def _fail_with_undefined_error(self, *args: t.Any, **kwargs: t.Any):
        """Raise an :exc:`UndefinedError` when operations are performed
            on the undefined value.
            
        """
        pass


code make_logging_undefined:
  body: |
    def make_logging_undefined(logger: t.Optional['logging.Logger']=None, base: t.Type[Undefined]=Undefined):
        """Given a logger object this returns a new undefined class that will
        log certain failures.  It will log iterations and printing.  If no
        logger is given a default logger is created.
    
        Example::
    
            logger = logging.getLogger(__name__)
            LoggingUndefined = make_logging_undefined(
                logger=logger,
                base=Undefined
            )
    
        .. versionadded:: 2.8
    
        :param logger: the logger to use.  If not provided, a default logger
                       is created.
        :param base: the base class to add logging functionality to.  This
                     defaults to :class:`Undefined`.
        
        """
        pass


code safe_range:
  body: |
    def safe_range(*args: int):
        """A range that can't generate ranges with a length of more than
        MAX_RANGE items.
        
        """
        pass


code unsafe:
  body: |
    def unsafe(f: F):
        """Marks a function or method as unsafe.
    
        .. code-block: python
    
            @unsafe
            def delete(self):
                pass
        
        """
        pass


code is_internal_attribute:
  body: |
    def is_internal_attribute(obj: t.Any, attr: str):
        """Test if the attribute given is an internal python attribute.  For
        example this function returns `True` for the `func_code` attribute of
        python objects.  This is useful if the environment method
        :meth:`~SandboxedEnvironment.is_safe_attribute` is overridden.
    
        >>> from jinja2.sandbox import is_internal_attribute
        >>> is_internal_attribute(str, "mro")
        True
        >>> is_internal_attribute(str, "upper")
        False
        
        """
        pass


code modifies_known_mutable:
  body: |
    def modifies_known_mutable(obj: t.Any, attr: str):
        """This function checks if an attribute on a builtin mutable object
        (list, dict, set or deque) or the corresponding ABCs would modify it
        if called.
    
        >>> modifies_known_mutable({}, "clear")
        True
        >>> modifies_known_mutable({}, "keys")
        False
        >>> modifies_known_mutable([], "append")
        True
        >>> modifies_known_mutable([], "index")
        False
    
        If called with an unsupported object, ``False`` is returned.
    
        >>> modifies_known_mutable("foo", "upper")
        False
        
        """
        pass


code SandboxedEnvironment__is_safe_attribute:
  body: |
    def is_safe_attribute(self, obj: t.Any, attr: str, value: t.Any):
        """The sandboxed environment will call this method to check if the
            attribute of an object is safe to access.  Per default all attributes
            starting with an underscore are considered private as well as the
            special attributes of internal python objects as returned by the
            :func:`is_internal_attribute` function.
            
        """
        pass


code SandboxedEnvironment__is_safe_callable:
  body: |
    def is_safe_callable(self, obj: t.Any):
        """Check if an object is safely callable. By default callables
            are considered safe unless decorated with :func:`unsafe`.
    
            This also recognizes the Django convention of setting
            ``func.alters_data = True``.
            
        """
        pass


code SandboxedEnvironment__call_binop:
  body: |
    def call_binop(self, context: Context, operator: str, left: t.Any, right: t.Any):
        """For intercepted binary operator calls (:meth:`intercepted_binops`)
            this function is executed instead of the builtin operator.  This can
            be used to fine tune the behavior of certain operators.
    
            .. versionadded:: 2.6
            
        """
        pass


code SandboxedEnvironment__call_unop:
  body: |
    def call_unop(self, context: Context, operator: str, arg: t.Any):
        """For intercepted unary operator calls (:meth:`intercepted_unops`)
            this function is executed instead of the builtin operator.  This can
            be used to fine tune the behavior of certain operators.
    
            .. versionadded:: 2.6
            
        """
        pass


code SandboxedEnvironment__getitem:
  body: |
    def getitem(self, obj: t.Any, argument: t.Union[str, t.Any]):
        """Subscribe an object from sandboxed code."""
        pass


code SandboxedEnvironment__getattr:
  body: |
    def getattr(self, obj: t.Any, attribute: str):
        """Subscribe an object from sandboxed code and prefer the
            attribute.  The attribute passed *must* be a bytestring.
            
        """
        pass


code SandboxedEnvironment__unsafe_undefined:
  body: |
    def unsafe_undefined(self, obj: t.Any, attribute: str):
        """Return an undefined object for unsafe attributes."""
        pass


code SandboxedEnvironment__format_string:
  body: |
    def format_string(self, s: str, args: t.Tuple[t.Any, ...], kwargs: t.Dict[str, t.Any], format_func: t.Optional[t.Callable[..., t.Any]]=None):
        """If a format call is detected, then this is routed through this
            method so that our safety sandbox can be used for it.
            
        """
        pass


code SandboxedEnvironment__call:
  body: |
    def call(__self, __context: Context, __obj: t.Any, *args: t.Any, **kwargs: t.Any):
        """Call an object from sandboxed code."""
        pass


code test_odd:
  body: |
    def test_odd(value: int):
        """Return true if the variable is odd."""
        pass


code test_even:
  body: |
    def test_even(value: int):
        """Return true if the variable is even."""
        pass


code test_divisibleby:
  body: |
    def test_divisibleby(value: int, num: int):
        """Check if a variable is divisible by a number."""
        pass


code test_defined:
  body: |
    def test_defined(value: t.Any):
        """Return true if the variable is defined:
    
        .. sourcecode:: jinja
    
            {% if variable is defined %}
                value of variable: {{ variable }}
            {% else %}
                variable is not defined
            {% endif %}
    
        See the :func:`default` filter for a simple way to set undefined
        variables.
        
        """
        pass


code test_undefined:
  body: |
    def test_undefined(value: t.Any):
        """Like :func:`defined` but the other way round."""
        pass


code test_filter:
  body: |
    def test_filter(env: 'Environment', value: str):
        """Check if a filter exists by name. Useful if a filter may be
        optionally available.
    
        .. code-block:: jinja
    
            {% if 'markdown' is filter %}
                {{ value | markdown }}
            {% else %}
                {{ value }}
            {% endif %}
    
        .. versionadded:: 3.0
        
        """
        pass


code test_test:
  body: |
    def test_test(env: 'Environment', value: str):
        """Check if a test exists by name. Useful if a test may be
        optionally available.
    
        .. code-block:: jinja
    
            {% if 'loud' is test %}
                {% if value is loud %}
                    {{ value|upper }}
                {% else %}
                    {{ value|lower }}
                {% endif %}
            {% else %}
                {{ value }}
            {% endif %}
    
        .. versionadded:: 3.0
        
        """
        pass


code test_none:
  body: |
    def test_none(value: t.Any):
        """Return true if the variable is none."""
        pass


code test_boolean:
  body: |
    def test_boolean(value: t.Any):
        """Return true if the object is a boolean value.
    
        .. versionadded:: 2.11
        
        """
        pass


code test_false:
  body: |
    def test_false(value: t.Any):
        """Return true if the object is False.
    
        .. versionadded:: 2.11
        
        """
        pass


code test_true:
  body: |
    def test_true(value: t.Any):
        """Return true if the object is True.
    
        .. versionadded:: 2.11
        
        """
        pass


code test_integer:
  body: |
    def test_integer(value: t.Any):
        """Return true if the object is an integer.
    
        .. versionadded:: 2.11
        
        """
        pass


code test_float:
  body: |
    def test_float(value: t.Any):
        """Return true if the object is a float.
    
        .. versionadded:: 2.11
        
        """
        pass


code test_lower:
  body: |
    def test_lower(value: str):
        """Return true if the variable is lowercased."""
        pass


code test_upper:
  body: |
    def test_upper(value: str):
        """Return true if the variable is uppercased."""
        pass


code test_string:
  body: |
    def test_string(value: t.Any):
        """Return true if the object is a string."""
        pass


code test_mapping:
  body: |
    def test_mapping(value: t.Any):
        """Return true if the object is a mapping (dict etc.).
    
        .. versionadded:: 2.6
        
        """
        pass


code test_number:
  body: |
    def test_number(value: t.Any):
        """Return true if the variable is a number."""
        pass


code test_sequence:
  body: |
    def test_sequence(value: t.Any):
        """Return true if the variable is a sequence. Sequences are variables
        that are iterable.
        
        """
        pass


code test_sameas:
  body: |
    def test_sameas(value: t.Any, other: t.Any):
        """Check if an object points to the same memory address than another
        object:
    
        .. sourcecode:: jinja
    
            {% if foo.attribute is sameas false %}
                the foo attribute really is the `False` singleton
            {% endif %}
        
        """
        pass


code test_iterable:
  body: |
    def test_iterable(value: t.Any):
        """Check if it's possible to iterate over an object."""
        pass


code test_escaped:
  body: |
    def test_escaped(value: t.Any):
        """Check if the value is escaped."""
        pass


code test_in:
  body: |
    def test_in(value: t.Any, seq: t.Container[t.Any]):
        """Check if value is in seq.
    
        .. versionadded:: 2.10
        
        """
        pass


code pass_context:
  body: |
    def pass_context(f: F):
        """Pass the :class:`~jinja2.runtime.Context` as the first argument
        to the decorated function when called while rendering a template.
    
        Can be used on functions, filters, and tests.
    
        If only ``Context.eval_context`` is needed, use
        :func:`pass_eval_context`. If only ``Context.environment`` is
        needed, use :func:`pass_environment`.
    
        .. versionadded:: 3.0.0
            Replaces ``contextfunction`` and ``contextfilter``.
        
        """
        pass


code pass_eval_context:
  body: |
    def pass_eval_context(f: F):
        """Pass the :class:`~jinja2.nodes.EvalContext` as the first argument
        to the decorated function when called while rendering a template.
        See :ref:`eval-context`.
    
        Can be used on functions, filters, and tests.
    
        If only ``EvalContext.environment`` is needed, use
        :func:`pass_environment`.
    
        .. versionadded:: 3.0.0
            Replaces ``evalcontextfunction`` and ``evalcontextfilter``.
        
        """
        pass


code pass_environment:
  body: |
    def pass_environment(f: F):
        """Pass the :class:`~jinja2.Environment` as the first argument to
        the decorated function when called while rendering a template.
    
        Can be used on functions, filters, and tests.
    
        .. versionadded:: 3.0.0
            Replaces ``environmentfunction`` and ``environmentfilter``.
        
        """
        pass


code internalcode:
  body: |
    def internalcode(f: F):
        """Marks the function as internally used"""
        pass


code is_undefined:
  body: |
    def is_undefined(obj: t.Any):
        """Check if the object passed is undefined.  This does nothing more than
        performing an instance check against :class:`Undefined` but looks nicer.
        This can be used for custom filters or tests that want to react to
        undefined variables.  For example a custom default filter can look like
        this::
    
            def default(var, default=''):
                if is_undefined(var):
                    return default
                return var
        
        """
        pass


code consume:
  body: |
    def consume(iterable: t.Iterable[t.Any]):
        """Consumes an iterable without doing anything with it."""
        pass


code clear_caches:
  body: |
    def clear_caches():
        """Jinja keeps internal caches for environments and lexers.  These are
        used so that Jinja doesn't have to recreate environments and lexers all
        the time.  Normally you don't have to care about that but if you are
        measuring memory consumption you may want to clean the caches.
        
        """
        pass


code import_string:
  body: |
    def import_string(import_name: str, silent: bool=False):
        """Imports an object based on a string.  This is useful if you want to
        use import paths as endpoints or something similar.  An import path can
        be specified either in dotted notation (``xml.sax.saxutils.escape``)
        or with a colon as object delimiter (``xml.sax.saxutils:escape``).
    
        If the `silent` is True the return value will be `None` if the import
        fails.
    
        :return: imported object
        
        """
        pass


code open_if_exists:
  body: |
    def open_if_exists(filename: str, mode: str='rb'):
        """Returns a file descriptor for the filename if that file exists,
        otherwise ``None``.
        
        """
        pass


code object_type_repr:
  body: |
    def object_type_repr(obj: t.Any):
        """Returns the name of the object's type.  For some recognized
        singletons the name of the object is returned instead. (For
        example for `None` and `Ellipsis`).
        
        """
        pass


code pformat:
  body: |
    def pformat(obj: t.Any):
        """Format an object using :func:`pprint.pformat`."""
        pass


code urlize:
  body: |
    def urlize(text: str, trim_url_limit: t.Optional[int]=None, rel: t.Optional[str]=None, target: t.Optional[str]=None, extra_schemes: t.Optional[t.Iterable[str]]=None):
        """Convert URLs in text into clickable links.
    
        This may not recognize links in some situations. Usually, a more
        comprehensive formatter, such as a Markdown library, is a better
        choice.
    
        Works on ``http://``, ``https://``, ``www.``, ``mailto:``, and email
        addresses. Links with trailing punctuation (periods, commas, closing
        parentheses) and leading punctuation (opening parentheses) are
        recognized excluding the punctuation. Email addresses that include
        header fields are not recognized (for example,
        ``mailto:address@example.com?cc=copy@example.com``).
    
        :param text: Original text containing URLs to link.
        :param trim_url_limit: Shorten displayed URL values to this length.
        :param target: Add the ``target`` attribute to links.
        :param rel: Add the ``rel`` attribute to links.
        :param extra_schemes: Recognize URLs that start with these schemes
            in addition to the default behavior.
    
        .. versionchanged:: 3.0
            The ``extra_schemes`` parameter was added.
    
        .. versionchanged:: 3.0
            Generate ``https://`` links for URLs without a scheme.
    
        .. versionchanged:: 3.0
            The parsing rules were updated. Recognize email addresses with
            or without the ``mailto:`` scheme. Validate IP addresses. Ignore
            parentheses and brackets in more cases.
        
        """
        pass


code generate_lorem_ipsum:
  body: |
    def generate_lorem_ipsum(n: int=5, html: bool=True, min: int=20, max: int=100):
        """Generate some lorem ipsum for the template."""
        pass


code url_quote:
  body: |
    def url_quote(obj: t.Any, charset: str='utf-8', for_qs: bool=False):
        """Quote a string for use in a URL using the given charset.
    
        :param obj: String or bytes to quote. Other types are converted to
            string then encoded to bytes using the given charset.
        :param charset: Encode text to bytes using this charset.
        :param for_qs: Quote "/" and use "+" for spaces.
        
        """
        pass


code LRUCache__copy:
  body: |
    def copy(self):
        """Return a shallow copy of the instance."""
        pass


code LRUCache__get:
  body: |
    def get(self, key: t.Any, default: t.Any=None):
        """Return an item from the cache dict or `default`"""
        pass


code LRUCache__setdefault:
  body: |
    def setdefault(self, key: t.Any, default: t.Any=None):
        """Set `default` if the key is not in the cache otherwise
            leave unchanged. Return the value of this key.
            
        """
        pass


code LRUCache__clear:
  body: |
    def clear(self):
        """Clear the cache."""
        pass


code LRUCache__items:
  body: |
    def items(self):
        """Return a list of items."""
        pass


code LRUCache__values:
  body: |
    def values(self):
        """Return a list of all values."""
        pass


code LRUCache__keys:
  body: |
    def keys(self):
        """Return a list of all keys ordered by most recent usage."""
        pass


code select_autoescape:
  body: |
    def select_autoescape(enabled_extensions: t.Collection[str]=('html', 'htm', 'xml'), disabled_extensions: t.Collection[str]=(), default_for_string: bool=True, default: bool=False):
        """Intelligently sets the initial value of autoescaping based on the
        filename of the template.  This is the recommended way to configure
        autoescaping if you do not want to write a custom function yourself.
    
        If you want to enable it for all templates created from strings or
        for all templates with `.html` and `.xml` extensions::
    
            from jinja2 import Environment, select_autoescape
            env = Environment(autoescape=select_autoescape(
                enabled_extensions=('html', 'xml'),
                default_for_string=True,
            ))
    
        Example configuration to turn it on at all times except if the template
        ends with `.txt`::
    
            from jinja2 import Environment, select_autoescape
            env = Environment(autoescape=select_autoescape(
                disabled_extensions=('txt',),
                default_for_string=True,
                default=True,
            ))
    
        The `enabled_extensions` is an iterable of all the extensions that
        autoescaping should be enabled for.  Likewise `disabled_extensions` is
        a list of all templates it should be disabled for.  If a template is
        loaded from a string then the default from `default_for_string` is used.
        If nothing matches then the initial value of autoescaping is set to the
        value of `default`.
    
        For security reasons this function operates case insensitive.
    
        .. versionadded:: 2.9
        
        """
        pass


code htmlsafe_json_dumps:
  body: |
    def htmlsafe_json_dumps(obj: t.Any, dumps: t.Optional[t.Callable[..., str]]=None, **kwargs: t.Any):
        """Serialize an object to a string of JSON with :func:`json.dumps`,
        then replace HTML-unsafe characters with Unicode escapes and mark
        the result safe with :class:`~markupsafe.Markup`.
    
        This is available in templates as the ``|tojson`` filter.
    
        The following characters are escaped: ``<``, ``>``, ``&``, ``'``.
    
        The returned string is safe to render in HTML documents and
        ``<script>`` tags. The exception is in HTML attributes that are
        double quoted; either use single quotes or the ``|forceescape``
        filter.
    
        :param obj: The object to serialize to JSON.
        :param dumps: The ``dumps`` function to use. Defaults to
            ``env.policies["json.dumps_function"]``, which defaults to
            :func:`json.dumps`.
        :param kwargs: Extra arguments to pass to ``dumps``. Merged onto
            ``env.policies["json.dumps_kwargs"]``.
    
        .. versionchanged:: 3.0
            The ``dumper`` parameter is renamed to ``dumps``.
    
        .. versionadded:: 2.9
        
        """
        pass


code Cycler__reset:
  body: |
    def reset(self):
        """Resets the current item to the first item."""
        pass


code Cycler__current:
  body: |
    def current(self):
        """Return the current item. Equivalent to the item that will be
            returned next time :meth:`next` is called.
            
        """
        pass


code Cycler__next:
  body: |
    def next(self):
        """Return the current item, then advance :attr:`current` to the
            next item.
            
        """
        pass


code NodeVisitor__get_visitor:
  body: |
    def get_visitor(self, node: Node):
        """Return the visitor function for this node or `None` if no visitor
            exists for this node.  In that case the generic visit function is
            used instead.
            
        """
        pass


code NodeVisitor__visit:
  body: |
    def visit(self, node: Node, *args: t.Any, **kwargs: t.Any):
        """Visit a node."""
        pass


code NodeVisitor__generic_visit:
  body: |
    def generic_visit(self, node: Node, *args: t.Any, **kwargs: t.Any):
        """Called if no explicit visitor function exists for a node."""
        pass


code NodeTransformer__visit_list:
  body: |
    def visit_list(self, node: Node, *args: t.Any, **kwargs: t.Any):
        """As transformers may return lists in some places this method
            can be used to enforce a list as return value.
            
        """
        pass
