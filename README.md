Ballerina Azure Storage Service Connectors
==========================================

[![Build Status](https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/workflows/CI/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/actions?query=workflow%3ACI)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-azure-storage-service.svg)](https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/commits/master)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

[Azure Storage Service](https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction) is a highly 
available, scalable, secure, durable and redundant cloud storage solution form Microsoft. There are four types of 
storage: Blob Storage, File Storage, Queue Storage and Table Storage.

This package allows you to access Azure Blob REST API and Azure File REST API through Ballerina.

For more information, go to the modules.
 - [ballerinax/azure_storage_service.blobs](storageservice/modules/blobs/Module.md)
 - [ballerinax/azure_storage_service.files](storageservice/modules/files/Module.md)

## Building from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 11 (from one of the following locations).

   * [Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)

   * [OpenJDK](https://adoptopenjdk.net/)

        > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.

2. Download and install [Ballerina Swan Lake Beta2](https://ballerina.io/). 

### Building the source

Execute the commands below to build from the source.

1. To build the Gradle project:
```shell script
    ./gradlew build
```

2. To build the ballerina package:
```shell script
    bal build -c ./storageservice
```

3. To build the ballerina package without the tests:
```shell script
    bal build --skip-tests ./storageservice
```

## Contributing to Ballerina
As an open source project, Ballerina welcomes contributions from the community. 

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct
All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links
* Discuss the code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
