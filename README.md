# Apex Trigger Framework

TODO: Badges

## Features

-   Delegating trigger handlers for different Apex jobs in scope of a DML transaction - [Show](https://github.com/IlyaMatsuev/Apex-Trigger-Helper-Library#usage)
-   Exchanging parameters between all handlers (from one to other and in reverse) - [Show](https://github.com/IlyaMatsuev/Apex-Trigger-Helper-Library#properties)
-   Opportunity to skip particular handlers (or all of them) - [Show](https://github.com/IlyaMatsuev/Apex-Trigger-Helper-Library#skipallhandlers)
-   Setting trigger error handler instance for a particular handler or for all of them - [Show](https://github.com/IlyaMatsuev/Apex-Trigger-Helper-Library#TriggerDispatcher)
-   Binding asynchronous trigger handlers - [Show](https://github.com/IlyaMatsuev/Apex-Trigger-Helper-Library#bindAsync)
-   Scheduling handlers to run in a particular time (for instance, in 3 minutes) - [Show](https://github.com/IlyaMatsuev/Apex-Trigger-Helper-Library#bindAsync)

## Overview

TODO: overview

## Installation

### From Unmanaged Package

You can just install the package by the link on a [sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=<package-id>) or [dev org](https://login.salesforce.com/packaging/installPackage.apexp?p0=<package-id>).

If you prefer using salesforce CLI you can run:

```
sfdx force:package:install -p <package-id> -w 10 -b 10 -u <username>
```

### From Source

You can also install the package with the automated scripts: [`pkg-deploy.sh`](scripts/pkg-deploy.sh) and [`pkg-from-scratch.sh`](scripts/pkg-from-scratch.sh).  
First is for deploying changes to the existing org.

```
./scripts/pkg-deploy.sh <username-or-alias>
```

Second is for creating a new configured scratch org.

```
./scripts/pkg-from-scratch.sh <devhub-username-or-alias> <new-scratch-org-alias>
```

## Configuration

Custom settings, custom metadata or any other configuration example.

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
