
# Ballerina Azure Storage Blob Service Connector

[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-azure-storage-service.svg)](https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/commits/master)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)


Connects to Azure Storage Blob Service using Ballerina.

# Introduction

## What is Azure Storage Service

[Azure Storage Service](https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction) is a highly 
available, scalable, secure, durable and redundant cloud storage solution form Microsoft. There are four types of 
storage which are Blob Storage, File Storage, Queue Storage and Table Storage.

## Azure Storage - Blobs Service

[Azure Blob Storage Service](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction) is for storing Blobs which are typically composed of unstructured data such as text, images 
and videos. It provides users with strong data consistency, storage and access flexibility that adapts to the user’s 
needs, and it also provides high availability by implementing geo-replication. 

Blobs are stored in directory-like structures called “containers”. A storage account can include an unlimited number of containers, and a container can store an unlimited number of blobs. The following image shows the relationship between a storage account, container and blobs.

![Relationship between Storage Account, Container and Blobs](https://docs.microsoft.com/en-us/azure/storage/blobs/media/storage-blobs-introduction/blob1.png)

There are 3 categories in Blobs. https://docs.microsoft.com/en-us/rest/api/storageservices/understanding-block-blobs--append-blobs--and-page-blobs
They are 
1. Block blobs.
2. Page blobs.
3. Append blobs. 

Block blobs are optimized for uploading large amounts of data efficiently. This is the commonly used Blob Type to store 
any type of data.

Page blobs are optimized for random read/write operations and which provide the ability to write to a range of bytes in 
a blob. Page blobs are mostly used in virtual machine (VM) storage disks. 

An append blob is comprised of blocks and is optimized for append operations. When you modify an append blob, blocks are added to the end of the blob, via the Append Block operation. Append blob is mostly used for log storage.


# Connector Overview

Azure Storage Blob Service Connector is used to connect to Azure Storage Blob Service via Ballerina language easily. It is capable to connect to Azure Storage Blob Service and to execute operations like listContainers, listBlobs, putBlob, deleteBlob etc. It is also capable of executing management operations such as createContainer and deleteContainer etc.

This connector will invoke the REST APIs exposed via the Azure Storage Blob Service. https://docs.microsoft.com/en-us/rest/api/storageservices/blob-service-rest-api

For the version 0.1.0 of this connector, version 2019-12-12 of Azure Blob Storage Service REST API is used.

# Prerequisites

* Azure Account to Access Azure Portal https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account/

* Azure Storage Account https://docs.microsoft.com/en-us/learn/modules/create-azure-storage-account/

* Java 11 Installed
Java Development Kit (JDK) with version 11 is required.

* Ballerina SLP8 Installed
Ballerina Swan Lake Preview Version 8 is required. 

* Shared Access Signature (SAS) or One of the Access Keys for authentication. 


## Supported Versions

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

# Samples

## Blob Client Operations

This section has the samples for the operations in Azure Blob Service Blob Client.

Sample is available at:
https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/blob/main/modules/blobs/samples/blobs-sample.bal

### List Containers

Get the list of Containers from the given storage account.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var listContainersResult = blobClient->listContainers();
    if (listContainersResult is error) {
        log:printError(listContainersResult.toString());
    } else {
        log:print(listContainersResult.toString());
    }
}
```

### Upload a Blob

Upload a blob to a container as a single byte array (Maximum size is 50MB).

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    byte[] testBlob = "hello".toBytes();
    var putBlobResult = blobClient->putBlob("containerName", "hello.txt", "BlockBlob", testBlob);
    if (putBlobResult is error) {
        log:printError(putBlobResult.toString());
    } else {
        log:print(putBlobResult.toString());
    }
}
```

### List Blobs

Get the list of blobs from the given container.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var listBlobsResult = blobClient->listBlobs("containerName");
    if (listBlobsResult is error) {
        log:printError(listBlobsResult.toString());
    } else {
        log:print(listBlobsResult.toString());
    }
}
```

### Get Blob

Get a blob by specifying container name and blob name.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var getBlobResult = blobClient->getBlob("containerName", "hello.txt");
    if (getBlobResult is error) {
        log:printError(getBlobResult.toString());
    } else {
        log:print(getBlobResult.toString());
    }
}
```

### Upload Large Blob

Upload a large blob from a file path.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var uploadLargeBlobResult = blobClient->uploadLargeBlob("containerName", "ballerina.jpg", "filePath");
    if (uploadLargeBlobResult is error) {
        log:printError(uploadLargeBlobResult.toString());
    } else {
        log:print(uploadLargeBlobResult.toString());
    }
}
```

### Delete a Blob

Delete a Blob

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var deleteBlobResult = blobClient->deleteBlob("containerName", "hello.txt");
    if (deleteBlobResult is error) {
        log:printError(deleteBlobResult.toString());
    } else {
        log:print(deleteBlobResult.toString());
    }
}
```

### Get Blob Properties

Get the properties of a Blob

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var blobProperties = blobClient->getBlobProperties("containerName", "hello.txt");
    if (blobProperties is error) {
        log:printError(blobProperties.toString());
    } else {
        log:print(blobProperties.toString());
    }
}
```

### Get Blob Metadata

Get metadata of a Blob

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var blobMetadata = blobClient->getBlobMetadata("containerName", "hello.txt");
    if (blobMetadata is error) {
        log:printError(blobMetadata.toString());
    } else {
        log:print(blobMetadata.toString());
    }
}
```

### Get Block List

Get list of blocks from a blob.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var blockListResult = blobClient->getBlockList("containerName", "hello.txt");
    if (blockListResult is error) {
        log:printError(blockListResult.toString());
    } else {
        log:print(blockListResult.toString());
    }
}
```

### Put Blob from URL

Creates a new Block Blob where the content of the blob is read from a given URL. Shared Access Signature of the source blob has to be in the end of the source blob URL.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var result = blobClient->putBlobFromURL("containerName", "hello.txt", "sourceBlobURL");
    if (result is error) {
        log:printError(result.toString());
    } else {
        log:print(result.toString());
    }
}
```


### Put Block

Commits a new block to be commited as part of a blob.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    byte[] content = "hello".toBytes();
    var result = blobClient->putBlock("containerName", "hello.txt", "blockId", content);
    if (result is error) {
        log:printError(result.toString());
    } else {
        log:print(result.toString());
    }
}
```


### Put Block List

Writes a blob by specifying the list of blockIDs that make up the blob.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    string[] blockIdList = ["blockId1", "blockId2"];
    var result = blobClient->putBlockList("containerName", "hello.txt", blockIdList);
    if (result is error) {
        log:printError(result.toString());
    } else {
        log:print(result.toString());
    }
}
```

### Put Block List

Writes a blob by specifying the list of blockIds that make up the blob. blockIdList should contain all the blockIds which should be added to the blob.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    string[] blockIdList = ["blockId1", "blockId2"];
    var result = blobClient->putBlockList("containerName", "hello.txt", blockIdList);
    if (result is error) {
        log:printError(result.toString());
    } else {
        log:print(result.toString());
    }
}
```

### Put Block from URL

Commits a new block to be commited as part of a blob where the content is read from a URL. Shared Access Signature of the source blob has to be in the end of the source blob URL.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    byte[] content = "hello".toBytes();
    var result = blobClient->putBlockFromURL("containerName", "hello.txt", "blockId", "sourceBlobURL");
    if (result is error) {
        log:printError(result.toString());
    } else {
        log:print(result.toString());
    }
}
```

### Copy Blob

Copy a blob to a destination within the storage account from any Storage account. Shared Access Signature of the source blob has to be in the end of the source blob URL.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    byte[] content = "hello".toBytes();
    var result = blobClient->copyBlob("containerName", "hello.txt", "blockId", "sourceBlobURL");
    if (result is error) {
        log:printError(result.toString());
    } else {
        log:print(result.toString());
    }
}
```

### Put Page

Writes a range of pages to a page blob. 
Full Sample is available at: https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/blob/main/modules/blobs/samples/page-blob-sample.bal

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var putPageUpdate = blobClient->putPage(containerName, "test-page.txt", "update", 0, 511, blobContent);
    if (putPageUpdate is error) {
        log:printError(putPageUpdate.toString());
    } else {
        log:print(putPageUpdate.toString());
    }
}
```

### Get Page Ranges

Get the list of valid page ranges for a page blob.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var pageRanges = blobClient->getPageRanges(containerName, "test-page.txt");
    if (pageRanges is error) {
        log:printError(pageRanges.toString());
    } else {
        log:print(pageRanges.toString());
    }
}
```

### Append Block

Commits a new block of data to the end of an existing append blob. 
Full Sample is available at: https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/blob/main/modules/blobs/samples/append-blob-sample.bal

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    byte[] testBlob = "hello".toBytes();
    var appendedBlock = blobClient->appendBlock(containerName, "test-append.txt", testBlob);
    if (appendedBlock is error) {
        log:printError(appendedBlock.toString());
    } else {
        log:print(appendedBlock.toString());
    }
}
```

### Append Block From URL

Commits a new block of data (from a sourceURL) to the end of an existing append blob. Shared Access Signature of the source blob has to be in the end of the source blob URL.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var appendBlockFromURL = blobClient->appendBlockFromURL(containerName, "test-append.txt", "sourceBlobURL");
    if (appendBlockFromURL is error) {
        log:printError(appendBlockFromURL.toString());
    } else {
        log:print(appendBlockFromURL.toString());
    }
}
```


## Management Client Operations

This section has the samples for the management operations in Azure Blob Service Management Client.

Sample is available at:
https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/blob/main/modules/blobs/samples/management-operations.bal

### Create Container

Create a new container

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var createContainerResult = managementClient->createContainer("containerName");
    if (createContainerResult is error) {
        log:printError(createContainerResult.toString());
    } else {
        log:print(createContainerResult.toString());
    }
}
```

### Delete Container

Delete a container with all its contents.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var deleteContainerResult = managementClient->deleteContainer("containerName");
    if (deleteContainerResult is error) {
        log:printError(deleteContainerResult.toString());
    } else {
        log:print(deleteContainerResult.toString());
    }
}
```

### Get Container Properties

Get properties of a Container.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var getContainerPropertiesResult = managementClient->getContainerProperties("containerName");
    if (getContainerPropertiesResult is error) {
        log:printError(getContainerPropertiesResult.toString());
    } else {
        log:print(getContainerPropertiesResult.toString());
    }
}
```

### Get Container ACL

Get the permissions for the specified container.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var getContainerACLResult = managementClient->getContainerACL("containerName");
    if (getContainerACLResult is error) {
        log:printError(getContainerACLResult.toString());
    } else {
        log:print(getContainerACLResult.toString());
    }
}
```

### Get Container Metadata

Get container metadata.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var getContainerMetadataResult = managementClient->getContainerMetadata("containerName");
    if (getContainerMetadataResult is error) {
        log:printError(getContainerMetadataResult.toString());
    } else {
        log:print(getContainerMetadataResult.toString());
    }
}
```

### Get Account Information

Get account information such as sku name, account kind of the account.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var getAccountInformationResult = managementClient->getAccountInformation();
    if (getAccountInformationResult is error) {
        log:printError(getAccountInformationResult.toString());
    } else {
        log:print(getAccountInformationResult.toString());
    }
}
```

### Get Blob Service Properties

Get the properties of a storage account’s Blob service.

```ballerina
import ballerina/config;
import ballerina/log;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
        baseURL: config:getAsString("BASE_URL"),
        accessKey: config:getAsString("ACCESS_KEY"),
        accountName: config:getAsString("ACCOUNT_NAME"),
        authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
    };
 
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
    var getBlobServicePropertiesResult = managementClient->getBlobServiceProperties();
    if (getBlobServicePropertiesResult is error) {
        log:printError(getBlobServicePropertiesResult.toString());
    } else {
        log:print(getBlobServicePropertiesResult.toString());
    }
}
```

## Building from the Source

### Setting Up the Prerequisites

1. Download and install Java SE Development Kit (JDK) version 11 (from one of the following locations).

   * [Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)

   * [OpenJDK](https://adoptopenjdk.net/)

        > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.

2. Download and install [Ballerina SLP8](https://ballerina.io/). 

### Building the Source

Execute the commands below to build from the source after installing Ballerina SLP8 version.

1. To build the library:
```shell script
    ballerina build
```

2. To build the module without the tests:
```shell script
    ballerina build --skip-tests
```

## Issues and Projects 

Issues and Projects tabs are disabled for this repository as this is part of the Ballerina Standard Library. To report 
bugs, request new features, start new discussions, view project boards, etc. please visit Ballerina Standard Library 
[parent repository](https://github.com/ballerina-platform/ballerina-standard-library). 

This repository only contains the source code for the module.

## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community. 

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of Conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful Links

* Discuss the code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
