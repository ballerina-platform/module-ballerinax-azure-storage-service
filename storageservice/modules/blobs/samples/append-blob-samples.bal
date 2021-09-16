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
    azure_blobs:ConnectionConfig blobServiceConfig = {
        accessKeyOrSAS: os:getEnv("ACCESS_KEY_OR_SAS"),
        accountName: os:getEnv("ACCOUNT_NAME"),
        authorizationMethod: "accessKey"
    };
 
    azure_blobs:BlobClient blobClient =  check new (blobServiceConfig);

    string containerName = "sample-container";
    byte[] testBlob = "hello".toBytes();

    // Initialize an Append Blob
    log:printInfo("Initialize an Append Blob");
    var putAppendBlob = blobClient->putBlob(containerName, "test-append.txt", "AppendBlob");
    if (putAppendBlob is error) {
        log:printError(putAppendBlob.toString());
    } else {
        log:print(putAppendBlob.toString());
    }

    // Append new block of data to the end of an existing append blob
    log:printInfo("Append new block of data to the end of an existing append blob");
    var appendedBlock = blobClient->appendBlock(containerName, "test-append.txt", testBlob);
    if (appendedBlock is error) {
        log:printError(appendedBlock.toString());
    } else {
        log:print(appendedBlock.toString());
    }

    // Append a new block of data (from a URL) to the end of an existing append blob.
    log:printInfo("Append a new block of data (from a URL) to the end of an existing append blob.");
    string sourceBlobUrl = "SOURCE_BLOB_URL";
    var appendBlockFromURL = blobClient->appendBlockFromURL(containerName, "test-append.txt", sourceBlobUrl);
    if (appendBlockFromURL is error) {
        log:printError(appendBlockFromURL.toString());
    } else {
        log:printInfo(appendBlockFromURL.toString());
    }
}
