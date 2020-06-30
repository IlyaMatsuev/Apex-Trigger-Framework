/**
 * Created by Ilya Matsuev on 7/10/2020.
 */

public with sharing class ScheduleTriggerHandlerContainer implements Database.Batchable<SObject>, IAsyncHandlerContainer, Database.AllowsCallouts, Database.Stateful {

    private TriggerContext context;
    private ITriggerHandler handler;
    private Map<TriggerBindOption, Object> options;

    private final String DEFAULT_JOB_PREFIX = 'Schedulable_job-';

    public ScheduleTriggerHandlerContainer() {}

    public ScheduleTriggerHandlerContainer(TriggerContext context, ITriggerHandler handler, Map<TriggerBindOption, Object> options) {
        this.context = context;
        this.handler = handler;
        this.options = options;
    }


    public void execute(TriggerContext context, ITriggerHandler handler, Map<TriggerBindOption, Object> options) {
        Integer delayMinutes = (Integer) options.get(TriggerBindOption.DELAY);
        String jobPrefix = (String) options.get(TriggerBindOption.JOB_PREFIX);
        if (delayMinutes == null) {
            throw new TriggerDispatcherException('Delay option must be indicated for a schedulable handler run');
        }
        if (String.isBlank(jobPrefix)) {
            jobPrefix = DEFAULT_JOB_PREFIX;
        }
        String completeJobName = jobPrefix + context.getClassName(handler) + System.now().getTime();
        System.scheduleBatch(new ScheduleTriggerHandlerContainer(context, handler, options), completeJobName, delayMinutes);
    }

    public void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        ITriggerService service = (ITriggerService) options.get(TriggerBindOption.SERVICE);
        ITriggerErrorHandler errorHandler = (ITriggerErrorHandler) options.get(TriggerBindOption.ERROR_HANDLER);
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

    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        return null;
    }

    public void finish(Database.BatchableContext batchableContext) {}
}
