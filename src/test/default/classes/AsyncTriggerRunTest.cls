@IsTest
private class AsyncTriggerRunTest {
    @IsTest
    private static void beforeInsertFutureTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        TriggerDispatcher.prepare = new TriggerDispatcher(contextFactory);

        Test.startTest();
        TriggerDispatcher.prepare.bindAsync(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler()).run();
        Test.stopTest();

        TriggerContext context = contextFactory.create();
        System.assertEquals(null, (Integer) context.stash.get('count'));
    }

    @IsTest
    private static void beforeInsertWithDefaultErrorHandlerFutureTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        TriggerDispatcher.prepare = new TriggerDispatcher(contextFactory);

        Test.startTest();
        TriggerDispatcher.prepare
            .bindAsync(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true))
            .run(new AccountTriggerTestHandler());
        Test.stopTest();

        TriggerContext context = contextFactory.create();
        System.assertEquals(null, (Integer) context.stash.get('count'));
        System.assertEquals(null, (String) context.stash.get('error'));
    }

    @IsTest
    private static void beforeInsertWithErrorHandlerFutureTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        TriggerDispatcher.prepare = new TriggerDispatcher(contextFactory);

        Test.startTest();
        TriggerDispatcher.prepare
            .bindAsync(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(true),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.ErrorHandler => new AccountTriggerTestHandler() }
            )
            .run();
        Test.stopTest();

        TriggerContext context = contextFactory.create();
        System.assertEquals(null, (Integer) context.stash.get('count'));
        System.assertEquals(null, (String) context.stash.get('error'));
    }

    @IsTest
    private static void beforeInsertWithoutErrorHandlerFutureNegativeTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        TriggerDispatcher.prepare = new TriggerDispatcher(contextFactory);

        Exception error;
        try {
            Test.startTest();
            TriggerDispatcher.prepare.bindAsync(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true))
                .run();
            Test.stopTest();
        } catch (Exception ex) {
            error = ex;
        }

        TriggerContext context = contextFactory.create();
        System.assertEquals(null, (Integer) context.stash.get('count'));
        System.assert(error != null);
        System.assert(error instanceof CalloutException);
    }

    @IsTest
    private static void beforeInsertScheduleTest() {
        TriggerDispatcher.prepare = new TriggerDispatcher(new FakeTriggerContextFactory());
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
        TriggerDispatcher.prepare = new TriggerDispatcher(new FakeTriggerContextFactory());

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
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        TriggerDispatcher.prepare = new TriggerDispatcher(contextFactory);
        TriggerHandlerWrapper handlerWrapper = new TriggerHandlerWrapper(
            TriggerOperation.BEFORE_INSERT,
            new AccountTriggerTestHandler(),
            new Map<TriggerBindOption, Object>()
        );

        Exception error;
        try {
            AsyncTriggerHandlerContainer.handle(new FakeTriggerContextFactory().create(), handlerWrapper);
        } catch (Exception ex) {
            error = ex;
        }

        TriggerContext context = contextFactory.create();
        System.assertEquals(null, (Integer) context.stash.get('count'));
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

    private class FakeTriggerContextFactory extends TriggerContextFactory {
        private final TriggerContext context;

        public FakeTriggerContextFactory() {
            List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
            context = new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList));
        }

        public override TriggerContext create() {
            return context;
        }
    }
}
