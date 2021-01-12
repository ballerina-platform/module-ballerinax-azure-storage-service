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

import ballerina/lang.array as arrlib;
import ballerina/http;
import ballerina/jsonutils;

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

# Creates AccountInformationResult from http response.
# 
# + response - validated http response
# + return - Returns AccountInformation type
isolated function convertResponseToAccountInformationType(http:Response response) 
                    returns @tainted AccountInformationResult|error {
    AccountInformationResult accountInformation = {};
    accountInformation.accountKind = response.getHeader(X_MS_ACCOUNT_KIND);
    accountInformation.skuName = response.getHeader(X_MS_SKU_NAME);
    accountInformation.isHNSEnabled = response.getHeader(X_MS_IS_HNS_ENABLED);
    accountInformation.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
    return accountInformation;
}

# Creates ContainerPropertiesResult from http response.
# 
# + response - validated http response
# + return - Returns ContainerPropertiesResult type
isolated function convertResponseToContainerPropertiesResult(http:Response response) 
                    returns @tainted ContainerPropertiesResult|error {      
    ContainerPropertiesResult containerProperties = {};
    containerProperties.metaData = getMetaDataHeaders(response);
    containerProperties.eTag = response.getHeader(ETAG);
    containerProperties.lastModified = response.getHeader(LAST_MODIFIED);
    containerProperties.leaseStatus = response.getHeader(X_MS_LEASE_STATUS);
    containerProperties.leaseState = response.getHeader(X_MS_LEASE_STATE);
    containerProperties.hasImmutabilityPolicy = response.getHeader(X_MS_HAS_IMMUTABILITY_POLICY);
    containerProperties.hasLegalHold = response.getHeader(X_MS_HAS_LEGAL_HOLD);

    if (response.hasHeader(X_MS_LEASE_DURATION)) {
        containerProperties.leaseDuration = response.getHeader(X_MS_LEASE_DURATION);
    }

    if (response.hasHeader(X_MS_BLOB_PUBLIC_ACCESS)) {
        containerProperties.publicAccess = response.getHeader(X_MS_BLOB_PUBLIC_ACCESS);
    }
    
    containerProperties.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
    return containerProperties;
}

# Creates ContainerMetadataResult from http response.
# 
# + response - validated http response
# + return - Returns ContainerMetadataResult type
isolated function convertResponseToContainerMetadataResult(http:Response response) 
                    returns @tainted ContainerMetadataResult|error {
    ContainerMetadataResult containerMetadataResult = {};
    containerMetadataResult.metadata = getMetaDataHeaders(response);                    
    containerMetadataResult.eTag = response.getHeader(ETAG);
    containerMetadataResult.lastModified = response.getHeader(LAST_MODIFIED);
    containerMetadataResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
    return containerMetadataResult;
}

# Creates ContainerACLResult from http response.
# 
# + response - validated http response
# + return - Returns ContainerACLResult type
isolated function convertResponseToContainerACLResult(http:Response response) 
                    returns @tainted ContainerACLResult|error {                    
    ContainerACLResult containerACLResult = {};                  
    containerACLResult.eTag = response.getHeader(ETAG);
    containerACLResult.lastModified = response.getHeader(LAST_MODIFIED);

    if (response.hasHeader(X_MS_BLOB_PUBLIC_ACCESS)) {
        containerACLResult.publicAccess = response.getHeader(X_MS_BLOB_PUBLIC_ACCESS);
    }

    if (response.getXmlPayload() is xml) {
        xml xmlResponse = check response.getXmlPayload();
        json signedIdentifiers = check jsonutils:fromXML(xmlResponse/*);
        containerACLResult.signedIdentifiers = signedIdentifiers;
    }
    
    containerACLResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
    return containerACLResult;
}

# Creates BlobMetadataResult from http response.
# 
# + response - validated http response
# + return - Returns BlobMetadataResult type
isolated function convertResponseToBlobMetadataResult(http:Response response) 
                    returns @tainted BlobMetadataResult|error {
    BlobMetadataResult blobMetadataResult = {};
    blobMetadataResult.metadata = getMetaDataHeaders(response);                    
    blobMetadataResult.eTag = response.getHeader(ETAG);
    blobMetadataResult.lastModified = response.getHeader(LAST_MODIFIED);
    blobMetadataResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
    return blobMetadataResult;
}

# Creates AppendBlockResult from http response.
# 
# + response - validated http response
# + return - Returns AppendBlockResult type
isolated function convertResponseToAppendBlockResult(http:Response response) 
                    returns @tainted AppendBlockResult|error {
    AppendBlockResult appendBlockResult = {};
    appendBlockResult.eTag = response.getHeader(ETAG);
    appendBlockResult.lastModified = response.getHeader(LAST_MODIFIED);
    appendBlockResult.blobAppendOffset = response.getHeader(X_MS_BLOB_APPEND_OFFSET);
    appendBlockResult.blobCommitedBlockCount = response.getHeader(X_MS_BLOB_COMMITTED_BLOCK_COUNT);
    appendBlockResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
    return appendBlockResult;
}

# Creates PutPageResult from http response.
# 
# + response - validated http response
# + return - Returns PutPageResult type
isolated function convertResponseToPutPageResult(http:Response response) 
                    returns @tainted PutPageResult|error {
    PutPageResult putPageResult = {};
    putPageResult.eTag = response.getHeader(ETAG);
    putPageResult.lastModified = response.getHeader(LAST_MODIFIED);
    putPageResult.blobSequenceNumber = response.getHeader(X_MS_BLOB_SEQUENCE_NUMBER);
    putPageResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
    return putPageResult;
}

# Creates PutPageResult from http response.
# 
# + response - validated http response
# + return - Returns PutPageResult type
isolated function convertResponseToCopyBlobResult(http:Response response) 
                    returns @tainted CopyBlobResult|error {
    CopyBlobResult copyBlobResult = {};
    copyBlobResult.eTag = response.getHeader(ETAG);
    copyBlobResult.lastModified = response.getHeader(LAST_MODIFIED);
    copyBlobResult.copyId = response.getHeader(X_MS_COPY_ID);
    copyBlobResult.copyStatus = response.getHeader(X_MS_COPY_STATUS);
    copyBlobResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
    return copyBlobResult;
}

# Creates Container Array from JSON container list
# 
# + containerListJsonArray - json array of containers
# + return - Returns Container array
isolated function convertJSONToContainerArray(json|error containerListJson) returns Container[]|error {
    Container[] containerList = [];
    if (containerListJson is json[]) { // When there are multiple containers, it will be a json[]
        foreach json containerJsonObject in containerListJson {
            Container container = check convertJSONToContainerType(containerJsonObject);
            container.Properties.LastModified = <string>container.Properties[LAST_MODIFIED];
            arrlib:push(containerList, container);
        }
    } else if (containerListJson is json) { // When there is only one container, it will be a json
        Container container = check convertJSONToContainerType(containerListJson);
        container.Properties.LastModified = <string>container.Properties[LAST_MODIFIED];
        arrlib:push(containerList, container);
    }
    return containerList;
}

# Creates Blob Array from JSON Blob list
# 
# + BlobListJsonArray - json array of Blob
# + return - Returns Blob array
isolated function convertJSONToBlobArray(json|error blobListJson) returns Blob[]|error {
    Blob[] blobList = [];
    if (blobListJson is json[]) { // When there are multiple blobs, it will be a json[]
        foreach json blobJsonObject in blobListJson {
            Blob blob = check convertJSONToBlobType(blobJsonObject);
            arrlib:push(blobList, blob);
        }
    } else if (blobListJson is json){ // When there is only one blob, it will be a json
        Blob blob = check convertJSONToBlobType(blobListJson);
        arrlib:push(blobList, blob);
    }
    return blobList;
}
