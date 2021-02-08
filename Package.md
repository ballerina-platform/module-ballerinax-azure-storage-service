
## Ballerina Azure Storage Service Connector
The Ballerina Azure Storage Service Connector allows you to connect to Azure Storage Service from Ballerina and 
perform various operations.


#### Azure Storage Service is a highly available, scalable, secure, durable and redundant cloud storage solution from Microsoft. There are four types of storage which are Blob Storage, File Storage, Queue Storage and Table Storage.


## Compatibility

|                      |  Version           |
|----------------------|------------------- |
| Ballerina            | Swan Lake Preview 8|
| Azure Storage Service|     2019-12-12     |


## Azure Storage Service - Blobs

Blobs module in this connector provides two clients to use Azure Blob Storage Service and Azure File Storage Service

### Using Blobs Module

First, import the `ballerinax/azure_storage_service.blobs` module into the Ballerina project

```ballerina
    import ballerinax/azure_storage_service.blobs as azure_blobs;
```

Add the configurations for Blobs Client

```ballerina
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        sharedAccessSignature: "",
        baseURL: "",
        accessKey: "",
        accountName: "",
        authorizationMethod: ""
    };
```

Create the BlobClient using the configuration

```ballerina
    azure_blobs:BlobClient blobClient = new (blobServiceConfig);
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
