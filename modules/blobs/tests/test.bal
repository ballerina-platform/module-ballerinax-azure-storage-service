// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/config;
import ballerina/log;
import ballerina/test;

AzureStorageConfiguration azureStorageConfig = {
    sharedAccessSignature: config:getAsString("SHARED_ACCESS_SIGNATURE"),
    baseURL: config:getAsString("BASE_URL"),
    accessKey: config:getAsString("ACCESS_KEY"),
    accountName: config:getAsString("ACCOUNT_NAME"),
    authorizationMethod: config:getAsString("AUTHORIZATION_METHOD")
};

Client testAzureStorageClient = new (azureStorageConfig);

const TEST_CONTAINER = "test-container";
const TEST_BLOCK_BLOB_TXT = "test-blockBlob.txt";
const TEST_BLOCK_BLOB_COPY_TXT = "test-blockBlobCopy.txt";
const TEST_PAGE_BLOB_TXT = "test-pageBlob.txt";
const TEST_APPEND_BLOB_TXT = "test-appendBlob.txt";
const TEST_COPY_TXT = "test-copy.txt";
const TEST_PUT_BLOCK_TXT = "testPutBlock.txt";
const TEST_BLOCK_ID = "testBlockId";
const TEST_BYTE_RANGE = "bytes=0-511";
const TEST_STRING = "test-string";
const TEST_X_MS_META_TEST = "x-ms-meta-test";

@test:Config {}
function testListContainers() {
    log:print("testAzureStorageClient -> listContainers()");
    var containerList = testAzureStorageClient->listContainers((), {"maxresults":"2"});
    if (containerList is error) {
        test:assertFail(containerList.toString());
    }
}

@test:Config {}
function testCreateContainer() {
    log:print("testAzureStorageClient -> createContainer()");
    map<string> optionalHeaders = {};
    optionalHeaders[X_MS_BLOB_PUBLIC_ACCESS] = CONTAINER;
    optionalHeaders[TEST_X_MS_META_TEST] = TEST_STRING;

    var containerCreated = testAzureStorageClient->createContainer(TEST_CONTAINER, optionalHeaders);
    if (containerCreated is error) {
        test:assertFail(containerCreated.toString());
    }
}

@test:Config {
    dependsOn:["testCreateContainer"]
}
function testListBlobs() {
    log:print("testAzureStorageClient -> listBlobs()");
    var blobList = testAzureStorageClient->listBlobs(TEST_CONTAINER);
    if (blobList is error) {
        test:assertFail(blobList.toString());
    }
}

@test:Config {
    dependsOn:["testCreateContainer"]
}
function testGetContainerProperties() {
    log:print("testAzureStorageClient -> getContainerProperties()");
    var containerProperties = testAzureStorageClient->getContainerProperties(TEST_CONTAINER);
    if (containerProperties is error) {
        test:assertFail(containerProperties.toString());
    }
}

@test:Config {
    dependsOn:["testCreateContainer"], enable:false  //enable
}
function testGetContainerMetadata() {
    log:print("testAzureStorageClient -> getContainerMetadata()");
    var containerMetadata = testAzureStorageClient->getContainerMetadata("TEST_CONTAINER");
    if (containerMetadata is error) {
        test:assertFail(containerMetadata.toString());
    }
}

@test:Config {
    dependsOn:["testCreateContainer"]
}
function testPutBlob() {
    log:print("testAzureStorageClient -> putBlob()");
    byte[] blob = TEST_STRING.toBytes();

    var putBlockBlob = testAzureStorageClient->putBlob(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT, blob, BLOCK_BLOB);
    if (putBlockBlob is error) {
        test:assertFail(putBlockBlob.toString());
    }

    var putPageBlob = testAzureStorageClient->putBlob(TEST_CONTAINER, TEST_PAGE_BLOB_TXT, blob, PAGE_BLOB, 512);
    if (putPageBlob is error) {
        test:assertFail(putPageBlob.toString());
    }

    var putAppendBlob = testAzureStorageClient->putBlob(TEST_CONTAINER, TEST_APPEND_BLOB_TXT, blob, APPEND_BLOB);
    if (putAppendBlob is error) {
        test:assertFail(putAppendBlob.toString());
    }
}

@test:Config {
    dependsOn:["testPutBlob"]
}
function testPutBlobFromURL() {
    log:print("testAzureStorageClient -> putBlobFromURL()");
    string sourceBlobURL =  azureStorageConfig.baseURL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL 
                              + TEST_BLOCK_BLOB_TXT + azureStorageConfig.sharedAccessSignature;
    var result = testAzureStorageClient->putBlobFromURL(TEST_CONTAINER, TEST_BLOCK_BLOB_COPY_TXT, sourceBlobURL);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {
    dependsOn:["testPutBlob"]
}
function testGetBlob() {
    log:print("testAzureStorageClient -> getBlob()");
    var blob = testAzureStorageClient->getBlob(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    if (blob is byte[]) {
        string value = <string> 'string:fromBytes(blob);
        test:assertEquals(value, TEST_STRING);
    } else {
        test:assertFail(blob.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testGetBlobMetadata() {
    log:print("testAzureStorageClient -> getBlobMetadata()");
    var blobMetadata = testAzureStorageClient->getBlobMetadata(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    if (blobMetadata is error) {
        test:assertFail(blobMetadata.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testGetBlobProperties() {
    log:print("testAzureStorageClient -> getBlobProperties()");
    var blobProperties = testAzureStorageClient->getBlobProperties(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    if (blobProperties is error) {
        test:assertFail(blobProperties.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"], enable:false
}
function testGetBlobTags() {
    log:print("testAzureStorageClient -> getBlobTags()");
    var blobTags = testAzureStorageClient->getBlobTags(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    if (blobTags is error) {
        test:assertFail(blobTags.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]//, enable:false // enable
}
function testPutBlock() {
    log:print("testAzureStorageClient -> putBlock()");
    byte[] blob = TEST_STRING.toBytes();
    var response = testAzureStorageClient->putBlock(TEST_CONTAINER, TEST_PUT_BLOCK_TXT, TEST_BLOCK_ID, blob);
    if (response is error) {
        test:assertFail(response.toString());
    } 
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testPutBlockFromURL() {
    log:print("testAzureStorageClient -> putBlockFromURL()");
    string sourceBlobURL =  azureStorageConfig.baseURL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL 
                              + TEST_BLOCK_BLOB_TXT + azureStorageConfig.sharedAccessSignature;
    var response = testAzureStorageClient->putBlockFromURL(TEST_CONTAINER, TEST_PUT_BLOCK_TXT, TEST_BLOCK_ID,
                     sourceBlobURL);
    if (response is error) {
        test:assertFail(response.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"], enable:false
}
function testGetBlockList() {
    log:print("testAzureStorageClient -> getBlockList()");
    var blockList = testAzureStorageClient->getBlobTags(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    if (blockList is error) {
        test:assertFail(blockList.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testCopyBlob() {
    log:print("testAzureStorageClient -> copyBlob()");
    string sourceBlobURL =  azureStorageConfig.baseURL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL 
                            + TEST_BLOCK_BLOB_TXT + azureStorageConfig.sharedAccessSignature;
    var copyBlob = testAzureStorageClient->copyBlob(TEST_CONTAINER, TEST_COPY_TXT, sourceBlobURL);
    if (copyBlob is error) {
        test:assertFail(copyBlob.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testCopyBlobFromURL() {
    log:print("testAzureStorageClient -> copyBlob()");
    string sourceBlobURL =  azureStorageConfig.baseURL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL 
                            + TEST_BLOCK_BLOB_TXT + azureStorageConfig.sharedAccessSignature;
    var copyBlob = testAzureStorageClient->copyBlobFromURL(TEST_CONTAINER, TEST_COPY_TXT, sourceBlobURL, true);
    if (copyBlob is error) {
        test:assertFail(copyBlob.toString());
    }
}

@test:Config {
    dependsOn:["testPutPageFromURL"]
}
function testPutPageUpdate() {
    log:print("testAzureStorageClient -> putPage() 'update' operation");
    byte[] blob = [];
    int i=0;
    while (i < 512) {
        blob[i] = 100;
        i = i + 1;
    }
    var putPage = testAzureStorageClient->putPage(TEST_CONTAINER, TEST_PAGE_BLOB_TXT, UPDATE, TEST_BYTE_RANGE, blob);
    if (putPage is error) {
        test:assertFail(putPage.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testPutPageFromURL() {
    log:print("testAzureStorageClient -> putPageFromURL()");
    string sourceBlobURL =  azureStorageConfig.baseURL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL 
                             + TEST_PAGE_BLOB_TXT + azureStorageConfig.sharedAccessSignature;
    var putPage = testAzureStorageClient->putPageFromURL(TEST_CONTAINER, TEST_PAGE_BLOB_TXT, sourceBlobURL,
                    TEST_BYTE_RANGE, TEST_BYTE_RANGE);
    if (putPage is error) {
        test:assertFail(putPage.toString());
    }
}

@test:Config {
    dependsOn: ["testPutPageUpdate"]
}
function testPutPageClear() {
    log:print("testAzureStorageClient -> putPage() - 'clear' operation");
    var putPage = testAzureStorageClient->putPage(TEST_CONTAINER, TEST_PAGE_BLOB_TXT, CLEAR, TEST_BYTE_RANGE);
    if (putPage is error) {
        test:assertFail(putPage.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testAppendBlock() {
    log:print("testAzureStorageClient -> appendBlock()");
    byte[] appendContent = TEST_STRING.toBytes();
    var appendedBlock = testAzureStorageClient->appendBlock(TEST_CONTAINER, TEST_APPEND_BLOB_TXT, appendContent);
    if (appendedBlock is error) {
        test:assertFail(appendedBlock.toString());
    }
}

@test:Config {
    dependsOn:["testAppendBlock"]
}
function testAppendBlockFromURL() {
    log:print("testAzureStorageClient -> appendBlockFromURL()");
    string sourceBlobURL =  azureStorageConfig.baseURL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL 
                             + TEST_BLOCK_BLOB_TXT + azureStorageConfig.sharedAccessSignature;
    var appendBlockFromURL = testAzureStorageClient->appendBlockFromURL(TEST_CONTAINER, TEST_APPEND_BLOB_TXT,
                                sourceBlobURL);
    if (appendBlockFromURL is error) {
        test:assertFail(appendBlockFromURL.toString());
    }
}

@test:Config {
    dependsOn:["testPutBlob"]
}
function testGetPageRanges() {
    log:print("testAzureStorageClient -> getPageRanges()");
    var pageRanges = testAzureStorageClient->getPageRanges(TEST_CONTAINER, TEST_PAGE_BLOB_TXT);
    if (pageRanges is error) {
        test:assertFail(pageRanges.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob", "testGetBlobMetadata", "testGetBlobProperties", "testCopyBlob", "testCopyBlobFromURL",
                "testAppendBlockFromURL", "testPutBlock", "testPutBlockFromURL", "testPutPageClear"]
}
function testDeleteBlob() {
    log:print("testAzureStorageClient -> deleteBlob()");
    var blobDeleted = testAzureStorageClient->deleteBlob(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    if (blobDeleted is error) {
        test:assertFail(blobDeleted.toString());
    }
}

// This is only for secondary location endpoint
@test:Config {
    enable:false
}
function testGetBlobServiceStats() {
    log:print("testAzureStorageClient -> getBlobServiceStats()");
    var blobServiceStats = testAzureStorageClient->getBlobServiceStats();
    if (blobServiceStats is error) {
        test:assertFail(blobServiceStats.toString());
    }
}

@test:Config {
    //enable:false // enable
}
function testGetAccoutInformation() {
    log:print("testAzureStorageClient -> getAccountInformation()");
    var accountInformation = testAzureStorageClient->getAccountInformation();
    if (accountInformation is error) {
        test:assertFail(accountInformation.toString());
    }
}

@test:Config {}
function testGetBlobServiceProperties() {
    log:print("testAzureStorageClient -> getBlobServiceProperties()");
    var blobServiceProperties = testAzureStorageClient->getBlobServiceProperties();
    if (blobServiceProperties is error) {
        test:assertFail(blobServiceProperties.toString());
    }
}

@test:Config {
    dependsOn:["testDeleteBlob", "testAppendBlock", "testGetPageRanges"]
}
function testDeleteContainer() {
    log:print("testAzureStorageClient -> deleteContainer()");
    var containerDeleted = testAzureStorageClient->deleteContainer(TEST_CONTAINER);
    if (containerDeleted is error) {
        test:assertFail(containerDeleted.toString());
    }
}
