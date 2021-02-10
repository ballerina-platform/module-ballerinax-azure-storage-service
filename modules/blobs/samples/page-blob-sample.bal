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
    byte[] testBlob = "hello".toBytes();

    // Initialize a Page Blob
    log:print("Initialize Page Blob");
    azure_blobs:PutBlobOptions pageBlobOptions = {pageBlobLength: "512"};
    var putPageBlob = blobClient->putBlob(containerName, "test-page.txt", "PageBlob", options = pageBlobOptions);
    if (putPageBlob is error) {
        log:printError(putPageBlob.toString());
    } else {
        log:print(putPageBlob.toString());
    }

    // Update Page Blob
    log:print("Update Page Blob");
    // Creating a byte[] with size of 512 
    byte[] blob = [];
    int i = 0;
    while (i < 512) {
        blob[i] = 1;
        i = i + 1;
    }
    var putPageUpdate = blobClient->putPage(containerName, "test-page.txt", "update", "bytes=0-511", blob);
    if (putPageUpdate is error) {
        log:printError(putPageUpdate.toString());
    } else {
        log:print(putPageUpdate.toString());
    }

    // Get Page Range
    log:print("Get Page Range");
    var pageRanges = blobClient->getPageRanges(containerName, "test-page.txt");
    if (pageRanges is error) {
        log:printError(pageRanges.toString());
    } else {
        log:print(pageRanges.toString());
    }

    // Clear Page Blob
    log:print("Clear Page Blob");
    var putPageClear = blobClient->putPage(containerName, "test-page.txt", "clear", "bytes=0-511");
    if (putPageClear is error) {
        log:printError(putPageClear.toString());
    } else {
        log:print(putPageClear.toString());
    }
}
