public class TriggerHandlerWrapper implements ITriggerHandler, ITriggerErrorHandler {
    private final static String DEFAULT_JOB_PREFIX = 'ScheduleHandlerJob-';

    public Boolean isExecuted { get; private set; }
    public final TriggerOperation operation;
    public final ITriggerHandler handler;
    private final Map<TriggerBindOption, Object> options;

    public String name {
        get {
            return options.containsKey(TriggerBindOption.HandlerName)
                ? (String) options.get(TriggerBindOption.HandlerName)
                : getHandlerClassName();
        }
    }
    public ITriggerErrorHandler errorHandler {
        get {
            return (ITriggerErrorHandler) options.get(TriggerBindOption.ErrorHandler);
        }
    }
    public Boolean isAsync {
        get {
            return options.get(TriggerBindOption.Async) == true;
        }
    }
    public AsyncHandlerType asyncType {
        get {
            if (!isAsync) {
                return null;
            }
            return options.containsKey(TriggerBindOption.Delay) ? AsyncHandlerType.Schedule : AsyncHandlerType.Future;
        }
    }
    public Integer delay {
        get {
            return (Integer) options.get(TriggerBindOption.Delay);
        }
    }
    public String jobName {
        get {
            String prefix = options.containsKey(TriggerBindOption.JobPrefix)
                ? (String) options.get(TriggerBindOption.JobPrefix)
                : DEFAULT_JOB_PREFIX;
            return prefix + getHandlerClassName() + DateTime.now().getTime();
        }
    }

    public TriggerHandlerWrapper(
        TriggerOperation operation,
        ITriggerHandler handler,
        Map<TriggerBindOption, Object> options
    ) {
        this.operation = operation;
        this.handler = handler;
        this.options = options;
        this.isExecuted = false;
    }

    public void setDefaultErrorHandler(ITriggerErrorHandler defaultErrorHandler) {
        if (errorHandler == null) {
            options.put(TriggerBindOption.ErrorHandler, defaultErrorHandler);
        }
    }

    public void executed() {
        isExecuted = true;
    }

    public void handle(TriggerContext context) {
        handler.handle(context);
    }

    public void handle(TriggerContext context, Exception error) {
        if (error instanceof TriggerDispatcher.TriggerDispatcherException || errorHandler == null) {
            throw error;
        }
        errorHandler.handle(context, error);
    }

    private String getHandlerClassName() {
        return String.valueOf(handler).split(':').get(0);
    }
}
