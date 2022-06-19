@IsTest(IsParallel=true)
private class SyncTriggerRunTest {
    @IsTest
    private static void beforeInsertTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerDispatcher.prepare = new TriggerDispatcher(
            new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList))
        );

        Test.startTest();
        TriggerDispatcher.prepare.bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler()).run();
        Test.stopTest();

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(1, newAccounts.size());
        System.assertEquals('Test', newAccounts.get(0).Name);
        System.assertEquals('Test description', newAccounts.get(0).Description);
    }

    @IsTest
    private static void beforeInsertWithDefaultErrorHandlerTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerDispatcher.prepare = new TriggerDispatcher(
            new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList))
        );

        Test.startTest();
        TriggerDispatcher.prepare
            .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true))
            .run(new AccountTriggerTestHandler());
        Test.stopTest();

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(1, newAccounts.size());
        System.assertEquals('Error', newAccounts.get(0).Name);
        System.assertEquals(TriggerOperation.BEFORE_INSERT.name(), newAccounts.get(0).Description);
    }

    @IsTest
    private static void beforeInsertWithoutErrorHandlerNegativeTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerDispatcher.prepare = new TriggerDispatcher(
            new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList))
        );

        Exception error;
        try {
            Test.startTest();
            TriggerDispatcher.prepare.bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler(true)).run();
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
    private static void skipAllHandlersTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerDispatcher.prepare = new TriggerDispatcher(
            new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList))
        );

        Test.startTest();
        TriggerDispatcher.prepare
            .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler())
            .bind(TriggerOperation.BEFORE_INSERT, new SkipTriggerHandler())
            .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler())
            .bind(TriggerOperation.BEFORE_INSERT, new AccountTriggerTestHandler())
            .run();
        Test.stopTest();

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(1, newAccounts.size());
    }

    @IsTest
    private static void skipHandlerByNameTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerDispatcher.prepare = new TriggerDispatcher(
            new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList))
        );

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

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(2, newAccounts.size());
    }

    @IsTest
    private static void skipAndResumeHandlerByNameTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerDispatcher.prepare = new TriggerDispatcher(
            new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList))
        );

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

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(2, newAccounts.size());
    }

    @IsTest
    private static void skipAndResumeAllHandlersTest() {
        List<Account> newList = new List<Account>{ new Account(Name = 'Test', Description = 'Test description') };
        TriggerDispatcher.prepare = new TriggerDispatcher(
            new TriggerContext(new TriggerContext.Props(TriggerOperation.BEFORE_INSERT, null, newList))
        );

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

        List<Account> newAccounts = [SELECT Name, Description FROM Account];
        System.assertEquals(2, newAccounts.size());
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

            insert context.props.newList.deepClone();
        }

        public void handle(TriggerContext context, Exception error) {
            insert new Account(Name = error.getMessage(), Description = context.props.operation.name());
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
}
