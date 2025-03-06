// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/os;
import ballerina/test;
import ballerina/crypto;

configurable string accessKeyOrSAS = os:getEnv("ACCESS_KEY_OR_SAS");
configurable string azureStorageAccountName = os:getEnv("ACCOUNT_NAME");

ConnectionConfig azureConfig = {
    accessKeyOrSAS: accessKeyOrSAS,
    accountName: azureStorageAccountName,
    authorizationMethod: ACCESS_KEY
};

string testFileShareName = "wso2fileshare";
string testDirectoryPath = "wso2DirectoryTest";
string testFileName = "test.txt";
string testFileName2 = "test2.txt";
string testCopyFileName = "copied.txt";
string testLargeFileName = "large_file.txt";
string resourcesPath = "modules/files/tests/resources/";
string metricsVersion = "1.0";
string baseURL = string `https://${azureConfig.accountName}.file.core.windows.net/`;

FileClient fileClient = check new (azureConfig);
ManagementClient managementClient = check new (azureConfig);

@test:Config {
    groups: ["properties", "live_server"]
}
function testGetFileServiceProperties() returns error? {
    FileServicePropertiesList result = check managementClient->getFileServiceProperties();
    test:assertTrue(result.StorageServiceProperties?.MinuteMetrics?.Version == metricsVersion, "version mismatch");
}

StorageServicePropertiesType storageServicePropertiesType = {HourMetrics: hourMetrics};
MetricsType minMetrics = {
    Version: metricsVersion,
    Enabled: true,
    IncludeAPIs: true,
    RetentionPolicy: hourRetentionPolicy
};
MetricsType hourMetrics = {
    Version: metricsVersion,
    Enabled: false,
    RetentionPolicy: mintRetentionPolicy
};
RetentionPolicyType hourRetentionPolicy = {
    Enabled: "true",
    Days: "7"
};
RetentionPolicyType mintRetentionPolicy = {Enabled: "false"};
ProtocolSettingsType protocolSettingsType = {SMB: smbType};
SMBType smbType = {Multichannel: multichannelType};
MultichannelType multichannelType = {Enabled: "false"};
FileServicePropertiesList fileService = {StorageServiceProperties: storageServicePropertiesType};

@test:Config {
    groups: ["properties", "live_server"]
}
function testSetFileServiceProperties() returns error? {
    check managementClient->setFileServiceProperties(fileService);
}

@test:Config {
    groups: ["shares", "live_server"]
}
function testCreateShare() returns error? {
    check managementClient->createShare(testFileShareName);
}

@test:Config {
    dependsOn: [testCreateShare],
    groups: ["shares", "live_server"]
}
function testListShares() returns error? {
    _ = check managementClient->listShares();
}

@test:Config {
    dependsOn: [testCreateShare],
    groups: ["directories", "live_server"]
}
function testCreateDirectory() returns error? {
    check fileClient->createDirectory(testFileShareName, testDirectoryPath);
}

@test:Config {
    dependsOn: [testCreateDirectory],
    groups: ["directories", "live_server"]
}
function testGetDirectoryList() returns error? {
    _ = check fileClient->getDirectoryList(testFileShareName);
}

@test:Config {
    dependsOn: [testCreateShare],
    groups: ["files", "live_server"]
}
function testCreateFile() returns error? {
    check fileClient->createFile(testFileShareName, testFileName, 8);
}

@test:Config {
    dependsOn: [testCreateFile],
    groups: ["files", "live_server"]
}
function testGetFileList() returns error? {
    _ = check fileClient->getFileList(testFileShareName);
}

@test:Config {
    dependsOn: [testCreateFile],
    groups: ["files", "live_server"]
}
function testPutRange() returns error? {
    check fileClient->putRange(testFileShareName, resourcesPath + testFileName, testFileName);
}

@test:Config {
    dependsOn: [testCreateShare],
    groups: ["files", "live_server"]
}
function testDirectUpload() returns error? {
    check fileClient->directUpload(testFileShareName, resourcesPath + testFileName, testFileName2);
}

@test:Config {
    dependsOn: [testPutRange],
    groups: ["files", "live_server"]
}
function testListRange() returns error? {
    _ = check fileClient->listRange(testFileShareName, testFileName);
}

@test:Config {
    dependsOn: [testPutRange],
    groups: ["files", "live_server"]
}
function testGetFile() returns error? {
    check fileClient->getFile(testFileShareName, testFileName, resourcesPath + "test_download.txt");
}

@test:Config {
    dependsOn: [testPutRange],
    groups: ["files", "live_server"]
}
function testGetFileAsByteArray() returns error? {
    byte[] result = check fileClient->getFileAsByteArray(testFileShareName, testFileName);
    test:assertTrue(result.length() == 8, "file size mismatch");
}

@test:Config {
    dependsOn: [testCreateShare, testCreateDirectory, testCreateFile, testPutRange],
    groups: ["files", "live_server"]
}
function testCopyFile() returns error? {
    var result = fileClient->copyFile(fileShareName = testFileShareName, destFileName = testCopyFileName,
        destDirectoryPath = testDirectoryPath, sourceURL = baseURL + testFileShareName + SLASH + testFileName);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {
    dependsOn: [testCopyFile, testListRange, testGetFile, testGetFileMetadata, testGetFileAsByteArray],
    groups: ["files", "live_server"]
}
function testDeleteFile() returns error? {
    check fileClient->deleteFile(testFileShareName, testFileName);
}

@test:Config {
    dependsOn: [testDeleteFile, testGetDirectoryList],
    groups: ["files", "live_server"]
}
function testDeleteDirectory() returns error? {
    check fileClient->deleteFile(testFileShareName, testCopyFileName, testDirectoryPath);
    check fileClient->deleteDirectory(testFileShareName, testDirectoryPath);
}

@test:Config {
    dependsOn: [testCreateShare],
    groups: ["files", "live_server"]
}
function testDirectUploadAsByteArray() returns error? {
    byte[] content = check io:fileReadBytes(path = resourcesPath + testFileName);
    check fileClient->directUploadFileAsByteArray(testFileShareName, content, "testFileAsByteArray.txt");
}

@test:Config {
    dependsOn: [testPutRange],
    groups: ["files", "live_server"]
}
function testGetFileMetadata() returns error? {
    _ = check fileClient->getFileMetadata(testFileShareName, testFileName);
}

@test:Config {
    groups: ["files", "live_server"]
}
function testLargeFileUpload() returns error? {
    byte[] actualContent = check io:fileReadBytes(path = resourcesPath + testLargeFileName);
    byte[] hashKey = "test-key".toBytes();
    byte[] md5Hash = check crypto:hmacMd5(actualContent, hashKey);
    check fileClient->directUploadFileAsByteArray(testFileShareName, actualContent, "largeFile.txt");
    byte[] downloadedContent = check fileClient->getFileAsByteArray(testFileShareName, "largeFile.txt");
    byte[] downloadedMd5Hash = check crypto:hmacMd5(downloadedContent, hashKey);
    test:assertTrue(md5Hash == downloadedMd5Hash, "MD5 hash mismatch");
}

@test:AfterSuite {}
function testDeleteShare() returns error? {
    check managementClient->deleteShare(testFileShareName);
}
