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

import ballerina/log;
import ballerina/os;
import ballerina/test;
import ballerina/io;

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
string resourcesPath = "modules/files/tests/resources/";
string metricsVersion = "1.0";
string baseURL = string `https://${azureConfig.accountName}.file.core.windows.net/`;

FileClient fileClient = check new (azureConfig);
ManagementClient managementClient = check new (azureConfig);

@test:Config {enable: true}
function testGetFileServiceProperties() {
    log:printInfo("GetFileServiceProperties");
    var result = managementClient->getFileServiceProperties();
    if (result is FileServicePropertiesList) {
        test:assertTrue(result.StorageServiceProperties?.MinuteMetrics?.Version == metricsVersion, 
        "Check the received version");
    } else {
        test:assertFail(result.toString());
    }
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

@test:Config {enable: true}
function testSetFileServiceProperties() {
    log:printInfo("testSetFileServiceProperties");
    var result = managementClient->setFileServiceProperties(fileService);
    if (result is error) {
        test:assertFail(result.toString());
    }    
}

@test:Config {enable: true}
function testCreateShare() {
    log:printInfo("testCreateShare");
    var result = managementClient->createShare(testFileShareName);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testCreateShare]}
function testListShares() {
    log:printInfo("testListShares");
    var result = managementClient ->listShares();
    if (result is SharesList) {
        var list = result.Shares.Share;
        if (list is ShareItem) {
            log:printInfo(list.Name);
        } else {
            log:printInfo(list[1].Name);
        }
    } else if (result is NoSharesFoundError) {
        log:printInfo(result.message());
    } else {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testCreateShare]}
function testCreateDirectory() {
    log:printInfo("testCreateDirectory");
    var result = fileClient->createDirectory(fileShareName = testFileShareName, 
        newDirectoryName = testDirectoryPath);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testCreateDirectory]}
function testGetDirectoryList() {
    log:printInfo("testGetDirectoryList");
    var result = fileClient->getDirectoryList(fileShareName = testFileShareName);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testCreateShare]}
function testCreateFile() {
    log:printInfo("testCreateFile");
    var result = fileClient->createFile(fileShareName = testFileShareName, newFileName = testFileName, 
    fileSizeInByte = 8);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testCreateFile]}
function testGetFileList() {
    log:printInfo("testGetFileList");
    var result = fileClient->getFileList(fileShareName = testFileShareName);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testCreateFile]}
function testPutRange() {
    log:printInfo("testPutRange");
    var result = fileClient->putRange(fileShareName = testFileShareName, 
    localFilePath = resourcesPath + testFileName, azureFileName = testFileName);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true,  dependsOn:[testCreateShare]}
function testDirectUpload() {
    log:printInfo("testDirectUpload");
    var result = fileClient->directUpload(fileShareName = testFileShareName, localFilePath = resourcesPath 
        + testFileName, azureFileName = testFileName2);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true,  dependsOn:[testPutRange]}
function testListRange() {
    log:printInfo("testListRange");
    var result = fileClient->listRange(fileShareName = testFileShareName, fileName = testFileName);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testPutRange]}
function testGetFile() {
    log:printInfo("testGetFile");
    var result = fileClient->getFile(fileShareName = testFileShareName, fileName = testFileName, 
    localFilePath = resourcesPath + "test_download.txt");
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true, dependsOn: [testPutRange]}
function testGetFileAsByteArray() {
    log:printInfo("testGetFileAsByteArray");
    byte[]|error result = fileClient->getFileAsByteArray(fileShareName = testFileShareName, fileName = testFileName);
    if (result is error) {
        test:assertFail(result.toString());
    } else {
        log:printInfo(result.length().toString());
    }
}

@test:Config {enable: true, dependsOn:[testCreateShare, testCreateDirectory, testCreateFile, testPutRange]}
function testCopyFile() {
    log:printInfo("testCopyFile");
    var result = fileClient->copyFile(fileShareName = testFileShareName, destFileName = testCopyFileName, 
        destDirectoryPath = testDirectoryPath, sourceURL = baseURL + testFileShareName + SLASH + testFileName);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testCopyFile, testListRange, testGetFile, testGetFileMetadata, 
             testGetFileAsByteArray]}
function testDeleteFile() {
    log:printInfo("testDeleteFile");
    var result = fileClient->deleteFile(fileShareName = testFileShareName, fileName = testFileName);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testDeleteFile, testGetDirectoryList]}
function testDeleteDirectory() {
    log:printInfo("testDeleteDirectory");
    var deleteCopied = fileClient->deleteFile(fileShareName = testFileShareName, fileName = testCopyFileName, 
        azureDirectoryPath = testDirectoryPath);
    if (deleteCopied is error) {
        log:printError("Failed to delete" + testCopyFileName);
    }
    var result = fileClient->deleteDirectory(fileShareName = testFileShareName, directoryName = testDirectoryPath);
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true,  dependsOn:[testCreateShare]}
function testDirectUploadAsByteArray() returns error? {
    log:printInfo("testDirectUploadAsByteArray");
    byte[] content= check io:fileReadBytes(path = resourcesPath + testFileName);
    var result = fileClient->directUploadFileAsByteArray(fileShareName = testFileShareName, fileContent=content, 
                                                azureFileName = "testFileAsByteArray.txt");
    if (result is error) {
        test:assertFail(result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testPutRange]} 
function testGetFileMetadata() returns error? {
    log:printInfo("testGetFileMetadata");
    FileMetadataResult|error result = fileClient->getFileMetadata(fileShareName = testFileShareName, fileName = testFileName);
    if (result is error) {
        test:assertFail(result.toString());
    } else {
        log:printInfo(result.toString());
    }   
}

@test:AfterSuite {}
function testDeleteShare() {
    log:printInfo("testDeleteShare");
    var result = managementClient->deleteShare(testFileShareName);
    if (result is error) {
        test:assertFail(result.toString());
    }
}
