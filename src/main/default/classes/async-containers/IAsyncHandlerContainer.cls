public interface IAsyncHandlerContainer {
    void execute(TriggerContext context, TriggerHandlerWrapper handlerWrapper);
}
