// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/log;
import ballerina/os;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns error? {
    azure_blobs:ConnectionConfig blobServiceConfig = {
        accessKeyOrSAS: os:getEnv("ACCESS_KEY_OR_SAS"),
        accountName: os:getEnv("ACCOUNT_NAME"),
        authorizationMethod: "accessKey"
    };
 
    azure_blobs:BlobClient blobClient = check new (blobServiceConfig);

    string containerName = "sample-container";
    string imagePath = "ballerina.jpg";
    byte[] testImageBlob = check io:fileReadBytes(imagePath);
    byte[] testBlob = "hello".toBytes();

    // List Containers
    log:printInfo("List all containers");
    var listContainersResult = blobClient->listContainers();
    if (listContainersResult is error) {
        log:printError(listContainersResult.toString());
    } else {
        log:printInfo(listContainersResult.toString());
    }
    
    // Upload Blob
    log:printInfo("Upload a Blob");
    var putBlobResult = blobClient->putBlob(containerName, "hello.txt", "BlockBlob", testBlob);
    if (putBlobResult is error) {
        log:printError(putBlobResult.toString());
    } else {
        log:printInfo(putBlobResult.toString());
    }
    
    // Upload large Blob by breaking into blocks
    log:printInfo("Upload large Blob by breaking into blocks");
    var uploadLargeBlobResult = blobClient->uploadLargeBlob(containerName, "ballerina.jpg", imagePath);
    if (uploadLargeBlobResult is error) {
        log:printError(uploadLargeBlobResult.toString());
    } else {
        log:printInfo(uploadLargeBlobResult.toString());
    }

    // List Blobs from a Container
    log:printInfo("List all blobs");
    var listBlobsResult = blobClient->listBlobs(containerName);
    if (listBlobsResult is error) {
        log:printError(listBlobsResult.toString());
    } else {
        log:printInfo(listBlobsResult.toString());
    }

    // Get a blob
    log:printInfo("Get blob");
    var getBlobResult = blobClient->getBlob(containerName, "hello.txt");
    if (getBlobResult is error) {
        log:printError(getBlobResult.toString());
    } else {
        log:printInfo(getBlobResult.toString());
    }

    // Delete a Blob
    log:printInfo("Delete a blob");
    var deleteBlobResult = blobClient->deleteBlob(containerName, "hello.txt");
    if (deleteBlobResult is error) {
        log:printError(deleteBlobResult.toString());
    } else {
        log:printInfo(deleteBlobResult.toString());
    }
}
