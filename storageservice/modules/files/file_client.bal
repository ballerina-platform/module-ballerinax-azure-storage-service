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

import ballerina/file;
import ballerina/http;
import ballerina/xmldata;

# Azure Storage File connector allows you to access the Azure Files REST API.
# This connector lets you to access data stored in Azure file shares.
#
# + httpClient - HTTP Client for Azure Storage File Service
# + azureConfig - Azure file service configuration
@display {label: "Azure Storage File", iconPath: "storageservice/icon.png"}
public isolated client class FileClient {
    private final http:Client httpClient;
    private final ConnectionConfig & readonly azureConfig;

    # Initializes the connector.
    # Create an Azure account following [this guide](https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account).
    # Create an Azure Storage account following [this guide](https://docs.microsoft.com/en-us/learn/modules/create-azure-storage-account)
    # Obtain `Shared Access Signature` (`SAS`) or use one of the Accesskeys for authentication. 
    # + azureConfig - ConnectionConfig record
    public isolated function init(ConnectionConfig config) returns error? {
        string baseURL = string `https://${config.accountName}.file.core.windows.net`;
        self.azureConfig = config.cloneReadOnly();
        http:ClientConfiguration httpClientConfig = {
            httpVersion: config.httpVersion,
            http1Settings: {chunking: CHUNKING_NEVER},
            http2Settings: config.http2Settings,
            timeout: config.timeout,
            forwarded: config.forwarded,
            poolConfig: config.poolConfig,
            cache: config.cache,
            compression: config.compression,
            circuitBreaker: config.circuitBreaker,
            retryConfig: config.retryConfig,
            responseLimits: config.responseLimits,
            secureSocket: config.secureSocket,
            proxy: config.proxy,
            validation: config.validation
        };
        self.httpClient = check new (baseURL, httpClientConfig);
    }

    # Lists directories within the share or specified directory. 
    #
    # + fileShareName - Name of the FileShare
    # + azureDirectoryPath - Path of the Azure directory
    # + uriParameters - Map of the optional URI parameters record
    # + return - If success, DirectoryList record with Details and the marker. Else an error.
    @display {label: "Get Directory List"}
    remote isolated function getDirectoryList(@display {label: "File Share Name"} string fileShareName,
                                            @display {label: "Azure Directory Path"} string? azureDirectoryPath = (),
                                            @display {label: "Optional URI Parameters Map"} GetFileListURIParameters
                                            uriParameters = {}) returns @display {label: "Response"}
                                            DirectoryList|error {
        string requestPath = azureDirectoryPath is () ? (SLASH + fileShareName + SLASH + LIST_FILES_DIRECTORIES_PATH)
            : SLASH + fileShareName + SLASH + azureDirectoryPath + SLASH + LIST_FILES_DIRECTORIES_PATH;
        string? optionalURIParameters = setOptionalURIParametersFromRecord(uriParameters);
        requestPath = optionalURIParameters is () ? requestPath : (requestPath + optionalURIParameters);
        http:Request request = new;
        if (self.azureConfig.authorizationMethod == ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[RESTYPE] = DIRECTORY;
            requiredURIParameters[COMP] = LIST;
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH)
                : (fileShareName + SLASH + azureDirectoryPath + SLASH);
            AuthorizationDetail authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_GET,
                uriParameterRecord: uriParameters,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);
        } else {
            requestPath = requestPath.concat(AMPERSAND, self.azureConfig.accessKeyOrSAS.substring(1));
        }
        map<string> headerMap = populateHeaderMapFromRequest(request);
        http:Response response = check self.httpClient->get(requestPath, headerMap);
        xml responseBody = check response.getXmlPayload();
        xml formattedXML = responseBody/<Entries>/<Directory>;
        if (formattedXML.length() == 0) {
            fail error(NO_DIRECTORIES_FOUND);
        }
        json convertedJsonContent = check xmldata:toJson(formattedXML);
        return check convertedJsonContent.cloneWithType(DirectoryList);
    }

    # Lists files within the share or specified directory.
    #
    # + fileShareName - Name of the FileShare
    # + azureDirectoryPath - Path of the Azure directory
    # + uriParameters - Map of the optional URI parameters record
    # + return - If success, FileList record with Details and the marker. Else an error
    @display {label: "Get File List"}
    remote isolated function getFileList(@display {label: "File Share Name"} string fileShareName,
                                        @display {label: "Azure Directory Path"} string? azureDirectoryPath = (),
                                        @display {label: "Optional URI Parameters"} GetFileListURIParameters
                                        uriParameters = {}) returns @display {label: "Response"} FileList|
                                        error {
        string requestPath = azureDirectoryPath is () ? (SLASH + fileShareName + SLASH + LIST_FILES_DIRECTORIES_PATH)
            : (SLASH + fileShareName + SLASH + azureDirectoryPath + SLASH + LIST_FILES_DIRECTORIES_PATH);
        string? optionalURIParameters = setOptionalURIParametersFromRecord(uriParameters);
        requestPath = optionalURIParameters is () ? requestPath : (requestPath + optionalURIParameters);
        http:Request request = new;
        if (self.azureConfig.authorizationMethod == ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[RESTYPE] = DIRECTORY;
            requiredURIParameters[COMP] = LIST;
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH)
                : (fileShareName + SLASH + azureDirectoryPath + SLASH);
            AuthorizationDetail authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_GET,
                uriParameterRecord: uriParameters,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);
        } else {
            requestPath = requestPath.concat(AMPERSAND, self.azureConfig.accessKeyOrSAS.substring(1));
        }
        map<string> headerMap = populateHeaderMapFromRequest(request);
        http:Response response = check self.httpClient->get(requestPath, headerMap);
        xml responseBody = check response.getXmlPayload();
        xml formattedXML = responseBody/<Entries>/<File>;
        if (formattedXML.length() == 0) {
            fail error(NO_FILE_FOUND);
        }
        json convertedJsonContent = check xmldata:toJson(formattedXML);
        return check convertedJsonContent.cloneWithType(FileList);
    }

    # Creates a directory in the share or parent directory.
    #
    # + fileShareName - Name of the fileshare
    # + newDirectoryName - New directory name in azure
    # + azureDirectoryPath - Path to the new directory
    # + return - If success true. Else an error
    @display {label: "Create Directory"}
    remote isolated function createDirectory(@display {label: "File Share Name"} string fileShareName,
                                            @display {label: "New Directory Name"} string newDirectoryName,
                                            @display {label: "Azure Directory Path"} string? azureDirectoryPath = ())
                                            returns @display {label: "Response"} error? {
        string requestPath = SLASH + fileShareName;
        requestPath = azureDirectoryPath is () ? requestPath : (requestPath + SLASH + azureDirectoryPath);
        requestPath = requestPath + SLASH + newDirectoryName + CREATE_DELETE_DIRECTORY_PATH;
        http:Request request = new;
        map<string> requiredHeaders = {
            [X_MS_FILE_PERMISSION]: INHERIT,
            [x_MS_FILE_ATTRIBUTES]: DIRECTORY,
            [X_MS_FILE_CREATION_TIME]: NOW,
            [X_MS_FILE_LAST_WRITE_TIME]: NOW
        };
        setSpecificRequestHeaders(request, requiredHeaders);
        if (self.azureConfig.authorizationMethod == ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[RESTYPE] = DIRECTORY;
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + newDirectoryName)
                : (fileShareName + SLASH + azureDirectoryPath + SLASH + newDirectoryName);
            AuthorizationDetail authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_PUT,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);
        } else {
            requestPath = requestPath.concat(AMPERSAND, self.azureConfig.accessKeyOrSAS.substring(1));
        }
        http:Response response = check self.httpClient->put(requestPath, request);
        if (response.statusCode != http:STATUS_CREATED) {
            fail error(check getErrorMessage(response));
        }
    }

    # Deletes the directory. Only supported for empty directories.
    #
    # + fileShareName - Name of the FileShare
    # + directoryName - Name of the Directory to be deleted
    # + azureDirectoryPath - Path of the Azure directory
    # + return - If success true. Else an error
    @display {label: "Delete Directory"}
    remote isolated function deleteDirectory(@display {label: "File Share Name"} string fileShareName,
                                            @display {label: "Directory Name"} string directoryName,
                                            @display {label: "Azure Directory Path"} string? azureDirectoryPath = ())
                                            returns @display {label: "Response"} error? {
        string requestPath = SLASH + fileShareName;
        requestPath = azureDirectoryPath is () ? requestPath : (requestPath + SLASH + azureDirectoryPath);
        requestPath = requestPath + SLASH + directoryName + CREATE_DELETE_DIRECTORY_PATH;
        http:Request request = new;
        if (self.azureConfig.authorizationMethod == ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[RESTYPE] = DIRECTORY;
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + directoryName)
                : (fileShareName + SLASH + azureDirectoryPath + SLASH + directoryName);
            AuthorizationDetail authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_DELETE,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);
        } else {
            requestPath = requestPath.concat(AMPERSAND, self.azureConfig.accessKeyOrSAS.substring(1));
        }
        http:Response response = check self.httpClient->delete(requestPath, request);
        if (response.statusCode != http:STATUS_ACCEPTED) {
            fail error(check getErrorMessage(response));
        }
    }

    # Creates a new file or replaces a file. This operation only initializes a file. putRange should be used to add 
    # content.
    #
    # + fileShareName - Name of the fileShare
    # + newFileName - Name of the file
    # + fileSizeInByte - Size of the file in Bytes
    # + azureDirectoryPath - Path of the Azure directory 
    # + return - If success true. Else an error
    @display {label: "Create File"}
    remote isolated function createFile(@display {label: "File Share Name"} string fileShareName,
                                        @display {label: "Azure File Name"} string newFileName,
                                        @display {label: "File Size"} int fileSizeInByte,
                                        @display {label: "Azure Directory Path"} string? azureDirectoryPath = ())
                                        returns @display {label: "Response"} error? {
        return createFileInternal(self.httpClient, fileShareName, newFileName, fileSizeInByte, self.azureConfig,
            azureDirectoryPath);
    }

    # Gets File Metadata.
    #
    # + fileShareName - Name of the FileShare  
    # + fileName - Name of the File  
    # + azureDirectoryPath - Path of the azure directory
    # + uriParameters - Optional URI Parameter Description
    # + return - If successful, File Metadata. Else an Error
    @display {label: "Get File Metadata"}
    remote isolated function getFileMetadata(@display {label: "File Share Name"} string fileShareName,
                                            @display {label: "File Name"} string fileName,
                                            @display {label: "Azure Directory Path"} string? azureDirectoryPath = (),
                                            @display {label: "Optional Parameters"} OptionalURIParametersFileMetaData
                                            uriParameters = {}) returns @display {label: "File metadata"}
                                            FileMetadataResult|error {
        string requestPath = azureDirectoryPath is () ? (SLASH + fileShareName + SLASH + fileName +
            GET_FILE_METADATA) : SLASH + fileShareName + SLASH + azureDirectoryPath + SLASH
            + fileName + GET_FILE_METADATA;
        string? optionalURIParameters = setOptionalURIParametersFromRecord(uriParameters);
        requestPath = optionalURIParameters is () ? requestPath : (requestPath + optionalURIParameters);
        http:Request request = new;
        if (self.azureConfig.authorizationMethod == ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[COMP] = METADATA;
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + fileName)
                : (fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);
            AuthorizationDetail authorizationDetail = {
                azureRequest:request,
                azureConfig:self.azureConfig,
                httpVerb: http:HTTP_GET,
                uriParameterRecord: uriParameters,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);
        } else {
            requestPath = requestPath.concat(AMPERSAND, self.azureConfig.accessKeyOrSAS.substring(1));
        }
        map<string> headerMap = populateHeaderMapFromRequest(request);
        http:Response response = check self.httpClient->get(requestPath, headerMap);
        return getMetadataFromResponse(response);
    }

    # Writes the content (a range of bytes) to a file initialized earlier.
    #
    # + fileShareName - Name of the FileShare
    # + localFilePath - Path of the local file
    # + azureFileName - Name of the file in azure
    # + azureDirectoryPath - Path of the azure directory
    # + return - If success true. Else an error
    @display {label: "Write Content To Azure File"}
    isolated remote function putRange(@display {label: "File Share Name"} string fileShareName,
                            @display {label: "Local File Path"} string localFilePath,
                            @display {label: "Azure File Name"} string azureFileName,
                            @display {label: "Azure Directory Path"} string? azureDirectoryPath = ())
                            returns @display {label: "Status"} error? {
        file:MetaData fileMetaData = check file:getMetaData(localFilePath);
        int fileSizeInByte = fileMetaData.size;
        return check putRangeInternal(self.httpClient, fileShareName, localFilePath, azureFileName, self.azureConfig,
            fileSizeInByte, azureDirectoryPath);
    }

    # Provides a list of valid ranges (in bytes) of a file.
    #
    # + fileShareName - Name of the FileShare
    # + fileName - Name of the file
    # + azureDirectoryPath - Path of the Azure directory
    # + return - If success RangeList record. Else an error
    @display {label: "Get List Of Valid Ranges"}
    remote isolated function listRange(@display {label: "File Share Name"} string fileShareName,
                                        @display {label: "Azure File Name"} string fileName,
                                        @display {label: "Azure Directory Path"} string? azureDirectoryPath = ())
                                        returns @display {label: "Response"} RangeList|error {
        string requestPath = azureDirectoryPath is () ? (SLASH + fileShareName + SLASH + fileName + QUESTION_MARK
            + LIST_FILE_RANGE) : (SLASH + fileShareName + SLASH + azureDirectoryPath + SLASH + fileName + QUESTION_MARK
            + LIST_FILE_RANGE);
        http:Request request = new ();
        if (self.azureConfig.authorizationMethod == ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[COMP] = RANGE_LIST;
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + fileName)
                : (fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);
            AuthorizationDetail authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_GET,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);
        } else {
            requestPath = requestPath.concat(AMPERSAND, self.azureConfig.accessKeyOrSAS.substring(1));
        }
        map<string> headerMap = populateHeaderMapFromRequest(request);
        http:Response response = check self.httpClient->get(requestPath, headerMap);
        xml responseBody = check response.getXmlPayload();
        if (responseBody.length() == 0) {
            fail error(NO_RANGE_LIST_FOUND);
        }
        json convertedJsonContent = check xmldata:toJson(responseBody);
        return check convertedJsonContent.cloneWithType(RangeList);
    }

    # Deletes a file from the fileshare.
    #
    # + fileShareName - Name of the FileShare
    # + fileName - Name of the file
    # + azureDirectoryPath - Path of the Azure directory
    # + return - If success true. Else an error
    @display {label: "Delete File"}
    remote isolated function deleteFile(@display {label: "File Share Name"} string fileShareName,
                                        @display {label: "Azure File Name"} string fileName,
                                        @display {label: "Azure Directory Path"} string? azureDirectoryPath = ())
                                        returns @display {label: "Response"} error? {
        http:Request request = new;
        string requestPath = SLASH + fileShareName;
        requestPath = azureDirectoryPath is () ? requestPath : (requestPath + SLASH + azureDirectoryPath);
        requestPath = requestPath + SLASH + fileName;
        if (self.azureConfig.authorizationMethod == ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + fileName)
                : (fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);
            AuthorizationDetail authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_DELETE,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);
        } else {
            requestPath = requestPath.concat(QUESTION_MARK, self.azureConfig.accessKeyOrSAS.substring(1));
        }
        http:Response response = check self.httpClient->delete(requestPath, request);
        if (response.statusCode != http:STATUS_ACCEPTED) {
            fail error(check getErrorMessage(response));
        }
    }

    # Downloads a file from fileshare to a specified location.
    #
    # + fileShareName - Name of the FileShare
    # + fileName - Name of the file
    # + azureDirectoryPath - Path of azure directory
    # + localFilePath - Path to the local destination location
    # + return - If success true. Else an error
    @display {label: "Download File"}
    remote isolated function getFile(@display {label: "File Share Name"} string fileShareName,
                                    @display {label: "Azure File Name"} string fileName,
                                    @display {label: "Download Location"} string localFilePath,
                                    @display {label: "Azure Directory Path"} string? azureDirectoryPath = ())
                                    returns @display {label: "Response"} error? {
        string requestPath = azureDirectoryPath is () ? (SLASH + fileShareName + SLASH + fileName) : (SLASH
            + fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);
        http:Request request = new;
        if (self.azureConfig.authorizationMethod == ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + fileName)
                : (fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);
            AuthorizationDetail authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_GET,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);
        } else {
            requestPath = requestPath.concat(QUESTION_MARK, self.azureConfig.accessKeyOrSAS.substring(1));
        }
        map<string> headerMap = populateHeaderMapFromRequest(request);
        http:Response response = check self.httpClient->get(requestPath, headerMap);
        byte[] responseBody = check response.getBinaryPayload();
        check writeFile(localFilePath, responseBody);
    }

    # Downloads a file from fileshare to a specified location as an Byte array
    #
    # + fileShareName - Name of the FileShare  
    # + fileName - Name of the file  
    # + azureDirectoryPath - Path of azure directory  
    # + range - The specified byte range to be returned the file data 
    # + return - If successful, file content as a byte array. Else an error
    @display {label: "Download File"}
    remote isolated function getFileAsByteArray(@display {label: "File Share Name"} string fileShareName,
                                    @display {label: "Azure File Name"} string fileName,
                                    @display {label: "Azure Directory Path"} string? azureDirectoryPath = (),
                                    @display {label: "Byte Range"} ContentRange? range = ())
                                    returns @display {label: "Response"} byte[]|error {
        string requestPath = azureDirectoryPath is () ? (SLASH + fileShareName + SLASH + fileName) : (SLASH
            + fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);
        http:Request request = new;
        if (range != ()) {
            string rangeHeader = "bytes=" + range.startByte.toString() + "-" + range.endByte.toString();
            request.setHeader(X_MS_RANGE, rangeHeader);
        }
        if (self.azureConfig.authorizationMethod == ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + fileName)
                : (fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);
            AuthorizationDetail authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_GET,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);
        } else {
            requestPath = requestPath.concat(QUESTION_MARK, self.azureConfig.accessKeyOrSAS.substring(1));
        }
        map<string> headerMap = populateHeaderMapFromRequest(request);
        http:Response response = check self.httpClient->get(requestPath, headerMap);
        boolean isFileTypeAvailable = response.hasHeader(X_MS_TYPE);
        if (isFileTypeAvailable == true) {
            byte[] payload = check response.getBinaryPayload();
            return payload;
        } else {
            xml errorMessage = check response.getXmlPayload();
            fail error(errorMessage.toString());
        }
    }

    # Copies a file to another location in fileShare. 
    #
    # + fileShareName - Name of the fileShare
    # + sourceURL - source file url in the fileShare
    # + destFileName - Name of the destination file
    # + destDirectoryPath - Path of the destination in fileShare
    # + return - If success, true. Else an error
    @display {label: "Copy File"}
    remote isolated function copyFile(@display {label: "File Share Name"} string fileShareName,
                                    @display {label: "Source File URL"} string sourceURL,
                                    @display {label: "Destination File Name"} string destFileName,
                                    @display {label: "Destination Directory Path"} string? destDirectoryPath = ())
                                    returns @display {label: "Response"} error? {
        string requestPath = destDirectoryPath is () ? (SLASH + fileShareName + SLASH + destFileName)
            : (SLASH + fileShareName + SLASH + destDirectoryPath + SLASH + destFileName);
        string sourcePath = sourceURL;
        if (self.azureConfig.authorizationMethod == SAS) {
            sourcePath = sourceURL + self.azureConfig.accessKeyOrSAS;
        }
        http:Request request = new;
        map<string> requiredSpecificHeaderes = {[X_MS_COPY_SOURCE]: sourcePath};
        setSpecificRequestHeaders(request, requiredSpecificHeaderes);
        if (self.azureConfig.authorizationMethod == ACCESS_KEY) {
            map<string> requiredURIParameters = {};
            string resourcePathForSharedkeyAuth = destDirectoryPath is () ? (fileShareName + SLASH + destFileName)
                : (fileShareName + SLASH + destDirectoryPath + SLASH + destFileName);
            AuthorizationDetail authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_PUT,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);
        } else {
            requestPath = requestPath.concat(self.azureConfig.accessKeyOrSAS);
        }
        http:Response response = check self.httpClient->put(requestPath, request);
        if (response.statusCode != http:STATUS_ACCEPTED) {
            fail error(check getErrorMessage(response));
        }
    }

    # Upload a file directly to the fileshare.
    #
    # + fileShareName - Name of the fileShare
    # + localFilePath - The path of the file to be uploaded
    # + azureFileName - The name of the file in Azure
    # + azureDirectoryPath - Directory path in Azure
    # + return - If success true. Else an error
    isolated remote function directUpload(@display {label: "File Share Name"} string fileShareName,
                                @display {label: "Local File Path"} string localFilePath,
                                @display {label: "Azure File Name"} string azureFileName,
                                @display {label: "Azure Directory Path"} string? azureDirectoryPath = ())
                                returns @display {label: "Response"} error? {
        file:MetaData fileMetaData = check file:getMetaData(localFilePath);
        int fileSizeInByte = fileMetaData.size;
        check self->createFile(fileShareName, azureFileName, fileSizeInByte, azureDirectoryPath);
        check putRangeInternal(self.httpClient, fileShareName, localFilePath, azureFileName,
                            self.azureConfig, fileSizeInByte, azureDirectoryPath);
    }

    # Uploads a byte array directly to the fileshare.
    #
    # + fileShareName - Name of the fileShare
    # + fileContent - File content as a byte array
    # + azureFileName - Name of the file in Azure
    # + azureDirectoryPath - Directory path in Azure
    # + return - If success true.  Else an error
    isolated remote function directUploadFileAsByteArray(@display {label: "File Share Name"} string fileShareName,
                                @display {label: "File Content (Byte Array)"} byte[] fileContent,
                                @display {label: "Azure File Name"} string azureFileName,
                                @display {label: "Azure Directory Path"} string? azureDirectoryPath = ())
                                returns @display {label: "Response"} error? {
        int fileSizeInByte = fileContent.length();
        check self->createFile(fileShareName, azureFileName, fileSizeInByte, azureDirectoryPath);
        check putRangeAsByteArray(self.httpClient, fileShareName, fileContent, azureFileName,
                            self.azureConfig, fileSizeInByte, azureDirectoryPath);
    }
}
