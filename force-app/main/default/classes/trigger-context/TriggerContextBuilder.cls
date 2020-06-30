/**
 * Created by Ilya Matsuev on 7/1/2020.
 */

public with sharing class TriggerContextBuilder {

    public static TriggerContext getContext() {
        return new TriggerContext(getTriggerEvent(), getTriggerType());
    }


    private static TriggerOperation getTriggerEvent() {
        return Trigger.operationType;
    }

    private static TriggerType getTriggerType() {
        return Trigger.isAfter ? TriggerType.AFTER : TriggerType.BEFORE;
    }
}
