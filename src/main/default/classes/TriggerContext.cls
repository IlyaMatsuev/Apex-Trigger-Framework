global class TriggerContext {
    private static Boolean skipAllHandlers = false;
    global final Props props;
    global final Skips skips;
    global final Map<String, Object> stash = new Map<String, Object>();

    public TriggerContext() {
        this(new Props());
    }

    @TestVisible
    private TriggerContext(Props props) {
        this.props = props;
        this.skips = new Skips();
    }

    global class Props {
        global final Boolean isBefore;
        global final Boolean isAfter;
        global final Boolean isInsert;
        global final Boolean isUpdate;
        global final Boolean isDelete;
        global final Boolean isUndelete;
        global final List<SObject> oldList;
        global final List<SObject> newList;
        global final Map<Id, SObject> oldMap;
        global final Map<Id, SObject> newMap;
        global final TriggerOperation operation;
        global final Integer size;

        global Boolean isExecuting { get; private set; }
        global Boolean isAsync {
            get {
                return asyncType != null;
            }
        }
        global AsyncHandlerType asyncType {
            get {
                if (System.isQueueable()) {
                    return AsyncHandlerType.Future;
                } else if (System.isBatch()) {
                    return AsyncHandlerType.Schedule;
                }
                return null;
            }
        }

        private Props() {
            isBefore = Trigger.isBefore;
            isAfter = Trigger.isAfter;
            isInsert = Trigger.isInsert;
            isUpdate = Trigger.isUpdate;
            isDelete = Trigger.isDelete;
            isUndelete = Trigger.isUndelete;
            oldList = Trigger.old;
            newList = Trigger.new;
            oldMap = Trigger.oldMap;
            newMap = Trigger.newMap;
            operation = Trigger.operationType;
            size = Trigger.size;
            isExecuting = true;
        }

        @TestVisible
        private Props(TriggerOperation operation, List<SObject> oldList, List<SObject> newList) {
            String operationName = String.valueOf(operation);
            this.operation = operation;
            this.isBefore = operationName.startsWithIgnoreCase('before');
            this.isAfter = operationName.startsWithIgnoreCase('after');
            this.isInsert = operationName.endsWithIgnoreCase('insert');
            this.isUpdate = operationName.endsWithIgnoreCase('update');
            this.isDelete = operationName.endsWithIgnoreCase('delete');
            this.isUndelete = operationName.endsWithIgnoreCase('undelete');
            this.oldList = oldList;
            this.newList = newList;
            this.oldMap = oldList != null ? new Map<Id, SObject>(oldList) : null;
            this.newMap = newList != null ? new Map<Id, SObject>(newList) : null;
            this.size = newList != null ? newList.size() : (oldList != null ? oldList.size() : 0);
            this.isExecuting = true;
        }
    }

    global class Skips {
        private final Set<String> skippedHandlers = new Set<String>();

        global Boolean skipAll {
            get {
                return skipAllHandlers;
            }
        }

        private Skips() {
        }

        global void all() {
            all(false);
        }

        global void all(Boolean skipAll) {
            skipAllHandlers = skipAll;
        }

        global void add(String handlerName) {
            skippedHandlers.add(handlerName);
        }

        global void remove(String handlerName) {
            skippedHandlers.remove(handlerName);
        }

        global Boolean has(String handlerName) {
            return skippedHandlers.contains(handlerName);
        }

        global void clear() {
            skippedHandlers.clear();
        }
    }
}
