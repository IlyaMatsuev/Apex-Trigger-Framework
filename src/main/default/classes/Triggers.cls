global class Triggers {
    private static Boolean skipAllHandlers;

    @TestVisible
    global static Dispatcher dispatcher {
        get {
            if (dispatcher == null) {
                dispatcher = new Dispatcher(new ContextFactory());
            }
            return dispatcher;
        }
        private set;
    }

    @TestVisible
    private Triggers() {
    }

    global class Dispatcher {
        private final ContextFactory contextFactory;
        private final List<Handler> handlers = new List<Handler>();

        @TestVisible
        private Dispatcher(ContextFactory contextFactory) {
            this.contextFactory = contextFactory;
        }

        global void run() {
            run(null);
        }

        global void run(IErrorHandler defaultErrorHandler) {
            if (!Trigger.isExecuting && !Test.isRunningTest()) {
                throw new TriggerDispatcherException('TriggerDispatcher cannot be run from the non-trigger context');
            }
            List<Handler> handlers = this.handlers.clone();
            this.handlers.clear();
            runHandlers(defaultErrorHandler, handlers);
        }

        global Dispatcher bind(TriggerOperation operation, IHandler handler) {
            return bind(operation, handler, new Map<BindOption, Object>());
        }

        global Dispatcher bind(TriggerOperation operation, IHandler handler, Map<BindOption, Object> options) {
            return addHandler(operation, handler, false, options);
        }

        global Dispatcher bindAsync(TriggerOperation operation, IHandler handler) {
            return bindAsync(operation, handler, new Map<BindOption, Object>());
        }

        global Dispatcher bindAsync(TriggerOperation operation, IHandler handler, Map<BindOption, Object> options) {
            return addHandler(operation, handler, true, options);
        }

        private Dispatcher addHandler(
            TriggerOperation operation,
            IHandler handler,
            Boolean async,
            Map<BindOption, Object> options
        ) {
            handlers.add(new Handler(operation, handler, async, options));
            return this;
        }

        private void runHandlers(IErrorHandler defaultErrorHandler, List<Handler> handlers) {
            Context context = contextFactory.create();
            for (Handler handler : handlers) {
                if (context.skips.skipAll) {
                    break;
                }
                if (defaultErrorHandler != null) {
                    handler.setDefaultErrorHandler(defaultErrorHandler);
                }
                if (!handler.isExecuted && handler.operation == context.props.operation) {
                    try {
                        if (context.skips.has(handler.name)) {
                            continue;
                        }
                        handler.handle(context);
                    } catch (Exception error) {
                        handler.handle(context, error);
                    } finally {
                        handler.executed();
                    }
                }
            }
        }
    }

    global class Context {
        global final Props props;
        global final Skips skips;
        global final Map<String, Object> stash = new Map<String, Object>();

        @TestVisible
        private Context(Props props, Skips skips) {
            this.props = props;
            this.skips = skips;
        }
    }

    global class Props {
        global final Boolean isBefore;
        global final Boolean isAfter;
        global final Boolean isInsert;
        global final Boolean isUpdate;
        global final Boolean isDelete;
        global final Boolean isUndelete;
        global final List<SObject> oldList;
        global final List<SObject> newList;
        global final Map<Id, SObject> oldMap;
        global final Map<Id, SObject> newMap;
        global final TriggerOperation operation;
        global final Integer size;
        global final Boolean isExecuting;

        global Boolean isAsync {
            get {
                return System.isQueueable();
            }
        }

        private Props() {
            isBefore = Trigger.isBefore;
            isAfter = Trigger.isAfter;
            isInsert = Trigger.isInsert;
            isUpdate = Trigger.isUpdate;
            isDelete = Trigger.isDelete;
            isUndelete = Trigger.isUndelete;
            oldList = Trigger.old;
            newList = Trigger.new;
            oldMap = Trigger.oldMap;
            newMap = Trigger.newMap;
            operation = Trigger.operationType;
            size = Trigger.size;
            isExecuting = Trigger.isExecuting;
        }

        @TestVisible
        private Props(TriggerOperation operation, List<SObject> oldList, List<SObject> newList) {
            String operationName = String.valueOf(operation);
            this.operation = operation;
            this.isBefore = operationName.startsWithIgnoreCase('before');
            this.isAfter = operationName.startsWithIgnoreCase('after');
            this.isInsert = operationName.endsWithIgnoreCase('insert');
            this.isUpdate = operationName.endsWithIgnoreCase('update');
            this.isDelete = operationName.endsWithIgnoreCase('delete');
            this.isUndelete = operationName.endsWithIgnoreCase('undelete');
            this.oldList = oldList;
            this.newList = newList;
            this.oldMap = oldList != null ? new Map<Id, SObject>(oldList) : null;
            this.newMap = (newList != null && (!isInsert || isAfter)) ? new Map<Id, SObject>(newList) : null;
            this.size = newList != null ? newList.size() : (oldList != null ? oldList.size() : 0);
            this.isExecuting = true;
        }
    }

    global class Skips {
        private final Set<String> skippedHandlers = new Set<String>();

        global Boolean skipAll {
            get {
                if (skipAllHandlers == null) {
                    skipAllHandlers = false;
                }
                return skipAllHandlers;
            }
        }

        @TestVisible
        private Skips() {
        }

        global void all() {
            all(true);
        }

        global void all(Boolean skipAll) {
            skipAllHandlers = skipAll;
        }

        global void byName(String handlerName) {
            byName(handlerName, true);
        }

        global void byName(String handlerName, Boolean skip) {
            if (skip) {
                skippedHandlers.add(handlerName);
            } else {
                skippedHandlers.remove(handlerName);
            }
        }

        global Boolean has(String handlerName) {
            return skippedHandlers.contains(handlerName);
        }

        global void clear() {
            skippedHandlers.clear();
        }
    }

    global class TriggerDispatcherException extends Exception {
    }

    global interface IHandler {
        void handle(Context context);
    }

    global interface IErrorHandler {
        void handle(Context context, Exception error);
    }

    global enum BindOption {
        Name,
        ErrorHandler
    }

    @TestVisible
    private virtual class ContextFactory {
        public virtual Context create() {
            return new Context(new Props(), new Skips());
        }
    }

    private class Handler implements IHandler, IErrorHandler, Queueable, Database.AllowsCallouts {
        private final IHandler handler;
        private final Context context;
        private final Boolean isAsync;
        private final TriggerOperation operation;
        private final Map<BindOption, Object> options;
        private Boolean isExecuted { get; private set; }

        private String name {
            get {
                return options.containsKey(BindOption.Name)
                    ? (String) options.get(BindOption.Name)
                    : getHandlerClassName();
            }
        }
        private IErrorHandler errorHandler {
            get {
                if (errorHandler == null) {
                    errorHandler = (IErrorHandler) options.get(BindOption.ErrorHandler);
                }
                return errorHandler;
            }
            private set;
        }

        private Handler(Context context, IHandler handler, IErrorHandler errorHandler) {
            this.context = context;
            this.handler = handler;
            this.errorHandler = errorHandler;
        }

        public Handler(TriggerOperation operation, IHandler handler, Boolean isAsync, Map<BindOption, Object> options) {
            this.operation = operation;
            this.handler = handler;
            this.isAsync = isAsync;
            this.options = options;
            this.isExecuted = false;
        }

        private void setDefaultErrorHandler(IErrorHandler defaultErrorHandler) {
            if (errorHandler == null) {
                options.put(BindOption.ErrorHandler, defaultErrorHandler);
            }
        }

        private void executed() {
            isExecuted = true;
        }

        public void handle(Context context) {
            if (isAsync) {
                System.enqueueJob(new Handler(context, handler, this));
            } else {
                handler.handle(context);
            }
        }

        public void handle(Context context, Exception error) {
            if (error instanceof TriggerDispatcherException || errorHandler == null) {
                throw error;
            }
            errorHandler.handle(context, error);
        }

        public void execute(QueueableContext queueableContext) {
            try {
                handler.handle(context);
            } catch (Exception error) {
                errorHandler.handle(context, error);
            }
        }

        private String getHandlerClassName() {
            return String.valueOf(handler).split(':').get(0);
        }
    }
}
