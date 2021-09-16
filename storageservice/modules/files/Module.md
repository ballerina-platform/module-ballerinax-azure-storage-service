## Overview
This module allows you to access the Azure Storage File REST API through Ballerina. Azure Files offers fully managed 
file shares in the cloud that are accessible via the Server Message Block (SMB) protocol or Network File System (NFS) 
protocol.
This module provides you the capability to execute operations like getFileList, getDirectoryList, createDirectory, 
directUpload and getFile etc using the FileClient. It also allows you to execute management operations such as 
createShare and deleteShare etc using the ManagementClient.

This module supports Azure Storage Service REST API 2019-12-12 version.

## Prerequisites
Before using this connector in your Ballerina application, complete the following:

* [Create an Azure account to access Azure Portal](https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account)

* [Create an Azure Storage Account](https://docs.microsoft.com/en-us/learn/modules/create-azure-storage-account)

* Obtain `Shared Access Signature` (`SAS`) or use one of the Accesskeys for authentication. 

## Quickstart
To use this connector in your Ballerina application, update the .bal file as follows:

### Step1: Import connector

Import the `ballerinax/azure_storage_service.files` module into the Ballerina project. 

```ballerina
    import ballerinax/azure_storage_service.files as azure_files;
```

### Step2: Create a new connector instance

Create an `azure_files:ConnectionConfig` with the obtained Shared Access Signature or Access Key, base URL and account name.

* If you are using Shared Access Signature, use the follwing format.

```ballerina
    azure_files:ConnectionConfig fileServiceConfig = {
        accessKeyOrSAS: "ACCESS_KEY_OR_SAS",
        accountName: "ACCOUNT_NAME",
        authorizationMethod: "SAS"
    };
```

* If you are using one of the Access Key, use the follwing format.

```ballerina
    azure_files:ConnectionConfig fileServiceConfig = {
        accessKeyOrSAS: "ACCESS_KEY_OR_SAS",
        accountName: "ACCOUNT_NAME",
        authorizationMethod: "accessKey"
    };
```

Create the FileClient using the fileServiceConfig you have created as shown above.

```ballerina
    azure_files:FileClient fileClient = check new (fileServiceConfig);
```

### Step3: Invoke connector operation

1. Now you can use the operations available within the connector. Note that they are in the form of remote operations. 
Following is an example on how to list all the directories in a file share using the connector.

```ballerina
    public function main() returns error? {
        azure_files:ConnectionConfig fileServiceConfig = {
            accessKeyOrSAS: "ACCESS_KEY_OR_SAS",
            accountName: "ACCOUNT_NAME",
            authorizationMethod: "accessKey"
        };
 
        azure_files:FileClient fileClient = check new (fileServiceConfig);
        azure_files:DirectoryList result = check fileClient->getDirectoryList(fileShareName = "demoshare");
    }
```

2. Use `bal run` command to compile and run the Ballerina program. 

## Quick reference

- Get list of directories in a file share

```ballerina
    azure_files:DirectoryList result = check fileClient->getDirectoryList(fileShareName = "demoshare");
```

- Get list of files in a file share

```ballerina
    azure_files:FileList result = check fileClient->getFileList(fileShareName = "demoshare");
```

- Create a directory

```ballerina
    _ = check fileClient->createDirectory(fileShareName = "demoshare", newDirectoryName = "demoDirectory");
```

- Upload a file to a fileshare.

```ballerina
    _ = check fileClient->directUpload(fileShareName = "demoshare", 
    localFilePath = "resources/uploads/test.txt", azureFileName = "testfile.txt");
```

- Download a file from a fileshare.
```ballerina
    _ = check fileClient->getFile(fileShareName = "demoshare", fileName = "testfile.txt",
    localFilePath = "resources/downloads/downloadedFile.txt");
```

**[You can find a list of samples here](https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/tree/main/storageservice/modules/files/samples)**
