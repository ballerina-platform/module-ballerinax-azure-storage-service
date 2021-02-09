import ballerina/io;
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

    string containerName = "sample-container";
    string imagePath = "ballerina.jpg";
    byte[] testImageBlob = check io:fileReadBytes(imagePath);
    byte[] testBlob = "hello".toBytes();

    // List Containers
    log:print("List all containers");
    var listContainersResult = blobClient->listContainers();
    if (listContainersResult is error) {
        log:printError(listContainersResult.toString());
    } else {
        log:print(listContainersResult.toString());
    }
    
    // Upload Blob
    log:print("Upload a Blob");
    var putBlobResult = blobClient->putBlob(containerName, "hello.txt", testBlob, "BlockBlob");
    if (putBlobResult is error) {
        log:printError(putBlobResult.toString());
    } else {
        log:print(putBlobResult.toString());
    }
    
    // Upload large Blob by breaking into blocks
    log:print("Upload large Blob by breaking into blocks");
    var uploadLargeBlobResult = blobClient->uploadLargeBlob(containerName, "ballerina.jpg", imagePath);
    if (uploadLargeBlobResult is error) {
        log:printError(uploadLargeBlobResult.toString());
    } else {
        log:print(uploadLargeBlobResult.toString());
    }

    // List Blobs from a Container
    log:print("List all blobs");
    var listBlobsResult = blobClient->listBlobs(containerName);
    if (listBlobsResult is error) {
        log:printError(listBlobsResult.toString());
    } else {
        log:print(listBlobsResult.toString());
    }

    // Get a blob
    log:print("Get blob");
    var getBlobResult = blobClient->getBlob(containerName, "hello.txt");
    if (getBlobResult is error) {
        log:printError(getBlobResult.toString());
    } else {
        log:print(getBlobResult.toString());
    }

    // Delete a Blob
    log:print("Delete a blob");
    var deleteBlobResult = blobClient->deleteBlob(containerName, "hello.txt");
    if (deleteBlobResult is error) {
        log:printError(deleteBlobResult.toString());
    } else {
        log:print(deleteBlobResult.toString());
    }
}
