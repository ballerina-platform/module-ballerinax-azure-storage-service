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

import ballerina/http;
import ballerina/xmldata;
import ballerinax/'client.config;

# Azure Storage File Service Management Client.
# 
# + httpClient - HTTP Client for Azure Storage File Service
# + azureConfig - Azure file service configuration
@display {label: "Azure Storage File Management", iconPath: "storageservice/icon.png"}
public isolated client class ManagementClient {
    private final http:Client httpClient;
    private final ConnectionConfig & readonly azureConfig;

    # Initialize Azure Client using the provided azureConfiguration by user
    #
    # + azureConfig - AzureConfiguration record
    public isolated function init(ConnectionConfig config) returns error? {
        string baseURL = string `https://${config.accountName}.file.core.windows.net`;
        self.azureConfig = config.cloneReadOnly();
        http:ClientConfiguration httpClientConfig = check config:constructHTTPClientConfig(config);
        httpClientConfig.http1Settings = {chunking: http:CHUNKING_NEVER};
        self.httpClient = check new (baseURL, httpClientConfig);
    }

    # Lists all the file shares in the  storage account.
    #
    # + uriParameters - URI Parameters
    # + return - If success, returns ShareList record with basic details.  Else returns an error.
    @display {label: "List File Shares"}
    remote isolated function listShares(@display {label: "URI Parameters"} ListShareURIParameters 
                                        uriParameters = {}) returns @display {label: "Response"} SharesList|
                                        error {
        string? appendedUriParameters = setOptionalURIParametersFromRecord(uriParameters);
        string getListPath = appendedUriParameters is () ? (LIST_SHARE_PATH) : (LIST_SHARE_PATH 
            + appendedUriParameters);
        http:Request request = new;
        if (self.azureConfig.authorizationMethod ==ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[COMP] = LIST;
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_GET,
                uriParameterRecord: uriParameters,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);     
        } else {
            getListPath = getListPath.concat(AMPERSAND, self.azureConfig.accessKeyOrSAS.substring(1)); 
        }
        map<string> headerMap = populateHeaderMapFromRequest(request);
        http:Response response = check self.httpClient->get(getListPath, headerMap);
        xml formattedXML = check removeDoubleQuotesFromXML(check response.getXmlPayload()/<Shares>);
        json jsonValue = check xmldata:toJson(formattedXML);
        if (jsonValue.Shares == EMPTY_STRING) {
            return error NoSharesFoundError(NO_SHARES_FOUND, storageAccountName = self.azureConfig.accountName);
        }
        return check jsonValue.cloneWithType(SharesList);
    }

    # Gets the File service properties for the storage account.
    #
    # + return - If success, returns FileServicePropertiesList record with details.  Else returns error.
    @display {label: "Get File Service Properties"}
    remote isolated function getFileServiceProperties() returns @display {label: "File Service Properties"} 
                                                      FileServicePropertiesList|error {
        string getListPath = GET_FILE_SERVICE_PROPERTIES;
        map<string> requiredURIParameters = {}; 
        http:Request request = new;
        if (self.azureConfig.authorizationMethod == ACCESS_KEY) {
            requiredURIParameters[RESTYPE] = SERVICE;
            requiredURIParameters[COMP] = PROPERTIES;     
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_GET,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);    
        } else {
            getListPath = getListPath.concat(AMPERSAND, self.azureConfig.accessKeyOrSAS.substring(1)); 
        }
        map<string> headerMap = populateHeaderMapFromRequest(request);
        http:Response response = check self.httpClient->get(getListPath, headerMap);
        xml responseBody = check response.getXmlPayload();
        xml formattedXML = check removeDoubleQuotesFromXML(responseBody);
        json jsonValue = check xmldata:toJson(formattedXML);
        return check jsonValue.cloneWithType(FileServicePropertiesList);
    }

    # Sets the File service properties for the storage account.
    #
    # + fileServicePropertiesList - fileServicePropertiesList record with detail to be set
    # + return - If success, returns true.  Else returns error.
    @display {label: "Set File Service Properties"}
    remote isolated function setFileServiceProperties(@display {label: "File Service Properties List"} 
                                                      FileServicePropertiesList fileServicePropertiesList) returns 
                                                      @display {label: "Status"} error? {
        string requestPath = GET_FILE_SERVICE_PROPERTIES;
        xml requestBody = check convertRecordToXml(fileServicePropertiesList);
        http:Request request = new;
        request.setXmlPayload(requestBody);
        request.setHeader(CONTENT_LENGTH, requestBody.toString().toBytes().length().toString());
        request.setHeader(CONTENT_TYPE, APPLICATION_XML);
        if (self.azureConfig.authorizationMethod ==ACCESS_KEY) {
            map<string> requiredURIParameters = {}; 
            requiredURIParameters[RESTYPE] = SERVICE;
            requiredURIParameters[COMP] = PROPERTIES;
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_PUT,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);        
        } else {
            requestPath = requestPath.concat(AMPERSAND, self.azureConfig.accessKeyOrSAS.substring(1)); 
        }
        http:Response response = check self.httpClient->put(requestPath, request);
        check checkAndHandleErrors(response);
    }

    # Creates a new share in a storage account.
    #
    # + fileShareName - Name of the fileshare
    # + fileShareRequestHeaders - Optional. Map of the user defined optional headers
    # + return - If success, returns true.  Else returns error.
    @display {label: "Create New Share"}
    remote isolated function createShare(@display {label: "File Share Name"}string fileShareName, 
                                         @display {label: "Optional Headers"} RequestHeaders? 
                                         fileShareRequestHeaders = ()) returns @display {label: "Response"} 
                                         error? {
        string requestPath = SLASH + fileShareName + QUESTION_MARK + CREATE_GET_DELETE_SHARE;
        http:Request request = new;
        if (fileShareRequestHeaders is RequestHeaders) {
            setAzureRequestHeaders(request, fileShareRequestHeaders);
        }
        if (self.azureConfig.authorizationMethod ==ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[RESTYPE] = SHARE;
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_PUT,
                requiredURIParameters: requiredURIParameters,
                resourcePath: fileShareName
            };
            check prepareAuthorizationHeaders(authorizationDetail); 
        } else {
            requestPath = requestPath.concat(AMPERSAND, self.azureConfig.accessKeyOrSAS.substring(1)); 
        }
        http:Response response = check self.httpClient->put(requestPath, request);
        check checkAndHandleErrors(response);
    }

    # Returns all user-defined metadata and system properties of a share.
    #
    # + fileShareName - Name of the FileShare
    # + return - If success, returns FileServicePropertiesList record with Details.  Else returns error.
    @display {label: "Get Share Properties"}
    remote isolated function getShareProperties(@display {label: "File Share Name"} string fileShareName) returns 
                                                @display {label: "File Service Properties"} 
                                                FileServicePropertiesList|error {
        string requestPath = SLASH + fileShareName + CREATE_GET_DELETE_SHARE;
        http:Request request = new;
        if (self.azureConfig.authorizationMethod ==ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[RESTYPE] = SHARE;
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_GET,
                requiredURIParameters: requiredURIParameters,
                resourcePath: fileShareName
            };
            check prepareAuthorizationHeaders(authorizationDetail);       
        } else {
            requestPath = requestPath.concat(AMPERSAND, self.azureConfig.accessKeyOrSAS.substring(1)); 
        }
        map<string> headerMap = populateHeaderMapFromRequest(request);
        http:Response response = check self.httpClient->get(requestPath, headerMap);
        xml responseBody = check response.getXmlPayload();
        xml formattedXML = check removeDoubleQuotesFromXML(responseBody);
        json jsonValue = check xmldata:toJson(formattedXML);
        return check jsonValue.cloneWithType(FileServicePropertiesList);
    }

    # Deletes the share and any files and directories it contains.
    #
    # + fileShareName - Name of the fileshare
    # + return - If success, returns true.  Else returns error.
    @display {label: "Delete Share"}
    remote isolated function deleteShare(@display {label: "File Share Name"} string fileShareName) returns 
                                         @display {label: "Response"} error? {
        string requestPath = SLASH + fileShareName + QUESTION_MARK + CREATE_GET_DELETE_SHARE;
        http:Request request = new;
        if (self.azureConfig.authorizationMethod ==ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[RESTYPE] = SHARE;
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_DELETE,
                requiredURIParameters: requiredURIParameters,
                resourcePath: fileShareName
            };
            check prepareAuthorizationHeaders(authorizationDetail);        
        } else {
            requestPath = requestPath.concat(AMPERSAND, self.azureConfig.accessKeyOrSAS.substring(1)); 
        }
        http:Response response = check self.httpClient->delete(requestPath, request);
        check checkAndHandleErrors(response);
    }
}
