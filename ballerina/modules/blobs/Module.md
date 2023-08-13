## Overview
This module allows you to access the Azure Blob service REST API through Ballerina.
The Azure Blob service stores text and binary data as objects in the cloud. The Blob service offers the following three 
resources: the storage account, containers, and blobs. Within your storage account, containers provide a way to organize 
sets of blobs.
This module provides you the capability to execute operations such as listContainers, listBlobs, putBlob, deleteBlob etc. It also allows you to execute management operations such as createContainer and deleteContainer etc.

This module supports Azure Storage Service REST API 2019-12-12 version.

## Prerequisites
Before using this connector in your Ballerina application, complete the following:

* [Create an Azure account to access Azure Portal](https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account)

* [Create an Azure Storage Account](https://docs.microsoft.com/en-us/learn/modules/create-azure-storage-account)

* Obtain `Shared Access Signature` (`SAS`) or use one of the Accesskeys for authentication. 

## Quickstart
To use this connector in your Ballerina application, update the .bal file as follows:

### Step1: Import connector

Import the `ballerinax/azure_storage_service.blobs` module into the Ballerina project

```ballerina
    import ballerinax/azure_storage_service.blobs as azure_blobs;
```

### Step2: Create a new connector instance

Create a `azure_blobs:ConnectionConfig` with the obtained Shared Access Signature or Access Key, 
base URL and account name.

If you are using Shared Access Signature, use the follwing format.

```ballerina
    azure_blobs:ConnectionConfig blobServiceConfig = {
        accessKeyOrSAS: "ACCESS_KEY_OR_SAS",
        accountName: "ACCOUNT_NAME",
        authorizationMethod: "SAS"
    };
```

* If you are using one of the Access Key, use the follwing format.

```ballerina
    azure_blobs:ConnectionConfig blobServiceConfig = {
        accessKeyOrSAS: "ACCESS_KEY_OR_SAS",
        accountName: "ACCOUNT_NAME",
        authorizationMethod: "accessKey"
    };
```

* Create the BlobClient using the blobServiceConfig you have created as shown above.

```ballerina
    azure_blobs:BlobClient blobClient = check new (blobServiceConfig);
```

### Step3: Invoke connector operation

1. Now you can use the operations available within the connector. Note that they are in the form of remote operations. 
Following is an example on how to list all the containers using the connector.

```ballerina
    public function main() returns error? {
        azure_blobs:ConnectionConfig blobServiceConfig = {
            accessKeyOrSAS: os:getEnv("ACCESS_KEY_OR_SAS"),
            accountName: os:getEnv("ACCOUNT_NAME"),
            authorizationMethod: "accessKey"
        };
 
        azure_blobs:BlobClient blobClient = check new (blobServiceConfig);
        azure_blobs:ListContainerResult result = blobClient->listContainers();
    }
```

2. Use `bal run` command to compile and run the Ballerina program. 

## Quick reference

- Get the list of containers in the storage account
```ballerina
    azure_blobs:ListContainerResult result = check blobClient->listContainers();
```

- Get the list of blobs from a container using container name

```ballerina
    azure_blobs:ListBlobResult result = check blobClient->listBlobs("container-1");
```

- Upload a blob

```ballerina
    byte[] testBlob = "hello".toBytes();
    map<json> result = check blobClient->putBlob(containerName, "hello.txt", "BlockBlob", testBlob);
```

- Get a blob using container name and blob name

```ballerina
    azure_blobs:BlobResult result = check blobClient->getBlob("container-1", "hello.txt");
```

- Delete a blob

```ballerina
    map<json> deleteBlobResult = check blobClient->deleteBlob("container-1", "hello.txt");
```

**[You can find a list of samples here](https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/tree/main/storageservice/modules/blobs/samples)**
