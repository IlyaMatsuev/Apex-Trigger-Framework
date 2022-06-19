public class AsyncTriggerHandlerContainer implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    private final TriggerContext context;
    private final TriggerHandlerWrapper handlerWrapper;

    private AsyncTriggerHandlerContainer(TriggerContext context, TriggerHandlerWrapper handlerWrapper) {
        this.context = context;
        this.handlerWrapper = handlerWrapper;
    }

    public static void handle(TriggerContext context, TriggerHandlerWrapper handlerWrapper) {
        if (handlerWrapper.asyncType == AsyncHandlerType.Future) {
            System.enqueueJob(new QueueableContainer(context, handlerWrapper));
        } else if (handlerWrapper.asyncType == AsyncHandlerType.Schedule) {
            System.scheduleBatch(
                new AsyncTriggerHandlerContainer(context, handlerWrapper),
                handlerWrapper.jobName,
                handlerWrapper.delay
            );
        } else {
            throw new TriggerDispatcher.TriggerDispatcherException(
                'Running sync handler in async container is not allowed'
            );
        }
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

    private class QueueableContainer implements Queueable, Database.AllowsCallouts {
        private final TriggerContext context;
        private final TriggerHandlerWrapper handlerWrapper;

        private QueueableContainer(TriggerContext context, TriggerHandlerWrapper handlerWrapper) {
            this.context = context;
            this.handlerWrapper = handlerWrapper;
        }

        public void execute(QueueableContext queueableContext) {
            try {
                handlerWrapper.handle(context);
            } catch (Exception error) {
                handlerWrapper.handle(context, error);
            }
        }
    }
}
