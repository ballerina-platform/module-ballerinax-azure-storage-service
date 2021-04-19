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

import ballerina/log;
import ballerina/os;
import ballerinax/azure_storage_service.blobs as azure_blobs;

public function main() returns @tainted error? {
    azure_blobs:AzureBlobServiceConfiguration blobServiceConfig = {
        accessKeyOrSAS: os:getEnv("ACCESS_KEY_OR_SAS"),
        accountName: os:getEnv("ACCOUNT_NAME"),
        authorizationMethod: "accessKey"
    };
 
    azure_blobs:BlobClient blobClient = check new (blobServiceConfig);

    string containerName = "sample-container";
    byte[] testBlob = "hello".toBytes();
    azure_blobs:ByteRange byteRange = {startByte: 0, endByte: 511};

    // Initialize a Page Blob
    log:printInfo("Initialize Page Blob");
    var putPageBlob = blobClient->putBlob(containerName, "test-page.txt", "PageBlob", pageBlobLength = 512);
    if (putPageBlob is error) {
        log:printError(putPageBlob.toString());
    } else {
        log:printInfo(putPageBlob.toString());
    }

    // Update Page Blob
    log:printInfo("Update Page Blob");
    // Creating a byte[] with size of 512 
    byte[] blob = [];
    int i = 0;
    while (i < 512) {
        blob[i] = 1;
        i = i + 1;
    }
    var putPageUpdate = blobClient->putPage(containerName, "test-page.txt", "update", byteRange, blob);
    if (putPageUpdate is error) {
        log:printError(putPageUpdate.toString());
    } else {
        log:printInfo(putPageUpdate.toString());
    }

    // Get Page Range
    log:printInfo("Get Page Range");
    var pageRanges = blobClient->getPageRanges(containerName, "test-page.txt");
    if (pageRanges is error) {
        log:printError(pageRanges.toString());
    } else {
        log:printInfo(pageRanges.toString());
    }

    // Clear Page Blob
    log:printInfo("Clear Page Blob");
    var putPageClear = blobClient->putPage(containerName, "test-page.txt", "clear", byteRange);
    if (putPageClear is error) {
        log:printError(putPageClear.toString());
    } else {
        log:printInfo(putPageClear.toString());
    }
}
