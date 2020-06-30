/**
 * Created by Ilya Matsuev on 7/4/2020.
 */

public with sharing class FutureTriggerHandlerContainer implements IAsyncHandlerContainer {

    public void execute(TriggerContext context, ITriggerHandler handler, Map<TriggerBindOption, Object> options) {
        executeContainer(JSON.serialize(new ContainerParametersWrapper(context, handler, options)));
    }

    @future(callout=true)
    private static void executeContainer(String jsonParameters) {
        ContainerParametersWrapper paramsWrapper = (ContainerParametersWrapper) JSON.deserialize(jsonParameters, ContainerParametersWrapper.class);
        TriggerContext context = paramsWrapper.context;
        ITriggerHandler handler = paramsWrapper.handler;
        ITriggerService service = (ITriggerService) paramsWrapper.options.get(TriggerBindOption.SERVICE);
        ITriggerErrorHandler errorHandler = (ITriggerErrorHandler) paramsWrapper.options.get(TriggerBindOption.ERROR_HANDLER);
        try {
            handler.handle(context, service);
        } catch(TriggerDispatcherException error) {
            throw error;
        } catch(Exception error) {
            if (errorHandler == null) {
                throw error;
            } else {
                errorHandler.handle(context, error);
            }
        }
    }

    private class ContainerParametersWrapper {
        public TriggerContext context;
        public ITriggerHandler handler;
        public Map<TriggerBindOption, Object> options;

        public ContainerParametersWrapper(TriggerContext context, ITriggerHandler handler, Map<TriggerBindOption, Object> options) {
            this.context = context;
            this.handler = handler;
            this.options = options;
        }
    }
}
