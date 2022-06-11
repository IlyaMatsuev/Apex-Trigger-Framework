public class FutureTriggerHandlerContainer implements Queueable, IAsyncHandlerContainer, Database.AllowsCallouts {
    private final TriggerContext context;
    private final TriggerHandlerWrapper handlerWrapper;

    public FutureTriggerHandlerContainer() {
    }

    public FutureTriggerHandlerContainer(TriggerContext context, TriggerHandlerWrapper handlerWrapper) {
        this.context = context;
        this.handlerWrapper = handlerWrapper;
    }

    public void execute(TriggerContext context, TriggerHandlerWrapper handlerWrapper) {
        System.enqueueJob(new FutureTriggerHandlerContainer(context, handlerWrapper));
    }

    public void execute(QueueableContext queueableContext) {
        try {
            handlerWrapper.handle(context);
        } catch (Exception error) {
            handlerWrapper.handle(context, error);
        }
    }
}
