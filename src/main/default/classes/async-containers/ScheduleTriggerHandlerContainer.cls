public class ScheduleTriggerHandlerContainer implements Database.Batchable<SObject>, IAsyncHandlerContainer, Database.AllowsCallouts, Database.Stateful {
    private final TriggerContext context;
    private final TriggerHandlerWrapper handlerWrapper;

    public ScheduleTriggerHandlerContainer() {
    }

    public ScheduleTriggerHandlerContainer(TriggerContext context, TriggerHandlerWrapper handlerWrapper) {
        this.context = context;
        this.handlerWrapper = handlerWrapper;
    }

    public void execute(TriggerContext context, TriggerHandlerWrapper handlerWrapper) {
        if (handlerWrapper.delay == null) {
            throw new TriggerDispatcher.TriggerDispatcherException('No delay value provided to the handler');
        }
        System.scheduleBatch(
            new ScheduleTriggerHandlerContainer(context, handlerWrapper),
            handlerWrapper.jobName,
            handlerWrapper.delay
        );
    }

    public List<SObject> start(Database.BatchableContext batchableContext) {
        return [SELECT Id FROM Organization LIMIT 1];
    }

    public void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        try {
            handlerWrapper.handle(context);
        } catch (Exception error) {
            handlerWrapper.handle(context, error);
        }
    }

    public void finish(Database.BatchableContext batchableContext) {
    }
}
