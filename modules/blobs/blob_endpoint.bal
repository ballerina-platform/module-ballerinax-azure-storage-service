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
import ballerina/lang.'array;

# Azure Storage Blob Client Object.
#
# + azureStorageBlobClient - The HTTP Client for Azure Storage Blob
# + sharedAccessSignature - Shared Access Signature for the Azure Storage Account
# + accessKey - Azure Stoage Access Key
# + accountName - Azure Storage Account Name
# 
public client class Client {
    http:Client azureStorageBlobClient;
    string sharedAccessSignature;
    string accessKey;
    string accountName;
    string authorizationMethod;

    public function init(AzureStorageConfiguration azureStorageConfig) {
        self.sharedAccessSignature = azureStorageConfig.sharedAccessSignature;
        self.azureStorageBlobClient = new (azureStorageConfig.baseURL);
        self.accessKey = azureStorageConfig.accessKey;
        self.accountName = azureStorageConfig.accountName;
        self.authorizationMethod = azureStorageConfig.authorizationMethod;
    }

    # Get list of containers of a storage account
    # 
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns ListContainerResult. Else returns Error. 
    remote function listContainers(ListContainersOptionalParameters? optionalParams = ()) 
                            returns @tainted ListContainerResult|error {
        OptionalParameterMapsHolder holder = getListContainerOptParams(optionalParams);
        http:Request request = check createRequest(holder.optionalHeaders);
        map<string> uriParameterMap = holder.optionalURIParameters;
        uriParameterMap[COMP] = LIST;

        request = check prepareAuthorizationHeader(request, GET, self.authorizationMethod, self.accountName,
                         self.accessKey, EMPTY_STRING, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->get(path, request);
        xml xmlListContainerResponse = <xml>check handleResponse(response);
        // Since some xml tags contains double quotes, they are removed to avoid error
        xml cleanXMLContainerList = check removeDoubleQuotesFromXML(xmlListContainerResponse/<Containers>);
        
        ListContainerResult listContainerResult = {};
        json jsonContainerList = check jsonutils:fromXML(cleanXMLContainerList);
        if (jsonContainerList.Containers == EMPTY_STRING) {
            return listContainerResult;
        } else {
            listContainerResult.containerList = check convertJSONToContainerArray(<json[]>jsonContainerList.Containers
                                                    .Container);
            listContainerResult.nextMarker =  (xmlListContainerResponse/<NextMarker>/*).toString();
            listContainerResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
            return listContainerResult;
        } 
    }

    # Get list of blobs of a from a container
    # 
    # + containerName - name of the container
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns ListBlobResult Else returns Error. 
    remote function listBlobs(string containerName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted ListBlobResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[COMP] = LIST;
        uriParameterMap[RESTYPE] = CONTAINER;

        request = check prepareAuthorizationHeader(request, GET, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        
        var response = check self.azureStorageBlobClient->get(path, request);
        xml xmlListBlobsResponse = <xml>check handleResponse(response);
        // Since some xml tags contains double quotes, they are removed to avoid error
        xml cleanXMLBlobList = check removeDoubleQuotesFromXML(xmlListBlobsResponse/<Blobs>);

        ListBlobResult listBlobResult = {};
        json jsonBlobList = check jsonutils:fromXML(cleanXMLBlobList);
        if (jsonBlobList.Blobs == EMPTY_STRING) {
            return listBlobResult;
        } else {
            listBlobResult.blobList = check convertJSONToBlobArray(<json[]>jsonBlobList.Blobs.Blob);
            listBlobResult.nextMarker = (xmlListBlobsResponse/<NextMarker>/*).toString();
            listBlobResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
            return listBlobResult;
        }  
    }

    # Get a blob from a from a container
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns blob as a byte array. Else returns Error. 
    remote function getBlob(string containerName, string blobName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted BlobResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);

        request = check prepareAuthorizationHeader(request, GET, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);                 
        var response = check self.azureStorageBlobClient->get(path, request);
        BlobResult blobResult = {};
        blobResult.blobContent = <byte[]>check handleGetBlobResponse(response);
        blobResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return blobResult;
    }

    # Get Account Information of the azure storage account
    # 
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns AccountInformation. Else returns Error. 
    remote function getAccountInformation(map<string>? optionalHeaders=(), map<string>? optionalURIParameters=()) 
                            returns @tainted AccountInformationResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[RESTYPE] = ACCOUNT;
        uriParameterMap[COMP] = PROPERTIES;

        request = check prepareAuthorizationHeader(request, GET, self.authorizationMethod, self.accountName,
                         self.accessKey, EMPTY_STRING, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);  
        var response = <http:Response>check self.azureStorageBlobClient->get(path, request);
        return convertResponseToAccountInformationType(check handleHeaderOnlyResponse(response));
    }

    # Get Blob Service Properties
    # 
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Blob Service Properties. Else returns Error. 
    remote function getBlobServiceProperties(map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted BlobServicePropertiesResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[RESTYPE] = SERVICE;
        uriParameterMap[COMP] = PROPERTIES;

        request = check prepareAuthorizationHeader(request, GET, self.authorizationMethod, self.accountName,
                         self.accessKey, EMPTY_STRING, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath); 
        var response = check self.azureStorageBlobClient->get(path, request);
        xml blobServiceProperties = <xml> check handleResponse(response);
        BlobServicePropertiesResult blobServicePropertiesResult = {};
        blobServicePropertiesResult.storageServiceProperties = check convertJSONtoStorageServiceProperties(
                                                                    check jsonutils:fromXML(blobServiceProperties/*));
        blobServicePropertiesResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return blobServicePropertiesResult;
    }

    //Maybe this operation is not needed
    # Get Blob Service Stats. (This is only for secondary location endpoint)
    # 
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Blob Service Stats. Else returns Error. 
    remote function getBlobServiceStats(map<string>? optionalHeaders=(), map<string>? optionalURIParameters=()) 
                            returns @tainted StorageServiceStats|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[RESTYPE] = SERVICE;
        uriParameterMap[COMP] = STATS;

        request = check prepareAuthorizationHeader(request, GET, self.authorizationMethod, self.accountName,
                         self.accessKey, EMPTY_STRING, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->get(path, request);
        xml blobServiceStats = <xml> check handleResponse(response);
        return check convertJSONtoStorageServiceStats(check jsonutils:fromXML(blobServiceStats/*));
    }

    # Get Container Properties
    # 
    # + containerName - name of the container
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Container Properties. Else returns Error. 
    remote function getContainerProperties(string containerName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted ContainerPropertiesResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[RESTYPE] = CONTAINER;

        request = check prepareAuthorizationHeader(request, HEAD, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->head(path, request);
        return convertResponseToContainerPropertiesResult(check handleHeaderOnlyResponse(response));
    }

    # Get Container Metadata
    # 
    # + containerName - name of the container
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Container Metadata. Else returns Error. 
    remote function getContainerMetadata(string containerName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted ContainerMetadataResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[RESTYPE] = CONTAINER;
        uriParameterMap[COMP] = METADATA;
             
        request = check prepareAuthorizationHeader(request, GET, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->get(path, request);
        return convertResponseToContainerMetadataResult(check handleHeaderOnlyResponse(response));
    }

    # Get Blob Metadata
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Blob Metadata. Else returns Error. 
    remote function getBlobMetadata(string containerName, string blobName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted BlobMetadataResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[COMP] = METADATA;

        request = check prepareAuthorizationHeader(request, HEAD, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->head(path, request);
        return convertResponseToBlobMetadataResult(check handleHeaderOnlyResponse(response));
    }

    # Get Container ACL (gets the permissions for the specified container)
    # 
    # + containerName - name of the container
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns container ACL. Else returns Error. 
    remote function getContainerACL(string containerName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted ContainerACLResult|error {
        if (self.authorizationMethod == SHARED_KEY ) {
            http:Request request = check createRequest(optionalHeaders);
            map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
            uriParameterMap[RESTYPE] = CONTAINER;
            uriParameterMap[COMP] = ACL;

            request = check prepareAuthorizationHeader(request, HEAD, self.authorizationMethod, self.accountName,
                        self.accessKey, containerName, uriParameterMap);
            string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
            string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap,
                             resourcePath);
            var response = check self.azureStorageBlobClient->head(path, request);
            return convertResponseToContainerACLResult(check handleHeaderOnlyResponse(response));
        } else {
            return error(AZURE_BLOB_ERROR_CODE, message = ("This operation is supported only with SharedKey " 
                        + "Authentication"));
        } 
    }
    
    # Get Blob Properties
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Blob Properties. Else returns Error. 
    remote function getBlobProperties(string containerName, string blobName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted map<json>|error {
        string getBlobPropsPath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName 
                                    + self.sharedAccessSignature;
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);

        request = check prepareAuthorizationHeader(request, HEAD, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->head(path, request);
        return getHeaderMapFromResponse(check handleHeaderOnlyResponse(response));
    }

    // Maybe this operation can be removed
    # Get Blob Tags
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Blob Tags. Else returns Error. 
    remote function getBlobTags(string containerName, string blobName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted xml|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[COMP] = TAGS;

        request = check prepareAuthorizationHeader(request, GET, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->get(path, request);
        return <xml> check handleResponse(response);
    }

    # Get Block List
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Block List. Else returns Error. 
    remote function getBlockList(string containerName, string blobName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted BlockListResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[BLOCKLISTTYPE] = ALL;
        uriParameterMap[COMP] = BLOCKLIST;

        request = check prepareAuthorizationHeader(request, GET, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->get(path, request);
        xml blockListXML = <xml> check handleResponse(response);
        json blockListJson = check jsonutils:fromXML(blockListXML);
        BlockListResult blockListResult = {};
        blockListResult.blockList = blockListJson;
        blockListResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return blockListResult;
    }

    # Put Blob (Upload a blob to a container)
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + blob - blob as a byte[]
    # + blobType - type of the Blob (BlockBlob or AppendBlob or PageBlob)
    # + pageBlobLength - maxSize of pageBlob. (Required only for PageBlob)
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns true. Else returns Error. 
    remote function putBlob(string containerName, string blobName, byte[] blob, string blobType,
                            int? pageBlobLength = (), map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted boolean|error {                      
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        
        if (blobType == BLOCK_BLOB) {
            request.setHeader(CONTENT_LENGTH, blob.length().toString());
            request.setBinaryPayload(<@untainted>blob);
        } else if (blobType == PAGE_BLOB) {
            if (pageBlobLength is int) {
                request.setHeader(X_MS_BLOB_CONTENT_LENGTH, pageBlobLength.toString());
                request.setHeader(CONTENT_LENGTH, ZERO);      
            } else {
                return error(AZURE_BLOB_ERROR_CODE, message = ("pageBlobLength cannot be empty for PageBlob"));
            }    
        } else if (blobType == APPEND_BLOB) {
            request.setHeader(CONTENT_LENGTH, ZERO);
        } else {
            return error(AZURE_BLOB_ERROR_CODE, message = (blobType + "is not a valid Blob Type. It should be "
                            + APPEND_BLOB + VERTICAL_BAR + BLOCK_BLOB + VERTICAL_BAR + PAGE_BLOB));
        }
        
        request.setHeader(X_MS_BLOB_TYPE, blobType);
        
        request = check prepareAuthorizationHeader(request, PUT, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->put(path, request);
        return <boolean> check handleResponse(response);
    }

    # Put Blob From URL - creates a new Block Blob where the content of the blob is read from a given URL
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + sourceBlobURL - url of source blob
    # + optionalHeaders - Optional. String map of optional headers and values
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns true. Else returns Error. 
    remote function putBlobFromURL(string containerName, string blobName, string sourceBlobURL, map<string>? 
                            optionalHeaders=(), map<string>? optionalURIParameters=()) returns @tainted boolean|error {                       
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        request.setHeader(CONTENT_LENGTH, ZERO);
        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);

        request = check prepareAuthorizationHeader(request, PUT, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->put(path, request);
        return <boolean> check handleResponse(response);
    }

    # Create a container in the azure storage account
    # 
    # + containerName - name of the container
    # + optionalHeaders - optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns true. Else returns Error. 
    remote function createContainer (string containerName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted boolean|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[RESTYPE] = CONTAINER;

        request = check prepareAuthorizationHeader(request, PUT, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->put(path, request);
        return <boolean> check handleResponse(response);
    }

    # Delete a container from the azure storage account
    # 
    # + containerName - name of the container
    # + optionalHeaders - optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns true. Else returns Error. 
    remote function deleteContainer (string containerName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted boolean|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[RESTYPE] = CONTAINER;

        request = check prepareAuthorizationHeader(request, DELETE, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->delete(path, request);
        return <boolean>check handleResponse(response);
    }

    # Delete a blob from a container
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + optionalHeaders - optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns true. Else returns Error. 
    remote function deleteBlob (string containerName, string blobName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted boolean|error {
        string getBlobPropsPath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName 
                                    + self.sharedAccessSignature;
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);

        request = check prepareAuthorizationHeader(request, DELETE, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);    
        var response = check self.azureStorageBlobClient->delete(path, request);
        return <boolean> check handleResponse(response);
    }

    // Remove this
    # Undelete a blob (restores the contents and metadata of a soft deleted blob)
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + optionalHeaders - optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns true. Else returns Error. 
    remote function undeleteBlob (string containerName, string blobName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted boolean|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[COMP] = UNDELETE;

        request = check prepareAuthorizationHeader(request, PUT, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->put(path, request);
        return <boolean> check handleResponse(response);
    }

    # Copy a blob
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + sourceBlobURL - url of source blob
    # + optionalHeaders - optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Response Headers. Else returns Error. 
    remote function copyBlob (string containerName, string blobName, string sourceBlobURL, map<string>? 
                    optionalHeaders=(), map<string>? optionalURIParameters=()) returns @tainted CopyBlobResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);

        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);
        request = check prepareAuthorizationHeader(request, PUT, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;

        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->put(path, request);
        return convertResponseToCopyBlobResult(check handleHeaderOnlyResponse(response));
    }

    # Copy a blob from a URL
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + sourceBlobURL - url of source blob
    # + isSynchronized - true if is a synchronous copy or false if it is an asynchronous copy
    # + optionalHeaders - Optional. optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Response Headers. Else returns Error. 
    remote function copyBlobFromURL (string containerName, string blobName, string sourceBlobURL, 
                            boolean isSynchronized, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted CopyBlobResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);

        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);
        request.setHeader(X_MS_REQUIRES_SYNC, isSynchronized.toString());
        request = check prepareAuthorizationHeader(request, PUT, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;

        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->put(path, request);
        return convertResponseToCopyBlobResult(check handleHeaderOnlyResponse(response));
    }

    // Maybe we can remove this
    # Aborts a pending Copy Blob operation, and leaves a destination blob with zero length and full metadata
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + copyId - copyId 
    # + optionalHeaders - optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Response Headers. Else returns Error. 
    remote function abortCopyBlob (string containerName, string blobName, string copyId, map<string>? 
                        optionalHeaders=(), map<string>? optionalURIParameters=()) returns @tainted map<json>|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[COMP] = COPY;
        uriParameterMap[COPYID] = copyId;

        request.setHeader(X_MS_COPY_ACTION, ABORT);
        request = check prepareAuthorizationHeader(request, PUT, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;

        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->put(path, request);
        return getHeaderMapFromResponse(check handleHeaderOnlyResponse(response));
    }

    # Get list of valid page ranges for a page blob
    # 
    # + containerName - name of the container
    # + blobName - name of the page blob
    # + optionalHeaders - optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns page ranges. Else returns Error. 
    remote function getPageRanges(string containerName, string blobName, map<string>? optionalHeaders=(), 
                            map<string>? optionalURIParameters=()) returns @tainted PageRangeResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[COMP] = PAGELIST;

        request = check prepareAuthorizationHeader(request, GET, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;

        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->get(path, request);
        xml pageRangesXML = <xml> check handleResponse(response);
        json pageRangesJson = check jsonutils:fromXML(pageRangesXML);
        PageRangeResult pageRangeResult = {};
        pageRangeResult.pageList = pageRangesJson;
        pageRangeResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return pageRangeResult;
    }

    # Commits a new block of data to the end of an existing append blob.
    # 
    # + containerName - name of the container
    # + blobName - name of the append blob
    # + block - content of the block
    # + optionalHeaders - optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Response Headers. Else returns Error. 
    remote function appendBlock(string containerName, string blobName, byte[] block, map<string>? 
                optionalHeaders=(), map<string>? optionalURIParameters=()) returns @tainted AppendBlockResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[COMP] = APPENDBLOCK;

        request.setBinaryPayload(<@untainted>block);
        request.setHeader(CONTENT_LENGTH, block.length().toString());
        request = check prepareAuthorizationHeader(request, PUT, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;

        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->put(path, request);
        return convertResponseToAppendBlockResult(check handleHeaderOnlyResponse(response));
    }

    # Commits a new block of data (from a URL) to the end of an existing append blob.
    # 
    # + containerName - name of the container
    # + blobName - name of the append blob
    # + sourceBlobURL - URL of the source blob
    # + optionalHeaders - optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Response Headers. Else returns Error. 
    remote function appendBlockFromURL(string containerName, string blobName, string sourceBlobURL, map<string>? 
                optionalHeaders=(), map<string>? optionalURIParameters=()) returns @tainted AppendBlockResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[COMP] = APPENDBLOCK;

        request.setHeader(CONTENT_LENGTH, ZERO);
        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);
        request = check prepareAuthorizationHeader(request, PUT, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->put(path, request);
        return convertResponseToAppendBlockResult(check handleHeaderOnlyResponse(response));
    }

    # Commits a new block to be commited as part of a blob.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + blockId - a string value that identifies the block (should be less than 64 bytes in size)
    # + content - blob content
    # + optionalHeaders - optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Response Headers. Else returns Error.
    remote function putBlock(string containerName, string blobName, string blockId, byte[] content, map<string>? 
                        optionalHeaders=(), map<string>? optionalURIParameters=()) returns @tainted map<json>|error {
        string encodedBlockId = 'array:toBase64(blockId.toBytes());
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[COMP] = BLOCK;
        uriParameterMap[BLOCKID] = encodedBlockId;

        request.setBinaryPayload(content);
        request.setHeader(CONTENT_LENGTH, content.length().toString());
        request = check prepareAuthorizationHeader(request, PUT, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->put(path, request);
        return getHeaderMapFromResponse(check handleHeaderOnlyResponse(response));
    }

    # Commits a new block to be commited as part of a blob where the content is read from a URL.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + blockId - a string value that identifies the block (should be less than 64 bytes in size)
    # + sourceBlobURL - URL of the source blob
    # + optionalHeaders - optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Response Headers. Else returns Error.
    remote function putBlockFromURL(string containerName, string blobName, string blockId, string sourceBlobURL, 
                            map<string>? optionalHeaders=(), map<string>? optionalURIParameters=()) 
                            returns @tainted map<json>|error {
        string encodedBlockId = 'array:toBase64(blockId.toBytes());

        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[COMP] = BLOCK;
        uriParameterMap[BLOCKID] = encodedBlockId;

        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);
        request.setHeader(CONTENT_LENGTH, ZERO);
        request = check prepareAuthorizationHeader(request, PUT, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->put(path, request);
        return getHeaderMapFromResponse(check handleHeaderOnlyResponse(response));
    }

    # Commits a new block to be commited as part of a blob.
    # 
    # + containerName - name of the container
    # + pageBlobName - name of the page blob
    # + operation - It can be update or clear
    # + range - Specifies the range of bytes to be written as a page. 
    # + content - blob content
    # + optionalHeaders - optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Response Headers. Else returns Error.
    remote function putPage(string containerName, string pageBlobName, string operation, string range,
                            byte[]? content=(), map<string>? optionalHeaders=(), map<string>? optionalURIParameters=()) 
                            returns @tainted PutPageResult|error {
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[COMP] = PAGE;

        if (operation == UPDATE) {
            if (content is byte[]) {
                request.setBinaryPayload(content);
                request.setHeader(CONTENT_LENGTH, content.length().toString());
            } else {
                return error(AZURE_BLOB_ERROR_CODE, message = ("The required parameter for UPDATE operation "
                                +"'content' is not provided"));
            }
        } else if (operation == CLEAR) {
            request.setHeader(CONTENT_LENGTH, ZERO);
        } else {
            return error(AZURE_BLOB_ERROR_CODE, message = (operation + "is not a valid operationType. It should be " 
                            + "either 'update' or 'clear'."));
        }

        request.setHeader(X_MS_PAGE_WRITE, operation);
        request.setHeader(X_MS_RANGE, range);
        request = check prepareAuthorizationHeader(request, PUT, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + pageBlobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + pageBlobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->put(path, request);
        return convertResponseToPutPageResult(check handleHeaderOnlyResponse(response));
    }

    # Commits a new block to be commited as part of a blob.
    # 
    # + containerName - name of the container
    # + pageBlobName - name of the page blob
    # + sourceBlobURL - URL of the source blob
    # + range - Specifies the range of bytes to be written as a page. 
    # + sourceRange - Specifies the range of bytes to be read from the source blob
    # + optionalHeaders - optional Headers
    # + optionalURIParameters - Optional. String map of optional uri parameters and values
    # + return - If successful, returns Response Headers. Else returns Error.
    remote function putPageFromURL(string containerName, string pageBlobName, string sourceBlobURL, string range,
                            string sourceRange, map<string>? optionalHeaders=(), map<string>? optionalURIParameters=()) 
                            returns @tainted PutPageResult|error {
        string putPagePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + pageBlobName 
                        + self.sharedAccessSignature + PUT_PAGE_RESOURCE;
        http:Request request = check createRequest(optionalHeaders);
        map<string> uriParameterMap = addOptionalURIParameters(optionalURIParameters);
        uriParameterMap[COMP] = PAGE;

        request.setHeader(CONTENT_LENGTH, ZERO);
        //request.setHeader(X_MS_PAGE_WRITE, UPDATE);
        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);
        request.setHeader(X_MS_RANGE, range);
        request.setHeader(X_MS_SOURCE_RANGE, sourceRange);
        request = check prepareAuthorizationHeader(request, PUT, self.authorizationMethod, self.accountName,
                         self.accessKey, containerName + FORWARD_SLASH_SYMBOL + pageBlobName, uriParameterMap);
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + pageBlobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        var response = check self.azureStorageBlobClient->put(putPagePath, request);
        return convertResponseToPutPageResult(check handleHeaderOnlyResponse(response));
    }
}
