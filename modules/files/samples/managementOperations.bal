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

import ballerinax/azure_storage_service.files as azure_files;
import ballerina/log;

configurable string accessKeyOrSAS = ?; 
configurable string accountName = ?;

public function main() returns error? {
    azure_files:AzureFileServiceConfiguration configuration = {
        accessKeyOrSAS: accessKeyOrSAS,
        accountName: accountName,
        authorizationMethod: "accessKey"
    };

    azure_files:ManagementClient managementClient = check new (configuration);

    // Creation of a azure fileshare with the name : "demoshare"
    string fileshareName = "demoshare";
    log:printInfo("Fileshare Creation");
    var creationResponse = managementClient->createShare(fileshareName);
    if (creationResponse is error){
        log:printInfo("Status: " + creationResponse.message());
    }
    
    // Getting a list of shares in the file service account
    // User can provide any optional uri paramteres and headers as separate maps respectively.
    // However, Connector only support some of them and Unsupported and invalid ones will be neglected even user provides
    log:printInfo("Listing down shares");
    var listShareResponse = managementClient ->listShares();
    if (listShareResponse is azure_files:SharesList) {
        log:printInfo(listShareResponse.Shares.toString());
    } else {
        log:printInfo("Status: " + listShareResponse.message());
    }
    
    // User can obtain service level properties
    log:printInfo("Getting file service properties");
    var filePropertiesResponse = managementClient->getFileServiceProperties();
    if (filePropertiesResponse is azure_files:FileServicePropertiesList) {
        log:printInfo(filePropertiesResponse.toString());
    } else {
        log:printInfo("Status: " + filePropertiesResponse.message());
    }

    // Preparing informations to be set as properties of the file service.
    log:printInfo("Setting file service properties");
    azure_files:MultichannelType multichannelType = {Enabled: "false"};
    azure_files:SMBType smbType = {Multichannel: multichannelType};
    azure_files:RetentionPolicyType mintRetentionPolicy = {Enabled: "false"};
    azure_files:RetentionPolicyType hourRetentionPolicy = {
        Enabled: "true",
        Days: "7"
    };
    azure_files:MetricsType hourMetrics = {
        Version: "1.0",
        Enabled: false,
        RetentionPolicy: mintRetentionPolicy
    };
    azure_files:StorageServicePropertiesType storageServicePropertiesType = {HourMetrics: hourMetrics};
    azure_files:FileServicePropertiesList fileService = {StorageServiceProperties: storageServicePropertiesType};

    // Use the operation to set the properties defined above.
    var settingResponse = managementClient->setFileServiceProperties(fileService);
    if (settingResponse is error) {
        log:printInfo("Status: " + settingResponse.message());
    }

    // Deletion of the fileshare
    log:printInfo("Deletion of the demo fileshare");
    var deletionResponse = managementClient->deleteShare(fileshareName);
    if (deletionResponse is error){
         log:printInfo("Status: " + deletionResponse.message());
    }
}
