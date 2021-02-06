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
import ballerina/log;
import ballerina/jsonutils;
import ballerina/lang.'array;
import ballerina/lang.'xml;
import ballerina/file;
import ballerina/io;

# Azure Storage Blob Client Object.
#
# + httpClient - The HTTP Client for Azure Storage Blob
# + sharedAccessSignature - Shared Access Signature for the Azure Storage Account
# + accessKey - Azure Stoage Access Key
# + accountName - Azure Storage Account Name
# 
public client class BlobClient {
    http:Client httpClient;
    string sharedAccessSignature;
    string accessKey;
    string accountName;
    string authorizationMethod;

    public function init(AzureStorageConfiguration azureStorageConfig) {
        self.sharedAccessSignature = azureStorageConfig.sharedAccessSignature;
        self.httpClient = new (azureStorageConfig.baseURL, {http1Settings: {chunking: http:CHUNKING_NEVER}});
        self.accessKey = azureStorageConfig.accessKey;
        self.accountName = azureStorageConfig.accountName;
        self.authorizationMethod = azureStorageConfig.authorizationMethod;
    }

    # Get list of containers of a storage account
    # 
    # + options - Optional. Optional parameters
    # + return - If successful, returns ListContainerResult. Else returns Error. 
    remote function listContainers(ListContainersOptions? options = ()) returns @tainted ListContainerResult|error {
        OptionsHolder optionsHolder = prepareListContainersOptions(options);
        http:Request request =  createRequest(optionsHolder.optionalHeaders);
        map<string> uriParameterMap = optionsHolder.optionalURIParameters;
        uriParameterMap[COMP] = LIST;
        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, EMPTY_STRING, uriParameterMap);
        }
        
        string resourcePath = FORWARD_SLASH_SYMBOL;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        xml xmlListContainerResponse = <xml>check handleResponse(response);
        // Since some xml tags contains double quotes, they are removed to avoid error
        xml cleanXMLContainerList = check removeDoubleQuotesFromXML(xmlListContainerResponse/<Containers>);
        
        ListContainerResult listContainerResult = {};
        json jsonContainerList = check jsonutils:fromXML(cleanXMLContainerList);
        listContainerResult.containerList = check convertJSONToContainerArray(jsonContainerList.Containers.Container);
        listContainerResult.nextMarker =  (xmlListContainerResponse/<NextMarker>/*).toString();
        listContainerResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return listContainerResult;
    }

    # Get list of containers as a stream
    # 
    # + options - Optional. Optional parameters
    # + return - If successful, returns ListContainerResult. Else returns Error. 
    remote function listContainersStream(ListContainersOptions? options = ()) returns @tainted stream<Container>|error {
        OptionsHolder optionsHolder = prepareListContainersOptions(options);
        http:Request request = createRequest(optionsHolder.optionalHeaders);
        map<string> uriParameterMap = optionsHolder.optionalURIParameters;
        uriParameterMap[COMP] = LIST;
        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, EMPTY_STRING, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        xml xmlListContainerResponse = <xml>check handleResponse(response);
        // Since some xml tags contains double quotes, they are removed to avoid error
        xml cleanXMLContainerList = check removeDoubleQuotesFromXML(xmlListContainerResponse/<Containers>);

        json jsonContainerList = check jsonutils:fromXML(cleanXMLContainerList);
        Container[] containerList =  check convertJSONToContainerArray(jsonContainerList.Containers.Container);
        return containerList.toStream();
    }

    # Get list of blobs of a from a container
    # 
    # + containerName - name of the container
    # + options - Optional. Optional parameters
    # + return - If successful, returns ListBlobResult Else returns Error. 
    remote function listBlobs(string containerName, ListBlobsOptions? options = ()) 
                                returns @tainted ListBlobResult|error {
        OptionsHolder optionsHolder = prepareListBlobsOptions(options);
        http:Request request = createRequest(optionsHolder.optionalHeaders);
        map<string> uriParameterMap = optionsHolder.optionalURIParameters;
        uriParameterMap[COMP] = LIST;
        uriParameterMap[RESTYPE] = CONTAINER;
        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, containerName, 
                    uriParameterMap);
        }
        
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        xml xmlListBlobsResponse = <xml>check handleResponse(response);
        // Since some xml tags contains double quotes, they are removed to avoid error
        xml cleanXMLBlobList = check removeDoubleQuotesFromXML(xmlListBlobsResponse/<Blobs>);

        ListBlobResult listBlobResult = {};
        json jsonBlobList = check jsonutils:fromXML(cleanXMLBlobList);
        listBlobResult.blobList = check convertJSONToBlobArray(jsonBlobList.Blobs.Blob);
        listBlobResult.nextMarker = (xmlListBlobsResponse/<NextMarker>/*).toString();
        listBlobResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return listBlobResult;
    }

    # Get a blob from a from a container
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + options - Optional. Optional parameters
    # + return - If successful, returns blob as a byte array. Else returns Error. 
    remote function getBlob(string containerName, string blobName, GetBlobOptions? options = ()) 
                            returns @tainted BlobResult|error {
        OptionsHolder optionsHolder = prepareGetBlobOptions(options);
        http:Request request = createRequest(optionsHolder.optionalHeaders);
        map<string> uriParameterMap = optionsHolder.optionalURIParameters;
        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);                 
        http:Response response = <http:Response> check self.httpClient->get(path, request);

        BlobResult blobResult = {};
        blobResult.blobContent = <byte[]>check handleGetBlobResponse(response);
        blobResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return blobResult;
    }

    # Get Account Information of the azure storage account
    # 
    # + clientRequestId - Optional. Client request Id
    # + return - If successful, returns AccountInformation. Else returns Error. 
    remote function getAccountInformation(string? clientRequestId = ()) 
                                            returns @tainted AccountInformationResult|error {
        map<string> optionalHeaderMap = {};  
        if (clientRequestId is string) {
            optionalHeaderMap[X_MS_CLIENT_REQUEST_ID] = clientRequestId;
        }
                              
        http:Request request = createRequest(optionalHeaderMap);
        map<string> uriParameterMap = {};
        uriParameterMap[RESTYPE] = ACCOUNT;
        uriParameterMap[COMP] = PROPERTIES;
        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, EMPTY_STRING, 
                    uriParameterMap);
        }
        
        string resourcePath = FORWARD_SLASH_SYMBOL;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);  
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToAccountInformationType(response);
    }

    # Get Blob Service Properties
    # 
    # + timeout - Optional. Timout value expressed in seconds
    # + clientRequestId - Optional. Client request Id
    # + return - If successful, returns Blob Service Properties. Else returns Error. 
    remote function getBlobServiceProperties(string? clientRequestId = (), string? timeout = ())
                                                returns @tainted BlobServicePropertiesResult|error {
        map<string> optionalHeaderMap = {}; 
        if (clientRequestId is string) {
            optionalHeaderMap[X_MS_CLIENT_REQUEST_ID] = clientRequestId;
        } 
        http:Request request = createRequest(optionalHeaderMap);

        map<string> uriParameterMap = {};
        if (timeout is string) {
            uriParameterMap[TIMEOUT] = timeout;
        } 
        uriParameterMap[RESTYPE] = SERVICE;
        uriParameterMap[COMP] = PROPERTIES;
        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, EMPTY_STRING, 
                    uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath); 
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        xml blobServiceProperties = <xml> check handleResponse(response);
        BlobServicePropertiesResult blobServicePropertiesResult = {};
        blobServicePropertiesResult.storageServiceProperties = check convertJSONtoStorageServiceProperties(
                                                                    check jsonutils:fromXML(blobServiceProperties/*));
        blobServicePropertiesResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return blobServicePropertiesResult;
    }

    # Get Container Properties
    # 
    # + containerName - name of the container
    # + timeout - Optional. Timout value expressed in seconds
    # + clientRequestId - Optional. Client generated value for correlating client side activities with requests received
    #                     by the server.
    # + leaseId - Optional. 
    # + return - If successful, returns Container Properties. Else returns Error. 
    remote function getContainerProperties(string containerName, string? clientRequestId = (), string? timeout = (),
                                            string? leaseId = ()) returns @tainted ContainerPropertiesResult|error {
        map<string> optionalHeaderMap = {}; 
        if (clientRequestId is string) {
            optionalHeaderMap[X_MS_CLIENT_REQUEST_ID] = clientRequestId;
        } 
        if (leaseId is string) {
            optionalHeaderMap[X_MS_LEASE_ID] = leaseId;
        } 
        http:Request request = createRequest(optionalHeaderMap);

        map<string> uriParameterMap = {};
        if (timeout is string) {
            uriParameterMap[TIMEOUT] = timeout;
        } 
        uriParameterMap[RESTYPE] = CONTAINER;
        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, HEAD, self.accountName, self.accessKey, containerName, 
                    uriParameterMap);
        }
        
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->head(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToContainerPropertiesResult(response);
    }

    # Get Container Metadata
    # 
    # + containerName - name of the container
    # + timeout - Optional. Timout value expressed in seconds
    # + clientRequestId - Optional. Client generated value for correlating client side activities with requests received
    #                     by the server.
    # + leaseId - Optional. 
    # + return - If successful, returns Container Metadata. Else returns Error. 
    remote function getContainerMetadata(string containerName, string? clientRequestId = (), string? timeout = (),
                                            string? leaseId = ()) returns @tainted ContainerMetadataResult|error {
        map<string> optionalHeaderMap = {}; 
        if (clientRequestId is string) {
            optionalHeaderMap[X_MS_CLIENT_REQUEST_ID] = clientRequestId;
        } 
        if (leaseId is string) {
            optionalHeaderMap[X_MS_LEASE_ID] = leaseId;
        } 
        http:Request request = createRequest(optionalHeaderMap);

        map<string> uriParameterMap = {};
        if (timeout is string) {
            uriParameterMap[TIMEOUT] = timeout;
        } 
        uriParameterMap[RESTYPE] = CONTAINER;
        uriParameterMap[COMP] = METADATA;

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, containerName, 
                    uriParameterMap);
        }   
        
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToContainerMetadataResult(response);
    }

    # Get Blob Metadata
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + options - Optional. Optional parameters
    # + return - If successful, returns Blob Metadata. Else returns Error. 
    remote function getBlobMetadata(string containerName, string blobName, GetBlobMetadataOptions? options = ()) 
                                    returns @tainted BlobMetadataResult|error {
        OptionsHolder optionsHolder = prepareGetBlobMetadataOptions(options);
        http:Request request = createRequest(optionsHolder.optionalHeaders);
        map<string> uriParameterMap = optionsHolder.optionalURIParameters;
        uriParameterMap[COMP] = METADATA;

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, HEAD, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }
        
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->head(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToBlobMetadataResult(response);
    }

    # Get Container ACL (gets the permissions for the specified container)
    # 
    # + containerName - name of the container
    # + timeout - Optional. Timout value expressed in seconds
    # + clientRequestId - Optional. Client generated value for correlating client side activities with requests received
    #                     by the server.
    # + leaseId - Optional. 
    # + return - If successful, returns container ACL. Else returns Error. 
    remote function getContainerACL(string containerName, string? clientRequestId = (), string? timeout = (),
                                    string? leaseId = ()) returns @tainted ContainerACLResult|error {
        if (self.authorizationMethod == SHARED_KEY ) {
            map<string> optionalHeaderMap = {}; 
            if (clientRequestId is string) {
                optionalHeaderMap[X_MS_CLIENT_REQUEST_ID] = clientRequestId;
            } 
            if (leaseId is string) {
                optionalHeaderMap[X_MS_LEASE_ID] = leaseId;
            } 
            http:Request request = createRequest(optionalHeaderMap);

            map<string> uriParameterMap = {};
            if (timeout is string) {
                uriParameterMap[TIMEOUT] = timeout;
            } 
            uriParameterMap[RESTYPE] = CONTAINER;
            uriParameterMap[COMP] = ACL;

            if (self.authorizationMethod == SHARED_KEY) {
                check addAuthorizationHeader(request, HEAD, self.accountName, self.accessKey, containerName, 
                        uriParameterMap);
            }

            string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
            string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap,
                                        resourcePath);
            http:Response response = <http:Response> check self.httpClient->head(path, request);
            check handleHeaderOnlyResponse(response);
            return convertResponseToContainerACLResult(response);
        } else {
            return error(AZURE_BLOB_ERROR_CODE, message = ("This operation is supported only with SharedKey " + 
                                                            "Authentication"));
        } 
    }
    
    # Get Blob Properties
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + options - Optional. Optional parameters
    # + return - If successful, returns Blob Properties. Else returns Error. 
    remote function getBlobProperties(string containerName, string blobName, GetBlobPropertiesOptions? options = ()) 
                                        returns @tainted Result|error {
        OptionsHolder optionsHolder = prepareGetBlobPropertiesOptions(options);                            
        http:Request request = createRequest(optionsHolder.optionalHeaders);
        map<string> uriParameterMap = optionsHolder.optionalURIParameters;

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, HEAD, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->head(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Get Block List
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + options - Optional. Optional parameters
    # + return - If successful, returns Block List. Else returns Error. 
    remote function getBlockList(string containerName, string blobName, GetBlockListOptions? options = ()) 
                                    returns @tainted BlockListResult|error {
        OptionsHolder optionsHolder = prepareGetBlockListOptions(options);                                 
        http:Request request = createRequest(optionsHolder.optionalHeaders);
        map<string> uriParameterMap = optionsHolder.optionalURIParameters;
        uriParameterMap[BLOCKLISTTYPE] = ALL;
        uriParameterMap[COMP] = BLOCKLIST;

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        
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
    # + options - Optional. Optional parameters
    # + return - If successful, returns true. Else returns Error. 
    remote function putBlob(string containerName, string blobName, byte[] blob, string blobType,
                            PutBlobOptions? options = ()) returns @tainted Result|error {   
        if (blob.length() > MAX_BLOB_UPLOAD_SIZE) {
            return error(AZURE_BLOB_ERROR_CODE, message = ("Blob content exceeds max supported size of 50MB"));
        } 

        OptionsHolder optionsHolder = preparePutBlobOptions(options);                                 
        http:Request request = createRequest(optionsHolder.optionalHeaders);
        map<string> uriParameterMap = optionsHolder.optionalURIParameters;
        
        if (blobType == BLOCK_BLOB) {
            request.setHeader(CONTENT_LENGTH, blob.length().toString());
            request.setBinaryPayload(<@untainted>blob);
        } else if (blobType == PAGE_BLOB) {
            if (request.hasHeader(X_MS_BLOB_CONTENT_LENGTH)) {
                request.setHeader(CONTENT_LENGTH, ZERO);      
            } else {
                return error(AZURE_BLOB_ERROR_CODE, message = ("pageBlobLength has to be specified in options"));
            }    
        } else if (blobType == APPEND_BLOB) {
            request.setHeader(CONTENT_LENGTH, ZERO);
        } else {
            return error(AZURE_BLOB_ERROR_CODE, message = (blobType + "is not a valid Blob Type. It should be " + 
                            APPEND_BLOB + VERTICAL_BAR + BLOCK_BLOB + VERTICAL_BAR + PAGE_BLOB));
        }
        
        request.setHeader(X_MS_BLOB_TYPE, blobType);
        
        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Put Blob From URL - creates a new Block Blob where the content of the blob is read from a given URL
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + sourceBlobURL - url of source blob
    # + options - Optional. Optional parameters
    # + return - If successful, returns true. Else returns Error. 
    remote function putBlobFromURL(string containerName, string blobName, string sourceBlobURL, PutBlobFromURLOptions? 
                                    options = ()) returns @tainted Result|error {                       
        OptionsHolder optionsHolder = preparePutBlobFromURLOptions(options);                                 
        http:Request request = createRequest(optionsHolder.optionalHeaders);
        map<string> uriParameterMap = optionsHolder.optionalURIParameters;

        request.setHeader(CONTENT_LENGTH, ZERO);
        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Create a container in the azure storage account
    # 
    # + containerName - name of the container
    # + timeout - Optional. Timout value expressed in seconds
    # + clientRequestId - Optional. Client generated value for correlating client side activities with requests received
    #                     by the server.
    # + blobPublicAccess - Optional. 
    #                    - container: Specifies full public read access for container and blob data. 
    #                    - blob: Specifies public read access for blobs.
    # + return - If successful, returns true. Else returns Error. 
    remote function createContainer (string containerName, string? blobPublicAccess = (), string? timeout = (),
                                        string? clientRequestId = ()) returns @tainted Result|error {
        map<string> optionalHeaderMap = {}; 
        if (blobPublicAccess is string) {
            optionalHeaderMap[X_MS_BLOB_PUBLIC_ACCESS] = blobPublicAccess;
        } 
        if (clientRequestId is string) {
            optionalHeaderMap[X_MS_CLIENT_REQUEST_ID] = clientRequestId;
        } 
        http:Request request = createRequest(optionalHeaderMap);
        
        map<string> uriParameterMap = {};
        if (timeout is string) {
            uriParameterMap[TIMEOUT] = timeout;
        }
        uriParameterMap[RESTYPE] = CONTAINER;

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName, 
                    uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Delete a container from the azure storage account
    # 
    # + containerName - name of the container
    # + timeout - Optional. Timout value expressed in seconds
    # + clientRequestId - Optional. Client generated value for correlating client side activities with requests received
    #  by the server.
    # + leaseId - Optional. 
    # + return - If successful, returns true. Else returns Error. 
    remote function deleteContainer (string containerName, string? clientRequestId = (), string? timeout = (),
                                        string? leaseId = ()) returns @tainted Result|error {
        map<string> optionalHeaderMap = {}; 
        if (clientRequestId is string) {
            optionalHeaderMap[X_MS_CLIENT_REQUEST_ID] = clientRequestId;
        } 
        if (leaseId is string) {
            optionalHeaderMap[X_MS_LEASE_ID] = leaseId;
        } 
        http:Request request = createRequest(optionalHeaderMap);
        
        map<string> uriParameterMap = {};
        if (timeout is string) {
            uriParameterMap[TIMEOUT] = timeout;
        } 
        uriParameterMap[RESTYPE] = CONTAINER;

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, DELETE, self.accountName, self.accessKey, containerName, 
                    uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->delete(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Delete a blob from a container
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + options - Optional. Optional parameters
    # + return - If successful, returns true. Else returns Error. 
    remote function deleteBlob (string containerName, string blobName, DeleteBlobOptions? options = ()) 
                                returns @tainted Result|error {
        OptionsHolder optionsHolder = prepareDeleteBlobOptions(options);                             
        http:Request request = createRequest(optionsHolder.optionalHeaders);
        map<string> uriParameterMap = optionsHolder.optionalURIParameters;

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, DELETE, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);    
        http:Response response = <http:Response> check self.httpClient->delete(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Copy a blob
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + sourceBlobURL - url of source blob
    # + options - Optional. Optional parameters
    # + return - If successful, returns Response Headers. Else returns Error. 
    remote function copyBlob (string containerName, string blobName, string sourceBlobURL, CopyBlobOptions? 
                                options = ()) returns @tainted CopyBlobResult|error {
        OptionsHolder optionsHolder = prepareCopyBlobOptions(options);                             
        http:Request request = createRequest(optionsHolder.optionalHeaders);
        map<string> uriParameterMap = optionsHolder.optionalURIParameters;

        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;

        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToCopyBlobResult(response);
    }

    # Copy a blob from a URL
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + sourceBlobURL - url of source blob
    # + isSynchronized - true if is a synchronous copy or false if it is an asynchronous copy
    # + timeout - Optional. Timout value expressed in seconds
    # + clientRequestId - Optional. Client generated value for correlating client side activities with requests received
    #  by the server.
    # + leaseId - Optional. 
    # + return - If successful, returns Response Headers. Else returns Error. 
    remote function copyBlobFromURL (string containerName, string blobName, string sourceBlobURL, 
                                        boolean isSynchronized, string? clientRequestId = (), string? timeout = (),
                                        string? leaseId = ()) returns @tainted CopyBlobResult|error {
        map<string> optionalHeaderMap = {}; 
        if (clientRequestId is string) {
            optionalHeaderMap[X_MS_CLIENT_REQUEST_ID] = clientRequestId;
        } 
        if (leaseId is string) {
            optionalHeaderMap[X_MS_LEASE_ID] = leaseId;
        } 
        http:Request request = createRequest(optionalHeaderMap);
        
        map<string> uriParameterMap = {};
        if (timeout is string) {
            uriParameterMap[TIMEOUT] = timeout;
        } 

        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);
        request.setHeader(X_MS_REQUIRES_SYNC, isSynchronized.toString());

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;

        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToCopyBlobResult(response);
    }

    # Commits a new block to be commited as part of a blob.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + blockId - a string value that identifies the block (should be less than 64 bytes in size)
    # + content - blob content
    # + timeout - Optional. Timout value expressed in seconds
    # + clientRequestId - Optional. Client generated value for correlating client side activities with requests received
    #  by the server.
    # + leaseId - Optional. 
    # + return - If successful, returns Response Headers. Else returns Error.
    remote function putBlock(string containerName, string blobName, string blockId, byte[] content, 
                                string? clientRequestId = (), string? timeout = (), string? leaseId = ()) 
                                returns @tainted Result|error {
        map<string> optionalHeaderMap = {}; 
        if (clientRequestId is string) {
            optionalHeaderMap[X_MS_CLIENT_REQUEST_ID] = clientRequestId;
        } 
        if (leaseId is string) {
            optionalHeaderMap[X_MS_LEASE_ID] = leaseId;
        } 
        http:Request request = createRequest(optionalHeaderMap);
        
        map<string> uriParameterMap = {};
        if (timeout is string) {
            uriParameterMap[TIMEOUT] = timeout;
        } 
        uriParameterMap[COMP] = BLOCK;
        string encodedBlockId = 'array:toBase64(blockId.toBytes());
        uriParameterMap[BLOCKID] = encodedBlockId;

        request.setBinaryPayload(content);
        request.setHeader(CONTENT_LENGTH, content.length().toString());

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Commits a new block to be commited as part of a blob where the content is read from a URL.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + blockId - a string value that identifies the block (should be less than 64 bytes in size)
    # + sourceBlobURL - URL of the source blob
    # + options - Optional. Optional parameters
    # + return - If successful, returns Response Headers. Else returns Error.
    remote function putBlockFromURL(string containerName, string blobName, string blockId, string sourceBlobURL, 
                                    PutBlockFromURLOptions? options = ()) returns @tainted Result|error {
        OptionsHolder optionsHolder = preparePutBlockFromURLOptions(options);
        http:Request request = createRequest(optionsHolder.optionalHeaders);
        map<string> uriParameterMap = optionsHolder.optionalURIParameters;
        uriParameterMap[COMP] = BLOCK;
        string encodedBlockId = 'array:toBase64(blockId.toBytes());
        uriParameterMap[BLOCKID] = encodedBlockId;

        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);
        request.setHeader(CONTENT_LENGTH, ZERO);

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Writes a blob by specifying the list of blockIDs that make up the blob.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + blockIdList - list of blockIds
    # + timeout - Optional. Timout value expressed in seconds
    # + return - If successful, returns Response Headers. Else returns Error.
    remote function putBlockList(string containerName, string blobName, string[] blockIdList, string? timeout = ()) 
                                    returns @tainted Result|error {
        if (blockIdList.length() < 1) {
            return error(AZURE_BLOB_ERROR_CODE, message = ("blockIdList cannot be empty"));
        }
    
        http:Request request = createRequest({});
        map<string> uriParameterMap = {};
        if (timeout is string) {
            uriParameterMap[TIMEOUT] = timeout;
        } 
        uriParameterMap[COMP] = BLOCKLIST;

        xml blockListElement =  xml `<BlockList></BlockList>`;
        'xml:Element blockListXML = <'xml:Element> blockListElement; 
        string firstBlockId = 'array:toBase64(blockIdList[0].toBytes());
        xml blockIdXML =  xml `<Latest>${firstBlockId}</Latest>`;
        
        int i = 1;
        while (i < blockIdList.length()) {
            string encodedBlockId = 'array:toBase64(blockIdList[i].toBytes());
            blockIdXML =  'xml:concat(blockIdXML, xml `<Latest>${encodedBlockId}</Latest>`);
            i = i + 1;
        }
        blockListXML.setChildren(blockIdXML);

        request.setXmlPayload(blockListXML);      
        request.setHeader(CONTENT_TYPE, APPLICATION_SLASH_XML); // have to fix issue in shared key token generation
        int xmlContentLength = blockListXML.toString().toBytes().length();
        request.setHeader(CONTENT_LENGTH, xmlContentLength.toString());

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Commits a new block to be commited as part of a blob.
    # 
    # + containerName - name of the container
    # + pageBlobName - name of the page blob
    # + operation - It can be update or clear
    # + range - Specifies the range of bytes to be written as a page. 
    # + content - blob content
    # + timeout - Optional. Timout value expressed in seconds
    # + clientRequestId - Optional. Client generated value for correlating client side activities with requests received
    #  by the server.
    # + return - If successful, returns Response Headers. Else returns Error.
    remote function putPage(string containerName, string pageBlobName, string operation, string range,
                            byte[]? content = (), string? clientRequestId = (), string? timeout = ()) 
                            returns @tainted PutPageResult|error {
        map<string> optionalHeaderMap = {}; 
        if (clientRequestId is string) {
            optionalHeaderMap[X_MS_CLIENT_REQUEST_ID] = clientRequestId;
        } 
        http:Request request = createRequest(optionalHeaderMap);
        
        map<string> uriParameterMap = {};
        if (timeout is string) {
            uriParameterMap[TIMEOUT] = timeout;
        } 
        uriParameterMap[COMP] = PAGE;

        if (operation == UPDATE) {
            if (content is byte[]) {
                request.setBinaryPayload(content);
                request.setHeader(CONTENT_LENGTH, content.length().toString());
            } else {
                return error(AZURE_BLOB_ERROR_CODE, message = ("The required parameter for UPDATE operation "
                                + "'content' is not provided"));
            }
        } else if (operation == CLEAR) {
            request.setHeader(CONTENT_LENGTH, ZERO);
        } else {
            return error(AZURE_BLOB_ERROR_CODE, message = (operation + "is not a valid operationType. It should be " 
                            + "either 'update' or 'clear'."));
        }

        request.setHeader(X_MS_PAGE_WRITE, operation);
        request.setHeader(X_MS_RANGE, range);

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + pageBlobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + pageBlobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToPutPageResult(response);
    }

    # Commits a new block to be commited as part of a blob.
    # 
    # + containerName - name of the container
    # + pageBlobName - name of the page blob
    # + sourceBlobURL - URL of the source blob
    # + range - Specifies the range of bytes to be written as a page. 
    # + sourceRange - Specifies the range of bytes to be read from the source blob
    # + timeout - Optional. Timout value expressed in seconds
    # + clientRequestId - Optional. Client generated value for correlating client side activities with requests received
    # + return - If successful, returns Response Headers. Else returns Error.
    remote function putPageFromURL(string containerName, string pageBlobName, string sourceBlobURL, string range,
                                    string sourceRange, string? clientRequestId = (), string? timeout = ()) 
                                    returns @tainted PutPageResult|error {
        map<string> optionalHeaderMap = {}; 
        if (clientRequestId is string) {
            optionalHeaderMap[X_MS_CLIENT_REQUEST_ID] = clientRequestId;
        } 
        http:Request request = createRequest(optionalHeaderMap);

        map<string> uriParameterMap = {};
        if (timeout is string) {
            uriParameterMap[TIMEOUT] = timeout;
        } 
        uriParameterMap[COMP] = PAGE;

        request.setHeader(CONTENT_LENGTH, ZERO);
        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);
        request.setHeader(X_MS_RANGE, range);
        request.setHeader(X_MS_SOURCE_RANGE, sourceRange);

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + pageBlobName, uriParameterMap);
        }
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + pageBlobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToPutPageResult(response);
    }

    # Get list of valid page ranges for a page blob
    # 
    # + containerName - name of the container
    # + blobName - name of the page blob
    # + options - Optional. Optional parameters
    # + return - If successful, returns page ranges. Else returns Error. 
    remote function getPageRanges(string containerName, string blobName, GetPageRangesOptions? options = ()) 
                                    returns @tainted PageRangeResult|error {
        OptionsHolder optionsHolder = prepareGetPageRangesOptions(options);                             
        http:Request request = createRequest(optionsHolder.optionalHeaders);
        map<string> uriParameterMap = optionsHolder.optionalURIParameters;
        uriParameterMap[COMP] = PAGELIST;

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;

        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->get(path, request);
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
    # + timeout - Optional. Timout value expressed in seconds
    # + clientRequestId - Optional. Client generated value for correlating client side activities with requests received
    #  by the server.
    # + leaseId - Optional. 
    # + return - If successful, returns Response Headers. Else returns Error. 
    remote function appendBlock(string containerName, string blobName, byte[] block, string? clientRequestId = (),
                                 string? timeout = (), string? leaseId = ()) returns @tainted AppendBlockResult|error {
        map<string> optionalHeaderMap = {}; 
        if (clientRequestId is string) {
            optionalHeaderMap[X_MS_CLIENT_REQUEST_ID] = clientRequestId;
        } 
        if (leaseId is string) {
            optionalHeaderMap[X_MS_LEASE_ID] = leaseId;
        } 
        http:Request request = createRequest(optionalHeaderMap);
        
        map<string> uriParameterMap = {};
        if (timeout is string) {
            uriParameterMap[TIMEOUT] = timeout;
        } 
        uriParameterMap[COMP] = APPENDBLOCK;

        request.setBinaryPayload(<@untainted>block);
        request.setHeader(CONTENT_LENGTH, block.length().toString());

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;

        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToAppendBlockResult(response);
    }

    # Commits a new block of data (from a URL) to the end of an existing append blob.
    # 
    # + containerName - name of the container
    # + blobName - name of the append blob
    # + sourceBlobURL - URL of the source blob
    # + timeout - Optional. Timout value expressed in seconds
    # + clientRequestId - Optional. Client generated value for correlating client side activities with requests received
    #  by the server.
    # + return - If successful, returns Response Headers. Else returns Error. 
    remote function appendBlockFromURL(string containerName, string blobName, string sourceBlobURL, 
                                        string? clientRequestId = (), string? timeout = ()) 
                                        returns @tainted AppendBlockResult|error {
        map<string> optionalHeaderMap = {}; 
        if (clientRequestId is string) {
            optionalHeaderMap[X_MS_CLIENT_REQUEST_ID] = clientRequestId;
        } 
        http:Request request = createRequest(optionalHeaderMap);
        
        map<string> uriParameterMap = {};
        if (timeout is string) {
            uriParameterMap[TIMEOUT] = timeout;
        } 
        uriParameterMap[COMP] = APPENDBLOCK;

        request.setHeader(CONTENT_LENGTH, ZERO);
        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToAppendBlockResult(response);
    }

    # Upload large blob
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + filePath - path to the file which should be uploaded
    # + return - true if successful
    remote function uploadLargeBlob(string containerName, string blobName, string filePath) 
                                    returns @tainted boolean|error {
        file:MetaData fileMetaData = check file:getMetaData(filePath);
        int fileSize = fileMetaData.size;
        log:print("File size: " + fileSize.toString());

        int i = 0;
        int index = 0;
        int remainingBytes = fileSize;
        string[] blockIdArr = [];

        stream<io:Block> fileStream = check io:fileReadBlocksAsStream(filePath, MAX_BLOB_UPLOAD_SIZE);
        error? upload = fileStream.forEach(function(io:Block byteBlock) {
            string blockId = blobName + COLON_SYMBOL + i.toString();
            //blockIdArr[i] = blockId;
            blockIdArr.push(blockId);
                    
            if (remainingBytes < MAX_BLOB_UPLOAD_SIZE) {
                byte[] lastByteArray = 'array:slice(byteBlock, 0, fileSize - index);
                Result response = checkpanic self->putBlock(containerName, blobName, blockId, lastByteArray);
                log:print(response.toString());
            } else {
                Result response = checkpanic self->putBlock(containerName, blobName, blockId, byteBlock);
                log:print(response.toString());
            }
                    
            remainingBytes -= MAX_BLOB_UPLOAD_SIZE;
            index = index + MAX_BLOB_UPLOAD_SIZE - 1;
                    
            log:print("remaining: " + remainingBytes.toString());
            i += 1;         
        });

        Result putBlockListResponse = check self->putBlockList(containerName, blobName, blockIdArr);
        return true;
    }
}
