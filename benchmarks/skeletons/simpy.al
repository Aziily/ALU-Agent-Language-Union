preamble __init__:
  source: simpy/__init__.py
  imports: |
    from __future__ import annotations
    import importlib.metadata
    from typing import Tuple, Type
    from simpy.core import Environment
    from simpy.events import AllOf, AnyOf, Event, Process, Timeout
    from simpy.exceptions import Interrupt, SimPyException
    from simpy.resources.container import Container
    from simpy.resources.resource import PreemptiveResource, PriorityResource, Resource
    from simpy.resources.store import FilterStore, PriorityItem, PriorityStore, Store
    from simpy.rt import RealtimeEnvironment
  constants: |
    __all__ = ['AllOf', 'AnyOf', 'Container', 'Environment', 'Event', 'FilterStore', 'Interrupt', 'PreemptiveResource', 'PriorityItem', 'PriorityResource', 'PriorityStore', 'Process', 'RealtimeEnvironment', 'Resource', 'SimPyException', 'Store', 'Timeout']
    _toc = (('Environments', (Environment, RealtimeEnvironment)), ('Events', (Event, Timeout, Process, AllOf, AnyOf, Interrupt)), ('Resources', (Resource, PriorityResource, PreemptiveResource, Container, Store, PriorityItem, PriorityStore, FilterStore)), ('Exceptions', (SimPyException, Interrupt)))
  body: |
    "\nThe ``simpy`` module aggregates SimPy's most used components into a single\nnamespace. This is purely for convenience. You can of course also access\neverything (and more!) via their actual submodules.\n\nThe following tables list all the available components in this module.\n\n{toc}\n\n"
    if __doc__:
        __doc__ = __doc__.format(toc=_compile_toc(_toc))
        assert set(__all__) == {obj.__name__ for _, objs in _toc for obj in objs}
    try:
        __version__ = importlib.metadata.version('simpy')
    except importlib.metadata.PackageNotFoundError:
        pass


preamble core:
  source: simpy/core.py
  imports: |
    from __future__ import annotations
    from heapq import heappop, heappush
    from itertools import count
    from types import MethodType
    from typing import TYPE_CHECKING, Any, Generic, Iterable, List, Optional, Tuple, Type, TypeVar, Union
    from simpy.events import NORMAL, URGENT, AllOf, AnyOf, Event, EventPriority, Process, ProcessGenerator, Timeout
  constants: |
    Infinity: float = float('inf')
    T = TypeVar('T')
    SimTime = Union[int, float]
  body: |
    '\nCore components for event-discrete simulation environments.\n\n'
    class BoundClass(Generic[T]):
        """Allows classes to behave like methods.

        The ``__get__()`` descriptor is basically identical to
        ``function.__get__()`` and binds the first argument of the ``cls`` to the
        descriptor instance.

        """

        def __init__(self, cls: Type[T]):
            self.cls = cls

        def __get__(self, instance: Optional[BoundClass], owner: Optional[Type[BoundClass]]=None) -> Union[Type[T], MethodType]:
            if instance is None:
                return self.cls
            return MethodType(self.cls, instance)

        @staticmethod
        def bind_early(instance: object) -> None:
            """Bind all :class:`BoundClass` attributes of the *instance's* class
            to the instance itself to increase performance."""
            pass
    class EmptySchedule(Exception):
        """Thrown by an :class:`Environment` if there are no further events to be
        processed."""
    class StopSimulation(Exception):
        """Indicates that the simulation should stop now."""

        @classmethod
        def callback(cls, event: Event) -> None:
            """Used as callback in :meth:`Environment.run()` to stop the simulation
            when the *until* event occurred."""
            pass
    class Environment:
        """Execution environment for an event-based simulation. The passing of time
        is simulated by stepping from event to event.

        You can provide an *initial_time* for the environment. By default, it
        starts at ``0``.

        This class also provides aliases for common event types, for example
        :attr:`process`, :attr:`timeout` and :attr:`event`.

        """

        def __init__(self, initial_time: SimTime=0):
            self._now = initial_time
            self._queue: List[Tuple[SimTime, EventPriority, int, Event]] = []
            self._eid = count()
            self._active_proc: Optional[Process] = None
            BoundClass.bind_early(self)

        @property
        def now(self) -> SimTime:
            """The current simulation time."""
            pass

        @property
        def active_process(self) -> Optional[Process]:
            """The currently active process of the environment."""
            pass
        if TYPE_CHECKING:

            def process(self, generator: ProcessGenerator) -> Process:
                """Create a new :class:`~simpy.events.Process` instance for
                *generator*."""
                pass

            def timeout(self, delay: SimTime=0, value: Optional[Any]=None) -> Timeout:
                """Return a new :class:`~simpy.events.Timeout` event with a *delay*
                and, optionally, a *value*."""
                pass

            def event(self) -> Event:
                """Return a new :class:`~simpy.events.Event` instance.

                Yielding this event suspends a process until another process
                triggers the event.
                """
                pass

            def all_of(self, events: Iterable[Event]) -> AllOf:
                """Return a :class:`~simpy.events.AllOf` condition for *events*."""
                pass

            def any_of(self, events: Iterable[Event]) -> AnyOf:
                """Return a :class:`~simpy.events.AnyOf` condition for *events*."""
                pass
        else:
            process = BoundClass(Process)
            timeout = BoundClass(Timeout)
            event = BoundClass(Event)
            all_of = BoundClass(AllOf)
            any_of = BoundClass(AnyOf)

        def schedule(self, event: Event, priority: EventPriority=NORMAL, delay: SimTime=0) -> None:
            """Schedule an *event* with a given *priority* and a *delay*."""
            pass

        def peek(self) -> SimTime:
            """Get the time of the next scheduled event. Return
            :data:`~simpy.core.Infinity` if there is no further event."""
            pass

        def step(self) -> None:
            """Process the next event.

            Raise an :exc:`EmptySchedule` if no further events are available.

            """
            pass

        def run(self, until: Optional[Union[SimTime, Event]]=None) -> Optional[Any]:
            """Executes :meth:`step()` until the given criterion *until* is met.

            - If it is ``None`` (which is the default), this method will return
              when there are no further events to be processed.

            - If it is an :class:`~simpy.events.Event`, the method will continue
              stepping until this event has been triggered and will return its
              value.  Raises a :exc:`RuntimeError` if there are no further events
              to be processed and the *until* event was not triggered.

            - If it is a number, the method will continue stepping
              until the environment's time reaches *until*.

            """
            pass


preamble events:
  source: simpy/events.py
  imports: |
    from __future__ import annotations
    from typing import TYPE_CHECKING, Any, Callable, Dict, Generator, Iterable, Iterator, List, NewType, Optional, Tuple, TypeVar
    from simpy.exceptions import Interrupt
  constants: |
    PENDING: object = object()
    EventPriority = NewType('EventPriority', int)
    URGENT: EventPriority = EventPriority(0)
    NORMAL: EventPriority = EventPriority(1)
    EventType = TypeVar('EventType', bound=Event)
    EventCallback = Callable[[EventType], None]
    EventCallbacks = List[EventCallback]
    ProcessGenerator = Generator[Event, Any, Any]
  body: |
    '\nThis module contains the basic event types used in SimPy.\n\nThe base class for all events is :class:`Event`. Though it can be directly\nused, there are several specialized subclasses of it.\n\n.. autosummary::\n\n    ~simpy.events.Event\n    ~simpy.events.Timeout\n    ~simpy.events.Process\n    ~simpy.events.AnyOf\n    ~simpy.events.AllOf\n\n'
    if TYPE_CHECKING:
        from types import FrameType
        from simpy.core import Environment, SimTime
    class Event:
        """An event that may happen at some point in time.

        An event

        - may happen (:attr:`triggered` is ``False``),
        - is going to happen (:attr:`triggered` is ``True``) or
        - has happened (:attr:`processed` is ``True``).

        Every event is bound to an environment *env* and is initially not
        triggered. Events are scheduled for processing by the environment after
        they are triggered by either :meth:`succeed`, :meth:`fail` or
        :meth:`trigger`. These methods also set the *ok* flag and the *value* of
        the event.

        An event has a list of :attr:`callbacks`. A callback can be any callable.
        Once an event gets processed, all callbacks will be invoked with the event
        as the single argument. Callbacks can check if the event was successful by
        examining *ok* and do further processing with the *value* it has produced.

        Failed events are never silently ignored and will raise an exception upon
        being processed. If a callback handles an exception, it must set
        :attr:`defused` to ``True`` to prevent this.

        This class also implements ``__and__()`` (``&``) and ``__or__()`` (``|``).
        If you concatenate two events using one of these operators,
        a :class:`Condition` event is generated that lets you wait for both or one
        of them.

        """
        _ok: bool
        _defused: bool
        _value: Any = PENDING

        def __init__(self, env: Environment):
            self.env = env
            'The :class:`~simpy.core.Environment` the event lives in.'
            self.callbacks: EventCallbacks = []
            'List of functions that are called when the event is processed.'

        def __repr__(self) -> str:
            """Return the description of the event (see :meth:`_desc`) with the id
            of the event."""
            return f'<{self._desc()} object at {id(self):#x}>'

        def _desc(self) -> str:
            """Return a string *Event()*."""
            pass

        @property
        def triggered(self) -> bool:
            """Becomes ``True`` if the event has been triggered and its callbacks
            are about to be invoked."""
            pass

        @property
        def processed(self) -> bool:
            """Becomes ``True`` if the event has been processed (e.g., its
            callbacks have been invoked)."""
            pass

        @property
        def ok(self) -> bool:
            """Becomes ``True`` when the event has been triggered successfully.

            A "successful" event is one triggered with :meth:`succeed()`.

            :raises AttributeError: if accessed before the event is triggered.

            """
            pass

        @property
        def defused(self) -> bool:
            """Becomes ``True`` when the failed event's exception is "defused".

            When an event fails (i.e. with :meth:`fail()`), the failed event's
            `value` is an exception that will be re-raised when the
            :class:`~simpy.core.Environment` processes the event (i.e. in
            :meth:`~simpy.core.Environment.step()`).

            It is also possible for the failed event's exception to be defused by
            setting :attr:`defused` to ``True`` from an event callback. Doing so
            prevents the event's exception from being re-raised when the event is
            processed by the :class:`~simpy.core.Environment`.

            """
            pass

        @property
        def value(self) -> Optional[Any]:
            """The value of the event if it is available.

            The value is available when the event has been triggered.

            Raises :exc:`AttributeError` if the value is not yet available.

            """
            pass

        def trigger(self, event: Event) -> None:
            """Trigger the event with the state and value of the provided *event*.
            Return *self* (this event instance).

            This method can be used directly as a callback function to trigger
            chain reactions.

            """
            pass

        def succeed(self, value: Optional[Any]=None) -> Event:
            """Set the event's value, mark it as successful and schedule it for
            processing by the environment. Returns the event instance.

            Raises :exc:`RuntimeError` if this event has already been triggerd.

            """
            pass

        def fail(self, exception: Exception) -> Event:
            """Set *exception* as the events value, mark it as failed and schedule
            it for processing by the environment. Returns the event instance.

            Raises :exc:`TypeError` if *exception* is not an :exc:`Exception`.

            Raises :exc:`RuntimeError` if this event has already been triggered.

            """
            pass

        def __and__(self, other: Event) -> Condition:
            """Return a :class:`~simpy.events.Condition` that will be triggered if
            both, this event and *other*, have been processed."""
            return Condition(self.env, Condition.all_events, [self, other])

        def __or__(self, other: Event) -> Condition:
            """Return a :class:`~simpy.events.Condition` that will be triggered if
            either this event or *other* have been processed (or even both, if they
            happened concurrently)."""
            return Condition(self.env, Condition.any_events, [self, other])
    class Timeout(Event):
        """A :class:`~simpy.events.Event` that gets processed after a *delay* has
        passed.

        This event is automatically triggered when it is created.


        """

        def __init__(self, env: Environment, delay: SimTime, value: Optional[Any]=None):
            if delay < 0:
                raise ValueError(f'Negative delay {delay}')
            self.env = env
            self.callbacks: EventCallbacks = []
            self._value = value
            self._delay = delay
            self._ok = True
            env.schedule(self, NORMAL, delay)

        def _desc(self) -> str:
            """Return a string *Timeout(delay[, value=value])*."""
            pass
    class Initialize(Event):
        """Initializes a process. Only used internally by :class:`Process`.

        This event is automatically triggered when it is created.

        """

        def __init__(self, env: Environment, process: Process):
            self.env = env
            self.callbacks: EventCallbacks = [process._resume]
            self._value: Any = None
            self._ok = True
            env.schedule(self, URGENT)
    class Interruption(Event):
        """Immediately schedules an :class:`~simpy.exceptions.Interrupt` exception
        with the given *cause* to be thrown into *process*.

        This event is automatically triggered when it is created.

        """

        def __init__(self, process: Process, cause: Optional[Any]):
            self.env = process.env
            self.callbacks: EventCallbacks = [self._interrupt]
            self._value = Interrupt(cause)
            self._ok = False
            self._defused = True
            if process._value is not PENDING:
                raise RuntimeError(f'{process} has terminated and cannot be interrupted.')
            if process is self.env.active_process:
                raise RuntimeError('A process is not allowed to interrupt itself.')
            self.process = process
            self.env.schedule(self, URGENT)
    class Process(Event):
        """Process an event yielding generator.

        A generator (also known as a coroutine) can suspend its execution by
        yielding an event. ``Process`` will take care of resuming the generator
        with the value of that event once it has happened. The exception of failed
        events is thrown into the generator.

        ``Process`` itself is an event, too. It is triggered, once the generator
        returns or raises an exception. The value of the process is the return
        value of the generator or the exception, respectively.

        Processes can be interrupted during their execution by :meth:`interrupt`.

        """

        def __init__(self, env: Environment, generator: ProcessGenerator):
            if not hasattr(generator, 'throw'):
                raise ValueError(f'{generator} is not a generator.')
            self.env = env
            self.callbacks: EventCallbacks = []
            self._generator = generator
            self._target: Event = Initialize(env, self)

        def _desc(self) -> str:
            """Return a string *Process(process_func_name)*."""
            pass

        @property
        def target(self) -> Event:
            """The event that the process is currently waiting for.

            Returns ``None`` if the process is dead, or it is currently being
            interrupted.

            """
            pass

        @property
        def name(self) -> str:
            """Name of the function used to start the process."""
            pass

        @property
        def is_alive(self) -> bool:
            """``True`` until the process generator exits."""
            pass

        def interrupt(self, cause: Optional[Any]=None) -> None:
            """Interrupt this process optionally providing a *cause*.

            A process cannot be interrupted if it already terminated. A process can
            also not interrupt itself. Raise a :exc:`RuntimeError` in these
            cases.

            """
            pass

        def _resume(self, event: Event) -> None:
            """Resumes the execution of the process with the value of *event*. If
            the process generator exits, the process itself will get triggered with
            the return value or the exception of the generator."""
            pass
    class ConditionValue:
        """Result of a :class:`~simpy.events.Condition`. It supports convenient
        dict-like access to the triggered events and their values. The events are
        ordered by their occurrences in the condition."""

        def __init__(self) -> None:
            self.events: List[Event] = []

        def __getitem__(self, key: Event) -> Any:
            if key not in self.events:
                raise KeyError(str(key))
            return key._value

        def __contains__(self, key: Event) -> bool:
            return key in self.events

        def __eq__(self, other: object) -> bool:
            if isinstance(other, ConditionValue):
                return self.events == other.events
            elif isinstance(other, dict):
                return self.todict() == other
            else:
                return NotImplemented

        def __repr__(self) -> str:
            return f'<ConditionValue {self.todict()}>'

        def __iter__(self) -> Iterator[Event]:
            return self.keys()
    class Condition(Event):
        """An event that gets triggered once the condition function *evaluate*
        returns ``True`` on the given list of *events*.

        The value of the condition event is an instance of :class:`ConditionValue`
        which allows convenient access to the input events and their values. The
        :class:`ConditionValue` will only contain entries for those events that
        occurred before the condition is processed.

        If one of the events fails, the condition also fails and forwards the
        exception of the failing event.

        The *evaluate* function receives the list of target events and the number
        of processed events in this list: ``evaluate(events, processed_count)``. If
        it returns ``True``, the condition is triggered. The
        :func:`Condition.all_events()` and :func:`Condition.any_events()` functions
        are used to implement *and* (``&``) and *or* (``|``) for events.

        Condition events can be nested.

        """

        def __init__(self, env: Environment, evaluate: Callable[[Tuple[Event, ...], int], bool], events: Iterable[Event]):
            super().__init__(env)
            self._evaluate = evaluate
            self._events = tuple(events)
            self._count = 0
            if not self._events:
                self.succeed(ConditionValue())
                return
            for event in self._events:
                if self.env != event.env:
                    raise ValueError('It is not allowed to mix events from different environments')
            for event in self._events:
                if event.callbacks is None:
                    self._check(event)
                else:
                    event.callbacks.append(self._check)
            assert isinstance(self.callbacks, list)
            self.callbacks.append(self._build_value)

        def _desc(self) -> str:
            """Return a string *Condition(evaluate, [events])*."""
            pass

        def _populate_value(self, value: ConditionValue) -> None:
            """Populate the *value* by recursively visiting all nested
            conditions."""
            pass

        def _build_value(self, event: Event) -> None:
            """Build the value of this condition."""
            pass

        def _remove_check_callbacks(self) -> None:
            """Remove _check() callbacks from events recursively.

            Once the condition has triggered, the condition's events no longer need
            to have _check() callbacks. Removing the _check() callbacks is
            important to break circular references between the condition and
            untriggered events.

            """
            pass

        def _check(self, event: Event) -> None:
            """Check if the condition was already met and schedule the *event* if
            so."""
            pass

        @staticmethod
        def all_events(events: Tuple[Event, ...], count: int) -> bool:
            """An evaluation function that returns ``True`` if all *events* have
            been triggered."""
            pass

        @staticmethod
        def any_events(events: Tuple[Event, ...], count: int) -> bool:
            """An evaluation function that returns ``True`` if at least one of
            *events* has been triggered."""
            pass
    class AllOf(Condition):
        """A :class:`~simpy.events.Condition` event that is triggered if all of
        a list of *events* have been successfully triggered. Fails immediately if
        any of *events* failed.

        """

        def __init__(self, env: Environment, events: Iterable[Event]):
            super().__init__(env, Condition.all_events, events)
    class AnyOf(Condition):
        """A :class:`~simpy.events.Condition` event that is triggered if any of
        a list of *events* has been successfully triggered. Fails immediately if
        any of *events* failed.

        """

        def __init__(self, env: Environment, events: Iterable[Event]):
            super().__init__(env, Condition.any_events, events)


preamble exceptions:
  source: simpy/exceptions.py
  imports: |
    from __future__ import annotations
    from typing import Any, Optional
  body: |
    '\nSimPy specific exceptions.\n\n'
    class SimPyException(Exception):
        """Base class for all SimPy specific exceptions."""
    class Interrupt(SimPyException):
        """Exception thrown into a process if it is interrupted (see
        :func:`~simpy.events.Process.interrupt()`).

        :attr:`cause` provides the reason for the interrupt, if any.

        If a process is interrupted concurrently, all interrupts will be thrown
        into the process in the same order as they occurred.


        """

        def __init__(self, cause: Optional[Any]):
            super().__init__(cause)

        def __str__(self) -> str:
            return f'{self.__class__.__name__}({self.cause!r})'

        @property
        def cause(self) -> Optional[Any]:
            """The cause of the interrupt or ``None`` if no cause was provided."""
            pass


preamble resources___init__:
  source: simpy/resources/__init__.py
  body: |
    '\nSimPy implements three types of resources that can be used to synchronize\nprocesses or to model congestion points:\n\n.. currentmodule:: simpy.resources\n\n.. autosummary::\n\n   resource\n   container\n   store\n\nThey are derived from the base classes defined in the\n:mod:`~simpy.resources.base` module. These classes are also meant to support\nthe implementation of custom resource types.\n\n'


preamble resources_base:
  source: simpy/resources/base.py
  imports: |
    from __future__ import annotations
    from typing import TYPE_CHECKING, ClassVar, ContextManager, Generic, MutableSequence, Optional, Type, TypeVar, Union
    from simpy.core import BoundClass, Environment
    from simpy.events import Event, Process
  constants: |
    ResourceType = TypeVar('ResourceType', bound='BaseResource')
    PutType = TypeVar('PutType', bound=Put)
    GetType = TypeVar('GetType', bound=Get)
  body: |
    "\nBase classes of for SimPy's shared resource types.\n\n:class:`BaseResource` defines the abstract base resource. It supports *get* and\n*put* requests, which return :class:`Put` and :class:`Get` events respectively.\nThese events are triggered once the request has been completed.\n\n"
    if TYPE_CHECKING:
        from types import TracebackType
    class Put(Event, ContextManager['Put'], Generic[ResourceType]):
        """Generic event for requesting to put something into the *resource*.

        This event (and all of its subclasses) can act as context manager and can
        be used with the :keyword:`with` statement to automatically cancel the
        request if an exception (like an :class:`simpy.exceptions.Interrupt` for
        example) occurs:

        .. code-block:: python

            with res.put(item) as request:
                yield request

        """

        def __init__(self, resource: ResourceType):
            super().__init__(resource._env)
            self.resource = resource
            self.proc: Optional[Process] = self.env.active_process
            resource.put_queue.append(self)
            self.callbacks.append(resource._trigger_get)
            resource._trigger_put(None)

        def __enter__(self) -> Put:
            return self

        def __exit__(self, exc_type: Optional[Type[BaseException]], exc_value: Optional[BaseException], traceback: Optional[TracebackType]) -> Optional[bool]:
            self.cancel()
            return None

        def cancel(self) -> None:
            """Cancel this put request.

            This method has to be called if the put request must be aborted, for
            example if a process needs to handle an exception like an
            :class:`~simpy.exceptions.Interrupt`.

            If the put request was created in a :keyword:`with` statement, this
            method is called automatically.

            """
            pass
    class Get(Event, ContextManager['Get'], Generic[ResourceType]):
        """Generic event for requesting to get something from the *resource*.

        This event (and all of its subclasses) can act as context manager and can
        be used with the :keyword:`with` statement to automatically cancel the
        request if an exception (like an :class:`simpy.exceptions.Interrupt` for
        example) occurs:

        .. code-block:: python

            with res.get() as request:
                item = yield request

        """

        def __init__(self, resource: ResourceType):
            super().__init__(resource._env)
            self.resource = resource
            self.proc = self.env.active_process
            resource.get_queue.append(self)
            self.callbacks.append(resource._trigger_put)
            resource._trigger_get(None)

        def __enter__(self) -> Get:
            return self

        def __exit__(self, exc_type: Optional[Type[BaseException]], exc_value: Optional[BaseException], traceback: Optional[TracebackType]) -> Optional[bool]:
            self.cancel()
            return None

        def cancel(self) -> None:
            """Cancel this get request.

            This method has to be called if the get request must be aborted, for
            example if a process needs to handle an exception like an
            :class:`~simpy.exceptions.Interrupt`.

            If the get request was created in a :keyword:`with` statement, this
            method is called automatically.

            """
            pass
    class BaseResource(Generic[PutType, GetType]):
        """Abstract base class for a shared resource.

        You can :meth:`put()` something into the resources or :meth:`get()`
        something out of it. Both methods return an event that is triggered once
        the operation is completed. If a :meth:`put()` request cannot complete
        immediately (for example if the resource has reached a capacity limit) it
        is enqueued in the :attr:`put_queue` for later processing. Likewise for
        :meth:`get()` requests.

        Subclasses can customize the resource by:

        - providing custom :attr:`PutQueue` and :attr:`GetQueue` types,
        - providing custom :class:`Put` respectively :class:`Get` events,
        - and implementing the request processing behaviour through the methods
          ``_do_get()`` and ``_do_put()``.

        """
        PutQueue: ClassVar[Type[MutableSequence]] = list
        'The type to be used for the :attr:`put_queue`. It is a plain\n    :class:`list` by default. The type must support index access (e.g.\n    ``__getitem__()`` and ``__len__()``) as well as provide ``append()`` and\n    ``pop()`` operations.'
        GetQueue: ClassVar[Type[MutableSequence]] = list
        'The type to be used for the :attr:`get_queue`. It is a plain\n    :class:`list` by default. The type must support index access (e.g.\n    ``__getitem__()`` and ``__len__()``) as well as provide ``append()`` and\n    ``pop()`` operations.'

        def __init__(self, env: Environment, capacity: Union[float, int]):
            self._env = env
            self._capacity = capacity
            self.put_queue: MutableSequence[PutType] = self.PutQueue()
            'Queue of pending *put* requests.'
            self.get_queue: MutableSequence[GetType] = self.GetQueue()
            'Queue of pending *get* requests.'
            BoundClass.bind_early(self)

        @property
        def capacity(self) -> Union[float, int]:
            """Maximum capacity of the resource."""
            pass
        if TYPE_CHECKING:

            def put(self) -> Put:
                """Request to put something into the resource and return a
                :class:`Put` event, which gets triggered once the request
                succeeds."""
                pass

            def get(self) -> Get:
                """Request to get something from the resource and return a
                :class:`Get` event, which gets triggered once the request
                succeeds."""
                pass
        else:
            put = BoundClass(Put)
            get = BoundClass(Get)

        def _do_put(self, event: PutType) -> Optional[bool]:
            """Perform the *put* operation.

            This method needs to be implemented by subclasses. If the conditions
            for the put *event* are met, the method must trigger the event (e.g.
            call :meth:`Event.succeed()` with an appropriate value).

            This method is called by :meth:`_trigger_put` for every event in the
            :attr:`put_queue`, as long as the return value does not evaluate
            ``False``.
            """
            pass

        def _trigger_put(self, get_event: Optional[GetType]) -> None:
            """This method is called once a new put event has been created or a get
            event has been processed.

            The method iterates over all put events in the :attr:`put_queue` and
            calls :meth:`_do_put` to check if the conditions for the event are met.
            If :meth:`_do_put` returns ``False``, the iteration is stopped early.
            """
            pass

        def _do_get(self, event: GetType) -> Optional[bool]:
            """Perform the *get* operation.

            This method needs to be implemented by subclasses. If the conditions
            for the get *event* are met, the method must trigger the event (e.g.
            call :meth:`Event.succeed()` with an appropriate value).

            This method is called by :meth:`_trigger_get` for every event in the
            :attr:`get_queue`, as long as the return value does not evaluate
            ``False``.
            """
            pass

        def _trigger_get(self, put_event: Optional[PutType]) -> None:
            """Trigger get events.

            This method is called once a new get event has been created or a put
            event has been processed.

            The method iterates over all get events in the :attr:`get_queue` and
            calls :meth:`_do_get` to check if the conditions for the event are met.
            If :meth:`_do_get` returns ``False``, the iteration is stopped early.
            """
            pass


preamble resources_container:
  source: simpy/resources/container.py
  imports: |
    from __future__ import annotations
    from typing import TYPE_CHECKING, Optional, Union
    from simpy.core import BoundClass, Environment
    from simpy.resources import base
  constants: |
    ContainerAmount = Union[int, float]
  body: |
    "\nResource for sharing homogeneous matter between processes, either continuous\n(like water) or discrete (like apples).\n\nA :class:`Container` can be used to model the fuel tank of a gasoline station.\nTankers increase and refuelled cars decrease the amount of gas in the station's\nfuel tanks.\n\n"
    class ContainerPut(base.Put):
        """Request to put *amount* of matter into the *container*. The request will
        be triggered once there is enough space in the *container* available.

        Raise a :exc:`ValueError` if ``amount <= 0``.

        """

        def __init__(self, container: Container, amount: ContainerAmount):
            if amount <= 0:
                raise ValueError(f'amount(={amount}) must be > 0.')
            self.amount = amount
            'The amount of matter to be put into the container.'
            super().__init__(container)
    class ContainerGet(base.Get):
        """Request to get *amount* of matter from the *container*. The request will
        be triggered once there is enough matter available in the *container*.

        Raise a :exc:`ValueError` if ``amount <= 0``.

        """

        def __init__(self, container: Container, amount: ContainerAmount):
            if amount <= 0:
                raise ValueError(f'amount(={amount}) must be > 0.')
            self.amount = amount
            'The amount of matter to be taken out of the container.'
            super().__init__(container)
    class Container(base.BaseResource):
        """Resource containing up to *capacity* of matter which may either be
        continuous (like water) or discrete (like apples). It supports requests to
        put or get matter into/from the container.

        The *env* parameter is the :class:`~simpy.core.Environment` instance the
        container is bound to.

        The *capacity* defines the size of the container. By default, a container
        is of unlimited size. The initial amount of matter is specified by *init*
        and defaults to ``0``.

        Raise a :exc:`ValueError` if ``capacity <= 0``, ``init < 0`` or
        ``init > capacity``.

        """

        def __init__(self, env: Environment, capacity: ContainerAmount=float('inf'), init: ContainerAmount=0):
            if capacity <= 0:
                raise ValueError('"capacity" must be > 0.')
            if init < 0:
                raise ValueError('"init" must be >= 0.')
            if init > capacity:
                raise ValueError('"init" must be <= "capacity".')
            super().__init__(env, capacity)
            self._level = init

        @property
        def level(self) -> ContainerAmount:
            """The current amount of the matter in the container."""
            pass
        if TYPE_CHECKING:

            def put(self, amount: ContainerAmount) -> ContainerPut:
                """Request to put *amount* of matter into the container."""
                pass

            def get(self, amount: ContainerAmount) -> ContainerGet:
                """Request to get *amount* of matter out of the container."""
                pass
        else:
            put = BoundClass(ContainerPut)
            get = BoundClass(ContainerGet)


preamble resources_resource:
  source: simpy/resources/resource.py
  imports: |
    from __future__ import annotations
    from typing import TYPE_CHECKING, Any, List, Optional, Type
    from simpy.core import BoundClass, Environment, SimTime
    from simpy.resources import base
  body: |
    '\nShared resources supporting priorities and preemption.\n\nThese resources can be used to limit the number of processes using them\nconcurrently. A process needs to *request* the usage right to a resource. Once\nthe usage right is not needed any more it has to be *released*. A gas station\ncan be modelled as a resource with a limited amount of fuel-pumps. Vehicles\narrive at the gas station and request to use a fuel-pump. If all fuel-pumps are\nin use, the vehicle needs to wait until one of the users has finished refueling\nand releases its fuel-pump.\n\nThese resources can be used by a limited number of processes at a time.\nProcesses *request* these resources to become a user and have to *release* them\nonce they are done. For example, a gas station with a limited number of fuel\npumps can be modeled with a `Resource`. Arriving vehicles request a fuel-pump.\nOnce one is available they refuel. When they are done, the release the\nfuel-pump and leave the gas station.\n\nRequesting a resource is modelled as "putting a process\' token into the\nresources" and releasing a resources correspondingly as "getting a process\'\ntoken out of the resource". Thus, calling ``request()``/``release()`` is\nequivalent to calling ``put()``/``get()``. Note, that releasing a resource will\nalways succeed immediately, no matter if a process is actually using a resource\nor not.\n\nBesides :class:`Resource`, there is a :class:`PriorityResource`, where\nprocesses can define a request priority, and a :class:`PreemptiveResource`\nwhose resource users can be preempted by requests with a higher priority.\n\n'
    if TYPE_CHECKING:
        from types import TracebackType
        from simpy.events import Process
    class Preempted:
        """Cause of a preemption :class:`~simpy.exceptions.Interrupt` containing
        information about the preemption.

        """

        def __init__(self, by: Optional[Process], usage_since: Optional[SimTime], resource: Resource):
            self.by = by
            'The preempting :class:`simpy.events.Process`.'
            self.usage_since = usage_since
            'The simulation time at which the preempted process started to use\n        the resource.'
            self.resource = resource
            'The resource which was lost, i.e., caused the preemption.'
    class Request(base.Put):
        """Request usage of the *resource*. The event is triggered once access is
        granted. Subclass of :class:`simpy.resources.base.Put`.

        If the maximum capacity of users has not yet been reached, the request is
        triggered immediately. If the maximum capacity has been
        reached, the request is triggered once an earlier usage request on the
        resource is released.

        The request is automatically released when the request was created within
        a :keyword:`with` statement.

        """
        resource: Resource
        usage_since: Optional[SimTime] = None

        def __exit__(self, exc_type: Optional[Type[BaseException]], exc_value: Optional[BaseException], traceback: Optional[TracebackType]) -> Optional[bool]:
            super().__exit__(exc_type, exc_value, traceback)
            if exc_type is not GeneratorExit:
                self.resource.release(self)
            return None
    class Release(base.Get):
        """Releases the usage of *resource* granted by *request*. This event is
        triggered immediately. Subclass of :class:`simpy.resources.base.Get`.

        """

        def __init__(self, resource: Resource, request: Request):
            self.request = request
            'The request (:class:`Request`) that is to be released.'
            super().__init__(resource)
    class PriorityRequest(Request):
        """Request the usage of *resource* with a given *priority*. If the
        *resource* supports preemption and *preempt* is ``True`` other usage
        requests of the *resource* may be preempted (see
        :class:`PreemptiveResource` for details).

        This event type inherits :class:`Request` and adds some additional
        attributes needed by :class:`PriorityResource` and
        :class:`PreemptiveResource`

        """

        def __init__(self, resource: Resource, priority: int=0, preempt: bool=True):
            self.priority = priority
            'The priority of this request. A smaller number means higher\n        priority.'
            self.preempt = preempt
            'Indicates whether the request should preempt a resource user or not\n        (:class:`PriorityResource` ignores this flag).'
            self.time = resource._env.now
            'The time at which the request was made.'
            self.key = (self.priority, self.time, not self.preempt)
            'Key for sorting events. Consists of the priority (lower value is\n        more important), the time at which the request was made (earlier\n        requests are more important) and finally the preemption flag (preempt\n        requests are more important).'
            super().__init__(resource)
    class SortedQueue(list):
        """Queue for sorting events by their :attr:`~PriorityRequest.key`
        attribute.

        """

        def __init__(self, maxlen: Optional[int]=None):
            super().__init__()
            self.maxlen = maxlen
            'Maximum length of the queue.'

        def append(self, item: Any) -> None:
            """Sort *item* into the queue.

            Raise a :exc:`RuntimeError` if the queue is full.

            """
            pass
    class Resource(base.BaseResource):
        """Resource with *capacity* of usage slots that can be requested by
        processes.

        If all slots are taken, requests are enqueued. Once a usage request is
        released, a pending request will be triggered.

        The *env* parameter is the :class:`~simpy.core.Environment` instance the
        resource is bound to.

        """

        def __init__(self, env: Environment, capacity: int=1):
            if capacity <= 0:
                raise ValueError('"capacity" must be > 0.')
            super().__init__(env, capacity)
            self.users: List[Request] = []
            'List of :class:`Request` events for the processes that are currently\n        using the resource.'
            self.queue = self.put_queue
            'Queue of pending :class:`Request` events. Alias of\n        :attr:`~simpy.resources.base.BaseResource.put_queue`.\n        '

        @property
        def count(self) -> int:
            """Number of users currently using the resource."""
            pass
        if TYPE_CHECKING:

            def request(self) -> Request:
                """Request a usage slot."""
                pass

            def release(self, request: Request) -> Release:
                """Release a usage slot."""
                pass
        else:
            request = BoundClass(Request)
            release = BoundClass(Release)
    class PriorityResource(Resource):
        """A :class:`~simpy.resources.resource.Resource` supporting prioritized
        requests.

        Pending requests in the :attr:`~Resource.queue` are sorted in ascending
        order by their *priority* (that means lower values are more important).

        """
        PutQueue = SortedQueue
        'Type of the put queue. See\n    :attr:`~simpy.resources.base.BaseResource.put_queue` for details.'
        GetQueue = list
        'Type of the get queue. See\n    :attr:`~simpy.resources.base.BaseResource.get_queue` for details.'

        def __init__(self, env: Environment, capacity: int=1):
            super().__init__(env, capacity)
        if TYPE_CHECKING:

            def request(self, priority: int=0, preempt: bool=True) -> PriorityRequest:
                """Request a usage slot with the given *priority*."""
                pass

            def release(self, request: PriorityRequest) -> Release:
                """Release a usage slot."""
                pass
        else:
            request = BoundClass(PriorityRequest)
            release = BoundClass(Release)
    class PreemptiveResource(PriorityResource):
        """A :class:`~simpy.resources.resource.PriorityResource` with preemption.

        If a request is preempted, the process of that request will receive an
        :class:`~simpy.exceptions.Interrupt` with a :class:`Preempted` instance as
        cause.

        """
        users: List[PriorityRequest]


preamble resources_store:
  source: simpy/resources/store.py
  imports: |
    from __future__ import annotations
    from heapq import heappop, heappush
    from typing import TYPE_CHECKING, Any, Callable, List, NamedTuple, Optional, Union
    from simpy.core import BoundClass, Environment
    from simpy.resources import base
  body: |
    '\nShared resources for storing a possibly unlimited amount of objects supporting\nrequests for specific objects.\n\nThe :class:`Store` operates in a FIFO (first-in, first-out) order. Objects are\nretrieved from the store in the order they were put in. The *get* requests of a\n:class:`FilterStore` can be customized by a filter to only retrieve objects\nmatching a given criterion.\n\n'
    class StorePut(base.Put):
        """Request to put *item* into the *store*. The request is triggered once
        there is space for the item in the store.

        """

        def __init__(self, store: Store, item: Any):
            self.item = item
            'The item to put into the store.'
            super().__init__(store)
    class StoreGet(base.Get):
        """Request to get an *item* from the *store*. The request is triggered
        once there is an item available in the store.

        """
    class FilterStoreGet(StoreGet):
        """Request to get an *item* from the *store* matching the *filter*. The
        request is triggered once there is such an item available in the store.

        *filter* is a function receiving one item. It should return ``True`` for
        items matching the filter criterion. The default function returns ``True``
        for all items, which makes the request to behave exactly like
        :class:`StoreGet`.

        """

        def __init__(self, resource: FilterStore, filter: Callable[[Any], bool]=lambda item: True):
            self.filter = filter
            'The filter function to filter items in the store.'
            super().__init__(resource)
    class Store(base.BaseResource):
        """Resource with *capacity* slots for storing arbitrary objects. By
        default, the *capacity* is unlimited and objects are put and retrieved from
        the store in a first-in first-out order.

        The *env* parameter is the :class:`~simpy.core.Environment` instance the
        container is bound to.

        """

        def __init__(self, env: Environment, capacity: Union[float, int]=float('inf')):
            if capacity <= 0:
                raise ValueError('"capacity" must be > 0.')
            super().__init__(env, capacity)
            self.items: List[Any] = []
            'List of the items available in the store.'
        if TYPE_CHECKING:

            def put(self, item: Any) -> StorePut:
                """Request to put *item* into the store."""
                pass

            def get(self) -> StoreGet:
                """Request to get an *item* out of the store."""
                pass
        else:
            put = BoundClass(StorePut)
            get = BoundClass(StoreGet)
    class PriorityItem(NamedTuple):
        """Wrap an arbitrary *item* with an order-able *priority*.

        Pairs a *priority* with an arbitrary *item*. Comparisons of *PriorityItem*
        instances only consider the *priority* attribute, thus supporting use of
        unorderable items in a :class:`PriorityStore` instance.

        """
        priority: Any
        item: Any

        def __lt__(self, other: PriorityItem) -> bool:
            return self.priority < other.priority
    class PriorityStore(Store):
        """Resource with *capacity* slots for storing objects in priority order.

        Unlike :class:`Store` which provides first-in first-out discipline,
        :class:`PriorityStore` maintains items in sorted order such that
        the smallest items value are retrieved first from the store.

        All items in a *PriorityStore* instance must be order-able; which is to say
        that items must implement :meth:`~object.__lt__()`. To use unorderable
        items with *PriorityStore*, use :class:`PriorityItem`.

        """
    class FilterStore(Store):
        """Resource with *capacity* slots for storing arbitrary objects supporting
        filtered get requests. Like the :class:`Store`, the *capacity* is unlimited
        by default and objects are put and retrieved from the store in a first-in
        first-out order.

        Get requests can be customized with a filter function to only trigger for
        items for which said filter function returns ``True``.

        .. note::

            In contrast to :class:`Store`, get requests of a :class:`FilterStore`
            won't necessarily be triggered in the same order they were issued.

            *Example:* The store is empty. *Process 1* tries to get an item of type
            *a*, *Process 2* an item of type *b*. Another process puts one item of
            type *b* into the store. Though *Process 2* made his request after
            *Process 1*, it will receive that new item because *Process 1* doesn't
            want it.

        """
        if TYPE_CHECKING:

            def get(self, filter: Callable[[Any], bool]=lambda item: True) -> FilterStoreGet:
                """Request to get an *item*, for which *filter* returns ``True``,
                out of the store."""
                pass
        else:
            get = BoundClass(FilterStoreGet)


preamble rt:
  source: simpy/rt.py
  imports: |
    from time import monotonic, sleep
    from simpy.core import EmptySchedule, Environment, Infinity, SimTime
  body: |
    'Execution environment for events that synchronizes passing of time\nwith the real-time (aka *wall-clock time*).\n\n'
    class RealtimeEnvironment(Environment):
        """Execution environment for an event-based simulation which is
        synchronized with the real-time (also known as wall-clock time). A time
        step will take *factor* seconds of real time (one second by default).
        A step from ``0`` to ``3`` with a ``factor=0.5`` will, for example, take at
        least
        1.5 seconds.

        The :meth:`step()` method will raise a :exc:`RuntimeError` if a time step
        took too long to compute. This behaviour can be disabled by setting
        *strict* to ``False``.

        """

        def __init__(self, initial_time: SimTime=0, factor: float=1.0, strict: bool=True):
            Environment.__init__(self, initial_time)
            self.env_start = initial_time
            self.real_start = monotonic()
            self._factor = factor
            self._strict = strict

        @property
        def factor(self) -> float:
            """Scaling factor of the real-time."""
            pass

        @property
        def strict(self) -> bool:
            """Running mode of the environment. :meth:`step()` will raise a
            :exc:`RuntimeError` if this is set to ``True`` and the processing of
            events takes too long."""
            pass

        def sync(self) -> None:
            """Synchronize the internal time with the current wall-clock time.

            This can be useful to prevent :meth:`step()` from raising an error if
            a lot of time passes between creating the RealtimeEnvironment and
            calling :meth:`run()` or :meth:`step()`.

            """
            pass

        def step(self) -> None:
            """Process the next event after enough real-time has passed for the
            event to happen.

            The delay is scaled according to the real-time :attr:`factor`. With
            :attr:`strict` mode enabled, a :exc:`RuntimeError` will be raised, if
            the event is processed too slowly.

            """
            pass


preamble util:
  source: simpy/util.py
  imports: |
    from typing import Generator
    from simpy.core import Environment, SimTime
    from simpy.events import Event, Process, ProcessGenerator
  body: |
    '\nA collection of utility functions:\n\n.. autosummary::\n   start_delayed\n\n'


flow simpy_lib:
  steps:
    - core_group
    - events_group
    - exceptions_group
    - resources_base_group
    - resources_container_group
    - resources_resource_group
    - rt_group
    - util_group


flow core_group:
  steps:
    - BoundClass__bind_early
    - StopSimulation__callback
    - Environment__now
    - Environment__active_process
    - Environment__schedule
    - Environment__peek
    - Environment__step
    - Environment__run


flow events_group:
  steps:
    - Event___desc
    - Event__triggered
    - Event__processed
    - Event__ok
    - Event__defused
    - Event__value
    - Event__trigger
    - Event__succeed
    - Event__fail
    - Timeout___desc
    - Process___desc
    - Process__target
    - Process__name
    - Process__is_alive
    - Process__interrupt
    - Process___resume
    - Condition___desc
    - Condition___populate_value
    - Condition___build_value
    - Condition___remove_check_callbacks
    - Condition___check
    - Condition__all_events
    - Condition__any_events
    - _describe_frame


flow exceptions_group:
  steps:
    - Interrupt__cause


flow resources_base_group:
  steps:
    - Put__cancel
    - Get__cancel
    - BaseResource__capacity
    - BaseResource___do_put
    - BaseResource___trigger_put
    - BaseResource___do_get
    - BaseResource___trigger_get


flow resources_container_group:
  steps:
    - Container__level


flow resources_resource_group:
  steps:
    - SortedQueue__append
    - Resource__count


flow rt_group:
  steps:
    - RealtimeEnvironment__factor
    - RealtimeEnvironment__strict
    - RealtimeEnvironment__sync
    - RealtimeEnvironment__step


flow util_group:
  steps:
    - start_delayed
    - subscribe_at


code BoundClass__bind_early:
  body: |
    def bind_early(instance: object):
        """Bind all :class:`BoundClass` attributes of the *instance's* class
            to the instance itself to increase performance.
        """
        pass


code StopSimulation__callback:
  body: |
    def callback(cls, event: Event):
        """Used as callback in :meth:`Environment.run()` to stop the simulation
            when the *until* event occurred.
        """
        pass


code Environment__now:
  body: |
    def now(self):
        """The current simulation time."""
        pass


code Environment__active_process:
  body: |
    def active_process(self):
        """The currently active process of the environment."""
        pass


code Environment__schedule:
  body: |
    def schedule(self, event: Event, priority: EventPriority=NORMAL, delay: SimTime=0):
        """Schedule an *event* with a given *priority* and a *delay*."""
        pass


code Environment__peek:
  body: |
    def peek(self):
        """Get the time of the next scheduled event. Return
            :data:`~simpy.core.Infinity` if there is no further event.
        """
        pass


code Environment__step:
  body: |
    def step(self):
        """Process the next event.
    
            Raise an :exc:`EmptySchedule` if no further events are available.
    
            
        """
        pass


code Environment__run:
  body: |
    def run(self, until: Optional[Union[SimTime, Event]]=None):
        """Executes :meth:`step()` until the given criterion *until* is met.
    
            - If it is ``None`` (which is the default), this method will return
              when there are no further events to be processed.
    
            - If it is an :class:`~simpy.events.Event`, the method will continue
              stepping until this event has been triggered and will return its
              value.  Raises a :exc:`RuntimeError` if there are no further events
              to be processed and the *until* event was not triggered.
    
            - If it is a number, the method will continue stepping
              until the environment's time reaches *until*.
    
            
        """
        pass


code Event___desc:
  body: |
    def _desc(self):
        """Return a string *Event()*."""
        pass


code Event__triggered:
  body: |
    def triggered(self):
        """Becomes ``True`` if the event has been triggered and its callbacks
            are about to be invoked.
        """
        pass


code Event__processed:
  body: |
    def processed(self):
        """Becomes ``True`` if the event has been processed (e.g., its
            callbacks have been invoked).
        """
        pass


code Event__ok:
  body: |
    def ok(self):
        """Becomes ``True`` when the event has been triggered successfully.
    
            A "successful" event is one triggered with :meth:`succeed()`.
    
            :raises AttributeError: if accessed before the event is triggered.
    
            
        """
        pass


code Event__defused:
  body: |
    def defused(self):
        """Becomes ``True`` when the failed event's exception is "defused".
    
            When an event fails (i.e. with :meth:`fail()`), the failed event's
            `value` is an exception that will be re-raised when the
            :class:`~simpy.core.Environment` processes the event (i.e. in
            :meth:`~simpy.core.Environment.step()`).
    
            It is also possible for the failed event's exception to be defused by
            setting :attr:`defused` to ``True`` from an event callback. Doing so
            prevents the event's exception from being re-raised when the event is
            processed by the :class:`~simpy.core.Environment`.
    
            
        """
        pass


code Event__value:
  body: |
    def value(self):
        """The value of the event if it is available.
    
            The value is available when the event has been triggered.
    
            Raises :exc:`AttributeError` if the value is not yet available.
    
            
        """
        pass


code Event__trigger:
  body: |
    def trigger(self, event: Event):
        """Trigger the event with the state and value of the provided *event*.
            Return *self* (this event instance).
    
            This method can be used directly as a callback function to trigger
            chain reactions.
    
            
        """
        pass


code Event__succeed:
  body: |
    def succeed(self, value: Optional[Any]=None):
        """Set the event's value, mark it as successful and schedule it for
            processing by the environment. Returns the event instance.
    
            Raises :exc:`RuntimeError` if this event has already been triggerd.
    
            
        """
        pass


code Event__fail:
  body: |
    def fail(self, exception: Exception):
        """Set *exception* as the events value, mark it as failed and schedule
            it for processing by the environment. Returns the event instance.
    
            Raises :exc:`TypeError` if *exception* is not an :exc:`Exception`.
    
            Raises :exc:`RuntimeError` if this event has already been triggered.
    
            
        """
        pass


code Timeout___desc:
  body: |
    def _desc(self):
        """Return a string *Timeout(delay[, value=value])*."""
        pass


code Process___desc:
  body: |
    def _desc(self):
        """Return a string *Process(process_func_name)*."""
        pass


code Process__target:
  body: |
    def target(self):
        """The event that the process is currently waiting for.
    
            Returns ``None`` if the process is dead, or it is currently being
            interrupted.
    
            
        """
        pass


code Process__name:
  body: |
    def name(self):
        """Name of the function used to start the process."""
        pass


code Process__is_alive:
  body: |
    def is_alive(self):
        """``True`` until the process generator exits."""
        pass


code Process__interrupt:
  body: |
    def interrupt(self, cause: Optional[Any]=None):
        """Interrupt this process optionally providing a *cause*.
    
            A process cannot be interrupted if it already terminated. A process can
            also not interrupt itself. Raise a :exc:`RuntimeError` in these
            cases.
    
            
        """
        pass


code Process___resume:
  body: |
    def _resume(self, event: Event):
        """Resumes the execution of the process with the value of *event*. If
            the process generator exits, the process itself will get triggered with
            the return value or the exception of the generator.
        """
        pass


code Condition___desc:
  body: |
    def _desc(self):
        """Return a string *Condition(evaluate, [events])*."""
        pass


code Condition___populate_value:
  body: |
    def _populate_value(self, value: ConditionValue):
        """Populate the *value* by recursively visiting all nested
            conditions.
        """
        pass


code Condition___build_value:
  body: |
    def _build_value(self, event: Event):
        """Build the value of this condition."""
        pass


code Condition___remove_check_callbacks:
  body: |
    def _remove_check_callbacks(self):
        """Remove _check() callbacks from events recursively.
    
            Once the condition has triggered, the condition's events no longer need
            to have _check() callbacks. Removing the _check() callbacks is
            important to break circular references between the condition and
            untriggered events.
    
            
        """
        pass


code Condition___check:
  body: |
    def _check(self, event: Event):
        """Check if the condition was already met and schedule the *event* if
            so.
        """
        pass


code Condition__all_events:
  body: |
    def all_events(events: Tuple[Event, ...], count: int):
        """An evaluation function that returns ``True`` if all *events* have
            been triggered.
        """
        pass


code Condition__any_events:
  body: |
    def any_events(events: Tuple[Event, ...], count: int):
        """An evaluation function that returns ``True`` if at least one of
            *events* has been triggered.
        """
        pass


code _describe_frame:
  body: |
    def _describe_frame(frame: FrameType):
        """Print filename, line number and function name of a stack frame."""
        pass


code Interrupt__cause:
  body: |
    def cause(self):
        """The cause of the interrupt or ``None`` if no cause was provided."""
        pass


code Put__cancel:
  body: |
    def cancel(self):
        """Cancel this put request.
    
            This method has to be called if the put request must be aborted, for
            example if a process needs to handle an exception like an
            :class:`~simpy.exceptions.Interrupt`.
    
            If the put request was created in a :keyword:`with` statement, this
            method is called automatically.
    
            
        """
        pass


code Get__cancel:
  body: |
    def cancel(self):
        """Cancel this get request.
    
            This method has to be called if the get request must be aborted, for
            example if a process needs to handle an exception like an
            :class:`~simpy.exceptions.Interrupt`.
    
            If the get request was created in a :keyword:`with` statement, this
            method is called automatically.
    
            
        """
        pass


code BaseResource__capacity:
  body: |
    def capacity(self):
        """Maximum capacity of the resource."""
        pass


code BaseResource___do_put:
  body: |
    def _do_put(self, event: PutType):
        """Perform the *put* operation.
    
            This method needs to be implemented by subclasses. If the conditions
            for the put *event* are met, the method must trigger the event (e.g.
            call :meth:`Event.succeed()` with an appropriate value).
    
            This method is called by :meth:`_trigger_put` for every event in the
            :attr:`put_queue`, as long as the return value does not evaluate
            ``False``.
            
        """
        pass


code BaseResource___trigger_put:
  body: |
    def _trigger_put(self, get_event: Optional[GetType]):
        """This method is called once a new put event has been created or a get
            event has been processed.
    
            The method iterates over all put events in the :attr:`put_queue` and
            calls :meth:`_do_put` to check if the conditions for the event are met.
            If :meth:`_do_put` returns ``False``, the iteration is stopped early.
            
        """
        pass


code BaseResource___do_get:
  body: |
    def _do_get(self, event: GetType):
        """Perform the *get* operation.
    
            This method needs to be implemented by subclasses. If the conditions
            for the get *event* are met, the method must trigger the event (e.g.
            call :meth:`Event.succeed()` with an appropriate value).
    
            This method is called by :meth:`_trigger_get` for every event in the
            :attr:`get_queue`, as long as the return value does not evaluate
            ``False``.
            
        """
        pass


code BaseResource___trigger_get:
  body: |
    def _trigger_get(self, put_event: Optional[PutType]):
        """Trigger get events.
    
            This method is called once a new get event has been created or a put
            event has been processed.
    
            The method iterates over all get events in the :attr:`get_queue` and
            calls :meth:`_do_get` to check if the conditions for the event are met.
            If :meth:`_do_get` returns ``False``, the iteration is stopped early.
            
        """
        pass


code Container__level:
  body: |
    def level(self):
        """The current amount of the matter in the container."""
        pass


code SortedQueue__append:
  body: |
    def append(self, item: Any):
        """Sort *item* into the queue.
    
            Raise a :exc:`RuntimeError` if the queue is full.
    
            
        """
        pass


code Resource__count:
  body: |
    def count(self):
        """Number of users currently using the resource."""
        pass


code RealtimeEnvironment__factor:
  body: |
    def factor(self):
        """Scaling factor of the real-time."""
        pass


code RealtimeEnvironment__strict:
  body: |
    def strict(self):
        """Running mode of the environment. :meth:`step()` will raise a
            :exc:`RuntimeError` if this is set to ``True`` and the processing of
            events takes too long.
        """
        pass


code RealtimeEnvironment__sync:
  body: |
    def sync(self):
        """Synchronize the internal time with the current wall-clock time.
    
            This can be useful to prevent :meth:`step()` from raising an error if
            a lot of time passes between creating the RealtimeEnvironment and
            calling :meth:`run()` or :meth:`step()`.
    
            
        """
        pass


code RealtimeEnvironment__step:
  body: |
    def step(self):
        """Process the next event after enough real-time has passed for the
            event to happen.
    
            The delay is scaled according to the real-time :attr:`factor`. With
            :attr:`strict` mode enabled, a :exc:`RuntimeError` will be raised, if
            the event is processed too slowly.
    
            
        """
        pass


code start_delayed:
  body: |
    def start_delayed(env: Environment, generator: ProcessGenerator, delay: SimTime):
        """Return a helper process that starts another process for *generator*
        after a certain *delay*.
    
        :meth:`~simpy.core.Environment.process()` starts a process at the current
        simulation time. This helper allows you to start a process after a delay of
        *delay* simulation time units::
    
            >>> from simpy import Environment
            >>> from simpy.util import start_delayed
            >>> def my_process(env, x):
            ...     print(f'{env.now}, {x}')
            ...     yield env.timeout(1)
            ...
            >>> env = Environment()
            >>> proc = start_delayed(env, my_process(env, 3), 5)
            >>> env.run()
            5, 3
    
        Raise a :exc:`ValueError` if ``delay <= 0``.
    
        
        """
        pass


code subscribe_at:
  body: |
    def subscribe_at(event: Event):
        """Register at the *event* to receive an interrupt when it occurs.
    
        The most common use case for this is to pass
        a :class:`~simpy.events.Process` to get notified when it terminates.
    
        Raise a :exc:`RuntimeError` if ``event`` has already occurred.
    
        
        """
        pass
