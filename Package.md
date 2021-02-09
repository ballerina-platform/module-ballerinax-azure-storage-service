![CI](https://github.com/ballerina-platform/module-ballerinax-azure-storage-service/workflows/CI/badge.svg)
# module-ballerinax-azure-storage-service
Connects to Microsoft Azure Storage Service using Ballerina.

# Module Overview
Azure storage is a cloud storage service for azure provided by Microsoft to fulfill the cloud storage needs with high availability, security, durability, scalability and redundancy. Data in Azure Storage is accessible from anywhere in the world over HTTP or HTTPS. Microsoft provides a Rest API and a collection of client libraries for different languages. Azure storage supports scripting in Azure PowerShell or Azure CLI, and also it provides visual solutions for working with data  by azure portal and azure storage explorer. All azure storage services can be access through a storage account. There are several types of storage accounts. Each type supports different features and has its own pricing mode.

*File Service

Files stored in Azure File service shares are accessible via the SMB protocol, and also via REST APIs. The File service offers the following four resources: the storage account, shares, directories, and files. Shares provide a way to organize sets of files and also can be mounted as an SMB file share that is hosted in the cloud.

# Compatibility
|                     |    Version                                  |
|:-------------------:|:-------------------------------------------:|
| Ballerina Language  | Swan-Lake-Preview8                          |
| File Service  API   | Version 2014-02-14 of the storage service   |

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

## Azure Storage Service - Files

## Operations on File Service level
The `ballerinax/azureStorageService.Files` module contains operations to do file service level operations like list file shares, get/set fileshare properities.

## Operations on Fileshares
This module contains operation such as create fileshares, delete fileshares etc. 

## Operations on FileShare Directories/Files
The module provides operations on both files/directories such as creating, uploading, copying files etc.

# Prerequisites

* An Azure account and subscription.
If you don't have an Azure subscription, [sign up for a free Azure account](https://azure.microsoft.com/free/).

* A stroage service account.
If you don't have [azure storage account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal), 
  learn how to create your azure storage service account.

* Java 11 Installed
Java Development Kit (JDK) with version 11 is required.

* Ballerina SLP8 Installed
Ballerina Swan Lake Preview Version 8 is required.

* Shared Access Signature Authentication Credentials
    *Use generated SAS token from the azure storage account. 
    *Azure storage account base URL

# Configuration for Files
Instantiate the connector by giving authorization credentials to the congfiguration

# Sample
First, import the `ballerinax/` module into the Ballerina project.
```ballerina
import ballerinax/azureStorageService.Files as fileShare;
import ballerinax/logs;
```

1. You can now make the connection configuration using the shared access signature key and the base URL by copying from the azure portal. In the file service module, You will have separate two clients as "ServiceLevelClient" and "FileShareClient"  for service level and non-service level functions respectively.
```ballerina
fileShare:AzureConfiguration azureConfiguration = {
        sharedKeyOrSASToken: config:getAsString("<SharedKey_OR_SAS_TOKEN>"),
        storageAccountName: config:getAsString("<STORAGE_ACCOUNT_NAME>"),
        isSharedKeySet:<true or (default)false>    
    };

fileShare:FileShareClient azureClient = new (azureConfiguration);
fileShare:ServiceLevelClient azureServiceLevelClient = new (azureConfiguration);
```
2. Then creating a fileshare using the service level client who can use service level function and a valid Shared access siganture(SAS) token or a shared key .
```ballerina
    var creationResponse = azureServiceLevelClient->createShare("demoshare");
    if(creationResponse is boolean){
        log:print("Fileshare Creation: "+creationResponse.toString());
    }else{
       log:printError(creationResponse.toString()); 
    }
```

3. You can now upload a file using the non-service level client.
```ballerina
    var uploadResponse = azureClient->directUpload(fileShareName = "demoshare", 
    localFilePath = "resources/uploads/test.txt", azureFileName = "testfile.txt");
    if (uploadResponse is boolean) {
        log:print("upload status:" + UploadResponse.toString());
    } else {
        log:printError(UploadResponse.toString()); 
    }
```

4. You can now download the file using non service level client.
```ballerina
    var downloadResponse = azureClient->getFile(fileShareName = "demoshare", fileName = "testfile.txt",
    localFilePath = "resources/downloads/downloadedFile.txt");
    if (downloadResponse is boolean) {
        log:print("Download status:" + UploadResponse.toString());
    } else {
       log:printError(DownloadResponse.toString());
    }
```

5. You can delete thefileshare using the service level client who can use service level function and a valid SAS token. 
```ballerina
    var deletionResponse = azureServiceLevelClient->deleteShare("demoshare");
    if (deletionResponse is boolean) {
        log:print("Fileshare Deletion status:" + deletionResponse.toString());
    } else {
        log:printError(deletionResponse.toString()); 
    }
```
# Please check sample directory in each module for more examples.