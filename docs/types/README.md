# Type Definitions

Here are only specified global Apex types that are supposed to be used by a user as part of this package.

### Classes

-   [TriggerDispatcher](#triggerdispatcher)
-   [TriggerContext](#triggercontext)
    -   [TriggerContext.Props](#triggercontextprops)
    -   [TriggerContext.Skips](#triggercontextskips)

### Interfaces

-   [ITriggerHandler](#itriggerhandler)
-   [ITriggerErrorHandler](#itriggererrorhandler)

### Enums

-   [TriggerOperation](#triggeroperation)
-   [TriggerBindOption](#triggerbindoption)
-   [AsyncHandlerType](#asynchandlertype)

---

### TriggerDispatcher

Dispatcher class for binding handlers for the trigger. Instance of the class can only be created via the `prepare` property.

#### Properties

`TriggerDispatcher prepare { get; }` - Returns the dispatcher instance.

#### Methods

`TriggerDispatcher bind(TriggerOperation operation, ITriggerHandler handler)` - Configure a handler to run for a particular trigger event.

`TriggerDispatcher bind(TriggerOperation operation, ITriggerHandler handler, Map<TriggerBindOption, Object> options)` - Configure a handler to run for a particular trigger event with the provided options.

`TriggerDispatcher bindAsync(TriggerOperation operation, ITriggerHandler handler)` - Configure an async handler to run for a particular trigger event.

`TriggerDispatcher bindAsync(TriggerOperation operation, ITriggerHandler handler, Map<TriggerBindOption, Object> options)` - Configure an async handler to run for a particular trigger event with the provided options.

`void run()` - This method is called at the end of the binding chain. Runs the appropriate trigger handlers.

`void run(ITriggerErrorHandler defaultErrorHandler)` - This method is called at the end of the binding chain. Runs the appropriate trigger handlers with the provided default error handler in case of an unhandled exception.

---

### TriggerContext

Class containing details about the trigger variables, skipping and stash functionality.

#### Fields

`Props props` - Instance of the `Props` class. Contains details about the trigger variables.

`Skips skips` - Instance of the `Skips` class. Provides trigger handlers skipping functionality.

`Map<String, Object> stash` - Stash that is shared across all handlers in scope of the trigger.

---

### TriggerContext.Props

Contains details about the trigger variables.

#### Fields

`Boolean isBefore` - True if executing inside the `before` trigger.

`Boolean isAfter` - True if executing inside the `after` trigger.

`Boolean isInsert` - True if executing inside the `insert` trigger.

`Boolean isUpdate` - True if executing inside the `update` trigger.

`Boolean isDelete` - True if executing inside the `delete` trigger.

`Boolean isUndelete` - True if executing inside the `undelete` trigger.

`TriggerOperation operation` - Current trigger event enum value.

`List<SObject> oldList` - Old list of changed records.

`List<SObject> newList` - New list of changed records.

`Integer size` - Size of the records processed in the current trigger execution context.

`Boolean` - True if executing inside the trigger context.

#### Properties

`Boolean isAsync` - True if the current trigger handler is running inside the async context.

`AsyncHandlerType asyncType` - Async type of the trigger handler execution. Null for the sync context.

---

### TriggerContext.Skips

Provides trigger handlers skipping functionality.

#### Properties

`Boolean skipAll` - True if all trigger handlers should be skipped at the moment.

#### Methods

`void all()` - Skip all following trigger handlers.

`void all(Boolean skipAll)` - Skip or unskip all following trigger handlers.

`void byName(String handlerName)` - Skip a following particular handler by its name.

`void byName(String handlerName, Boolean skip)` - Skip or unskip a following particular handler by its name.

`Boolean has(String handlerName)` - True if the provided handler is set to skip next.

`void clear()` - Removes all handler skips. The `skipAll` flag is not affected by this method.

---

### ITriggerHandler

Trigger handler implementation.

`void handle(TriggerContext context)` - Method that will be called from the trigger, passing the context.

---

### ITriggerErrorHandler

Trigger error handler implementation. Called whenever an unexpected error occurs.

`void handle(TriggerContext context, Exception error)` - Method that will be called from the trigger if an unexpected exception happens, passing the context and the exception instance.

---

### TriggerOperation

The standard Apex enum defining the trigger event types.

`BEFORE_INSERT`

`AFTER_INSERT`

`BEFORE_UPDATE`

`AFTER_UPDATE`

`BEFORE_DELETE`

`AFTER_DELETE`

`BEFORE_UNDELETE`

`AFTER_UNDELETE`

---

### TriggerBindOption

Binding option for the trigger handler configuration.

`HandlerName` - Explicit name of the trigger handler. By default it's the handler's class name.

`ErrorHandler` - Trigger error handler instance. Should implement the `ITriggerErrorHandler` interface.

`Delay` - The amount of minutes for the timeout. Applicable only for the async scheduled handlers.

`JobPrefix` - The prefix for a scheduled job. Applicable only for the async scheduled handlers.

---

### AsyncHandlerType

Trigger handler async type.

`Future` - Executes the handler right after the trigger event is executed. Uses Queuable Apex.

`Schedule` - Executes the handler after a certain timeout, specified in the binding options. Uses Batch Apex.

---
