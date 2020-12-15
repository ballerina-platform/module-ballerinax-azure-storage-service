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

import ballerina/lang.array as arrlib;
import ballerina/http;

# Converts Container JSON into Container Type.
# 
# + containerJsonObject - json container object
# + return - Returns Container type
isolated function convertJSONToContainerType(json containerJsonObject) returns Container|error {
    Container container = check containerJsonObject.cloneWithType(Container);
    return container;
}

# Converts Blob JSON into Blob Type.
# 
# + blobJsonObject - json blob object
# + return - Returns Blob type
isolated function convertJSONToBlobType(json blobJsonObject) returns Blob|error {
    Blob blob = check blobJsonObject.cloneWithType(Blob);
    return blob;
}

# Converts Storage Service Properties JSON into StorageServiceProperties Type.
# 
# + storageServicePropertiesJson - json Storage Service Properties object
# + return - Returns Blob type
isolated function convertJSONtoStorageServiceProperties(json storageServicePropertiesJson) 
                    returns StorageServiceProperties|error {
    StorageServiceProperties properties = check storageServicePropertiesJson.cloneWithType(StorageServiceProperties);
    return properties;
}

# Converts Storage Service Stats JSON into StorageServiceStats Type.
# 
# + storageServiceStatsJson - json Storage Service Stats object
# + return - Returns Blob type
isolated function convertJSONtoStorageServiceStats(json storageServiceStatsJson) 
                    returns StorageServiceStats|error {
    StorageServiceStats stats = check storageServiceStatsJson.cloneWithType(StorageServiceStats);
    return stats;
}

# Creates AccountInformation from http response.
# 
# + response - validated http response
# + return - Returns AccountInformation type
isolated function convertResponseToAccountInformationType(http:Response response) 
                    returns @tainted AccountInformation|error {
    AccountInformation accountInformation = {};
    accountInformation.accountKind = response.getHeader(X_MS_ACCOUNT_KIND);
    accountInformation.skuName = response.getHeader(X_MS_SKU_NAME);
    accountInformation.isHNSEnabled = response.getHeader(X_MS_IS_HNS_ENABLED);
    return accountInformation;
}

# Creates Container Array from JSON container list
# 
# + containerListJsonArray - json array of containers
# + return - Returns Container array
isolated function convertJSONToContainerArray(json[] containerListJsonArray) returns Container[]|error {
    Container[] containerList = [];
    foreach json containerJsonObject in containerListJsonArray {
        Container container = check convertJSONToContainerType(containerJsonObject);
        container.Properties.LastModified = <string>container.Properties[LAST_MODIFIED];
        arrlib:push(containerList, container);
    }
    return containerList;
}

# Creates Blob Array from JSON Blob list
# 
# + BlobListJsonArray - json array of Blob
# + return - Returns Blob array
isolated function convertJSONToBlobArray(json[] BlobListJsonArray) returns Blob[]|error {
    Blob[] blobList = [];
    foreach json blobJsonObject in BlobListJsonArray {
        Blob blob = check convertJSONToBlobType(blobJsonObject);
        arrlib:push(blobList, blob);
    }
    return blobList;
}
