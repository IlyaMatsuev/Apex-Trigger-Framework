@IsTest
private class AsyncTriggerRunTest {
    @IsTest
    private static void beforeInsertFutureTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerDispatcher.prepare = new TriggerDispatcher(
            new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList))
        );

        Test.startTest();
        TriggerDispatcher.prepare.bindAsync(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler()).run();
        Test.stopTest();

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(1, newAccounts.size());
        System.assertEquals('Test', newAccounts.get(0).Name);
        System.assertEquals('Test description', newAccounts.get(0).Description);
    }

    @IsTest
    private static void beforeInsertWithDefaultErrorHandlerFutureTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerDispatcher.prepare = new TriggerDispatcher(
            new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList))
        );

        Test.startTest();
        TriggerDispatcher.prepare
            .bindAsync(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true))
            .run(new AccountTriggerTestHandler());
        Test.stopTest();

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(1, newAccounts.size());
        System.assertEquals('Error', newAccounts.get(0).Name);
        System.assertEquals(TriggerOperation.BEFORE_INSERT.name(), newAccounts.get(0).Description);
    }

    @IsTest
    private static void beforeInsertWithErrorHandlerFutureTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerDispatcher.prepare = new TriggerDispatcher(
            new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList))
        );

        Test.startTest();
        TriggerDispatcher.prepare
            .bindAsync(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(true),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.ErrorHandler => new AccountTriggerTestHandler() }
            )
            .run();
        Test.stopTest();

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(1, newAccounts.size());
        System.assertEquals('Error', newAccounts.get(0).Name);
        System.assertEquals(TriggerOperation.BEFORE_INSERT.name(), newAccounts.get(0).Description);
    }

    @IsTest
    private static void beforeInsertWithoutErrorHandlerFutureNegativeTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerDispatcher.prepare = new TriggerDispatcher(
            new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList))
        );

        Exception error;
        try {
            Test.startTest();
            TriggerDispatcher.prepare.bindAsync(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true))
                .run();
            Test.stopTest();
        } catch (Exception ex) {
            error = ex;
        }

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assert(newAccounts.isEmpty());
        System.assert(error != null);
        System.assert(error instanceof CalloutException);
    }

    @IsTest
    private static void beforeInsertScheduleTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerDispatcher.prepare = new TriggerDispatcher(
            new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList))
        );
        Map<TriggerBindOption, Object> options = new Map<TriggerBindOption, Object>{
            TriggerBindOption.Delay => 1,
            TriggerBindOption.JobPrefix => 'test-'
        };

        Test.startTest();
        TriggerDispatcher.prepare.bindAsync(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(AsyncHandlerType.Schedule),
                options
            )
            .run();
        Test.stopTest();

        List<CronTrigger> lastSubmittedJob = [
            SELECT CronJobDetail.Name
            FROM CronTrigger
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, lastSubmittedJob.size());
        System.assert(lastSubmittedJob.get(0).CronJobDetail.Name.startsWith('test-AccountTriggerTestHandler'));
    }

    @IsTest
    private static void beforeInsertWithDefaultErrorHandlerScheduleTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerDispatcher.prepare = new TriggerDispatcher(
            new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList))
        );

        Test.startTest();
        TriggerDispatcher.prepare
            .bindAsync(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(AsyncHandlerType.Schedule, true),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.Delay => 1 }
            )
            .run(new AccountTriggerTestHandler());
        Test.stopTest();

        List<CronTrigger> lastSubmittedJob = [
            SELECT CronJobDetail.Name
            FROM CronTrigger
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, lastSubmittedJob.size());
        System.assert(
            lastSubmittedJob.get(0).CronJobDetail.Name.startsWith('ScheduleHandlerJob-AccountTriggerTestHandler')
        );
    }

    @IsTest
    private static void syncHandlerInAsyncContainerNegativeTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerContext context = new TriggerContext(
            new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList)
        );
        TriggerHandlerWrapper handlerWrapper = new TriggerHandlerWrapper(
            TriggerOperation.BEFORE_INSERT,
            new AccountTriggerTestHandler(),
            new Map<TriggerBindOption, Object>()
        );

        Exception error;
        try {
            AsyncTriggerHandlerContainer.handle(context, handlerWrapper);
        } catch (Exception ex) {
            error = ex;
        }

        System.debug(error.getMessage());
        System.debug(error.getStackTraceString());
        System.assert(error != null);
        System.assert(error instanceof TriggerDispatcher.TriggerDispatcherException);
    }

    private class AccountTriggerTestHandler implements ITriggerHandler, ITriggerErrorHandler {
        private final Boolean throwException;
        private final AsyncHandlerType asyncType;

        public AccountTriggerTestHandler() {
            this(AsyncHandlerType.Future, false);
        }

        public AccountTriggerTestHandler(AsyncHandlerType asyncType) {
            this(asyncType, false);
        }

        public AccountTriggerTestHandler(Boolean throwException) {
            this(AsyncHandlerType.Future, throwException);
        }

        public AccountTriggerTestHandler(AsyncHandlerType asyncType, Boolean throwException) {
            this.asyncType = asyncType;
            this.throwException = throwException;
        }

        public void handle(TriggerContext context) {
            if (throwException) {
                throw new CalloutException('Error');
            }

            System.assert(context.props.isAsync);
            System.assert(context.props.asyncType == asyncType);

            insert context.props.newList.deepClone();
        }

        public void handle(TriggerContext context, Exception error) {
            insert new Account(Name = error.getMessage(), Description = context.props.operation.name());
        }
    }
}
