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

public function main() returns error? {
    azure_blobs:ConnectionConfig blobServiceConfig = {
        accessKeyOrSAS: os:getEnv("ACCESS_KEY_OR_SAS"),
        accountName: os:getEnv("ACCOUNT_NAME"),
        authorizationMethod: "accessKey"
    };
 
    azure_blobs:ManagementClient managementClient = check  new (blobServiceConfig);

    string containerName = "test-container";

    // Create Container
    log:printInfo("Create Container");
    var createContainerResult = managementClient->createContainer(containerName);
    if (createContainerResult is error) {
        log:printError(createContainerResult.toString());
    } else {
        log:printInfo(createContainerResult.toString());
    }

    // Get Container Properties
    log:printInfo("Get Container Properties");
    var getContainerPropertiesResult = managementClient->getContainerProperties(containerName);
    if (getContainerPropertiesResult is error) {
        log:printError(getContainerPropertiesResult.toString());
    } else {
        log:printInfo(getContainerPropertiesResult.toString());
    }

    // Get Container Meta Data
    log:printInfo("Get Container Metadata");
    var getContainerMetadataResult = managementClient->getContainerMetadata(containerName);
    if (getContainerMetadataResult is error) {
        log:printError(getContainerMetadataResult.toString());
    } else {
        log:printInfo(getContainerMetadataResult.toString());
    }

    // Get Container ACL
    log:printInfo("Get Container ACL");
    var getContainerACLResult = managementClient->getContainerACL(containerName);
    if (getContainerACLResult is error) {
        log:printError(getContainerACLResult.toString());
    } else {
        log:printInfo(getContainerACLResult.toString());
    }

    // Get Account Information
    log:printInfo("Get Account Information");
    var getAccountInformationResult = managementClient->getAccountInformation();
    if (getAccountInformationResult is error) {
        log:printError(getAccountInformationResult.toString());
    } else {
        log:printInfo(getAccountInformationResult.toString());
    }
    
    // Get Blob Service Properties
    log:printInfo("Get Blob Service Properties");
    var getBlobServicePropertiesResult = managementClient->getBlobServiceProperties();
    if (getBlobServicePropertiesResult is error) {
        log:printError(getBlobServicePropertiesResult.toString());
    } else {
        log:printInfo(getBlobServicePropertiesResult.toString());
    }

    // Delete a Container
    log:printInfo("Delete a container");
    var deleteContainerResult = managementClient->deleteContainer(containerName);
    if (deleteContainerResult is error) {
        log:printError(deleteContainerResult.toString());
    } else {
        log:printInfo(deleteContainerResult.toString());
    }
}
