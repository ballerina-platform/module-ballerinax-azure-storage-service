
# Ballerina Azure Storage Service Connector

[![Build Status](https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/workflows/CI/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/actions?query=workflow%3ACI)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-azure-storage-service.svg)](https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/commits/master)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Connects to Azure Storage Service using Ballerina.

# Introduction

## What is Azure Storage Service

[Azure Storage Service](https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction) is a highly 
available, scalable, secure, durable and redundant cloud storage solution form Microsoft. There are four types of 
storage which are Blob Storage, File Storage, Queue Storage and Table Storage.

# Prerequisites

* Azure Account to Access Azure Portal https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account/

* Azure Storage Account https://docs.microsoft.com/en-us/learn/modules/create-azure-storage-account/

* Java 11 Installed
Java Development Kit (JDK) with version 11 is required.

* Ballerina Alpha 2 Installed
Ballerina Swan Lake Alpha 2 is required. 

* Shared Access Signature (SAS) or One of the Access Key for authentication


## Compatibility

|                      |  Version           |
|----------------------|------------------- |
| Ballerina            | Swan Lake Alpha 2  |
| Azure Storage Service|     2019-12-12     |


## Azure Storage Service - Blobs

Azure Blob Storage Service is for storing Blobs which are typically composed of unstructured data such as text, images 
and videos. It provides users with strong data consistency, storage and access flexibility that adapts to the user’s 
needs, and it also provides high availability by implementing geo-replication. 

Blobs are stored in directory-like structures called “containers”. There are 3 categories in Blobs. They are Block 
blobs, Page blobs and Append blobs. Block blobs are optimized for uploading large amounts of data efficiently. Page 
blobs are optimized for random read/write operations and which provide the ability to write to a range of bytes in a 
blob. Page blobs are mostly used in virtual machine (VM) storage disks. An append blob is comprised of blocks and is optimized for append operations. When you modify an append blob, blocks are added to the end of the blob, via the Append Block operation. Append blob is mostly used for log storage.



## Using Blobs Module

First, import the `ballerinax/azure_storage_service.blobs` module into the Ballerina project

```ballerina
    import ballerinax/azure_storage_service.blobs as azure_blobs;
```

Add the configurations for Blobs Client

```ballerina
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        accessKeyOrSAS: os:getEnv("ACCESS_KEY_OR_SAS"),
        accountName: os:getEnv("ACCOUNT_NAME"),
        authorizationMethod: "accessKey"
    };
```

Create the BlobClient using the configuration

```ballerina
    azure_blobs:BlobClient blobClient = check new (blobServiceConfig);
```

1. Get the list of containers in the storage account

```ballerina
    var listContainersResult = blobClient->listContainers();
    if (listContainersResult is error) {
        log:printError(listContainersResult.toString());
    } else {
        log:print(listContainersResult.toString());
    }
```

2. Get the list of blobs from a container using container name

```ballerina
    var listBlobsResult = blobClient->listBlobs("container-1");
    if (listBlobsResult is error) {
        log:printError(listBlobsResult.toString());
    } else {
        log:print(listBlobsResult.toString());
    }
```

3. Upload a blob

```ballerina
    byte[] testBlob = "hello".toBytes();
    var putBlobResult = blobClient->putBlob(containerName, "hello.txt", "BlockBlob", testBlob);
    if (putBlobResult is error) {
        log:printError(putBlobResult.toString());
    } else {
        log:print(putBlobResult.toString());
    }
```

4. Get a blob using container name and blob name

```ballerina
    var getBlobResult = blobClient->getBlob("container-1", "hello.txt");
    if (getBlobResult is error) {
        log:printError(getBlobResult.toString());
    } else {
        log:print(getBlobResult.toString());
    }
```

5. Delete a blob

```ballerina
    var deleteBlobResult = blobClient->deleteBlob("container-1", "hello.txt");
    if (deleteBlobResult is error) {
        log:printError(deleteBlobResult.toString());
    } else {
        log:print(deleteBlobResult.toString());
    }
```
