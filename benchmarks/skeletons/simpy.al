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
