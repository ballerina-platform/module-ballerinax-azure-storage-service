//import ballerina/io;
import ballerina/test;
import ballerina/config;
import ballerina/system;
import ballerina/io;

AzureConfiguration azureConfig = {
    sasToken: getConfigValue("SAS_TOKEN"),
    baseUrl: getConfigValue("BASE_URL")
};

function getConfigValue(string key) returns string {
    return (system:getEnv(key) != "") ? system:getEnv(key) : config:getAsString(key);
}

Client azureClient = new (azureConfig);

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

StorageServicePropertiesType storageServicePropertiesType = {HourMetrics: hourMetrics
// MinuteMetrics: minMetrics,
// Cors: "",
// ProtocolSettings: protocolSettingsType
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
        test:assertTrue(result, "Sucess");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testCreateShare() {

    RequestParameterList parameterList = {fileShareName: "wso2fileshare"};
    var result = azureClient->createShare(parameterList);
    if (result is boolean) {
        test:assertTrue(result, "Sucess");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testListShares() {

    var result = azureClient->listShares();
    if (result is SharesList) {
        var list = result.Shares.Share;
        if (list is ShareItem) {
            io:println(list.Name);
        } else {
            io:println(list[1].Name);
        }
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testcreateDirectory() {
    RequestParameterList parameterList = {
        fileShareName: "wso2fileshare",
        newDirectoryName: "wso2DirectoryTest",
        azureDirectoryPath: ""
    };
    var result = azureClient->createDirectory(parameterList);
    if (result is boolean) {
        test:assertTrue(result, "Sucess");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testgetDirectoryList() {
    var result = azureClient->getDirectoryList(fileShareName = "wso2fileshare");
    if (result is DirecotyList) {
        test:assertTrue(true, "Sucess");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testCreateFile() {
    var result = azureClient->createFile(fileShareName = "wso2fileshare", fileName = "test.txt", fileSizeInByte = 10, 
    azureDirectoryPath = "");
    if (result is boolean) {
        test:assertTrue(result, "Sucess");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testgetFileList() {
    var result = azureClient->getFileList(fileShareName = "wso2fileshare", maxResult = 3);
    if (result is FileList) {
        test:assertTrue(true, "Sucess");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testPutRange() {
    var result = azureClient->putRange(fileShareName = "wso2fileshare", 
    localFilePath = "modules/azureFileShare/tests/resources/test.txt", azureFileName = "test.txt");
    if (result is boolean) {
        test:assertTrue(result, "Sucess");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testListRange() {
    var result = azureClient->listRange(fileShareName = "wso2fileshare", fileName = "test.txt");
    if (result is RangeList) {
        test:assertTrue(true, "Sucess");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testgetFile() {
    var result = azureClient->getFile(fileShareName = "wso2fileshare", fileName = "test.txt", azureDirectoryPath = "", 
    localFilePath = "modules/azureFileShare/tests/resources/test.txt");
    if (result is boolean) {
        test:assertTrue(result, "Sucess");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testCopyFile() {
    var result = azureClient->copyFile(fileShareName = "wso2fileshare", destFileName = "copied.txt", 
    destDirectoryPath = "wso2DirectoryTest", 
    sourceURL = "https://filesharetestwso2.file.core.windows.net/wso2fileshare/test.txt");
    if (result is boolean) {
        test:assertTrue(result, "Sucess");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testDeleteFile() {
    var result = azureClient->deleteFile(fileShareName = "wso2fileshare", fileName = "test.txt", azureDirectoryPath = "");
    if (result is boolean) {
        test:assertTrue(result, "Sucess");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testDeleteDirectory() {
    var deleteCopied = azureClient->deleteFile(fileShareName = "wso2fileshare", fileName = "copied.txt", 
    azureDirectoryPath = "wso2DirectoryTest");
    var result = azureClient->deleteDirectory(fileShareName = "wso2fileshare", directoryName = "wso2DirectoryTest");
    if (result is boolean) {

        test:assertTrue(result, "Sucess");
    } else {
        test:assertFail(msg = result.toString());
    }
}

@test:Config {enable: true}
function testdeleteShare() {
    RequestParameterList parameterList = {fileShareName: "wso2fileshare"};
    var result = azureClient->deleteShare(parameterList);
    if (result is boolean) {
        test:assertTrue(result, "Sucess");
    } else {
        test:assertFail(msg = result.toString());
    }
}
