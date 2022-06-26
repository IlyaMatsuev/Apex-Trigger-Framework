global class TriggerDispatcher {
    private final TriggerContextFactory contextFactory;
    private final List<TriggerHandlerWrapper> handlers = new List<TriggerHandlerWrapper>();

    @TestVisible
    global static TriggerDispatcher prepare {
        get {
            if (prepare == null) {
                prepare = new TriggerDispatcher(new TriggerContextFactory());
            }
            return prepare;
        }
        private set;
    }

    @TestVisible
    private TriggerDispatcher(TriggerContextFactory contextFactory) {
        this.contextFactory = contextFactory;
    }

    global void run() {
        run(null);
    }

    global void run(ITriggerErrorHandler defaultErrorHandler) {
        if (!Trigger.isExecuting && !Test.isRunningTest()) {
            throw new TriggerDispatcherException('TriggerDispatcher cannot be run from the non-trigger context');
        }
        List<TriggerHandlerWrapper> handlers = this.handlers.clone();
        this.handlers.clear();
        runHandlers(defaultErrorHandler, handlers);
    }

    global TriggerDispatcher bind(TriggerOperation operation, ITriggerHandler handler) {
        return bind(operation, handler, new Map<TriggerBindOption, Object>());
    }

    global TriggerDispatcher bind(
        TriggerOperation operation,
        ITriggerHandler handler,
        Map<TriggerBindOption, Object> options
    ) {
        return addHandler(operation, handler, false, options);
    }

    global TriggerDispatcher bindAsync(TriggerOperation operation, ITriggerHandler handler) {
        return bindAsync(operation, handler, new Map<TriggerBindOption, Object>());
    }

    global TriggerDispatcher bindAsync(
        TriggerOperation operation,
        ITriggerHandler handler,
        Map<TriggerBindOption, Object> options
    ) {
        return addHandler(operation, handler, true, options);
    }

    private TriggerDispatcher addHandler(
        TriggerOperation operation,
        ITriggerHandler handler,
        Boolean async,
        Map<TriggerBindOption, Object> options
    ) {
        options.put(TriggerBindOption.Async, async);
        handlers.add(new TriggerHandlerWrapper(operation, handler, options));
        return this;
    }

    private void runHandlers(ITriggerErrorHandler defaultErrorHandler, List<TriggerHandlerWrapper> handlers) {
        TriggerContext context = contextFactory.create();
        for (TriggerHandlerWrapper handlerWrapper : handlers) {
            if (context.skips.skipAll) {
                break;
            }
            if (defaultErrorHandler != null) {
                handlerWrapper.setDefaultErrorHandler(defaultErrorHandler);
            }
            if (!handlerWrapper.isExecuted && handlerWrapper.operation == context.props.operation) {
                try {
                    if (context.skips.has(handlerWrapper.name)) {
                        continue;
                    }
                    if (handlerWrapper.isAsync) {
                        AsyncTriggerHandlerContainer.handle(context, handlerWrapper);
                    } else {
                        handlerWrapper.handle(context);
                    }
                } catch (Exception error) {
                    handlerWrapper.handle(context, error);
                } finally {
                    handlerWrapper.executed();
                }
            }
        }
    }

    global class TriggerDispatcherException extends Exception {
    }
}
