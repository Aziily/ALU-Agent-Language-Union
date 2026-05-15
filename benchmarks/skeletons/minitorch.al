preamble __init__:
  source: minitorch/__init__.py
  imports: |
    import minitorch.scalar_functions as scalar_functions
    from .autodiff import *
    from .cuda_ops import *
    from .datasets import datasets
    from .fast_conv import *
    from .fast_ops import *
    from .module import *
    from .nn import *
    from .optim import *
    from .scalar import Scalar, ScalarHistory, derivative_check
    from .scalar_functions import ScalarFunction
    from .tensor import *
    from .tensor_data import *
    from .tensor_functions import *
    from .tensor_ops import *
    from .testing import MathTest, MathTestVariable
  body: |
    version = '0.4'


preamble autodiff:
  source: minitorch/autodiff.py
  imports: |
    from dataclasses import dataclass
    from typing import Any, Iterable, List, Tuple
    from typing_extensions import Protocol
  body: |
    variable_count = 1
    class Variable(Protocol):
        pass
    @dataclass
    class Context:
        """
        Context class is used by `Function` to store information during the forward pass.
        """
        no_grad: bool = False
        saved_values: Tuple[Any, ...] = ()

        def save_for_backward(self, *values: Any) -> None:
            """Store the given `values` if they need to be used during backpropagation."""
            pass


preamble cuda_ops:
  source: minitorch/cuda_ops.py
  imports: |
    from typing import Callable, Optional
    import numba
    from numba import cuda
    from .tensor import Tensor
    from .tensor_data import MAX_DIMS, Shape, Storage, Strides, TensorData, broadcast_index, index_to_position, shape_broadcast, to_index
    from .tensor_ops import MapProto, TensorOps
  body: |
    to_index = cuda.jit(device=True)(to_index)
    index_to_position = cuda.jit(device=True)(index_to_position)
    broadcast_index = cuda.jit(device=True)(broadcast_index)
    THREADS_PER_BLOCK = 32
    class CudaOps(TensorOps):
        cuda = True

        @staticmethod
        def map(fn: Callable[[float], float]) -> MapProto:
            """See `tensor_ops.py`"""
            pass
    jit_sum_practice = cuda.jit()(_sum_practice)
    jit_mm_practice = cuda.jit()(_mm_practice)
    tensor_matrix_multiply = cuda.jit(_tensor_matrix_multiply)


preamble datasets:
  source: minitorch/datasets.py
  imports: |
    import math
    import random
    from dataclasses import dataclass
    from typing import List, Tuple
  body: |
    @dataclass
    class Graph:
        N: int
        X: List[Tuple[float, float]]
        y: List[int]
    datasets = {'Simple': simple, 'Diag': diag, 'Split': split, 'Xor': xor, 'Circle': circle, 'Spiral': spiral}


preamble fast_conv:
  source: minitorch/fast_conv.py
  imports: |
    from typing import Tuple
    import numpy as np
    from numba import njit, prange
    from .autodiff import Context
    from .tensor import Tensor
    from .tensor_data import MAX_DIMS, Index, Shape, Strides, broadcast_index, index_to_position, to_index
    from .tensor_functions import Function
  body: |
    to_index = njit(inline='always')(to_index)
    index_to_position = njit(inline='always')(index_to_position)
    broadcast_index = njit(inline='always')(broadcast_index)
    tensor_conv1d = njit(parallel=True)(_tensor_conv1d)
    class Conv1dFun(Function):

        @staticmethod
        def forward(ctx: Context, input: Tensor, weight: Tensor) -> Tensor:
            """
            Compute a 1D Convolution

            Args:
                ctx : Context
                input : batch x in_channel x h x w
                weight : out_channel x in_channel x kh x kw

            Returns:
                batch x out_channel x h x w
            """
            pass
    conv1d = Conv1dFun.apply
    tensor_conv2d = njit(parallel=True, fastmath=True)(_tensor_conv2d)
    class Conv2dFun(Function):

        @staticmethod
        def forward(ctx: Context, input: Tensor, weight: Tensor) -> Tensor:
            """
            Compute a 2D Convolution

            Args:
                ctx : Context
                input : batch x in_channel x h x w
                weight  : out_channel x in_channel x kh x kw

            Returns:
                (:class:`Tensor`) : batch x out_channel x h x w
            """
            pass
    conv2d = Conv2dFun.apply


preamble fast_ops:
  source: minitorch/fast_ops.py
  imports: |
    from __future__ import annotations
    from typing import TYPE_CHECKING
    import numpy as np
    from numba import njit, prange
    from .tensor_data import MAX_DIMS, broadcast_index, index_to_position, shape_broadcast, to_index
    from .tensor_ops import MapProto, TensorOps
  body: |
    if TYPE_CHECKING:
        from typing import Callable, Optional
        from .tensor import Tensor
        from .tensor_data import Index, Shape, Storage, Strides
    to_index = njit(inline='always')(to_index)
    index_to_position = njit(inline='always')(index_to_position)
    broadcast_index = njit(inline='always')(broadcast_index)
    class FastOps(TensorOps):

        @staticmethod
        def map(fn: Callable[[float], float]) -> MapProto:
            """See `tensor_ops.py`"""
            pass

        @staticmethod
        def zip(fn: Callable[[float, float], float]) -> Callable[[Tensor, Tensor], Tensor]:
            """See `tensor_ops.py`"""
            pass

        @staticmethod
        def reduce(fn: Callable[[float, float], float], start: float=0.0) -> Callable[[Tensor, int], Tensor]:
            """See `tensor_ops.py`"""
            pass

        @staticmethod
        def matrix_multiply(a: Tensor, b: Tensor) -> Tensor:
            """
            Batched tensor matrix multiply ::

                for n:
                  for i:
                    for j:
                      for k:
                        out[n, i, j] += a[n, i, k] * b[n, k, j]

            Where n indicates an optional broadcasted batched dimension.

            Should work for tensor shapes of 3 dims ::

                assert a.shape[-1] == b.shape[-2]

            Args:
                a : tensor data a
                b : tensor data b

            Returns:
                New tensor data
            """
            pass
    tensor_matrix_multiply = njit(parallel=True, fastmath=True)(_tensor_matrix_multiply)


preamble module:
  source: minitorch/module.py
  imports: |
    from __future__ import annotations
    from typing import Any, Dict, Optional, Sequence, Tuple
  body: |
    class Module:
        """
        Modules form a tree that store parameters and other
        submodules. They make up the basis of neural network stacks.

        Attributes:
            _modules : Storage of the child modules
            _parameters : Storage of the module's parameters
            training : Whether the module is in training mode or evaluation mode

        """
        _modules: Dict[str, Module]
        _parameters: Dict[str, Parameter]
        training: bool

        def __init__(self) -> None:
            self._modules = {}
            self._parameters = {}
            self.training = True

        def modules(self) -> Sequence[Module]:
            """Return the direct child modules of this module."""
            pass

        def train(self) -> None:
            """Set the mode of this module and all descendent modules to `train`."""
            pass

        def eval(self) -> None:
            """Set the mode of this module and all descendent modules to `eval`."""
            pass

        def named_parameters(self) -> Sequence[Tuple[str, Parameter]]:
            """
            Collect all the parameters of this module and its descendents.


            Returns:
                The name and `Parameter` of each ancestor parameter.
            """
            pass

        def parameters(self) -> Sequence[Parameter]:
            """Enumerate over all the parameters of this module and its descendents."""
            pass

        def add_parameter(self, k: str, v: Any) -> Parameter:
            """
            Manually add a parameter. Useful helper for scalar parameters.

            Args:
                k: Local name of the parameter.
                v: Value for the parameter.

            Returns:
                Newly created parameter.
            """
            pass

        def __setattr__(self, key: str, val: Parameter) -> None:
            if isinstance(val, Parameter):
                self.__dict__['_parameters'][key] = val
            elif isinstance(val, Module):
                self.__dict__['_modules'][key] = val
            else:
                super().__setattr__(key, val)

        def __getattr__(self, key: str) -> Any:
            if key in self.__dict__['_parameters']:
                return self.__dict__['_parameters'][key]
            if key in self.__dict__['_modules']:
                return self.__dict__['_modules'][key]
            return None

        def __call__(self, *args: Any, **kwargs: Any) -> Any:
            return self.forward(*args, **kwargs)

        def __repr__(self) -> str:

            def _addindent(s_: str, numSpaces: int) -> str:
                s2 = s_.split('\n')
                if len(s2) == 1:
                    return s_
                first = s2.pop(0)
                s2 = [numSpaces * ' ' + line for line in s2]
                s = '\n'.join(s2)
                s = first + '\n' + s
                return s
            child_lines = []
            for key, module in self._modules.items():
                mod_str = repr(module)
                mod_str = _addindent(mod_str, 2)
                child_lines.append('(' + key + '): ' + mod_str)
            lines = child_lines
            main_str = self.__class__.__name__ + '('
            if lines:
                main_str += '\n  ' + '\n  '.join(lines) + '\n'
            main_str += ')'
            return main_str
    class Parameter:
        """
        A Parameter is a special container stored in a `Module`.

        It is designed to hold a `Variable`, but we allow it to hold
        any value for testing.
        """

        def __init__(self, x: Any, name: Optional[str]=None) -> None:
            self.value = x
            self.name = name
            if hasattr(x, 'requires_grad_'):
                self.value.requires_grad_(True)
                if self.name:
                    self.value.name = self.name

        def update(self, x: Any) -> None:
            """Update the parameter value."""
            pass

        def __repr__(self) -> str:
            return repr(self.value)

        def __str__(self) -> str:
            return str(self.value)


preamble nn:
  source: minitorch/nn.py
  imports: |
    from typing import Tuple
    from . import operators
    from .autodiff import Context
    from .fast_ops import FastOps
    from .tensor import Tensor
    from .tensor_functions import Function, rand, tensor
  body: |
    max_reduce = FastOps.reduce(operators.max, -1000000000.0)
    class Max(Function):

        @staticmethod
        def forward(ctx: Context, input: Tensor, dim: Tensor) -> Tensor:
            """Forward of max should be max reduction"""
            pass

        @staticmethod
        def backward(ctx: Context, grad_output: Tensor) -> Tuple[Tensor, float]:
            """Backward of max should be argmax (see above)"""
            pass


preamble operators:
  source: minitorch/operators.py
  imports: |
    import math
    from typing import Callable, Iterable
  body: |
    '\nCollection of the core mathematical operators used throughout the code base.\n'
    EPS = 1e-06


preamble optim:
  source: minitorch/optim.py
  imports: |
    from typing import Sequence
    from .module import Parameter
    from .scalar import Scalar
  body: |
    class Optimizer:

        def __init__(self, parameters: Sequence[Parameter]):
            self.parameters = parameters
    class SGD(Optimizer):

        def __init__(self, parameters: Sequence[Parameter], lr: float=1.0):
            super().__init__(parameters)
            self.lr = lr


preamble scalar:
  source: minitorch/scalar.py
  imports: |
    from __future__ import annotations
    from dataclasses import dataclass
    from typing import Any, Iterable, Optional, Sequence, Tuple, Type, Union
    import numpy as np
    from .autodiff import Context, Variable, backpropagate, central_difference
    from .scalar_functions import EQ, LT, Add, Exp, Inv, Log, Mul, Neg, ReLU, ScalarFunction, Sigmoid
  body: |
    ScalarLike = Union[float, int, 'Scalar']
    @dataclass
    class ScalarHistory:
        """
        `ScalarHistory` stores the history of `Function` operations that was
        used to construct the current Variable.

        Attributes:
            last_fn : The last Function that was called.
            ctx : The context for that Function.
            inputs : The inputs that were given when `last_fn.forward` was called.

        """
        last_fn: Optional[Type[ScalarFunction]] = None
        ctx: Optional[Context] = None
        inputs: Sequence[Scalar] = ()
    _var_count = 0
    class Scalar:
        """
        A reimplementation of scalar values for autodifferentiation
        tracking. Scalar Variables behave as close as possible to standard
        Python numbers while also tracking the operations that led to the
        number's creation. They can only be manipulated by
        `ScalarFunction`.
        """
        history: Optional[ScalarHistory]
        derivative: Optional[float]
        data: float
        unique_id: int
        name: str

        def __init__(self, v: float, back: ScalarHistory=ScalarHistory(), name: Optional[str]=None):
            global _var_count
            _var_count += 1
            self.unique_id = _var_count
            self.data = float(v)
            self.history = back
            self.derivative = None
            if name is not None:
                self.name = name
            else:
                self.name = str(self.unique_id)

        def __repr__(self) -> str:
            return 'Scalar(%f)' % self.data

        def __mul__(self, b: ScalarLike) -> Scalar:
            return Mul.apply(self, b)

        def __truediv__(self, b: ScalarLike) -> Scalar:
            return Mul.apply(self, Inv.apply(b))

        def __rtruediv__(self, b: ScalarLike) -> Scalar:
            return Mul.apply(b, Inv.apply(self))

        def __add__(self, b: ScalarLike) -> Scalar:
            raise NotImplementedError('Need to implement for Task 1.2')

        def __bool__(self) -> bool:
            return bool(self.data)

        def __lt__(self, b: ScalarLike) -> Scalar:
            raise NotImplementedError('Need to implement for Task 1.2')

        def __gt__(self, b: ScalarLike) -> Scalar:
            raise NotImplementedError('Need to implement for Task 1.2')

        def __eq__(self, b: ScalarLike) -> Scalar:
            raise NotImplementedError('Need to implement for Task 1.2')

        def __sub__(self, b: ScalarLike) -> Scalar:
            raise NotImplementedError('Need to implement for Task 1.2')

        def __neg__(self) -> Scalar:
            raise NotImplementedError('Need to implement for Task 1.2')

        def __radd__(self, b: ScalarLike) -> Scalar:
            return self + b

        def __rmul__(self, b: ScalarLike) -> Scalar:
            return self * b

        def accumulate_derivative(self, x: Any) -> None:
            """
            Add `val` to the the derivative accumulated on this variable.
            Should only be called during autodifferentiation on leaf variables.

            Args:
                x: value to be accumulated
            """
            pass

        def is_leaf(self) -> bool:
            """True if this variable created by the user (no `last_fn`)"""
            pass

        def backward(self, d_output: Optional[float]=None) -> None:
            """
            Calls autodiff to fill in the derivatives for the history of this object.

            Args:
                d_output (number, opt): starting derivative to backpropagate through the model
                                       (typically left out, and assumed to be 1.0).
            """
            pass


preamble scalar_functions:
  source: minitorch/scalar_functions.py
  imports: |
    from __future__ import annotations
    from typing import TYPE_CHECKING
    import minitorch
    from . import operators
    from .autodiff import Context
  body: |
    if TYPE_CHECKING:
        from typing import Tuple
        from .scalar import Scalar, ScalarLike
    class ScalarFunction:
        """
        A wrapper for a mathematical function that processes and produces
        Scalar variables.

        This is a static class and is never instantiated. We use `class`
        here to group together the `forward` and `backward` code.
        """
    class Add(ScalarFunction):
        """Addition function $f(x, y) = x + y$"""
    class Log(ScalarFunction):
        """Log function $f(x) = log(x)$"""
    class Mul(ScalarFunction):
        """Multiplication function"""
    class Inv(ScalarFunction):
        """Inverse function"""
    class Neg(ScalarFunction):
        """Negation function"""
    class Sigmoid(ScalarFunction):
        """Sigmoid function"""
    class ReLU(ScalarFunction):
        """ReLU function"""
    class Exp(ScalarFunction):
        """Exp function"""
    class LT(ScalarFunction):
        """Less-than function $f(x) =$ 1.0 if x is less than y else 0.0"""
    class EQ(ScalarFunction):
        """Equal function $f(x) =$ 1.0 if x is equal to y else 0.0"""


preamble tensor:
  source: minitorch/tensor.py
  imports: |
    from __future__ import annotations
    from dataclasses import dataclass
    from typing import TYPE_CHECKING
    import numpy as np
    from . import operators
    from .autodiff import Context, Variable, backpropagate
    from .tensor_data import TensorData
    from .tensor_functions import EQ, LT, Add, All, Copy, Exp, Inv, IsClose, Log, MatMul, Mul, Neg, Permute, ReLU, Sigmoid, Sum, View, tensor
  body: |
    '\nImplementation of the core Tensor object for autodifferentiation.\n'
    if TYPE_CHECKING:
        from typing import Any, Iterable, List, Optional, Sequence, Tuple, Type, Union
        import numpy.typing as npt
        from .tensor_data import Shape, Storage, Strides, UserIndex, UserShape, UserStrides
        from .tensor_functions import Function
        from .tensor_ops import TensorBackend
        TensorLike = Union[float, int, 'Tensor']
    @dataclass
    class History:
        """
        `History` stores the history of `Function` operations that was
        used to construct the current Variable.
        """
        last_fn: Optional[Type[Function]] = None
        ctx: Optional[Context] = None
        inputs: Sequence[Tensor] = ()
    _tensor_count = 0
    class Tensor:
        """
        Tensor is a generalization of Scalar in that it is a Variable that
        handles multidimensional arrays.
        """
        backend: TensorBackend
        history: Optional[History]
        grad: Optional[Tensor]
        _tensor: TensorData
        unique_id: int
        name: str

        def __init__(self, v: TensorData, back: Optional[History]=None, name: Optional[str]=None, backend: Optional[TensorBackend]=None):
            global _tensor_count
            _tensor_count += 1
            self.unique_id = _tensor_count
            assert isinstance(v, TensorData)
            assert backend is not None
            self._tensor = v
            self.history = back
            self.backend = backend
            self.grad = None
            if name is not None:
                self.name = name
            else:
                self.name = str(self.unique_id)
            self.f = backend

        def to_numpy(self) -> npt.NDArray[np.float64]:
            """
            Returns:
                 Converted to numpy array
            """
            pass

        @property
        def shape(self) -> UserShape:
            """
            Returns:
                 shape of the tensor
            """
            pass

        @property
        def size(self) -> int:
            """
            Returns:
                 int : size of the tensor
            """
            pass

        @property
        def dims(self) -> int:
            """
            Returns:
                 int : dimensionality of the tensor
            """
            pass

        def _ensure_tensor(self, b: TensorLike) -> Tensor:
            """Turns a python number into a tensor with the same backend."""
            pass

        def __add__(self, b: TensorLike) -> Tensor:
            return Add.apply(self, self._ensure_tensor(b))

        def __sub__(self, b: TensorLike) -> Tensor:
            return Add.apply(self, -self._ensure_tensor(b))

        def __mul__(self, b: TensorLike) -> Tensor:
            return Mul.apply(self, self._ensure_tensor(b))

        def __truediv__(self, b: TensorLike) -> Tensor:
            return Mul.apply(self, Inv.apply(self._ensure_tensor(b)))

        def __rtruediv__(self, b: TensorLike) -> Tensor:
            return Mul.apply(self._ensure_tensor(b), Inv.apply(self))

        def __matmul__(self, b: Tensor) -> Tensor:
            """Not used until Module 3"""
            return MatMul.apply(self, b)

        def __lt__(self, b: TensorLike) -> Tensor:
            return LT.apply(self, self._ensure_tensor(b))

        def __eq__(self, b: TensorLike) -> Tensor:
            return EQ.apply(self, self._ensure_tensor(b))

        def __gt__(self, b: TensorLike) -> Tensor:
            return LT.apply(self._ensure_tensor(b), self)

        def __neg__(self) -> Tensor:
            return Neg.apply(self)

        def __radd__(self, b: TensorLike) -> Tensor:
            return self + b

        def __rmul__(self, b: TensorLike) -> Tensor:
            return self * b

        def sum(self, dim: Optional[int]=None) -> Tensor:
            """Compute the sum over dimension `dim`"""
            pass

        def mean(self, dim: Optional[int]=None) -> Tensor:
            """Compute the mean over dimension `dim`"""
            pass

        def permute(self, *order: int) -> Tensor:
            """Permute tensor dimensions to *order"""
            pass

        def view(self, *shape: int) -> Tensor:
            """Change the shape of the tensor to a new shape with the same size"""
            pass

        def contiguous(self) -> Tensor:
            """Return a contiguous tensor with the same data"""
            pass

        def __repr__(self) -> str:
            return self._tensor.to_string()

        def __getitem__(self, key: Union[int, UserIndex]) -> float:
            key2 = (key,) if isinstance(key, int) else key
            return self._tensor.get(key2)

        def __setitem__(self, key: Union[int, UserIndex], val: float) -> None:
            key2 = (key,) if isinstance(key, int) else key
            self._tensor.set(key2, val)

        @staticmethod
        def make(storage: Union[Storage, List[float]], shape: UserShape, strides: Optional[UserStrides]=None, backend: Optional[TensorBackend]=None) -> Tensor:
            """Create a new tensor from data"""
            pass

        def expand(self, other: Tensor) -> Tensor:
            """
            Method used to allow for backprop over broadcasting.
            This method is called when the output of `backward`
            is a different size than the input of `forward`.


            Parameters:
                other : backward tensor (must broadcast with self)

            Returns:
                Expanded version of `other` with the right derivatives

            """
            pass

        def accumulate_derivative(self, x: Any) -> None:
            """
            Add `val` to the the derivative accumulated on this variable.
            Should only be called during autodifferentiation on leaf variables.

            Args:
                x : value to be accumulated
            """
            pass

        def is_leaf(self) -> bool:
            """True if this variable created by the user (no `last_fn`)"""
            pass

        def zero_grad_(self) -> None:
            """
            Reset the derivative on this variable.
            """
            pass


preamble tensor_data:
  source: minitorch/tensor_data.py
  imports: |
    from __future__ import annotations
    import random
    from typing import Iterable, Optional, Sequence, Tuple, Union
    import numba
    import numpy as np
    import numpy.typing as npt
    from numpy import array, float64
    from typing_extensions import TypeAlias
    from .operators import prod
  body: |
    MAX_DIMS = 32
    class IndexingError(RuntimeError):
        """Exception raised for indexing errors."""
        pass
    Storage: TypeAlias = npt.NDArray[np.float64]
    OutIndex: TypeAlias = npt.NDArray[np.int32]
    Index: TypeAlias = npt.NDArray[np.int32]
    Shape: TypeAlias = npt.NDArray[np.int32]
    Strides: TypeAlias = npt.NDArray[np.int32]
    UserIndex: TypeAlias = Sequence[int]
    UserShape: TypeAlias = Sequence[int]
    UserStrides: TypeAlias = Sequence[int]
    class TensorData:
        _storage: Storage
        _strides: Strides
        _shape: Shape
        strides: UserStrides
        shape: UserShape
        dims: int

        def __init__(self, storage: Union[Sequence[float], Storage], shape: UserShape, strides: Optional[UserStrides]=None):
            if isinstance(storage, np.ndarray):
                self._storage = storage
            else:
                self._storage = array(storage, dtype=float64)
            if strides is None:
                strides = strides_from_shape(shape)
            assert isinstance(strides, tuple), 'Strides must be tuple'
            assert isinstance(shape, tuple), 'Shape must be tuple'
            if len(strides) != len(shape):
                raise IndexingError(f'Len of strides {strides} must match {shape}.')
            self._strides = array(strides)
            self._shape = array(shape)
            self.strides = strides
            self.dims = len(strides)
            self.size = int(prod(shape))
            self.shape = shape
            assert len(self._storage) == self.size

        def is_contiguous(self) -> bool:
            """
            Check that the layout is contiguous, i.e. outer dimensions have bigger strides than inner dimensions.

            Returns:
                bool : True if contiguous
            """
            pass

        def permute(self, *order: int) -> TensorData:
            """
            Permute the dimensions of the tensor.

            Args:
                *order: a permutation of the dimensions

            Returns:
                New `TensorData` with the same storage and a new dimension order.
            """
            pass


preamble tensor_functions:
  source: minitorch/tensor_functions.py
  imports: |
    from __future__ import annotations
    import random
    from typing import TYPE_CHECKING
    import numpy as np
    import minitorch
    from . import operators
    from .autodiff import Context
    from .tensor_ops import SimpleBackend, TensorBackend
  body: |
    '\nImplementation of the autodifferentiation Functions for Tensor.\n'
    if TYPE_CHECKING:
        from typing import Any, List, Tuple
        from .tensor import Tensor
        from .tensor_data import UserIndex, UserShape
    class Function:
        pass
    class Neg(Function):
        pass
    class Inv(Function):
        pass
    class Add(Function):
        pass
    class Mul(Function):
        pass
    class Sigmoid(Function):
        pass
    class ReLU(Function):
        pass
    class Log(Function):
        pass
    class Exp(Function):
        pass
    class Sum(Function):
        pass
    class All(Function):
        pass
    class LT(Function):
        pass
    class EQ(Function):
        pass
    class IsClose(Function):
        pass
    class Permute(Function):
        pass
    class View(Function):
        pass
    class Copy(Function):
        pass
    class MatMul(Function):
        pass


preamble tensor_ops:
  source: minitorch/tensor_ops.py
  imports: |
    from __future__ import annotations
    from typing import TYPE_CHECKING, Callable, Optional, Type
    import numpy as np
    from typing_extensions import Protocol
    from . import operators
    from .tensor_data import MAX_DIMS, broadcast_index, index_to_position, shape_broadcast, to_index
  body: |
    if TYPE_CHECKING:
        from .tensor import Tensor
        from .tensor_data import Index, Shape, Storage, Strides
    class MapProto(Protocol):

        def __call__(self, x: Tensor, out: Optional[Tensor]=..., /) -> Tensor:
            ...
    class TensorOps:
        cuda = False
    class TensorBackend:

        def __init__(self, ops: Type[TensorOps]):
            """
            Dynamically construct a tensor backend based on a `tensor_ops` object
            that implements map, zip, and reduce higher-order functions.

            Args:
                ops : tensor operations object see `tensor_ops.py`


            Returns :
                A collection of tensor functions

            """
            self.neg_map = ops.map(operators.neg)
            self.sigmoid_map = ops.map(operators.sigmoid)
            self.relu_map = ops.map(operators.relu)
            self.log_map = ops.map(operators.log)
            self.exp_map = ops.map(operators.exp)
            self.id_map = ops.map(operators.id)
            self.id_cmap = ops.cmap(operators.id)
            self.inv_map = ops.map(operators.inv)
            self.add_zip = ops.zip(operators.add)
            self.mul_zip = ops.zip(operators.mul)
            self.lt_zip = ops.zip(operators.lt)
            self.eq_zip = ops.zip(operators.eq)
            self.is_close_zip = ops.zip(operators.is_close)
            self.relu_back_zip = ops.zip(operators.relu_back)
            self.log_back_zip = ops.zip(operators.log_back)
            self.inv_back_zip = ops.zip(operators.inv_back)
            self.add_reduce = ops.reduce(operators.add, 0.0)
            self.mul_reduce = ops.reduce(operators.mul, 1.0)
            self.matrix_multiply = ops.matrix_multiply
            self.cuda = ops.cuda
    class SimpleOps(TensorOps):

        @staticmethod
        def map(fn: Callable[[float], float]) -> MapProto:
            """
            Higher-order tensor map function ::

              fn_map = map(fn)
              fn_map(a, out)
              out

            Simple version::

                for i:
                    for j:
                        out[i, j] = fn(a[i, j])

            Broadcasted version (`a` might be smaller than `out`) ::

                for i:
                    for j:
                        out[i, j] = fn(a[i, 0])

            Args:
                fn: function from float-to-float to apply.
                a (:class:`TensorData`): tensor to map over
                out (:class:`TensorData`): optional, tensor data to fill in,
                       should broadcast with `a`

            Returns:
                new tensor data
            """
            pass

        @staticmethod
        def zip(fn: Callable[[float, float], float]) -> Callable[['Tensor', 'Tensor'], 'Tensor']:
            """
            Higher-order tensor zip function ::

              fn_zip = zip(fn)
              out = fn_zip(a, b)

            Simple version ::

                for i:
                    for j:
                        out[i, j] = fn(a[i, j], b[i, j])

            Broadcasted version (`a` and `b` might be smaller than `out`) ::

                for i:
                    for j:
                        out[i, j] = fn(a[i, 0], b[0, j])


            Args:
                fn: function from two floats-to-float to apply
                a (:class:`TensorData`): tensor to zip over
                b (:class:`TensorData`): tensor to zip over

            Returns:
                :class:`TensorData` : new tensor data
            """
            pass

        @staticmethod
        def reduce(fn: Callable[[float, float], float], start: float=0.0) -> Callable[['Tensor', int], 'Tensor']:
            """
            Higher-order tensor reduce function. ::

              fn_reduce = reduce(fn)
              out = fn_reduce(a, dim)

            Simple version ::

                for j:
                    out[1, j] = start
                    for i:
                        out[1, j] = fn(out[1, j], a[i, j])


            Args:
                fn: function from two floats-to-float to apply
                a (:class:`TensorData`): tensor to reduce over
                dim (int): int of dim to reduce

            Returns:
                :class:`TensorData` : new tensor
            """
            pass
        is_cuda = False
    SimpleBackend = TensorBackend(SimpleOps)


preamble testing:
  source: minitorch/testing.py
  imports: |
    from typing import Callable, Generic, Iterable, Tuple, TypeVar
    import minitorch.operators as operators
  body: |
    A = TypeVar('A')
    class MathTest(Generic[A]):

        @staticmethod
        def neg(a: A) -> A:
            """Negate the argument"""
            pass

        @staticmethod
        def addConstant(a: A) -> A:
            """Add contant to the argument"""
            pass

        @staticmethod
        def square(a: A) -> A:
            """Manual square"""
            pass

        @staticmethod
        def cube(a: A) -> A:
            """Manual cube"""
            pass

        @staticmethod
        def subConstant(a: A) -> A:
            """Subtract a constant from the argument"""
            pass

        @staticmethod
        def multConstant(a: A) -> A:
            """Multiply a constant to the argument"""
            pass

        @staticmethod
        def div(a: A) -> A:
            """Divide by a constant"""
            pass

        @staticmethod
        def inv(a: A) -> A:
            """Invert after adding"""
            pass

        @staticmethod
        def sig(a: A) -> A:
            """Apply sigmoid"""
            pass

        @staticmethod
        def log(a: A) -> A:
            """Apply log to a large value"""
            pass

        @staticmethod
        def relu(a: A) -> A:
            """Apply relu"""
            pass

        @staticmethod
        def exp(a: A) -> A:
            """Apply exp to a smaller value"""
            pass

        @staticmethod
        def add2(a: A, b: A) -> A:
            """Add two arguments"""
            pass

        @staticmethod
        def mul2(a: A, b: A) -> A:
            """Mul two arguments"""
            pass

        @staticmethod
        def div2(a: A, b: A) -> A:
            """Divide two arguments"""
            pass

        @classmethod
        def _tests(cls) -> Tuple[Tuple[str, Callable[[A], A]], Tuple[str, Callable[[A, A], A]], Tuple[str, Callable[[Iterable[A]], A]]]:
            """
            Returns a list of all the math tests.
            """
            pass
    class MathTestVariable(MathTest):
        pass


flow minitorch_lib:
  steps:
    - autodiff_group
    - cuda_ops_group
    - fast_conv_group
    - fast_ops_group
    - module_group
    - nn_group
    - operators_group
    - scalar_group
    - scalar_functions_group
    - tensor_group
    - tensor_data_group
    - tensor_functions_group
    - tensor_ops_group
    - testing_group


flow autodiff_group:
  steps:
    - central_difference
    - topological_sort
    - backpropagate
    - Context__save_for_backward


flow cuda_ops_group:
  steps:
    - CudaOps__map
    - tensor_map
    - tensor_zip
    - _sum_practice
    - tensor_reduce
    - _mm_practice
    - _tensor_matrix_multiply


flow fast_conv_group:
  steps:
    - _tensor_conv1d
    - Conv1dFun__forward
    - _tensor_conv2d
    - Conv2dFun__forward


flow fast_ops_group:
  steps:
    - FastOps__map
    - FastOps__zip
    - FastOps__reduce
    - FastOps__matrix_multiply
    - tensor_map
    - tensor_zip
    - tensor_reduce
    - _tensor_matrix_multiply


flow module_group:
  steps:
    - Module__modules
    - Module__train
    - Module__eval
    - Module__named_parameters
    - Module__parameters
    - Module__add_parameter
    - Parameter__update


flow nn_group:
  steps:
    - tile
    - avgpool2d
    - argmax
    - Max__forward
    - Max__backward
    - softmax
    - logsoftmax
    - maxpool2d
    - dropout


flow operators_group:
  steps:
    - mul
    - id
    - add
    - neg
    - lt
    - eq
    - max
    - is_close
    - sigmoid
    - relu
    - log
    - exp
    - log_back
    - inv
    - inv_back
    - relu_back
    - map
    - negList
    - zipWith
    - addLists
    - reduce
    - sum
    - prod


flow scalar_group:
  steps:
    - Scalar__accumulate_derivative
    - Scalar__is_leaf
    - Scalar__backward
    - derivative_check


flow scalar_functions_group:
  steps:
    - wrap_tuple
    - unwrap_tuple


flow tensor_group:
  steps:
    - Tensor__to_numpy
    - Tensor__shape
    - Tensor__size
    - Tensor__dims
    - Tensor___ensure_tensor
    - Tensor__sum
    - Tensor__mean
    - Tensor__permute
    - Tensor__view
    - Tensor__contiguous
    - Tensor__make
    - Tensor__expand
    - Tensor__accumulate_derivative
    - Tensor__is_leaf
    - Tensor__zero_grad_


flow tensor_data_group:
  steps:
    - index_to_position
    - to_index
    - broadcast_index
    - shape_broadcast
    - TensorData__is_contiguous
    - TensorData__permute


flow tensor_functions_group:
  steps:
    - wrap_tuple
    - zeros
    - rand
    - _tensor
    - tensor


flow tensor_ops_group:
  steps:
    - SimpleOps__map
    - SimpleOps__zip
    - SimpleOps__reduce
    - tensor_map
    - tensor_zip
    - tensor_reduce


flow testing_group:
  steps:
    - MathTest__neg
    - MathTest__addConstant
    - MathTest__square
    - MathTest__cube
    - MathTest__subConstant
    - MathTest__multConstant
    - MathTest__div
    - MathTest__inv
    - MathTest__sig
    - MathTest__log
    - MathTest__relu
    - MathTest__exp
    - MathTest__add2
    - MathTest__mul2
    - MathTest__div2
    - MathTest___tests


code central_difference:
  body: |
    def central_difference(f: Any, *vals: Any, arg: int=0, epsilon: float=1e-06):
        """
        Computes an approximation to the derivative of `f` with respect to one arg.
    
        See :doc:`derivative` or https://en.wikipedia.org/wiki/Finite_difference for more details.
    
        Args:
            f : arbitrary function from n-scalar args to one value
            *vals : n-float values $x_0 \ldots x_{n-1}$
            arg : the number $i$ of the arg to compute the derivative
            epsilon : a small constant
    
        Returns:
            An approximation of $f'_i(x_0, \ldots, x_{n-1})$
        
        """
        pass


code topological_sort:
  body: |
    def topological_sort(variable: Variable):
        """
        Computes the topological order of the computation graph.
    
        Args:
            variable: The right-most variable
    
        Returns:
            Non-constant Variables in topological order starting from the right.
        
        """
        pass


code backpropagate:
  body: |
    def backpropagate(variable: Variable, deriv: Any):
        """
        Runs backpropagation on the computation graph in order to
        compute derivatives for the leave nodes.
    
        Args:
            variable: The right-most variable
            deriv  : Its derivative that we want to propagate backward to the leaves.
    
        No return. Should write to its results to the derivative values of each leaf through `accumulate_derivative`.
        
        """
        pass


code Context__save_for_backward:
  body: |
    def save_for_backward(self, *values: Any):
        """Store the given `values` if they need to be used during backpropagation."""
        pass


code CudaOps__map:
  body: |
    def map(fn: Callable[[float], float]):
        """See `tensor_ops.py`"""
        pass


code tensor_map:
  body: |
    def tensor_map(fn: Callable[[float], float]):
        """
        CUDA higher-order tensor map function. ::
    
          fn_map = tensor_map(fn)
          fn_map(out, ... )
    
        Args:
            fn: function mappings floats-to-floats to apply.
    
        Returns:
            Tensor map function.
        
        """
        pass


code tensor_zip:
  body: |
    def tensor_zip(fn: Callable[[float, float], float]):
        """
        CUDA higher-order tensor zipWith (or map2) function ::
    
          fn_zip = tensor_zip(fn)
          fn_zip(out, ...)
    
        Args:
            fn: function mappings two floats to float to apply.
    
        Returns:
            Tensor zip function.
        
        """
        pass


code _sum_practice:
  body: |
    def _sum_practice(out: Storage, a: Storage, size: int):
        """
        This is a practice sum kernel to prepare for reduce.
    
        Given an array of length $n$ and out of size $n // 	ext{blockDIM}$
        it should sum up each blockDim values into an out cell.
    
        $[a_1, a_2, ..., a_{100}]$
    
        |
    
        $[a_1 +...+ a_{31}, a_{32} + ... + a_{64}, ... ,]$
    
        Note: Each block must do the sum using shared memory!
    
        Args:
            out (Storage): storage for `out` tensor.
            a (Storage): storage for `a` tensor.
            size (int):  length of a.
    
        
        """
        pass


code tensor_reduce:
  body: |
    def tensor_reduce(fn: Callable[[float, float], float]):
        """
        CUDA higher-order tensor reduce function.
    
        Args:
            fn: reduction function maps two floats to float.
    
        Returns:
            Tensor reduce function.
    
        
        """
        pass


code _mm_practice:
  body: |
    def _mm_practice(out: Storage, a: Storage, b: Storage, size: int):
        """
        This is a practice square MM kernel to prepare for matmul.
    
        Given a storage `out` and two storage `a` and `b`. Where we know
        both are shape [size, size] with strides [size, 1].
    
        Size is always < 32.
    
        Requirements:
    
        * All data must be first moved to shared memory.
        * Only read each cell in `a` and `b` once.
        * Only write to global memory once per kernel.
    
        Compute
    
        ```
         for i:
             for j:
                  for k:
                      out[i, j] += a[i, k] * b[k, j]
        ```
    
        Args:
            out (Storage): storage for `out` tensor.
            a (Storage): storage for `a` tensor.
            b (Storage): storage for `b` tensor.
            size (int): size of the square
        
        """
        pass


code _tensor_matrix_multiply:
  body: |
    def _tensor_matrix_multiply(out: Storage, out_shape: Shape, out_strides: Strides, out_size: int, a_storage: Storage, a_shape: Shape, a_strides: Strides, b_storage: Storage, b_shape: Shape, b_strides: Strides):
        """
        CUDA tensor matrix multiply function.
    
        Requirements:
    
        * All data must be first moved to shared memory.
        * Only read each cell in `a` and `b` once.
        * Only write to global memory once per kernel.
    
        Should work for any tensor shapes that broadcast as long as ::
    
        ```python
        assert a_shape[-1] == b_shape[-2]
        ```
        Returns:
            None : Fills in `out`
        
        """
        pass


code _tensor_conv1d:
  body: |
    def _tensor_conv1d(out: Tensor, out_shape: Shape, out_strides: Strides, out_size: int, input: Tensor, input_shape: Shape, input_strides: Strides, weight: Tensor, weight_shape: Shape, weight_strides: Strides, reverse: bool):
        """
        1D Convolution implementation.
    
        Given input tensor of
    
           `batch, in_channels, width`
    
        and weight tensor
    
           `out_channels, in_channels, k_width`
    
        Computes padded output of
    
           `batch, out_channels, width`
    
        `reverse` decides if weight is anchored left (False) or right.
        (See diagrams)
    
        Args:
            out (Storage): storage for `out` tensor.
            out_shape (Shape): shape for `out` tensor.
            out_strides (Strides): strides for `out` tensor.
            out_size (int): size of the `out` tensor.
            input (Storage): storage for `input` tensor.
            input_shape (Shape): shape for `input` tensor.
            input_strides (Strides): strides for `input` tensor.
            weight (Storage): storage for `input` tensor.
            weight_shape (Shape): shape for `input` tensor.
            weight_strides (Strides): strides for `input` tensor.
            reverse (bool): anchor weight at left or right
        
        """
        pass


code Conv1dFun__forward:
  body: |
    def forward(ctx: Context, input: Tensor, weight: Tensor):
        """
            Compute a 1D Convolution
    
            Args:
                ctx : Context
                input : batch x in_channel x h x w
                weight : out_channel x in_channel x kh x kw
    
            Returns:
                batch x out_channel x h x w
            
        """
        pass


code _tensor_conv2d:
  body: |
    def _tensor_conv2d(out: Tensor, out_shape: Shape, out_strides: Strides, out_size: int, input: Tensor, input_shape: Shape, input_strides: Strides, weight: Tensor, weight_shape: Shape, weight_strides: Strides, reverse: bool):
        """
        2D Convolution implementation.
    
        Given input tensor of
    
           `batch, in_channels, height, width`
    
        and weight tensor
    
           `out_channels, in_channels, k_height, k_width`
    
        Computes padded output of
    
           `batch, out_channels, height, width`
    
        `Reverse` decides if weight is anchored top-left (False) or bottom-right.
        (See diagrams)
    
    
        Args:
            out (Storage): storage for `out` tensor.
            out_shape (Shape): shape for `out` tensor.
            out_strides (Strides): strides for `out` tensor.
            out_size (int): size of the `out` tensor.
            input (Storage): storage for `input` tensor.
            input_shape (Shape): shape for `input` tensor.
            input_strides (Strides): strides for `input` tensor.
            weight (Storage): storage for `input` tensor.
            weight_shape (Shape): shape for `input` tensor.
            weight_strides (Strides): strides for `input` tensor.
            reverse (bool): anchor weight at top-left or bottom-right
        
        """
        pass


code Conv2dFun__forward:
  body: |
    def forward(ctx: Context, input: Tensor, weight: Tensor):
        """
            Compute a 2D Convolution
    
            Args:
                ctx : Context
                input : batch x in_channel x h x w
                weight  : out_channel x in_channel x kh x kw
    
            Returns:
                (:class:`Tensor`) : batch x out_channel x h x w
            
        """
        pass


code FastOps__map:
  body: |
    def map(fn: Callable[[float], float]):
        """See `tensor_ops.py`"""
        pass


code FastOps__zip:
  body: |
    def zip(fn: Callable[[float, float], float]):
        """See `tensor_ops.py`"""
        pass


code FastOps__reduce:
  body: |
    def reduce(fn: Callable[[float, float], float], start: float=0.0):
        """See `tensor_ops.py`"""
        pass


code FastOps__matrix_multiply:
  body: |
    def matrix_multiply(a: Tensor, b: Tensor):
        """
            Batched tensor matrix multiply ::
    
                for n:
                  for i:
                    for j:
                      for k:
                        out[n, i, j] += a[n, i, k] * b[n, k, j]
    
            Where n indicates an optional broadcasted batched dimension.
    
            Should work for tensor shapes of 3 dims ::
    
                assert a.shape[-1] == b.shape[-2]
    
            Args:
                a : tensor data a
                b : tensor data b
    
            Returns:
                New tensor data
            
        """
        pass


code tensor_map:
  body: |
    def tensor_map(fn: Callable[[float], float]):
        """
        NUMBA low_level tensor_map function. See `tensor_ops.py` for description.
    
        Optimizations:
    
        * Main loop in parallel
        * All indices use numpy buffers
        * When `out` and `in` are stride-aligned, avoid indexing
    
        Args:
            fn: function mappings floats-to-floats to apply.
    
        Returns:
            Tensor map function.
        
        """
        pass


code tensor_zip:
  body: |
    def tensor_zip(fn: Callable[[float, float], float]):
        """
        NUMBA higher-order tensor zip function. See `tensor_ops.py` for description.
    
    
        Optimizations:
    
        * Main loop in parallel
        * All indices use numpy buffers
        * When `out`, `a`, `b` are stride-aligned, avoid indexing
    
        Args:
            fn: function maps two floats to float to apply.
    
        Returns:
            Tensor zip function.
        
        """
        pass


code tensor_reduce:
  body: |
    def tensor_reduce(fn: Callable[[float, float], float]):
        """
        NUMBA higher-order tensor reduce function. See `tensor_ops.py` for description.
    
        Optimizations:
    
        * Main loop in parallel
        * All indices use numpy buffers
        * Inner-loop should not call any functions or write non-local variables
    
        Args:
            fn: reduction function mapping two floats to float.
    
        Returns:
            Tensor reduce function
        
        """
        pass


code _tensor_matrix_multiply:
  body: |
    def _tensor_matrix_multiply(out: Storage, out_shape: Shape, out_strides: Strides, a_storage: Storage, a_shape: Shape, a_strides: Strides, b_storage: Storage, b_shape: Shape, b_strides: Strides):
        """
        NUMBA tensor matrix multiply function.
    
        Should work for any tensor shapes that broadcast as long as
    
        ```
        assert a_shape[-1] == b_shape[-2]
        ```
    
        Optimizations:
    
        * Outer loop in parallel
        * No index buffers or function calls
        * Inner loop should have no global writes, 1 multiply.
    
    
        Args:
            out (Storage): storage for `out` tensor
            out_shape (Shape): shape for `out` tensor
            out_strides (Strides): strides for `out` tensor
            a_storage (Storage): storage for `a` tensor
            a_shape (Shape): shape for `a` tensor
            a_strides (Strides): strides for `a` tensor
            b_storage (Storage): storage for `b` tensor
            b_shape (Shape): shape for `b` tensor
            b_strides (Strides): strides for `b` tensor
    
        Returns:
            None : Fills in `out`
        
        """
        pass


code Module__modules:
  body: |
    def modules(self):
        """Return the direct child modules of this module."""
        pass


code Module__train:
  body: |
    def train(self):
        """Set the mode of this module and all descendent modules to `train`."""
        pass


code Module__eval:
  body: |
    def eval(self):
        """Set the mode of this module and all descendent modules to `eval`."""
        pass


code Module__named_parameters:
  body: |
    def named_parameters(self):
        """
            Collect all the parameters of this module and its descendents.
    
    
            Returns:
                The name and `Parameter` of each ancestor parameter.
            
        """
        pass


code Module__parameters:
  body: |
    def parameters(self):
        """Enumerate over all the parameters of this module and its descendents."""
        pass


code Module__add_parameter:
  body: |
    def add_parameter(self, k: str, v: Any):
        """
            Manually add a parameter. Useful helper for scalar parameters.
    
            Args:
                k: Local name of the parameter.
                v: Value for the parameter.
    
            Returns:
                Newly created parameter.
            
        """
        pass


code Parameter__update:
  body: |
    def update(self, x: Any):
        """Update the parameter value."""
        pass


code tile:
  body: |
    def tile(input: Tensor, kernel: Tuple[int, int]):
        """
        Reshape an image tensor for 2D pooling
    
        Args:
            input: batch x channel x height x width
            kernel: height x width of pooling
    
        Returns:
            Tensor of size batch x channel x new_height x new_width x (kernel_height * kernel_width) as well as the new_height and new_width value.
        
        """
        pass


code avgpool2d:
  body: |
    def avgpool2d(input: Tensor, kernel: Tuple[int, int]):
        """
        Tiled average pooling 2D
    
        Args:
            input : batch x channel x height x width
            kernel : height x width of pooling
    
        Returns:
            Pooled tensor
        
        """
        pass


code argmax:
  body: |
    def argmax(input: Tensor, dim: int):
        """
        Compute the argmax as a 1-hot tensor.
    
        Args:
            input : input tensor
            dim : dimension to apply argmax
    
    
        Returns:
            :class:`Tensor` : tensor with 1 on highest cell in dim, 0 otherwise
    
        
        """
        pass


code Max__forward:
  body: |
    def forward(ctx: Context, input: Tensor, dim: Tensor):
        """Forward of max should be max reduction"""
        pass


code Max__backward:
  body: |
    def backward(ctx: Context, grad_output: Tensor):
        """Backward of max should be argmax (see above)"""
        pass


code softmax:
  body: |
    def softmax(input: Tensor, dim: int):
        """
        Compute the softmax as a tensor.
    
    
    
        $z_i = \frac{e^{x_i}}{\sum_i e^{x_i}}$
    
        Args:
            input : input tensor
            dim : dimension to apply softmax
    
        Returns:
            softmax tensor
        
        """
        pass


code logsoftmax:
  body: |
    def logsoftmax(input: Tensor, dim: int):
        """
        Compute the log of the softmax as a tensor.
    
        $z_i = x_i - \log \sum_i e^{x_i}$
    
        See https://en.wikipedia.org/wiki/LogSumExp#log-sum-exp_trick_for_log-domain_calculations
    
        Args:
            input : input tensor
            dim : dimension to apply log-softmax
    
        Returns:
             log of softmax tensor
        
        """
        pass


code maxpool2d:
  body: |
    def maxpool2d(input: Tensor, kernel: Tuple[int, int]):
        """
        Tiled max pooling 2D
    
        Args:
            input: batch x channel x height x width
            kernel: height x width of pooling
    
        Returns:
            Tensor : pooled tensor
        
        """
        pass


code dropout:
  body: |
    def dropout(input: Tensor, rate: float, ignore: bool=False):
        """
        Dropout positions based on random noise.
    
        Args:
            input : input tensor
            rate : probability [0, 1) of dropping out each position
            ignore : skip dropout, i.e. do nothing at all
    
        Returns:
            tensor with random positions dropped out
        
        """
        pass


code mul:
  body: |
    def mul(x: float, y: float):
        """$f(x, y) = x * y$"""
        pass


code id:
  body: |
    def id(x: float):
        """$f(x) = x$"""
        pass


code add:
  body: |
    def add(x: float, y: float):
        """$f(x, y) = x + y$"""
        pass


code neg:
  body: |
    def neg(x: float):
        """$f(x) = -x$"""
        pass


code lt:
  body: |
    def lt(x: float, y: float):
        """$f(x) =$ 1.0 if x is less than y else 0.0"""
        pass


code eq:
  body: |
    def eq(x: float, y: float):
        """$f(x) =$ 1.0 if x is equal to y else 0.0"""
        pass


code max:
  body: |
    def max(x: float, y: float):
        """$f(x) =$ x if x is greater than y else y"""
        pass


code is_close:
  body: |
    def is_close(x: float, y: float):
        """$f(x) = |x - y| < 1e-2$"""
        pass


code sigmoid:
  body: |
    def sigmoid(x: float):
        """
        $f(x) =  \frac{1.0}{(1.0 + e^{-x})}$
    
        (See https://en.wikipedia.org/wiki/Sigmoid_function )
    
        Calculate as
    
        $f(x) =  \frac{1.0}{(1.0 + e^{-x})}$ if x >=0 else $\frac{e^x}{(1.0 + e^{x})}$
    
        for stability.
        
        """
        pass


code relu:
  body: |
    def relu(x: float):
        """
        $f(x) =$ x if x is greater than 0, else 0
    
        (See https://en.wikipedia.org/wiki/Rectifier_(neural_networks) .)
        
        """
        pass


code log:
  body: |
    def log(x: float):
        """$f(x) = log(x)$"""
        pass


code exp:
  body: |
    def exp(x: float):
        """$f(x) = e^{x}$"""
        pass


code log_back:
  body: |
    def log_back(x: float, d: float):
        """If $f = log$ as above, compute $d \times f'(x)$"""
        pass


code inv:
  body: |
    def inv(x: float):
        """$f(x) = 1/x$"""
        pass


code inv_back:
  body: |
    def inv_back(x: float, d: float):
        """If $f(x) = 1/x$ compute $d \times f'(x)$"""
        pass


code relu_back:
  body: |
    def relu_back(x: float, d: float):
        """If $f = relu$ compute $d \times f'(x)$"""
        pass


code map:
  body: |
    def map(fn: Callable[[float], float]):
        """
        Higher-order map.
    
        See https://en.wikipedia.org/wiki/Map_(higher-order_function)
    
        Args:
            fn: Function from one value to one value.
    
        Returns:
             A function that takes a list, applies `fn` to each element, and returns a
             new list
        
        """
        pass


code negList:
  body: |
    def negList(ls: Iterable[float]):
        """Use `map` and `neg` to negate each element in `ls`"""
        pass


code zipWith:
  body: |
    def zipWith(fn: Callable[[float, float], float]):
        """
        Higher-order zipwith (or map2).
    
        See https://en.wikipedia.org/wiki/Map_(higher-order_function)
    
        Args:
            fn: combine two values
    
        Returns:
             Function that takes two equally sized lists `ls1` and `ls2`, produce a new list by
             applying fn(x, y) on each pair of elements.
    
        
        """
        pass


code addLists:
  body: |
    def addLists(ls1: Iterable[float], ls2: Iterable[float]):
        """Add the elements of `ls1` and `ls2` using `zipWith` and `add`"""
        pass


code reduce:
  body: |
    def reduce(fn: Callable[[float, float], float], start: float):
        """
        Higher-order reduce.
    
        Args:
            fn: combine two values
            start: start value $x_0$
    
        Returns:
             Function that takes a list `ls` of elements
             $x_1 \ldots x_n$ and computes the reduction :math:`fn(x_3, fn(x_2,
             fn(x_1, x_0)))`
        
        """
        pass


code sum:
  body: |
    def sum(ls: Iterable[float]):
        """Sum up a list using `reduce` and `add`."""
        pass


code prod:
  body: |
    def prod(ls: Iterable[float]):
        """Product of a list using `reduce` and `mul`."""
        pass


code Scalar__accumulate_derivative:
  body: |
    def accumulate_derivative(self, x: Any):
        """
            Add `val` to the the derivative accumulated on this variable.
            Should only be called during autodifferentiation on leaf variables.
    
            Args:
                x: value to be accumulated
            
        """
        pass


code Scalar__is_leaf:
  body: |
    def is_leaf(self):
        """True if this variable created by the user (no `last_fn`)"""
        pass


code Scalar__backward:
  body: |
    def backward(self, d_output: Optional[float]=None):
        """
            Calls autodiff to fill in the derivatives for the history of this object.
    
            Args:
                d_output (number, opt): starting derivative to backpropagate through the model
                                       (typically left out, and assumed to be 1.0).
            
        """
        pass


code derivative_check:
  body: |
    def derivative_check(f: Any, *scalars: Scalar):
        """
        Checks that autodiff works on a python function.
        Asserts False if derivative is incorrect.
    
        Parameters:
            f : function from n-scalars to 1-scalar.
            *scalars  : n input scalar values.
        
        """
        pass


code wrap_tuple:
  body: |
    def wrap_tuple(x):
        """Turn a possible value into a tuple"""
        pass


code unwrap_tuple:
  body: |
    def unwrap_tuple(x):
        """Turn a singleton tuple into a value"""
        pass


code Tensor__to_numpy:
  body: |
    def to_numpy(self):
        """
            Returns:
                 Converted to numpy array
            
        """
        pass


code Tensor__shape:
  body: |
    def shape(self):
        """
            Returns:
                 shape of the tensor
            
        """
        pass


code Tensor__size:
  body: |
    def size(self):
        """
            Returns:
                 int : size of the tensor
            
        """
        pass


code Tensor__dims:
  body: |
    def dims(self):
        """
            Returns:
                 int : dimensionality of the tensor
            
        """
        pass


code Tensor___ensure_tensor:
  body: |
    def _ensure_tensor(self, b: TensorLike):
        """Turns a python number into a tensor with the same backend."""
        pass


code Tensor__sum:
  body: |
    def sum(self, dim: Optional[int]=None):
        """Compute the sum over dimension `dim`"""
        pass


code Tensor__mean:
  body: |
    def mean(self, dim: Optional[int]=None):
        """Compute the mean over dimension `dim`"""
        pass


code Tensor__permute:
  body: |
    def permute(self, *order: int):
        """Permute tensor dimensions to *order"""
        pass


code Tensor__view:
  body: |
    def view(self, *shape: int):
        """Change the shape of the tensor to a new shape with the same size"""
        pass


code Tensor__contiguous:
  body: |
    def contiguous(self):
        """Return a contiguous tensor with the same data"""
        pass


code Tensor__make:
  body: |
    def make(storage: Union[Storage, List[float]], shape: UserShape, strides: Optional[UserStrides]=None, backend: Optional[TensorBackend]=None):
        """Create a new tensor from data"""
        pass


code Tensor__expand:
  body: |
    def expand(self, other: Tensor):
        """
            Method used to allow for backprop over broadcasting.
            This method is called when the output of `backward`
            is a different size than the input of `forward`.
    
    
            Parameters:
                other : backward tensor (must broadcast with self)
    
            Returns:
                Expanded version of `other` with the right derivatives
    
            
        """
        pass


code Tensor__accumulate_derivative:
  body: |
    def accumulate_derivative(self, x: Any):
        """
            Add `val` to the the derivative accumulated on this variable.
            Should only be called during autodifferentiation on leaf variables.
    
            Args:
                x : value to be accumulated
            
        """
        pass


code Tensor__is_leaf:
  body: |
    def is_leaf(self):
        """True if this variable created by the user (no `last_fn`)"""
        pass


code Tensor__zero_grad_:
  body: |
    def zero_grad_(self):
        """
            Reset the derivative on this variable.
            
        """
        pass


code index_to_position:
  body: |
    def index_to_position(index: Index, strides: Strides):
        """
        Converts a multidimensional tensor `index` into a single-dimensional position in
        storage based on strides.
    
        Args:
            index : index tuple of ints
            strides : tensor strides
    
        Returns:
            Position in storage
        
        """
        pass


code to_index:
  body: |
    def to_index(ordinal: int, shape: Shape, out_index: OutIndex):
        """
        Convert an `ordinal` to an index in the `shape`.
        Should ensure that enumerating position 0 ... size of a
        tensor produces every index exactly once. It
        may not be the inverse of `index_to_position`.
    
        Args:
            ordinal: ordinal position to convert.
            shape : tensor shape.
            out_index : return index corresponding to position.
    
        
        """
        pass


code broadcast_index:
  body: |
    def broadcast_index(big_index: Index, big_shape: Shape, shape: Shape, out_index: OutIndex):
        """
        Convert a `big_index` into `big_shape` to a smaller `out_index`
        into `shape` following broadcasting rules. In this case
        it may be larger or with more dimensions than the `shape`
        given. Additional dimensions may need to be mapped to 0 or
        removed.
    
        Args:
            big_index : multidimensional index of bigger tensor
            big_shape : tensor shape of bigger tensor
            shape : tensor shape of smaller tensor
            out_index : multidimensional index of smaller tensor
    
        Returns:
            None
        
        """
        pass


code shape_broadcast:
  body: |
    def shape_broadcast(shape1: UserShape, shape2: UserShape):
        """
        Broadcast two shapes to create a new union shape.
    
        Args:
            shape1 : first shape
            shape2 : second shape
    
        Returns:
            broadcasted shape
    
        Raises:
            IndexingError : if cannot broadcast
        
        """
        pass


code TensorData__is_contiguous:
  body: |
    def is_contiguous(self):
        """
            Check that the layout is contiguous, i.e. outer dimensions have bigger strides than inner dimensions.
    
            Returns:
                bool : True if contiguous
            
        """
        pass


code TensorData__permute:
  body: |
    def permute(self, *order: int):
        """
            Permute the dimensions of the tensor.
    
            Args:
                *order: a permutation of the dimensions
    
            Returns:
                New `TensorData` with the same storage and a new dimension order.
            
        """
        pass


code wrap_tuple:
  body: |
    def wrap_tuple(x):
        """Turn a possible value into a tuple"""
        pass


code zeros:
  body: |
    def zeros(shape: UserShape, backend: TensorBackend=SimpleBackend):
        """
        Produce a zero tensor of size `shape`.
    
        Args:
            shape : shape of tensor
            backend : tensor backend
    
        Returns:
            new tensor
        
        """
        pass


code rand:
  body: |
    def rand(shape: UserShape, backend: TensorBackend=SimpleBackend, requires_grad: bool=False):
        """
        Produce a random tensor of size `shape`.
    
        Args:
            shape : shape of tensor
            backend : tensor backend
            requires_grad : turn on autodifferentiation
    
        Returns:
            :class:`Tensor` : new tensor
        
        """
        pass


code _tensor:
  body: |
    def _tensor(ls: Any, shape: UserShape, backend: TensorBackend=SimpleBackend, requires_grad: bool=False):
        """
        Produce a tensor with data ls and shape `shape`.
    
        Args:
            ls: data for tensor
            shape: shape of tensor
            backend: tensor backend
            requires_grad: turn on autodifferentiation
    
        Returns:
            new tensor
        
        """
        pass


code tensor:
  body: |
    def tensor(ls: Any, backend: TensorBackend=SimpleBackend, requires_grad: bool=False):
        """
        Produce a tensor with data and shape from ls
    
        Args:
            ls: data for tensor
            backend : tensor backend
            requires_grad : turn on autodifferentiation
    
        Returns:
            :class:`Tensor` : new tensor
        
        """
        pass


code SimpleOps__map:
  body: |
    def map(fn: Callable[[float], float]):
        """
            Higher-order tensor map function ::
    
              fn_map = map(fn)
              fn_map(a, out)
              out
    
            Simple version::
    
                for i:
                    for j:
                        out[i, j] = fn(a[i, j])
    
            Broadcasted version (`a` might be smaller than `out`) ::
    
                for i:
                    for j:
                        out[i, j] = fn(a[i, 0])
    
            Args:
                fn: function from float-to-float to apply.
                a (:class:`TensorData`): tensor to map over
                out (:class:`TensorData`): optional, tensor data to fill in,
                       should broadcast with `a`
    
            Returns:
                new tensor data
            
        """
        pass


code SimpleOps__zip:
  body: |
    def zip(fn: Callable[[float, float], float]):
        """
            Higher-order tensor zip function ::
    
              fn_zip = zip(fn)
              out = fn_zip(a, b)
    
            Simple version ::
    
                for i:
                    for j:
                        out[i, j] = fn(a[i, j], b[i, j])
    
            Broadcasted version (`a` and `b` might be smaller than `out`) ::
    
                for i:
                    for j:
                        out[i, j] = fn(a[i, 0], b[0, j])
    
    
            Args:
                fn: function from two floats-to-float to apply
                a (:class:`TensorData`): tensor to zip over
                b (:class:`TensorData`): tensor to zip over
    
            Returns:
                :class:`TensorData` : new tensor data
            
        """
        pass


code SimpleOps__reduce:
  body: |
    def reduce(fn: Callable[[float, float], float], start: float=0.0):
        """
            Higher-order tensor reduce function. ::
    
              fn_reduce = reduce(fn)
              out = fn_reduce(a, dim)
    
            Simple version ::
    
                for j:
                    out[1, j] = start
                    for i:
                        out[1, j] = fn(out[1, j], a[i, j])
    
    
            Args:
                fn: function from two floats-to-float to apply
                a (:class:`TensorData`): tensor to reduce over
                dim (int): int of dim to reduce
    
            Returns:
                :class:`TensorData` : new tensor
            
        """
        pass


code tensor_map:
  body: |
    def tensor_map(fn: Callable[[float], float]):
        """
        Low-level implementation of tensor map between
        tensors with *possibly different strides*.
    
        Simple version:
    
        * Fill in the `out` array by applying `fn` to each
          value of `in_storage` assuming `out_shape` and `in_shape`
          are the same size.
    
        Broadcasted version:
    
        * Fill in the `out` array by applying `fn` to each
          value of `in_storage` assuming `out_shape` and `in_shape`
          broadcast. (`in_shape` must be smaller than `out_shape`).
    
        Args:
            fn: function from float-to-float to apply
    
        Returns:
            Tensor map function.
        
        """
        pass


code tensor_zip:
  body: |
    def tensor_zip(fn: Callable[[float, float], float]):
        """
        Low-level implementation of tensor zip between
        tensors with *possibly different strides*.
    
        Simple version:
    
        * Fill in the `out` array by applying `fn` to each
          value of `a_storage` and `b_storage` assuming `out_shape`
          and `a_shape` are the same size.
    
        Broadcasted version:
    
        * Fill in the `out` array by applying `fn` to each
          value of `a_storage` and `b_storage` assuming `a_shape`
          and `b_shape` broadcast to `out_shape`.
    
        Args:
            fn: function mapping two floats to float to apply
    
        Returns:
            Tensor zip function.
        
        """
        pass


code tensor_reduce:
  body: |
    def tensor_reduce(fn: Callable[[float, float], float]):
        """
        Low-level implementation of tensor reduce.
    
        * `out_shape` will be the same as `a_shape`
           except with `reduce_dim` turned to size `1`
    
        Args:
            fn: reduction function mapping two floats to float
    
        Returns:
            Tensor reduce function.
        
        """
        pass


code MathTest__neg:
  body: |
    def neg(a: A):
        """Negate the argument"""
        pass


code MathTest__addConstant:
  body: |
    def addConstant(a: A):
        """Add contant to the argument"""
        pass


code MathTest__square:
  body: |
    def square(a: A):
        """Manual square"""
        pass


code MathTest__cube:
  body: |
    def cube(a: A):
        """Manual cube"""
        pass


code MathTest__subConstant:
  body: |
    def subConstant(a: A):
        """Subtract a constant from the argument"""
        pass


code MathTest__multConstant:
  body: |
    def multConstant(a: A):
        """Multiply a constant to the argument"""
        pass


code MathTest__div:
  body: |
    def div(a: A):
        """Divide by a constant"""
        pass


code MathTest__inv:
  body: |
    def inv(a: A):
        """Invert after adding"""
        pass


code MathTest__sig:
  body: |
    def sig(a: A):
        """Apply sigmoid"""
        pass


code MathTest__log:
  body: |
    def log(a: A):
        """Apply log to a large value"""
        pass


code MathTest__relu:
  body: |
    def relu(a: A):
        """Apply relu"""
        pass


code MathTest__exp:
  body: |
    def exp(a: A):
        """Apply exp to a smaller value"""
        pass


code MathTest__add2:
  body: |
    def add2(a: A, b: A):
        """Add two arguments"""
        pass


code MathTest__mul2:
  body: |
    def mul2(a: A, b: A):
        """Mul two arguments"""
        pass


code MathTest__div2:
  body: |
    def div2(a: A, b: A):
        """Divide two arguments"""
        pass


code MathTest___tests:
  body: |
    def _tests(cls):
        """
            Returns a list of all the math tests.
            
        """
        pass
