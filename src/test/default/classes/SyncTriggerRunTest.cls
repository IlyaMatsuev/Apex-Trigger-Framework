@IsTest(IsParallel=true)
private class SyncTriggerRunTest {
    @IsTest
    private static void beforeInsertTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        TriggerDispatcher.prepare = new TriggerDispatcher(contextFactory);

        Test.startTest();
        TriggerDispatcher.prepare.bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler()).run();
        Test.stopTest();

        TriggerContext context = contextFactory.create();
        System.assertEquals(1, (Integer) context.stash.get('count'));
    }

    @IsTest
    private static void beforeInsertWithDefaultErrorHandlerTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        TriggerDispatcher.prepare = new TriggerDispatcher(contextFactory);

        Test.startTest();
        TriggerDispatcher.prepare
            .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true))
            .run(new AccountTriggerTestHandler());
        Test.stopTest();

        TriggerContext context = contextFactory.create();
        System.assertEquals(null, (Integer) context.stash.get('count'));
        System.assertEquals('Error', (String) context.stash.get('error'));
    }

    @IsTest
    private static void beforeInsertWithoutErrorHandlerNegativeTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        TriggerDispatcher.prepare = new TriggerDispatcher(contextFactory);

        Exception error;
        try {
            Test.startTest();
            TriggerDispatcher.prepare.bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true)).run();
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
    private static void skipAllHandlersTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        TriggerDispatcher.prepare = new TriggerDispatcher(contextFactory);

        Test.startTest();
        TriggerDispatcher.prepare
            .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler())
            .bind(TriggerOperation.BEFORE_INSERT, new SkipTriggerHandler())
            .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler())
            .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler())
            .run();
        Test.stopTest();

        TriggerContext context = contextFactory.create();
        System.assertEquals(1, (Integer) context.stash.get('count'));
    }

    @IsTest
    private static void skipHandlerByNameTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        TriggerDispatcher.prepare = new TriggerDispatcher(contextFactory);

        Test.startTest();
        TriggerDispatcher.prepare
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.HandlerName => 'testHandler1' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new SkipTriggerHandler('testHandler3'),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.HandlerName => 'testHandler2' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.HandlerName => 'testHandler3' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.HandlerName => 'testHandler4' }
            )
            .run();
        Test.stopTest();

        TriggerContext context = contextFactory.create();
        System.assertEquals(2, (Integer) context.stash.get('count'));
    }

    @IsTest
    private static void skipAndResumeHandlerByNameTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        TriggerDispatcher.prepare = new TriggerDispatcher(contextFactory);

        Test.startTest();
        TriggerDispatcher.prepare
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.HandlerName => 'testHandler1' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new SkipTriggerHandler('testHandler4'),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.HandlerName => 'testHandler2' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new ResumeTriggerHandler('testHandler4'),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.HandlerName => 'testHandler3' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.HandlerName => 'testHandler4' }
            )
            .run();
        Test.stopTest();

        TriggerContext context = contextFactory.create();
        System.assertEquals(2, (Integer) context.stash.get('count'));
    }

    @IsTest
    private static void skipAndResumeAllHandlersTest() {
        FakeTriggerContextFactory contextFactory = new FakeTriggerContextFactory();
        TriggerDispatcher.prepare = new TriggerDispatcher(contextFactory);

        Test.startTest();
        TriggerDispatcher.prepare
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.HandlerName => 'testHandler1' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new SkipTriggerHandler('testHandler4'),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.HandlerName => 'testHandler2' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new ResumeTriggerHandler(),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.HandlerName => 'testHandler3' }
            )
            .bind(
                TriggerOperation.BEFORE_INSERT,
                new AccountTriggerTestHandler(),
                new Map<TriggerBindOption, Object>{ TriggerBindOption.HandlerName => 'testHandler4' }
            )
            .run();
        Test.stopTest();

        TriggerContext context = contextFactory.create();
        System.assertEquals(2, (Integer) context.stash.get('count'));
    }

    @IsTest
    static void triggerContextFactoryTest() {
        // The purpose of this test is to cover the TriggerContextFactory class
        new TriggerContextFactory().create();
    }

    private class AccountTriggerTestHandler implements ITriggerHandler, ITriggerErrorHandler {
        private final Boolean throwException;

        public AccountTriggerTestHandler() {
            this(false);
        }

        public AccountTriggerTestHandler(Boolean throwException) {
            this.throwException = throwException;
        }

        public void handle(TriggerContext context) {
            if (throwException) {
                throw new CalloutException('Error');
            }

            System.assert(!context.props.isAsync);

            Integer count = context.stash.containsKey('count') ? (Integer) context.stash.get('count') : 0;
            context.stash.put('count', ++count);
        }

        public void handle(TriggerContext context, Exception error) {
            context.stash.put('error', error.getMessage());
        }
    }

    private class SkipTriggerHandler implements ITriggerHandler {
        private final String handlerName;

        public SkipTriggerHandler() {
            this(null);
        }

        public SkipTriggerHandler(String handlerName) {
            this.handlerName = handlerName;
        }

        public void handle(TriggerContext context) {
            if (String.isBlank(handlerName)) {
                context.skips.all();
            } else {
                context.skips.byName(handlerName);
            }
        }
    }

    private class ResumeTriggerHandler implements ITriggerHandler {
        private final String handlerName;

        public ResumeTriggerHandler() {
            this(null);
        }

        public ResumeTriggerHandler(String handlerName) {
            this.handlerName = handlerName;
        }

        public void handle(TriggerContext context) {
            if (String.isBlank(handlerName)) {
                context.skips.clear();
            } else {
                context.skips.byName(handlerName, false);
            }
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
