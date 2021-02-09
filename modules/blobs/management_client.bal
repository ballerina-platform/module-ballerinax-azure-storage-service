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

# Azure Storage Blob Management Client Object.
#
# + httpClient - The HTTP Client for Azure Storage Blob
# + sharedAccessSignature - Shared Access Signature for the Azure Storage Account
# + accessKey - Azure Stoage Access Key
# + accountName - Azure Storage Account Name
# 
public client class ManagementClient {
    http:Client httpClient;
    string sharedAccessSignature;
    string accessKey;
    string accountName;
    string authorizationMethod;

    public function init(AzureBlobServiceConfiguration blobServiceConfig) {
        self.sharedAccessSignature = blobServiceConfig.sharedAccessSignature;
        self.httpClient = new (blobServiceConfig.baseURL, {http1Settings: {chunking: http:CHUNKING_NEVER}});
        self.accessKey = blobServiceConfig.accessKey;
        self.accountName = blobServiceConfig.accountName;
        self.authorizationMethod = blobServiceConfig.authorizationMethod;
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
}
