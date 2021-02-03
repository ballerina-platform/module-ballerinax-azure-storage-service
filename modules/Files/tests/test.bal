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

import ballerina/log;
import ballerina/test;
import ballerina/config;
import ballerina/system;

AzureConfiguration azureConfig = {
    sasToken: getConfigValue("SAS_TOKEN"),
    baseUrl: getConfigValue("BASE_URL")
};

function getConfigValue(string key) returns string {
    return (system:getEnv(key) != "") ? system:getEnv(key) : config:getAsString(key);
}

AzureFileShareClient azureClient = new (azureConfig);
string testFileShareName = "wso2fileshare";

@test:Config {enable: true}
function testGetFileServiceProperties() {
    var result = azureClient->getFileServiceProperties();
    if (result is FileServicePropertiesList) {
        test:assertTrue(result.StorageServiceProperties?.MinuteMetrics?.Version == "1.0", 
        msg = "Check the received version");
    } else {
        test:assertFail(msg = result.toString());
    }
}

StorageServicePropertiesType storageServicePropertiesType = {
    HourMetrics: hourMetrics
};
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
    var result = azureClient->setFileServiceProperties(fileService);
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testCreateShare() {
    //tests whether user can set any URI or headers but the function uses only allowed ones by the connector.
    map<any> testURIParameters = {
        include:"metadata",
        test:"place"
    };

    map<any> testRequestHeaders = {
        'x\-ms\-client\-request\-id:"www",
        "ms-test":"test-value"
    };
    var result = azureClient->createShare(testFileShareName,testURIParameters,testRequestHeaders);
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testListShares() {
    log:print("testListShares with optinal URI parameters and headers");
    map<any> myparas = {
        include:"metadata",
        test:"testValue"
    };
    map<any> myRequestHeaders = {
        'x\-ms\-client\-request\-id:"www"
    };
    var result = azureClient->listShares(myparas);
    if (result is SharesList) {
        var list = result.Shares.Share;
        if (list is ShareItem) {
            log:print(list.Name);
        } else {
            log:print(list[1].Name);
        }
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testcreateDirectory() {
    RequestParameterList parameterList = {
        fileShareName: testFileShareName,
        newDirectoryName: "wso2DirectoryTest",
        azureDirectoryPath: ""
    };
    var result = azureClient->createDirectory(fileShareName = testFileShareName, newDirectoryName = "wso2DirectoryTest");
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testgetDirectoryList() {
    var result = azureClient->getDirectoryList(fileShareName = testFileShareName);
    if (result is DirectoryList) {
        test:assertTrue(true, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testCreateFile() {
    var result = azureClient->createFile(fileShareName = testFileShareName, azureFileName = "test.txt", fileSizeInByte = 8, 
    azureDirectoryPath = "");
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testgetFileList() {
    // uses an optional parameter to get only limited number of results
    map<any> testURIParameters = {
        maxresults : 3
    };
    var result = azureClient->getFileList(fileShareName = testFileShareName, uriParameters = testURIParameters);
    if (result is FileList) {
        test:assertTrue(true, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testPutRange() {
    var result = azureClient->putRange(fileShareName = testFileShareName, 
    localFilePath = "modules/Files/tests/resources/test.txt", azureFileName = "test.txt");
    if (result is boolean) {
        test:assertTrue(result, "Uploading Failure");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testDirectUpload() {
    var result = azureClient->directUpload(fileShareName = testFileShareName, 
    localFilePath = "modules/Files/tests/resources/test.txt", azureFileName = "test2.txt");
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testListRange() {
    var result = azureClient->listRange(fileShareName = testFileShareName, fileName = "test.txt");
    if (result is RangeList) {
        test:assertTrue(true, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testgetFile() {
    var result = azureClient->getFile(fileShareName = testFileShareName, fileName = "test.txt",
    localFilePath = "modules/Files/tests/resources/test_downloaded.txt");
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testCopyFile() {
    var result = azureClient->copyFile(fileShareName = testFileShareName, destFileName = "copied.txt", 
    destDirectoryPath = "wso2DirectoryTest", 
    sourceURL = "https://filesharetestwso2.file.core.windows.net/wso2fileshare/test.txt");
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testDeleteFile() {
    var result = azureClient->deleteFile(fileShareName = testFileShareName, fileName = "test.txt");
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testDeleteDirectory() {
    var deleteCopied = azureClient->deleteFile(fileShareName = testFileShareName, fileName = "copied.txt", 
    azureDirectoryPath = "wso2DirectoryTest");
    var result = azureClient->deleteDirectory(fileShareName = testFileShareName, directoryName = "wso2DirectoryTest");
    if (result is boolean) {

        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testdeleteShare() {
    var result = azureClient->deleteShare(testFileShareName);
    if (result is boolean) {
        test:assertTrue(result, "Operation Failed");
    } else {
        test:assertFail(msg = result.toString());
    }
}
