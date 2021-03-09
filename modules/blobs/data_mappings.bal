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

import ballerina/http;
import ballerina/jsonutils;

# Creates AccountInformationResult from http response.
# 
# + response - Validated http response
# + return - Returns AccountInformation type
isolated function convertResponseToAccountInformationType(http:Response response) returns @tainted 
                                                            AccountInformationResult {
    AccountInformationResult accountInformation = {
        accountKind: let var value = response.getHeader(X_MS_ACCOUNT_KIND) in value is string ? value : EMPTY_STRING,
        skuName: let var value = response.getHeader(X_MS_SKU_NAME) in value is string ? value : EMPTY_STRING,
        isHNSEnabled: let var value = response.getHeader(X_MS_IS_HNS_ENABLED) in value is string ? value : EMPTY_STRING,
        responseHeaders: getHeaderMapFromResponse(response)
    };
    return accountInformation;
}

# Creates ContainerPropertiesResult from http response.
# 
# + response - Validated http response
# + return - Returns ContainerPropertiesResult type
isolated function convertResponseToContainerPropertiesResult(http:Response response) returns @tainted 
                                                                ContainerPropertiesResult {      
    ContainerPropertiesResult containerProperties = {
        metaData: getMetaDataHeaders(response),
        eTag: let var value = response.getHeader(ETAG) in value is string ? value : EMPTY_STRING,
        lastModified: let var value = response.getHeader(LAST_MODIFIED) in value is string ? value : EMPTY_STRING,
        leaseStatus: let var value = response.getHeader(X_MS_LEASE_STATUS) in value is string ? value : EMPTY_STRING,
        leaseState: let var value = response.getHeader(X_MS_LEASE_STATE) in value is string ? value : EMPTY_STRING,
        hasImmutabilityPolicy: let var value = response.getHeader(X_MS_HAS_IMMUTABILITY_POLICY) in value is string ? 
            value : EMPTY_STRING,
        hasLegalHold: let var value = response.getHeader(X_MS_HAS_LEGAL_HOLD) in value is string ? value : EMPTY_STRING,
        responseHeaders: getHeaderMapFromResponse(response)
    };

    if (response.hasHeader(X_MS_LEASE_DURATION)) {
        containerProperties.leaseDuration = let var value = response.getHeader(X_MS_LEASE_DURATION) in value is string ? 
            value : EMPTY_STRING;
    }
    if (response.hasHeader(X_MS_BLOB_PUBLIC_ACCESS)) {
        containerProperties.publicAccess = let var value = response.getHeader(X_MS_BLOB_PUBLIC_ACCESS) in value is 
            string ? value : EMPTY_STRING;
    }
    return containerProperties;
}

# Creates ContainerMetadataResult from http response.
# 
# + response - Validated http response
# + return - Returns ContainerMetadataResult type
isolated function convertResponseToContainerMetadataResult(http:Response response) returns @tainted 
                                                            ContainerMetadataResult {
    ContainerMetadataResult containerMetadataResult = {
        metadata: getMetaDataHeaders(response),
        eTag: let var value = response.getHeader(ETAG) in value is string ? value : EMPTY_STRING,
        lastModified: let var value = response.getHeader(LAST_MODIFIED) in value is string ? value : EMPTY_STRING,
        responseHeaders: getHeaderMapFromResponse(response)
    };                 
    return containerMetadataResult;
}

# Creates ContainerACLResult from http response.
# 
# + response - Validated http response
# + return - Returns ContainerACLResult type
isolated function convertResponseToContainerACLResult(http:Response response) returns @tainted 
                                                        ContainerACLResult|error {                    
    ContainerACLResult containerACLResult = {
        eTag: let var value = response.getHeader(ETAG) in value is string ? value : EMPTY_STRING,
        lastModified: let var value = response.getHeader(LAST_MODIFIED) in value is string ? value : EMPTY_STRING,
        responseHeaders: getHeaderMapFromResponse(response)
    };                  
    if (response.hasHeader(X_MS_BLOB_PUBLIC_ACCESS)) {
        containerACLResult.publicAccess = let var value = response.getHeader(X_MS_BLOB_PUBLIC_ACCESS) in value is 
            string ? value : EMPTY_STRING;
    }
    if (response.getXmlPayload() is xml) {
        xml xmlResponse = check response.getXmlPayload();
        containerACLResult.signedIdentifiers = check jsonutils:fromXML(xmlResponse/*);
    }
    return containerACLResult;
}

# Creates BlobMetadataResult from http response.
# 
# + response - Validated http response
# + return - Returns BlobMetadataResult type
isolated function convertResponseToBlobMetadataResult(http:Response response) returns @tainted BlobMetadataResult {
    BlobMetadataResult blobMetadataResult = {
        metadata: getMetaDataHeaders(response),
        eTag: let var value = response.getHeader(ETAG) in value is string ? value : EMPTY_STRING,
        lastModified: let var value = response.getHeader(LAST_MODIFIED) in value is string ? value : EMPTY_STRING,
        responseHeaders: getHeaderMapFromResponse(response)
    };
    return blobMetadataResult;
}

# Creates AppendBlockResult from http response.
# 
# + response - Validated http response
# + return - Returns AppendBlockResult type
isolated function convertResponseToAppendBlockResult(http:Response response) returns @tainted AppendBlockResult {
    AppendBlockResult appendBlockResult = {
        eTag: let var value = response.getHeader(ETAG) in value is string ? value : EMPTY_STRING,
        lastModified: let var value = response.getHeader(LAST_MODIFIED) in value is string ? value : EMPTY_STRING,
        blobAppendOffset: let var value = response.getHeader(X_MS_BLOB_APPEND_OFFSET) in value is string ? value : 
            EMPTY_STRING,
        blobCommitedBlockCount: let var value = response.getHeader(X_MS_BLOB_COMMITTED_BLOCK_COUNT) in value is string ? 
            value : EMPTY_STRING,
        responseHeaders: getHeaderMapFromResponse(response)
    };
    return appendBlockResult;
}

# Creates PutPageResult from http response.
# 
# + response - Validated http response
# + return - Returns PutPageResult type
isolated function convertResponseToPutPageResult(http:Response response) returns @tainted PutPageResult {
    PutPageResult putPageResult = {
        eTag: let var value = response.getHeader(ETAG) in value is string ? value : EMPTY_STRING,
        lastModified: let var value = response.getHeader(LAST_MODIFIED) in value is string ? value : EMPTY_STRING,
        blobSequenceNumber: let var value = response.getHeader(X_MS_BLOB_SEQUENCE_NUMBER) in value is string ? value : 
            EMPTY_STRING,
        responseHeaders: getHeaderMapFromResponse(response)
    };
    return putPageResult;
}

# Creates PutPageResult from http response.
# 
# + response - Validated http response
# + return - Returns PutPageResult type
isolated function convertResponseToCopyBlobResult(http:Response response) returns @tainted CopyBlobResult {
    CopyBlobResult copyBlobResult = {
        eTag: let var value = response.getHeader(ETAG) in value is string ? value : EMPTY_STRING,
        lastModified: let var value = response.getHeader(LAST_MODIFIED) in value is string ? value : EMPTY_STRING,
        copyId: let var value = response.getHeader(X_MS_COPY_ID) in value is string ? value : EMPTY_STRING,
        copyStatus: let var value = response.getHeader(X_MS_COPY_STATUS) in value is string ? value : EMPTY_STRING,
        responseHeaders: getHeaderMapFromResponse(response)
    };
    return copyBlobResult;
}

# Creates Container Array from JSON container list.
# 
# + containerListJson - List of containers in json format
# + return - Returns Container array
isolated function convertJSONToContainerArray(json|error containerListJson) returns Container[]|error {
    Container[] containerList = [];
    if (containerListJson is json[]) { // When there are multiple containers, it will be a json[]
        foreach json containerJsonObject in containerListJson {
            Container container = check containerJsonObject.cloneWithType(Container);
            containerList.push(container);
        }
    } else if (containerListJson is json) { // When there is only one container, it will be a json
        Container container = check containerListJson.cloneWithType(Container);
        containerList.push(container);
    }
    return containerList;
}

# Creates Blob Array from JSON Blob list.
# 
# + blobListJson - list of blobs in json format
# + return - Returns Blob array
isolated function convertJSONToBlobArray(json|error blobListJson) returns Blob[]|error {
    Blob[] blobList = [];
    if (blobListJson is json[]) { // When there are multiple blobs, it will be a json[]
        foreach json blobJsonObject in blobListJson {
            Blob blob = check blobJsonObject.cloneWithType(Blob);
            blobList.push(blob);
        }
    } else if (blobListJson is json) { // When there is only one blob, it will be a json
        Blob blob = check blobListJson.cloneWithType(Blob);
        blobList.push(blob);
    }
    return blobList;
}
