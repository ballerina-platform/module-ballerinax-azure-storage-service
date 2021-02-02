
# Ballerina Azure Storage Service Connector
The Ballerina Azure Storage Service Connector allows you to connect to Azure Storage Service from Ballerina and 
perform various operations.


###### Azure Storage Service is a highly available, scalable, secure, durable and redundant cloud storage solution from Microsoft. There are four types of storage which are Blob Storage, File Storage, Queue Storage and Table Storage.


# Compatibility

|  Ballerina Version | Azure Storage Service Version |
|--------------------|-------------------------------|
| Swan Lake Preview 8|          2019-12-12           |


# Azure Storage Service Clients

This connectors provides two clients to use Azure Blob Storage Service and Azure File Storage Service

# Sample for Blob Storage Service

First, import the `ballerinax/azure_storage_service.blobs` module into the Ballerina project

```ballerina
    import ballerinax/azure_storage_service.blobs as azure_blobs;
```

Add the configurations for Blobs Client

```ballerina
    azure_blobs:AzureStorageConfiguration azureStorageConfig = {
        sharedAccessSignature: "",
        baseURL: "",
        accessKey: "",
        accountName: "",
        authorizationMethod: ""
    };
```

Create the BlobClient using the configuration

```ballerina
    azure_blobs:BlobClient testAzureStorageBlobClient = new (azureStorageConfig);
```

Get the list of containers in the storage account

```ballerina
    var response = testAzureStorageBlobClient->listContainers();
```
