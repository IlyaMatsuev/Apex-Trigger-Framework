# Apex Trigger Framework

[![Scratch org CI](https://github.com/IlyaMatsuev/Apex-Trigger-Framework/actions/workflows/scratch-org-ci.yml/badge.svg?branch=main)](https://github.com/IlyaMatsuev/Apex-Trigger-Framework/actions/workflows/scratch-org-ci.yml)

Simple Apex Trigger Framework wrapped as an unlocked package. Contains the following features:

-   Delegating trigger handlers
-   Exchanging parameters between all handlers
-   Skiping mechanism
-   Configuring trigger error handlers
-   Binding asynchronous trigger handlers
-   Schedule trigger handlers

## Overview

To create a trigger handler you first need to implement the `ITriggerHandler` interface:

```java
public class TestTriggerHandler implements ITriggerHandler {
    public void handle(TriggerContext context) {
        // Sample logic
        Integer count = context.stash.containsKey('count') ? (Integer) context.stash.get('count') : 0;
        context.stash.put('count', ++count);
        System.debug('count: ' + count);
    }
}
```

The example of using the framework:

```java
trigger Account on Account (before insert, before update, before delete, after insert, after update, after delete) {
	TriggerDispatcher.prepare
        .bind(TriggerOperation.AFTER_INSERT, new TestTriggerHandler())
        .bind(TriggerOperation.AFTER_UPDATE, new TestTriggerHandler())
        .bindAsync(TriggerOperation.AFTER_DELETE, new TestAsyncTriggerHandler())
        .run();
}
```

First, setup all your handlers by calling `bind()` or `bindAsync()` methods from the `TriggerDispatcher.prepare` instance. After all handlers set you call the `run()` method.

## Installation

You can just install the package by the link on a [sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t5Y000001wN95QAE) or [dev org](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5Y000001wN95QAE).

If you prefer using salesforce CLI you can run:

```
sfdx force:package:install -p 04t5Y000001wN95QAE -w 10 -b 10 -u <username>
```

## Documentation

For more detailed information about the content of the repository and the sfdx package, please visit the [docs folder](docs).

## Questions

If you have any questions you can start a discussion.  
If you think something works not as expected or you want to request a new feature, you can create an issue with the appropriate template selected.

## Contributing

Pull requests are welcome.  
For major changes, please open an issue first to discuss what you would like to change.  
Please make sure to update tests as appropriate.

## License

[MIT](LICENSE)
