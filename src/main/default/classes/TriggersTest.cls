@IsTest(IsParallel=true)
private class TriggersTest {
    /**
     * Sync tests
     */
    @IsTest
    private static void beforeInsertTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        Triggers.dispatcher = new Triggers.Dispatcher(contextFactory);

        Test.startTest();
        Triggers.dispatcher.bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler()).run();
        Test.stopTest();

        Triggers.Context context = contextFactory.create();
        System.assertEquals(1, (Integer) context.stash.get('count'));
    }

    @IsTest
    private static void beforeInsertWithDefaultErrorHandlerTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        Triggers.dispatcher = new Triggers.Dispatcher(contextFactory);

        Test.startTest();
        Triggers.dispatcher
            .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true))
            .run(new AccountTriggerTestHandler());
        Test.stopTest();

        Triggers.Context context = contextFactory.create();
        System.assertEquals(null, (Integer) context.stash.get('count'));
        System.assertEquals('Error', (String) context.stash.get('error'));
    }

    @IsTest
    private static void beforeInsertWithoutErrorHandlerNegativeTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        Triggers.dispatcher = new Triggers.Dispatcher(contextFactory);

        Exception error;
        try {
            Test.startTest();
            Triggers.dispatcher.bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true)).run();
            Test.stopTest();
        } catch (Exception ex) {
            error = ex;
        }

        Triggers.Context context = contextFactory.create();
        System.assertEquals(null, (Integer) context.stash.get('count'));
        System.assert(error != null);
        System.assert(error instanceof CalloutException);
    }

    @IsTest
    private static void skipAllHandlersTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        Triggers.dispatcher = new Triggers.Dispatcher(contextFactory);

        Test.startTest();
        Triggers.dispatcher
            .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler())
            .bind(TriggerOperation.BEFORE_INSERT, new SkipTriggerHandler())
            .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler())
            .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler())
            .run();
        Test.stopTest();

        Triggers.Context context = contextFactory.create();
        System.assertEquals(1, (Integer) context.stash.get('count'));
    }

    @IsTest
    private static void skipHandlerByNameTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        Triggers.dispatcher = new Triggers.Dispatcher(contextFactory);

        Test.startTest();
        Triggers.dispatcher
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<Triggers.BindOption, Object>{ Triggers.BindOption.Name => 'testHandler1' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new SkipTriggerHandler('testHandler3'),
                new Map<Triggers.BindOption, Object>{ Triggers.BindOption.Name => 'testHandler2' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<Triggers.BindOption, Object>{ Triggers.BindOption.Name => 'testHandler3' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<Triggers.BindOption, Object>{ Triggers.BindOption.Name => 'testHandler4' }
            )
            .run();
        Test.stopTest();

        Triggers.Context context = contextFactory.create();
        System.assertEquals(2, (Integer) context.stash.get('count'));
    }

    @IsTest
    private static void skipAndResumeHandlerByNameTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        Triggers.dispatcher = new Triggers.Dispatcher(contextFactory);

        Test.startTest();
        Triggers.dispatcher
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<Triggers.BindOption, Object>{ Triggers.BindOption.Name => 'testHandler1' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new SkipTriggerHandler('testHandler4'),
                new Map<Triggers.BindOption, Object>{ Triggers.BindOption.Name => 'testHandler2' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new ResumeTriggerHandler('testHandler4'),
                new Map<Triggers.BindOption, Object>{ Triggers.BindOption.Name => 'testHandler3' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<Triggers.BindOption, Object>{ Triggers.BindOption.Name => 'testHandler4' }
            )
            .run();
        Test.stopTest();

        Triggers.Context context = contextFactory.create();
        System.assertEquals(2, (Integer) context.stash.get('count'));
    }

    @IsTest
    private static void skipAndResumeAllHandlersTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        Triggers.dispatcher = new Triggers.Dispatcher(contextFactory);

        Test.startTest();
        Triggers.dispatcher
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<Triggers.BindOption, Object>{ Triggers.BindOption.Name => 'testHandler1' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new SkipTriggerHandler('testHandler4'),
                new Map<Triggers.BindOption, Object>{ Triggers.BindOption.Name => 'testHandler2' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new ResumeTriggerHandler(),
                new Map<Triggers.BindOption, Object>{ Triggers.BindOption.Name => 'testHandler3' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<Triggers.BindOption, Object>{ Triggers.BindOption.Name => 'testHandler4' }
            )
            .run();
        Test.stopTest();

        Triggers.Context context = contextFactory.create();
        System.assertEquals(2, (Integer) context.stash.get('count'));
    }

    @IsTest
    private static void triggerCtorTest() {
        // The purpose of this test is to cover the Triggers constructor
        new Triggers();
    }

    @IsTest
    private static void triggerDispatcherInstanceTest() {
        // The purpose of this test is to cover the Triggers.dispatcher instance
        Triggers.Dispatcher dispatcher = Triggers.dispatcher;
    }

    @IsTest
    private static void triggerContextFactoryTest() {
        // The purpose of this test is to cover the Triggers.ContextFactory class
        new Triggers.ContextFactory().create();
    }

    /**
     * Async tests
     */
    @IsTest
    private static void beforeInsertAsyncHandlerTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        Triggers.dispatcher = new Triggers.Dispatcher(contextFactory);

        Test.startTest();
        Triggers.dispatcher.bindAsync(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true, false)).run();
        Test.stopTest();

        Triggers.Context context = contextFactory.create();
        System.assertEquals(null, (Integer) context.stash.get('count'));
    }

    @IsTest
    private static void beforeInsertWithDefaultErrorHandlerAsyncHandlerTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        Triggers.dispatcher = new Triggers.Dispatcher(contextFactory);

        Test.startTest();
        Triggers.dispatcher
            .bindAsync(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true, true))
            .run(new AccountTriggerTestHandler());
        Test.stopTest();

        Triggers.Context context = contextFactory.create();
        System.assertEquals(null, (Integer) context.stash.get('count'));
        System.assertEquals(null, (String) context.stash.get('error'));
    }

    @IsTest
    private static void beforeInsertWithErrorHandlerAsyncHandlerTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        Triggers.dispatcher = new Triggers.Dispatcher(contextFactory);

        Test.startTest();
        Triggers.dispatcher
            .bindAsync(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(true, true),
                new Map<Triggers.BindOption, Object>{
                    Triggers.BindOption.ErrorHandler => new AccountTriggerTestHandler()
                }
            )
            .run();
        Test.stopTest();

        Triggers.Context context = contextFactory.create();
        System.assertEquals(null, (Integer) context.stash.get('count'));
        System.assertEquals(null, (String) context.stash.get('error'));
    }

    @IsTest
    private static void beforeInsertWithoutErrorHandlerAsyncHandlerNegativeTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        Triggers.dispatcher = new Triggers.Dispatcher(contextFactory);

        Exception error;
        try {
            Test.startTest();
            Triggers.dispatcher.bindAsync(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true)).run();
            Test.stopTest();
        } catch (Exception ex) {
            error = ex;
        }

        Triggers.Context context = contextFactory.create();
        System.assertEquals(null, (Integer) context.stash.get('count'));
        System.assert(error != null);
        System.assert(error instanceof CalloutException);
    }

    private class AccountTriggerTestHandler implements Triggers.IHandler, Triggers.IErrorHandler {
        private final Boolean isAsync;
        private final Boolean throwException;

        public AccountTriggerTestHandler() {
            this(false);
        }

        public AccountTriggerTestHandler(Boolean throwException) {
            this(false, throwException);
        }

        public AccountTriggerTestHandler(Boolean isAsync, Boolean throwException) {
            this.isAsync = isAsync;
            this.throwException = throwException;
        }

        public void handle(Triggers.Context context) {
            if (throwException) {
                throw new CalloutException('Error');
            }

            System.assertEquals(isAsync, context.props.isAsync);

            Integer count = context.stash.containsKey('count') ? (Integer) context.stash.get('count') : 0;
            context.stash.put('count', ++count);
        }

        public void handle(Triggers.Context context, Exception error) {
            context.stash.put('error', error.getMessage());
        }
    }

    private class SkipTriggerHandler implements Triggers.IHandler {
        private final String handlerName;

        public SkipTriggerHandler() {
            this(null);
        }

        public SkipTriggerHandler(String handlerName) {
            this.handlerName = handlerName;
        }

        public void handle(Triggers.Context context) {
            if (String.isBlank(handlerName)) {
                context.skips.all();
            } else {
                context.skips.byName(handlerName);
            }
        }
    }

    private class ResumeTriggerHandler implements Triggers.IHandler {
        private final String handlerName;

        public ResumeTriggerHandler() {
            this(null);
        }

        public ResumeTriggerHandler(String handlerName) {
            this.handlerName = handlerName;
        }

        public void handle(Triggers.Context context) {
            if (String.isBlank(handlerName)) {
                context.skips.clear();
            } else {
                context.skips.byName(handlerName, false);
            }
        }
    }

    private class FakeTriggerContextFactory extends Triggers.ContextFactory {
        private final Triggers.Context context;

        public FakeTriggerContextFactory() {
            List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
            context = new Triggers.Context(
                new Triggers.Props(TriggerOperation.BEFORE_INSERT, null, newList),
                new Triggers.Skips()
            );
        }

        public override Triggers.Context create() {
            return context;
        }
    }
}
