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

import ballerina/config;
import ballerina/log;
import ballerina/test;
import ballerina/system;
import azure_storage_service.utils as storage_utils;

AzureBlobServiceConfiguration blobServiceConfig = {
    sharedAccessSignature: getConfigValue("SHARED_ACCESS_SIGNATURE"),
    baseURL: getConfigValue("BASE_URL"),
    accessKey: getConfigValue("ACCESS_KEY"),
    accountName: getConfigValue("ACCOUNT_NAME"),
    authorizationMethod: getConfigValue("AUTHORIZATION_METHOD")
};

BlobClient blobClient = new (blobServiceConfig);
ManagementClient managementClient = new (blobServiceConfig);

string TEST_CONTAINER = "test-blob-container-" + storage_utils:getCurrentTime();
const TEST_BLOCK_BLOB_TXT = "test-blockBlob.txt";
const TEST_BLOCK_BLOB_COPY_TXT = "test-blockBlobCopy.txt";
const TEST_PAGE_BLOB_TXT = "test-pageBlob.txt";
const TEST_APPEND_BLOB_TXT = "test-appendBlob.txt";
const TEST_COPY_TXT = "test-copy.txt";
const TEST_PUT_BLOCK_TXT = "testPutBlock.txt";
const TEST_PUT_BLOCK_2_TXT = "testPutBlock2.txt";
const TEST_BLOCK_ID = "testBlockId";
const TEST_STRING = "test-string";
const TEST_IMAGE = "test.jpg";
const TEST_IMAGE_PATH = "modules/blobs/tests/resources/test.jpg";
const TEST_X_MS_META_TEST = "x-ms-meta-test";

@test:Config {}
function testListContainers() {
    log:print("blobClient -> listContainers()");
    var containerList = blobClient->listContainers(maxResults = 10);
    if (containerList is error) {
        test:assertFail(containerList.toString());
    }
}

@test:Config {}
function testListContainerStream() {
    log:print("blobClient -> listContainersStream()");
    stream<Container>|error containerList = blobClient->listContainersStream();
    if (containerList is stream<Container>) {
        var container = containerList.next();
    } else {
        test:assertFail(containerList.message());
    }
}

@test:Config {}
function testCreateContainer() {
    log:print("managementClient -> createContainer()");
    var containerCreated = managementClient->createContainer(TEST_CONTAINER);
    if (containerCreated is error) {
        test:assertFail(containerCreated.toString());
    }
}

@test:Config {
    dependsOn:["testCreateContainer"]
}
function testListBlobs() {
    log:print("blobClient -> listBlobs()");
    var blobList = blobClient->listBlobs(TEST_CONTAINER);
    if (blobList is error) {
        test:assertFail(blobList.toString());
    }
}

@test:Config {
    dependsOn:["testCreateContainer"]
}
function testGetContainerProperties() {
    log:print("managementClient -> getContainerProperties()");
    var containerProperties = managementClient->getContainerProperties(TEST_CONTAINER);
    if (containerProperties is error) {
        test:assertFail(containerProperties.toString());
    }
}

@test:Config {
    dependsOn:["testCreateContainer"]
}
function testGetContainerMetadata() {
    log:print("managementClient -> getContainerMetadata()");
    var containerMetadata = managementClient->getContainerMetadata(TEST_CONTAINER);
    if (containerMetadata is error) {
        test:assertFail(containerMetadata.toString());
    }
}

@test:Config {
    dependsOn:["testCreateContainer"]
}
function testGetContainerACL() {
    log:print("managementClient -> getContainerACL()");
    if (blobServiceConfig.authorizationMethod == SHARED_KEY) {
        var containerACLData = managementClient->getContainerACL(TEST_CONTAINER);
        if (containerACLData is error) {
            test:assertFail(containerACLData.toString());
        }
    } else {
        // Only Account owner can perform this operation using SharedKey
        log:print("Skipping test for getContainerACL() since the authentication method is not SharedKey");
    }
}

@test:Config {
    dependsOn:["testCreateContainer"]
}
function testPutBlob() {
    log:print("blobClient -> putBlob()");
    byte[] blob = TEST_STRING.toBytes();

    var putBlockBlob = blobClient->putBlob(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT, BLOCK_BLOB, blob);
    if (putBlockBlob is error) {
        test:assertFail(putBlockBlob.toString());
    }

    var putPageBlob = blobClient->putBlob(TEST_CONTAINER, TEST_PAGE_BLOB_TXT, PAGE_BLOB, pageBlobLength = 512);
    if (putPageBlob is error) {
        test:assertFail(putPageBlob.toString());
    }

    var putAppendBlob = blobClient->putBlob(TEST_CONTAINER, TEST_APPEND_BLOB_TXT, APPEND_BLOB);
    if (putAppendBlob is error) {
        test:assertFail(putAppendBlob.toString());
    }
}

@test:Config {
    dependsOn:["testPutBlob"]
}
function testPutBlobFromURL() {
    log:print("blobClient -> putBlobFromURL()");
    string sourceBlobURL =  blobServiceConfig.baseURL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL 
                              + TEST_BLOCK_BLOB_TXT+ blobServiceConfig.sharedAccessSignature;
    var result = blobClient->putBlobFromURL(TEST_CONTAINER, TEST_BLOCK_BLOB_COPY_TXT, sourceBlobURL);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {
    dependsOn:["testPutBlob"]
}
function testGetBlob() {
    log:print("blobClient -> getBlob()");
    var blob = blobClient->getBlob(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    if (blob is BlobResult) {
        byte[] blobContent = blob.blobContent;
        string value = <string> 'string:fromBytes(blobContent);
        test:assertEquals(value, TEST_STRING);
    } else {
        test:assertFail(blob.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testGetBlobMetadata() {
    log:print("blobClient -> getBlobMetadata()");
    var blobMetadata = blobClient->getBlobMetadata(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    if (blobMetadata is error) {
        test:assertFail(blobMetadata.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testGetBlobProperties() {
    log:print("blobClient -> getBlobProperties()");
    var blobProperties = blobClient->getBlobProperties(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    if (blobProperties is error) {
        test:assertFail(blobProperties.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testPutBlock() {
    log:print("blobClient -> putBlock()");
    byte[] blob1 = "blob1".toBytes();
    byte[] blob2 = "blob2".toBytes();
    byte[] blob3 = "blob3".toBytes();
    var response1 = blobClient->putBlock(TEST_CONTAINER, TEST_PUT_BLOCK_TXT, "1", blob1);
    var response2 = blobClient->putBlock(TEST_CONTAINER, TEST_PUT_BLOCK_TXT, "2", blob2);
    var response3 = blobClient->putBlock(TEST_CONTAINER, TEST_PUT_BLOCK_TXT, "3", blob3);
    if (response1 is error) {
        test:assertFail(response1.toString());
    } 
    if (response2 is error) {
        test:assertFail(response2.toString());
    } 
    if (response3 is error) {
        test:assertFail(response3.toString());
    } 
}

@test:Config {
    dependsOn: ["testPutBlock"]
}
function testPutBlockList() {
    log:print("blobClient -> putBlockList()");
    var response = blobClient->putBlockList(TEST_CONTAINER, TEST_PUT_BLOCK_TXT, ["1", "2", "3"]);
    if (response is error) {
        test:assertFail(response.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testPutBlockFromURL() {
    log:print("blobClient -> putBlockFromURL()");
    string sourceBlobURL =  blobServiceConfig.baseURL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL 
                              + TEST_BLOCK_BLOB_TXT + blobServiceConfig.sharedAccessSignature;
    var response = blobClient->putBlockFromURL(TEST_CONTAINER, TEST_PUT_BLOCK_2_TXT, TEST_BLOCK_ID,
                     sourceBlobURL);
    if (response is error) {
        test:assertFail(response.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob", "testPutBlock"]
}
function testGetBlockList() {
    log:print("blobClient -> getBlockList()");
    var blockList = blobClient->getBlockList(TEST_CONTAINER, TEST_PUT_BLOCK_TXT);
    if (blockList is error) {
        test:assertFail(blockList.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testCopyBlob() {
    log:print("blobClient -> copyBlob()");
    string sourceBlobURL =  blobServiceConfig.baseURL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL 
                            + TEST_BLOCK_BLOB_TXT + blobServiceConfig.sharedAccessSignature;
    var copyBlob = blobClient->copyBlob(TEST_CONTAINER, TEST_COPY_TXT, sourceBlobURL);
    if (copyBlob is error) {
        test:assertFail(copyBlob.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testPutPageUpdate() {
    log:print("blobClient -> putPage() 'update' operation");
    byte[] blob = [];
    int i = 0;
    while (i < 512) {
        blob[i] = 100;
        i = i + 1;
    }
    var putPage = blobClient->putPage(TEST_CONTAINER, TEST_PAGE_BLOB_TXT, UPDATE, 0, 511, blob);
    if (putPage is error) {
        test:assertFail(putPage.toString());
    }
}

@test:Config {
    dependsOn: ["testPutPageUpdate"]
}
function testPutPageClear() {
    log:print("blobClient -> putPage() - 'clear' operation");
    var putPage = blobClient->putPage(TEST_CONTAINER, TEST_PAGE_BLOB_TXT, CLEAR, 0, 511);
    if (putPage is error) {
        test:assertFail(putPage.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob"]
}
function testAppendBlock() {
    log:print("blobClient -> appendBlock()");
    byte[] appendContent = TEST_STRING.toBytes();
    var appendedBlock = blobClient->appendBlock(TEST_CONTAINER, TEST_APPEND_BLOB_TXT, appendContent);
    if (appendedBlock is error) {
        test:assertFail(appendedBlock.toString());
    }
}

@test:Config {
    dependsOn:["testAppendBlock"]
}
function testAppendBlockFromURL() {
    log:print("blobClient -> appendBlockFromURL()");
    string sourceBlobURL =  blobServiceConfig.baseURL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL 
                             + TEST_BLOCK_BLOB_TXT + blobServiceConfig.sharedAccessSignature;
    var appendBlockFromURL = blobClient->appendBlockFromURL(TEST_CONTAINER, TEST_APPEND_BLOB_TXT,
                                sourceBlobURL);
    if (appendBlockFromURL is error) {
        test:assertFail(appendBlockFromURL.toString());
    }
}

@test:Config {
    dependsOn:["testPutBlob"]
}
function testGetPageRanges() {
    log:print("blobClient -> getPageRanges()");
    var pageRanges = blobClient->getPageRanges(TEST_CONTAINER, TEST_PAGE_BLOB_TXT);
    if (pageRanges is error) {
        test:assertFail(pageRanges.toString());
    }
}

@test:Config {
    dependsOn:["testGetBlob", "testGetBlobMetadata", "testGetBlobProperties", "testCopyBlob", "testAppendBlockFromURL", 
                "testPutBlockList", "testPutBlockFromURL", "testPutPageClear", "testGetBlockList"]
}
function testDeleteBlob() {
    log:print("blobClient -> deleteBlob()");
    var blobDeleted = blobClient->deleteBlob(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    if (blobDeleted is error) {
        test:assertFail(blobDeleted.toString());
    }
}

@test:Config {}
function testUploadLargeBlob() {
    log:print("blobClient -> uploadLargeBlob()");
    var response = blobClient->uploadLargeBlob(TEST_CONTAINER, TEST_IMAGE, TEST_IMAGE_PATH);
    if (response is error) {
        test:assertFail(response.toString());
    }
}

@test:Config {}
function testGetAccountInformation() {
    log:print("managementClient -> getAccountInformation()");
    var accountInformation = managementClient->getAccountInformation();
    if (accountInformation is error) {
        test:assertFail(accountInformation.toString());
    }
}

@test:Config {}
function testGetBlobServiceProperties() {
    log:print("managementClient -> getBlobServiceProperties()");
    var blobServiceProperties = managementClient->getBlobServiceProperties();
    if (blobServiceProperties is error) {
        test:assertFail(blobServiceProperties.toString());
    }
}

@test:AfterSuite {}
function testDeleteContainer() {
    log:print("managementClient -> deleteContainer()");
    var containerDeleted = managementClient->deleteContainer(TEST_CONTAINER);
    if (containerDeleted is error) {
        test:assertFail(containerDeleted.toString());
    }
}

# Get configuration value for the given key from ballerina.conf file.
# 
# + return - configuration value of the given key as a string
isolated function getConfigValue(string key) returns string {
    return (system:getEnv(key) != "") ? system:getEnv(key) : config:getAsString(key);
}
