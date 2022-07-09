# Type Definitions

Here are only specified global Apex types that are supposed to be used by a user as part of this package.

**All types below are made as nested classes of the `Triggers` class.**

### Classes

-   [Dispatcher](#dispatcher)
-   [Context](#context)
    -   [Props](#props)
    -   [Skips](#skips)

### Interfaces

-   [IHandler](#ihandler)
-   [IErrorHandler](#ierrorhandler)

### Enums

-   [BindOption](#bindoption)
-   [TriggerOperation](#triggeroperation)

---

### Dispatcher

Dispatcher class for binding handlers for the trigger. Instance of the class can only be created via the `Triggers.dispatcher` property.

#### Methods

`Dispatcher bind(TriggerOperation operation, IHandler handler)` - Configure a handler to run for a particular trigger event.

`Dispatcher bind(TriggerOperation operation, IHandler handler, Map<BindOption, Object> options)` - Configure a handler to run for a particular trigger event with the provided options.

`Dispatcher bindAsync(TriggerOperation operation, IHandler handler)` - Configure an async handler to run for a particular trigger event.

`Dispatcher bindAsync(TriggerOperation operation, IHandler handler, Map<BindOption, Object> options)` - Configure an async handler to run for a particular trigger event with the provided options.

`void run()` - This method is called at the end of the binding chain. Runs the appropriate trigger handlers.

`void run(IErrorHandler defaultErrorHandler)` - This method is called at the end of the binding chain. Runs the appropriate trigger handlers with the provided default error handler in case of an unhandled exception.

---

### Context

Class containing details about the trigger variables, skipping and stash functionality.

#### Fields

`Props props` - Instance of the `Props` class. Contains details about the trigger variables.

`Skips skips` - Instance of the `Skips` class. Provides trigger handlers skipping functionality.

`Map<String, Object> stash` - Stash that is shared across all handlers in scope of the trigger.

---

### Props

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

`Boolean isExecuting` - True if executing inside the trigger context.

`Boolean isAsync` - True if the current trigger handler is running inside the async context.

---

### Context.Skips

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

### IHandler

Trigger handler implementation.

`void handle(Context context)` - Method that will be called from the trigger, passing the context.

---

### IErrorHandler

Trigger error handler implementation. Called whenever an unexpected error occurs.

`void handle(Context context, Exception error)` - Method that will be called from the trigger if an unexpected exception happens, passing the context and the exception instance.

---

### BindOption

Binding option for the trigger handler configuration.

`Name` - Explicit name of the trigger handler. By default it's the handler's class name.

`ErrorHandler` - Trigger error handler instance. Should implement the `IErrorHandler` interface.

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
