/**
 * Created by Ilya Matsuev on 7/11/2020.
 */

@IsTest
public with sharing class SyncTriggerRunTest {
    @IsTest
    public static void positiveOnlyHandlerRun() {
        TriggerContext.runningTests = true;

        Test.startTest();
        TriggerDispatcher.dispatcher.bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler()).run();
        Test.stopTest();

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(1, newAccounts.size());

        Account newAccount = newAccounts.get(0);
        System.assertEquals('test', newAccount.Name);
        System.assertEquals(TriggerOperation.BEFORE_INSERT.name(), newAccount.Description);
    }

    @IsTest
    public static void positiveHandlerAndErrorHandlerRun() {
        TriggerContext.runningTests = true;

        Test.startTest();
        Map<TriggerBindOption, Object> options = new Map<TriggerBindOption, Object>{
            TriggerBindOption.ERROR_HANDLER => new AccountTriggerTestErrorHandler()
        };
        TriggerDispatcher.dispatcher
            .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true), options)
            .setDefaultErrorHandler(new AccountTriggerTestErrorHandler())
            .run();
        Test.stopTest();

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(1, newAccounts.size());

        Account newAccount = newAccounts.get(0);
        System.assertEquals('Error handling test', newAccount.Name);
        System.assertEquals(TriggerOperation.BEFORE_INSERT.name(), newAccount.Description);
    }

    private class AccountTriggerTestHandler implements ITriggerHandler {
        private Boolean throwException = false;

        public AccountTriggerTestHandler() {
        }

        public AccountTriggerTestHandler(Boolean throwException) {
            this.throwException = throwException;
        }

        public void handle(TriggerContext context) {
            TriggerOperation triggerEvent = context.triggerEvent;
            TriggerType triggerType = context.predOrPost;
            AsyncHandlerType asyncHandlerType = context.asyncRunType;
            Boolean isAsync = context.isAsyncRun;
            List<SObject> newList = context.newList;
            List<SObject> oldList = context.oldList;
            Map<Id, SObject> newMap = context.newMap;
            Map<Id, SObject> oldMap = context.oldMap;

            context.properties.put('event', triggerEvent);
            context.properties.put('type', triggerType);
            context.properties.put('async type', asyncHandlerType);
            context.properties.put('is async', isAsync);

            Account testAccount = new Account(Name = 'test', Description = triggerEvent.name());

            if (throwException) {
                throw new CalloutException('Error handling test');
            }

            insert testAccount;
        }
    }

    private class AccountTriggerTestErrorHandler implements ITriggerErrorHandler {
        public void handle(TriggerContext context, Exception error) {
            TriggerContext.skipAllHandlers();
            insert new Account(Name = error.getMessage(), Description = context.properties.get('event').toString());
        }
    }
}