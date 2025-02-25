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

import ballerina/os;
import ballerina/test;

configurable string accessKeyOrSAS = os:getEnv("ACCESS_KEY_OR_SAS");
configurable string accountName = os:getEnv("ACCOUNT_NAME");

ConnectionConfig blobServiceConfig = {
    accessKeyOrSAS,
    accountName,
    authorizationMethod: "accessKey"
};

BlobClient blobClient = check new (blobServiceConfig);
ManagementClient managementClient = check new (blobServiceConfig);

string TEST_CONTAINER = "test-blob-container";
string BASE_URL = string `https://${blobServiceConfig.accountName}.blob.core.windows.net`;
const TEST_BLOCK_BLOB_TXT = "test-blockBlob.txt";
const TEST_BLOCK_BLOB_2_TXT = "test-blockBlob2.txt";
const TEST_PAGE_BLOB_TXT = "test-pageBlob.txt";
const TEST_APPEND_BLOB_TXT = "test-appendBlob.txt";
const TEST_COPY_TXT = "test-copy.txt";
const TEST_PUT_BLOCK_TXT = "testPutBlock.txt";
const TEST_PUT_BLOCK_2_TXT = "testPutBlock2.txt";
const TEST_BLOCK_ID = "testBlockId";
const TEST_STRING = "test-string";
const TEST_IMAGE = "test.jpg";
const TEST_IMAGE_PATH = "modules/blobs/tests/resources/test.jpg";
ByteRange byteRange = {startByte: 0, endByte: 511};
map<string> testMetadata1 = {
    "t1": "123",
    "t2": "456",
    "t3": "789"
};
map<string> testMetadata2 = {
    "country": "UK",
    "city": "London"
};
Properties testProperties1 = {
    metadata: testMetadata1,
    blobContentType: "application/text"
};
Properties testProperties2 = {
    metadata: testMetadata2,
    blobContentType: "image/png"
};

@test:Config {}
function testListContainers() {
    var containerList = blobClient->listContainers(maxResults = 10);
    if (containerList is error) {
        test:assertFail(containerList.toString());
    }
}

@test:Config {}
function testCreateContainer() {
    var containerCreated = managementClient->createContainer(TEST_CONTAINER);
    if (containerCreated is error) {
        test:assertFail(containerCreated.toString());
    }
}

@test:Config {
    dependsOn: [testCreateContainer]
}
function testListBlobs() {
    var blobList = blobClient->listBlobs(TEST_CONTAINER);
    if (blobList is error) {
        test:assertFail(blobList.toString());
    }
}

@test:Config {
    dependsOn: [testCreateContainer]
}
function testGetContainerProperties() {
    var containerProperties = managementClient->getContainerProperties(TEST_CONTAINER);
    if (containerProperties is error) {
        test:assertFail(containerProperties.toString());
    }
}

@test:Config {
    dependsOn: [testCreateContainer]
}
function testGetContainerMetadata() {
    var containerMetadata = managementClient->getContainerMetadata(TEST_CONTAINER);
    if (containerMetadata is error) {
        test:assertFail(containerMetadata.toString());
    }
}

@test:Config {
    dependsOn: [testCreateContainer]
}
function testGetContainerACL() {
    if (blobServiceConfig.authorizationMethod == ACCESS_KEY) {
        var containerACLData = managementClient->getContainerACL(TEST_CONTAINER);
        if (containerACLData is error) {
            test:assertFail(containerACLData.toString());
        }
    }
}

@test:Config {
    dependsOn: [testCreateContainer]
}
function testPutBlob() {
    byte[] blob = TEST_STRING.toBytes();

    var putBlockBlob = blobClient->putBlob(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT, BLOCK_BLOB, blob, testProperties1);
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
    dependsOn: [testGetBlob]
}
function testPutBlobFromURL() {
    if (blobServiceConfig.authorizationMethod == SAS) {
        string sourceBlobURL = BASE_URL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL
            + TEST_BLOCK_BLOB_TXT + blobServiceConfig.accessKeyOrSAS;
        var result = blobClient->putBlobFromURL(TEST_CONTAINER, TEST_BLOCK_BLOB_2_TXT, sourceBlobURL);
        if (result is error) {
            test:assertFail(result.toString());
        }
    }

}

@test:Config {
    dependsOn: [testPutBlob]
}
function testGetBlob() returns error? {
    var blob = blobClient->getBlob(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    if (blob is BlobResult) {
        test:assertEquals(blob.properties.blobContentType, testProperties1.blobContentType);
        byte[] blobContent = blob.blobContent;
        string value = <string>check string:fromBytes(blobContent);
        test:assertEquals(value, TEST_STRING);
    } else {
        test:assertFail(blob.toString());
    }
}

@test:Config {
    dependsOn: [testGetBlob]
}
function testSetBlobMetadata() returns error? {
    ResponseHeaders response = check blobClient->setBlobMetadata(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT, testMetadata2);
    test:assertEquals(response.x\-ms\-version, "2019-12-12");
}

@test:Config {
    dependsOn: [testGetBlob, testSetBlobMetadata]
}
function testGetBlobMetadata() returns error? {
    BlobMetadataResult blobMetadata = check blobClient->getBlobMetadata(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    test:assertEquals(blobMetadata.metadata, testMetadata2);
}

@test:Config {
    dependsOn: [testGetBlob]
}
function testGetBlobProperties() {
    var blobProperties = blobClient->getBlobProperties(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    if (blobProperties is error) {
        test:assertFail(blobProperties.toString());
    }
}

@test:Config {
    dependsOn: [testGetBlob]
}
function testPutBlock() {
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
    dependsOn: [testPutBlock]
}
function testPutBlockList() {
    var response = blobClient->putBlockList(TEST_CONTAINER, TEST_PUT_BLOCK_TXT, ["1", "2", "3"]);
    if (response is error) {
        test:assertFail(response.toString());
    }
}

@test:Config {
    dependsOn: [testGetBlob]
}
function testPutBlockFromURL() {
    if (blobServiceConfig.authorizationMethod == SAS) {
        string sourceBlobURL = BASE_URL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL
            + TEST_BLOCK_BLOB_TXT + blobServiceConfig.accessKeyOrSAS;
        var response = blobClient->putBlockFromURL(TEST_CONTAINER, TEST_PUT_BLOCK_2_TXT, TEST_BLOCK_ID, sourceBlobURL);
        if (response is error) {
            test:assertFail(response.toString());
        }
    }
}

@test:Config {
    dependsOn: [testGetBlob, testPutBlock]
}
function testGetBlockList() {
    var blockList = blobClient->getBlockList(TEST_CONTAINER, TEST_PUT_BLOCK_TXT);
    if (blockList is error) {
        test:assertFail(blockList.toString());
    }
}

@test:Config {
    dependsOn: [testGetBlob]
}
function testCopyBlob() {
    if (blobServiceConfig.authorizationMethod == SAS) {
        string sourceBlobURL = BASE_URL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL
            + TEST_BLOCK_BLOB_TXT + blobServiceConfig.accessKeyOrSAS;
        var copyBlob = blobClient->copyBlob(TEST_CONTAINER, TEST_COPY_TXT, sourceBlobURL);
        if (copyBlob is error) {
            test:assertFail(copyBlob.toString());
        }
    }
}

@test:Config {
    dependsOn: [testGetBlob]
}
function testPutPageUpdate() {
    byte[] blob = [];
    int i = 0;
    while (i < 512) {
        blob[i] = 100;
        i = i + 1;
    }
    var putPage = blobClient->putPage(TEST_CONTAINER, TEST_PAGE_BLOB_TXT, UPDATE, byteRange, blob);
    if (putPage is error) {
        test:assertFail(putPage.toString());
    }
}

@test:Config {
    dependsOn: [testPutPageUpdate]
}
function testPutPageClear() {
    var putPage = blobClient->putPage(TEST_CONTAINER, TEST_PAGE_BLOB_TXT, CLEAR, byteRange);
    if (putPage is error) {
        test:assertFail(putPage.toString());
    }
}

@test:Config {
    dependsOn: [testGetBlob]
}
function testAppendBlock() {
    byte[] appendContent = TEST_STRING.toBytes();
    var appendedBlock = blobClient->appendBlock(TEST_CONTAINER, TEST_APPEND_BLOB_TXT, appendContent);
    if (appendedBlock is error) {
        test:assertFail(appendedBlock.toString());
    }
}

@test:Config {
    dependsOn: [testAppendBlock]
}
function testAppendBlockFromURL() {
    if (blobServiceConfig.authorizationMethod == SAS) {
        string sourceBlobURL = BASE_URL + FORWARD_SLASH_SYMBOL + TEST_CONTAINER + FORWARD_SLASH_SYMBOL
            + TEST_BLOCK_BLOB_TXT + blobServiceConfig.accessKeyOrSAS;
        var appendBlockFromURL = blobClient->appendBlockFromURL(TEST_CONTAINER, TEST_APPEND_BLOB_TXT, sourceBlobURL);
        if (appendBlockFromURL is error) {
            test:assertFail(appendBlockFromURL.toString());
        }
    }

}

@test:Config {
    dependsOn: [testPutBlob]
}
function testGetPageRanges() {
    var pageRanges = blobClient->getPageRanges(TEST_CONTAINER, TEST_PAGE_BLOB_TXT);
    if (pageRanges is error) {
        test:assertFail(pageRanges.toString());
    }
}

@test:Config {
    dependsOn: [
        testGetBlob,
        testGetBlobMetadata,
        testGetBlobProperties,
        testCopyBlob,
        testAppendBlockFromURL,
        testPutBlockList,
        testPutBlobFromURL,
        testPutBlockFromURL,
        testPutPageClear,
        testGetBlockList
    ]
}
function testDeleteBlob() {
    var blobDeleted = blobClient->deleteBlob(TEST_CONTAINER, TEST_BLOCK_BLOB_TXT);
    if (blobDeleted is error) {
        test:assertFail(blobDeleted.toString());
    }
}

@test:Config {}
function testUploadLargeBlob() {
    var response = blobClient->uploadLargeBlob(TEST_CONTAINER, TEST_IMAGE, TEST_IMAGE_PATH, testProperties2);
    if (response is error) {
        test:assertFail(response.toString());
    }
}

@test:Config {}
function testGetAccountInformation() {
    var accountInformation = managementClient->getAccountInformation();
    if (accountInformation is error) {
        test:assertFail(accountInformation.toString());
    }
}

@test:Config {}
function testGetBlobServiceProperties() {
    var blobServiceProperties = managementClient->getBlobServiceProperties();
    if (blobServiceProperties is error) {
        test:assertFail(blobServiceProperties.toString());
    }
}

@test:AfterSuite {}
function testDeleteContainer() {
    var containerDeleted = managementClient->deleteContainer(TEST_CONTAINER);
    if (containerDeleted is error) {
        test:assertFail(containerDeleted.toString());
    }
}
