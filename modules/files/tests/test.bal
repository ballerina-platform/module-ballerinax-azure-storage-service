//Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/log;
import ballerina/os;
import ballerina/test;

configurable string azureSharedKeyOrSASToken = os:getEnv("ACCESS_KEY_OR_SAS");
configurable string azureStorageAccountName = os:getEnv("ACCOUNT_NAME");

//For tearing down the resources sas token is used
configurable string sasToken = "";

AzureConfiguration azureConfig = {
    sharedKeyOrSASToken: azureSharedKeyOrSASToken,
    storageAccountName: azureStorageAccountName,
    authorizationMethod : SHARED_ACCESS_SIGNATURE
};

string testFileShareName = "wso2fileshare";
string baseURL = string `https://${azureConfig.storageAccountName}.file.core.windows.net/`;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  * FileShareClient is the client for non-service level client operations such as create/delete files/directories   //
//    within a fileshare.                                                                                             //
//  * ServiceLevelClient is the client for the file service level operation such as create/delete shares.             //
//    For more information : https://docs.microsoft.com/en-us/rest/api/storageservices/file-service-rest-api          //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
FileShareClient azureClient = new (azureConfig);
ServiceLevelClient azureServiceLevelClient = new (azureConfig);

//////////////////////////////////////////////////Service Level Function Tests//////////////////////////////////////////
@test:Config {enable: true}
function testGetFileServiceProperties() {
    log:print("GetFileServiceProperties");
    var result = azureServiceLevelClient->getFileServiceProperties();
    if (result is FileServicePropertiesList) {
        test:assertTrue(result.StorageServiceProperties?.MinuteMetrics?.Version == "1.0", 
        msg = "Check the received version");
    } else {
        test:assertFail(msg = result.toString());
    }
}

StorageServicePropertiesType storageServicePropertiesType = {HourMetrics: hourMetrics};
MetricsType minMetrics = {
    Version: "1.0",
    Enabled: true,
    IncludeAPIs: true,
    RetentionPolicy: hourRetentionPolicy
};
MetricsType hourMetrics = {
    Version: "1.0",
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
    log:print("testSetFileServiceProperties");
    var result = azureServiceLevelClient->setFileServiceProperties(fileService);
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testCreateShare() {
    log:print("testCreateShare");
    //tests whether user can set any URI or headers but the function uses only allowed ones by the connector.
    var result = azureServiceLevelClient->createShare(testFileShareName);
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testCreateShare]}
function testListShares() {
    log:print("testListShares with optinal URI parameters and headers");
    var result = azureServiceLevelClient ->listShares();
    if (result is SharesList) {
        var list = result.Shares.Share;
        if (list is ShareItem) {
            log:print(list.Name);
        } else {
            log:print(list[1].Name);
        }
    } else if (result is NoSharesFoundError) {
        log:print(result.message());
    } else {
        test:assertFail(msg = result.toString());
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////Non-Service Level Fileshare Functions///////////////////////////////
@test:Config {enable: true, dependsOn:[testCreateShare]}
function testcreateDirectory() {
    log:print("testcreateDirectory");
    var result = azureClient->createDirectory(fileShareName = testFileShareName, 
        newDirectoryName = "wso2DirectoryTest");
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testcreateDirectory]}
function testgetDirectoryList() {
    log:print("testgetDirectoryList");
    var result = azureClient->getDirectoryList(fileShareName = testFileShareName);
    if (result is DirectoryList) {
        test:assertTrue(true, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testCreateShare]}
function testCreateFile() {
    log:print("testCreateFile");
    var result = azureClient->createFile(fileShareName = testFileShareName, azureFileName = "test.txt", 
    fileSizeInByte = 8);
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testCreateFile]}
function testgetFileList() {
    log:print("testgetFileList");
    //log:print(testURIParameters.get("maxresults").toString());
    var result = azureClient->getFileList(fileShareName = testFileShareName);
    if (result is FileList) {
        test:assertTrue(true, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testCreateFile]}
function testPutRange() {
    log:print("testPutRange");
    var result = azureClient->putRange(fileShareName = testFileShareName, 
    localFilePath = "modules/files/tests/resources/test.txt", azureFileName = "test.txt");
    if (result is boolean) {
        test:assertTrue(result, "Uploading Failure");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true,  dependsOn:[testCreateShare]}
function testDirectUpload() {
    log:print("testDirectUpload");
    var result = azureClient->directUpload(fileShareName = testFileShareName, 
    localFilePath = "modules/files/tests/resources/test.txt", azureFileName = "test2.txt");
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true,  dependsOn:[testPutRange]}
function testListRange() {
    log:print("testListRange");
    var result = azureClient->listRange(fileShareName = testFileShareName, fileName = "test.txt");
    if (result is RangeList) {
        test:assertTrue(true, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testPutRange]}
function testgetFile() {
    log:print("testgetFile");
    var result = azureClient->getFile(fileShareName = testFileShareName, fileName = "test.txt", 
    localFilePath = "modules/files/tests/resources/test_download.txt");
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testCreateShare,testcreateDirectory,testCreateFile, testPutRange]}
function testCopyFile() {
    log:print("testCopyFile");
    var result = azureClient->copyFile(fileShareName = testFileShareName, destFileName = "copied.txt", 
    destDirectoryPath = "wso2DirectoryTest", 
    sourceURL = baseURL+ testFileShareName + SLASH +"test.txt");
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testCopyFile, testListRange, testgetFile]}
function testDeleteFile() {
    log:print("testDeleteFile");
    var result = azureClient->deleteFile(fileShareName = testFileShareName, fileName = "test.txt");
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true, dependsOn:[testDeleteFile, testgetDirectoryList]}
function testDeleteDirectory() {
    log:print("testDeleteDirectory");
    var deleteCopied = azureClient->deleteFile(fileShareName = testFileShareName, fileName = "copied.txt", 
    azureDirectoryPath = "wso2DirectoryTest");
    var result = azureClient->deleteDirectory(fileShareName = testFileShareName, directoryName = "wso2DirectoryTest");
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////Service Level Functions///////////////////////////////////////////

@test:Config {enable: true, dependsOn:[testDeleteDirectory, testDirectUpload, testDeleteFile, testDeleteDirectory]}
function testdeleteShare() {
    log:print("testdeleteShare");
    var result = azureServiceLevelClient->deleteShare(testFileShareName);
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////Tearing Down///////////////////////////////////////////////////////////
@test:AfterSuite {}
function ReleaseResources() {
    log:print("Used Resources will be removed if available");
    http:Client clientEP = checkpanic new ("https://" + azureConfig.storageAccountName + ".file.core.windows.net/");
    http:Response payload = <http:Response> checkpanic clientEP->delete("/" + testFileShareName + "?restype=share" 
        + sasToken);
    log:print(payload.statusCode.toString());
}
