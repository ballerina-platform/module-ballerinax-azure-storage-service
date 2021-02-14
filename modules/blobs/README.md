
# Ballerina Azure Storage Blob Service Connector
Connects to Azure Storage Blob Service using Ballerina.

# Introduction

## What is Azure Storage Service

[Azure Storage Service](https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction) is a highly 
available, scalable, secure, durable and redundant cloud storage solution form Microsoft. There are four types of 
storage which are Blob Storage, File Storage, Queue Storage and Table Storage.

## Azure Storage - Blobs Service

Azure Blob Storage Service is for storing Blobs which are typically composed of unstructured data such as text, images 
and videos. It provides users with strong data consistency, storage and access flexibility that adapts to the user’s 
needs, and it also provides high availability by implementing geo-replication. 

Blobs are stored in directory-like structures called “containers”. There are 3 categories in Blobs. They are Block 
blobs, Page blobs and Append blobs. Block blobs are optimized for uploading large amounts of data efficiently. Page 
blobs are optimized for random read/write operations and which provide the ability to write to a range of bytes in a 
blob. Page blobs are mostly used in virtual machine (VM) storage disks. An append blob is comprised of blocks and is optimized for append operations. When you modify an append blob, blocks are added to the end of the blob, via the Append Block operation. Append blob is mostly used for log storage.

# Prerequisites

* Azure Account to Access Azure Portal https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account/

* Azure Storage Account https://docs.microsoft.com/en-us/learn/modules/create-azure-storage-account/

* Java 11 Installed
Java Development Kit (JDK) with version 11 is required.

* Ballerina SLP8 Installed
Ballerina Swan Lake Preview Version 8 is required. 

* Shared Access Signature (SAS) or One of the Access Keys for authentication. 


## Compatibility

|                      |  Version           |
|----------------------|------------------- |
| Ballerina            | Swan Lake Preview 8|
| Azure Storage Service|     2019-12-12     |


# Quickstart(s)

## Simple operations in Azure Blob Service Blob Client.
These are the simplest scenarios in Azure Blob Service Blob Client. You must have the following prerequisites in order 
to obtain these configurations.

* Azure Account to Access Azure Portal https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account/

* Azure Storage Account https://docs.microsoft.com/en-us/learn/modules/create-azure-storage-account/

* You need to get a Shared Access Key or one of the Access Keys from the Azure Portal.


## Step1: Import the Azure Storage Blobs Ballerina Library

First, import the `ballerinax/azure_storage_service.blobs` module into the Ballerina project

```ballerina
    import ballerinax/azure_storage_service.blobs as azure_blobs;
```

## Step2: Create Azure Blob Service Configuration

Create the connection configuration using the Shared Access Signature or Access Key, base URL and account name.

If you are using Shared Access Signature, use the follwing format.

```ballerina
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: "",
        baseURL: "",
        accountName: "",
        authorizationMethod: "SharedAccessSignature"
    };
```

If you are using one of the Access Key, use the follwing format.

```ballerina
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        accessKey: "",
        baseURL: "",
        accountName: "",
        authorizationMethod: "SharedKey"
    };
```

## Step3: Initialize Azure Storage Blob Client 

Create the BlobClient using the configuration you have created as shown above.

```ballerina
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
```

## Step4: Try the common operations in Azure Storage Blob Client

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
    var putBlobResult = blobClient->putBlob("container-1", "hello.txt", testBlob, "BlockBlob");
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
