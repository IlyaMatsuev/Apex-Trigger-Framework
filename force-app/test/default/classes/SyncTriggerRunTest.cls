/**
 * Created by Ilya Matsuev on 7/11/2020.
 */

@IsTest
public with sharing class SyncTriggerRunTest {

    @IsTest
    public static void positiveOnlyHandlerRun() {
        Test.startTest();
        TriggerDispatcher.dispatcher
                .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler1())
                .run();
        Test.stopTest();

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(1, newAccounts.size());

        Account newAccount = newAccounts.get(0);
        System.assertEquals('test', newAccount.Name);
        System.assertEquals(TriggerOperation.BEFORE_INSERT.name(), newAccount.Description);
    }

    @IsTest
    public static void positiveHandlerAndServiceRun() {
        Test.startTest();
        Map<TriggerBindOption, Object> options = new Map<TriggerBindOption, Object> {
                TriggerBindOption.SERVICE => new AccountTriggerTestService1()
        };
        TriggerDispatcher.dispatcher
                .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler1(), options)
                .setDefaultService(new AccountTriggerTestService1())
                .run();
        Test.stopTest();

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(1, newAccounts.size());

        Account newAccount = newAccounts.get(0);
        System.assertEquals('test', newAccount.Name);
        System.assertEquals(TriggerOperation.BEFORE_INSERT.name(), newAccount.Description);
    }

    @IsTest
    public static void positiveHandlerServiceAndErrorHandlerRun() {
        Test.startTest();
        Map<TriggerBindOption, Object> options = new Map<TriggerBindOption, Object> {
                TriggerBindOption.SERVICE => new AccountTriggerTestService1(),
                TriggerBindOption.ERROR_HANDLER => new AccountTriggerTestErrorHandler1()
        };
        TriggerDispatcher.dispatcher
                .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler1(true), options)
                .setDefaultService(new AccountTriggerTestService1())
                .setDefaultErrorHandler(new AccountTriggerTestErrorHandler1())
                .run();
        Test.stopTest();

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(1, newAccounts.size());

        Account newAccount = newAccounts.get(0);
        System.assertEquals('Error handling test', newAccount.Name);
        System.assertEquals(TriggerOperation.BEFORE_INSERT.name(), newAccount.Description);
    }


    private class AccountTriggerTestHandler1 implements ITriggerHandler {

        private Boolean throwException = false;

        public AccountTriggerTestHandler1() {}

        public AccountTriggerTestHandler1(Boolean throwException) {
            this.throwException = throwException;
        }


        public void handle(TriggerContext context, ITriggerService service) {
            TriggerOperation triggerEvent = context.triggerEvent;
            TriggerType triggerType = context.predOrPost;
            AsyncHandlerType asyncHandlerType = context.asyncRunType;
            Boolean isAsync = context.isAsyncRun;

            context.properties.put('event', triggerEvent);
            context.properties.put('type', triggerType);
            context.properties.put('async type', asyncHandlerType);
            context.properties.put('is async', isAsync);

            Account testAccount = new Account(Name = 'test', Description = triggerEvent.name());

            if (service != null) {
                service.insertRelatedRecords();
                service.updateRelatedRecords();
                service.deleteRelatedRecords();
            }

            if (throwException) {
                throw new CalloutException('Error handling test');
            }

            insert testAccount;
        }
    }

    private class AccountTriggerTestService1 implements ITriggerService {

        public void insertRelatedRecords() {}

        public void updateRelatedRecords() {}

        public void deleteRelatedRecords() {}
    }

    private class AccountTriggerTestErrorHandler1 implements ITriggerErrorHandler {

        public void handle(TriggerContext context, Exception error) {
            TriggerContext.skipAllHandlers();
            insert new Account(Name = error.getMessage(), Description = context.properties.get('event').toString());
        }
    }
}
