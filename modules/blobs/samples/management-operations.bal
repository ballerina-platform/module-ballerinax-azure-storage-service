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
 
    azure_blobs:ManagementClient managementClient = new (blobServiceConfig);

    string containerName = "test-container";

    // Create Container
    log:print("Create Container");
    var createContainerResult = managementClient->createContainer(containerName);
    if (createContainerResult is error) {
        log:printError(createContainerResult.toString());
    } else {
        log:print(createContainerResult.toString());
    }

    // Get Container Properties
    log:print("Get Container Properties");
    var getContainerPropertiesResult = managementClient->getContainerProperties(containerName);
    if (getContainerPropertiesResult is error) {
        log:printError(getContainerPropertiesResult.toString());
    } else {
        log:print(getContainerPropertiesResult.toString());
    }

    // Get Container Meta Data
    log:print("Get Container Metadata");
    var getContainerMetadataResult = managementClient->getContainerMetadata(containerName);
    if (getContainerMetadataResult is error) {
        log:printError(getContainerMetadataResult.toString());
    } else {
        log:print(getContainerMetadataResult.toString());
    }

    // Get Container ACL
    log:print("Get Container ACL");
    var getContainerACLResult = managementClient->getContainerACL(containerName);
    if (getContainerACLResult is error) {
        log:printError(getContainerACLResult.toString());
    } else {
        log:print(getContainerACLResult.toString());
    }

    // Get Account Information
    log:print("Get Account Information");
    var getAccountInformationResult = managementClient->getAccountInformation();
    if (getAccountInformationResult is error) {
        log:printError(getAccountInformationResult.toString());
    } else {
        log:print(getAccountInformationResult.toString());
    }
    
    // Get Blob Service Properties
    log:print("Get Blob Service Properties");
    var getBlobServicePropertiesResult = managementClient->getBlobServiceProperties();
    if (getBlobServicePropertiesResult is error) {
        log:printError(getBlobServicePropertiesResult.toString());
    } else {
        log:print(getBlobServicePropertiesResult.toString());
    }

    // Delete a Container
    log:print("Delete a container");
    var deleteContainerResult = managementClient->deleteContainer(containerName);
    if (deleteContainerResult is error) {
        log:printError(deleteContainerResult.toString());
    } else {
        log:print(deleteContainerResult.toString());
    }
}
