/**
 * Created by Ilya Matsuev on 7/1/2020.
 */

global with sharing class TriggerContext {

    global TriggerOperation triggerEvent {
        get {
            if (Test.isRunningTest()) {
                return TriggerOperation.BEFORE_INSERT;
            }
            return Trigger.operationType;
        }
    }
    global TriggerType predOrPost {
        get {
            if (Test.isRunningTest()) {
                return TriggerType.BEFORE;
            }
            return Trigger.isAfter ? TriggerType.AFTER : TriggerType.BEFORE;
        }
    }
    global Boolean isAsyncRun {
        get {
            return asyncRunType != null;
        }
    }
    global AsyncHandlerType asyncRunType {
        get {
            if (System.isFuture()) {
                return AsyncHandlerType.FUTURE;
            } else if (System.isScheduled()) {
                return AsyncHandlerType.SCHEDULABLE;
            }
            return null;
        }
    }
    global final Map<String, Object> properties {get; private set;}

    global static Boolean skippingAllHandlers {get; private set;}
    global static final Set<String> handlersToBeSkipped {get; private set;}

    static {
        skippingAllHandlers = false;
        handlersToBeSkipped = new Set<String>();
    }

    public TriggerContext() {
        this.properties = new Map<String, Object>();
    }


    global static void skipAllHandlers() {
        skippingAllHandlers = true;
    }

    global static void doNotSkipAllHandlers() {
        skippingAllHandlers = false;
    }

    global static void skipHandler(String handlerTypeName) {
        handlersToBeSkipped.add(handlerTypeName);
    }

    global static void doNotSkipHandler(String handlerTypeName) {
        handlersToBeSkipped.remove(handlerTypeName);
    }

    public static String getClassName(Object obj) {
        return String.valueOf(obj).split(':').get(0);
    }
}
