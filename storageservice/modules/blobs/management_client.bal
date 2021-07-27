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
import ballerina/xmldata;

# Azure Storage Blob Management Client Object.
#
# + httpClient - The HTTP Client for Azure Storage Blob Service
# + accessKeyOrSAS - Access Key or Shared Access Signature for the Azure Storage Account
# + accountName - Azure Storage Account Name
# + authorizationMethod - If authorization method is accessKey or SAS
# 
@display {label: "Azure Storage Blob Management Client", iconPath: "AzureStorageBlobLogo.png"}
public isolated client class ManagementClient {
    private final http:Client httpClient;
    private final string accountName;
    private final string accessKeyOrSAS;
    private final AuthorizationMethod authorizationMethod;

    public isolated function init(AzureBlobServiceConfiguration blobServiceConfig) returns error? {
        string baseURL = string `https://${blobServiceConfig.accountName}.blob.core.windows.net`;
        
        self.httpClient = check new (baseURL, {http1Settings: {chunking: http:CHUNKING_NEVER}});
        self.accessKeyOrSAS = blobServiceConfig.accessKeyOrSAS;
        self.accountName = blobServiceConfig.accountName;
        self.authorizationMethod = blobServiceConfig.authorizationMethod;
    }

    # Get Account Information of the azure storage account.
    # 
    # + return - If successful, returns AccountInformation. Else returns Error. 
    @display {label: "Get Account Info"}
    remote isolated function getAccountInformation() returns @tainted @display {label: "Account information"} 
            AccountInformationResult|error {                 
        http:Request request = new;
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[RESTYPE] = ACCOUNT;
        uriParameterMap[COMP] = PROPERTIES;

        if (self.authorizationMethod === ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_GET, self.accountName, self.accessKeyOrSAS, EMPTY_STRING, 
                uriParameterMap);
        }
        
        string resourcePath = FORWARD_SLASH_SYMBOL;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);  
        map<string> headerMap = populateHeaderMapFromRequest(request);
        http:Response response = <http:Response> check self.httpClient->get(path, headerMap);
        check handleHeaderOnlyResponse(response);
        return convertResponseToAccountInformationType(response);
    }

    # Create a container in the azure storage account.
    # 
    # + containerName - Name of the container
    # + return - If successful, returns Response. Else returns Error. 
    @display {label: "Create Container"}
    remote isolated function createContainer (@display {label: "Container Name"} string containerName) 
                                              returns @tainted @display {label: "Response"} map<json>|error {
        http:Request request = new;
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[RESTYPE] = CONTAINER;

        if (self.authorizationMethod === ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_PUT, self.accountName, self.accessKeyOrSAS, containerName, 
                uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        _ = check handleResponse(response);
        return getHeaderMapFromResponse(response);
    }

    # Delete a container from the azure storage account.
    # 
    # + containerName - Name of the container
    # + return - If successful, returns Response. Else returns Error. 
    @display {label: "Delete Container"}
    remote isolated function deleteContainer (@display {label: "Container Name"} string containerName) 
                                              returns @tainted @display {label: "Response"} map<json>|error {
        http:Request request = new;
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[RESTYPE] = CONTAINER;

        if (self.authorizationMethod === ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_DELETE, self.accountName, self.accessKeyOrSAS, containerName, 
                uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->delete(path, request);
        _ = check handleResponse(response);
        return getHeaderMapFromResponse(response);
    }

    # Get Container Properties.
    # 
    # + containerName - Name of the container
    # + return - If successful, returns Container Properties. Else returns Error. 
    @display {label: "Get Container Properties"}
    remote isolated function getContainerProperties(@display {label: "Container Name"} string containerName) 
                                                    returns @tainted @display {label: "Container properties"} 
                                                    ContainerPropertiesResult|error {
        http:Request request = new;
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[RESTYPE] = CONTAINER;

        if (self.authorizationMethod === ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_HEAD, self.accountName, self.accessKeyOrSAS, containerName, 
                uriParameterMap);
        }
        
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        map<string> headerMap = populateHeaderMapFromRequest(request);
        http:Response response = <http:Response> check self.httpClient->head(path, headerMap);
        check handleHeaderOnlyResponse(response);
        return convertResponseToContainerPropertiesResult(response);
    }

    # Get Container Metadata.
    # 
    # + containerName - Name of the container
    # + return - If successful, returns Container Metadata. Else returns Error. 
    @display {label: "Container Metadata"}
    remote isolated function getContainerMetadata(@display {label: "Container Name"} string containerName) 
                                                  returns @tainted @display {label: "Container metadata"} 
                                                  ContainerMetadataResult|error {
        http:Request request = new;
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[RESTYPE] = CONTAINER;
        uriParameterMap[COMP] = METADATA;

        if (self.authorizationMethod === ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_GET, self.accountName, self.accessKeyOrSAS, containerName, 
                uriParameterMap);
        }   
        
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        map<string> headerMap = populateHeaderMapFromRequest(request);
        http:Response response = <http:Response> check self.httpClient->get(path, headerMap);
        check handleHeaderOnlyResponse(response);
        return convertResponseToContainerMetadataResult(response);
    }

    # Get Container ACL (gets the permissions for the specified container).
    # 
    # + containerName - Name of the container
    # + return - If successful, returns container ACL. Else returns Error. 
    @display {label: "Get Containe ACL"}
    remote isolated function getContainerACL(@display {label: "Container Name"} string containerName) returns @tainted 
                                             @display {label: "Container ACL"} ContainerACLResult|error {
        if (self.authorizationMethod === ACCESS_KEY ) {
            http:Request request = new;
            check setDefaultHeaders(request);
            map<string> uriParameterMap = {};
            uriParameterMap[RESTYPE] = CONTAINER;
            uriParameterMap[COMP] = ACL;

            check addAuthorizationHeader(request, http:HTTP_HEAD, self.accountName, self.accessKeyOrSAS, containerName, 
                uriParameterMap);

            string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
            string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
            map<string> headerMap = populateHeaderMapFromRequest(request);
            http:Response response = <http:Response> check self.httpClient->head(path, headerMap);
            check handleHeaderOnlyResponse(response);
            return convertResponseToContainerACLResult(response);
        } else {
            return error(AZURE_BLOB_ERROR_CODE, message = ("This operation is supported only with accessKey "
                + "Authentication"));
        } 
    }

    # Get Blob Service Properties.
    # 
    # + return - If successful, returns Blob Service Properties. Else returns Error. 
    @display {label: "Get Blob Service Properties"}
    remote isolated function getBlobServiceProperties() returns @tainted @display {label: "Blob service properties"} 
            BlobServicePropertiesResult|error {
        http:Request request = new;
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[RESTYPE] = SERVICE;
        uriParameterMap[COMP] = PROPERTIES;

        if (self.authorizationMethod === ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_GET, self.accountName, self.accessKeyOrSAS, EMPTY_STRING, 
                uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath); 
        map<string> headerMap = populateHeaderMapFromRequest(request);
        http:Response response = <http:Response> check self.httpClient->get(path, headerMap);
        xml blobServiceProperties = <xml> check handleResponse(response);
        BlobServicePropertiesResult blobServicePropertiesResult = {
            storageServiceProperties: check xmldata:toJson(blobServiceProperties/*),
            responseHeaders: getHeaderMapFromResponse(response)
        };
        return blobServicePropertiesResult;
    }  
}
