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
import ballerina/jsonutils as jsonlib;
import ballerina/lang.array as arrays;
import ballerina/lang.'string as stringLib;
import azure_storage_service.utils as storage_utils;
import ballerina/http;
import ballerina/file;
import ballerina/io;
import ballerina/log;

public client class FileShareClient {
    private string sharedKeyOrSASToken;
    private string baseUrl;
    private http:Client httpClient;
    private boolean isSharedKeyUsed;
    private AzureConfiguration azureConfig;

    # Initalize Azure Client using the provided azureConfiguration by user
    #
    # + azureConfig - AzureConfiguration record
    public function init(AzureConfiguration azureConfig) {
        http:ClientSecureSocket? secureSocketConfig = azureConfig?.secureSocketConfig;
        self.sharedKeyOrSASToken = stringLib:substring(azureConfig.sharedKeyOrSASToken, startIndex = 1);
        self.baseUrl = string `https://${azureConfig.storageAccountName}.file.core.windows.net/`;
        self.isSharedKeyUsed = azureConfig.isSharedKeySet;
        self.azureConfig = azureConfig;
        if (secureSocketConfig is http:ClientSecureSocket) {
            self.httpClient = new (self.baseUrl, {
                http1Settings: {chunking: http:CHUNKING_NEVER},
                secureSocket: secureSocketConfig
            });
        } else {
            self.httpClient = new (self.baseUrl, {http1Settings: {chunking: http:CHUNKING_NEVER}});
        }
    }

    # Lists directories within the share or specified directory 
    #
    # + fileShareName - Name of the FileShare.
    # + azureDirectoryPath -Path of the Azure directory.
    # + uriParameters - Map of the optional URI parameters record.
    # + return -  If success, returns DirectoryList record with Details and the marker, else returns error.
    remote function getDirectoryList(string fileShareName, string? azureDirectoryPath = (), GetFileListURIParamteres uriParameters = {}) returns @tainted DirectoryList|error {
        string requestPath = azureDirectoryPath is () ? (SLASH + fileShareName + SLASH + LIST_FILES_DIRECTORIES_PATH) : SLASH + fileShareName + SLASH + azureDirectoryPath + SLASH + 
        LIST_FILES_DIRECTORIES_PATH;
        string? optinalURIParameters = setoptionalURIParametersFromRecord(uriParameters);
        requestPath = optinalURIParameters is () ? requestPath : (requestPath + optinalURIParameters);
        http:Request request = new;
        if(self.isSharedKeyUsed) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[RESTYPE] = DIRECTORY;
            requiredURIParameters[COMP] = LIST;
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH) : (fileShareName + SLASH + azureDirectoryPath + SLASH);
            AuthorizationDetail  authorizationDetail = {
                azureRequest:request,
                azureConfig:self.azureConfig,
                httpVerb: http:HTTP_GET,
                uriParameterRecord: uriParameters,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            prepareAuthorizationHeaders(authorizationDetail);       
        } else {
            requestPath = stringLib:concat(requestPath, AMPERSAND + self.sharedKeyOrSASToken); 
        }

        http:Response response = <http:Response>check self.httpClient->get(<@untainted>requestPath, request);
        if (response.statusCode == http:STATUS_OK ) {
            xml responseBody = check response.getXmlPayload();
            xml formattedXML = responseBody/<Entries>/<Directory>;
            if (formattedXML.length() == 0) {
                fail error(NO_DIRECTORIES_FOUND);
            }
            json convertedJsonContent = check jsonlib:fromXML(formattedXML);
            return <DirectoryList>check convertedJsonContent.cloneWithType(DirectoryList);
        } else {
            fail error(getErrorMessage(response));
        }
    }

    # Lists files within the share or specified directory 
    #
    # + fileShareName - Name of the FileShare. 
    # + azureDirectoryPath - Path of the Azure directory.
    # + uriParameters - Map of the optional URI parameters record.
    # + return -  If success, returns FileList record with Details and the marker, else returns error.
    remote function getFileList(string fileShareName, string? azureDirectoryPath = (), GetFileListURIParamteres uriParameters = {}) returns @tainted FileList|error {
        string requestPath = azureDirectoryPath is () ? (SLASH + fileShareName + SLASH + LIST_FILES_DIRECTORIES_PATH) : (SLASH + fileShareName + SLASH + azureDirectoryPath + SLASH + 
        LIST_FILES_DIRECTORIES_PATH);
        string? optinalURIParameters = setoptionalURIParametersFromRecord(uriParameters);
        requestPath = optinalURIParameters is () ? requestPath : (requestPath + optinalURIParameters);
        http:Request request = new;
        if(self.isSharedKeyUsed) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[RESTYPE] = DIRECTORY;
            requiredURIParameters[COMP] = LIST;
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH) : (fileShareName + SLASH + azureDirectoryPath + SLASH);
            AuthorizationDetail  authorizationDetail = {
                azureRequest:request,
                azureConfig:self.azureConfig,
                httpVerb: http:HTTP_GET,
                uriParameterRecord: uriParameters,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            prepareAuthorizationHeaders(authorizationDetail);        
        } else {
            requestPath = stringLib:concat(requestPath, AMPERSAND + self.sharedKeyOrSASToken); 
        }
        http:Response response = <http:Response>check self.httpClient->get(<@untainted>requestPath, request);
        if (response.statusCode == http:STATUS_OK ) {
            xml responseBody = check response.getXmlPayload();
            xml formattedXML = responseBody/<Entries>/<File>;
            if (formattedXML.length() == 0) {
                fail error(NO_FILE_FOUND);
            }
            json convertedJsonContent = check jsonlib:fromXML(formattedXML);
            return <FileList>check convertedJsonContent.cloneWithType(FileList);
        } else {
            fail error(getErrorMessage(response));
        }
    }

    # Creates a directory in the share or parent directory.
    #
    # + fileShareName - Name of the fileshare.
    # + newDirectoryName - New directory name in azure.
    # + azureDirectoryPath - Path to the new directory.
    # + return - If success, returns true, else returns error.
    remote function createDirectory(string fileShareName, string newDirectoryName, string? azureDirectoryPath = ()) returns @tainted boolean|error {
        string requestPath = SLASH + fileShareName;
        requestPath = azureDirectoryPath is () ? requestPath : (requestPath + SLASH + azureDirectoryPath);
        requestPath = requestPath + SLASH + newDirectoryName + CREATE_DELETE_DIRECTORY_PATH;
        http:Request request = new;
        map<string> requiredHeaderes = {
            [X_MS_FILE_PERMISSION]: INHERIT,
            [x_MS_FILE_ATTRIBUTES]: DIRECTORY,
            [X_MS_FILE_CREATION_TIME]: NOW,
            [X_MS_FILE_LAST_WRITE_TIME]: NOW
        };
        setSpecficRequestHeaders(request, requiredHeaderes);
        if(self.isSharedKeyUsed) {
            map<string> requiredURIParameters = {}; 
            requiredURIParameters[RESTYPE] = DIRECTORY;
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + newDirectoryName) : (fileShareName + SLASH + azureDirectoryPath + SLASH + newDirectoryName);
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_PUT,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            prepareAuthorizationHeaders(authorizationDetail);       
        } else {
            requestPath = stringLib:concat(requestPath, AMPERSAND + self.sharedKeyOrSASToken); 
        }
        http:Response response = <http:Response>check self.httpClient->put(requestPath, request);
        if (response.statusCode == http:STATUS_CREATED) {
            return true;
        } else {
            fail error(getErrorMessage(response));
        }
    }

    # Deletes the directory. Only supported for empty directories.
    #
    # + fileShareName - Name of the FileShare.
    # + directoryName - Name of the Direcoty to be deleted.
    # + azureDirectoryPath - Path of the Azure directory.
    # + return - If success, returns true, else returns error.
    remote function deleteDirectory(string fileShareName, string directoryName, string? azureDirectoryPath = ()) 
            returns @tainted boolean|error {
        string requestPath = SLASH + fileShareName;
        requestPath = azureDirectoryPath is () ? requestPath : (requestPath + SLASH + azureDirectoryPath);
        requestPath = requestPath + SLASH + directoryName + CREATE_DELETE_DIRECTORY_PATH;
        http:Request request = new;
        if(self.isSharedKeyUsed) {
            map<string> requiredURIParameters ={}; 
            requiredURIParameters[RESTYPE] = DIRECTORY;
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + directoryName) : (fileShareName + SLASH + azureDirectoryPath + SLASH + directoryName);
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_DELETE,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            prepareAuthorizationHeaders(authorizationDetail);       
        } else {
            requestPath = stringLib:concat(requestPath, AMPERSAND + self.sharedKeyOrSASToken); 
        }
        http:Response response = <http:Response>check self.httpClient->delete(requestPath, request);
        if (response.statusCode == http:STATUS_ACCEPTED) {
            return true;
        } else {
            fail error(getErrorMessage(response));
        }
    }

    # Creates a new file or replaces a file.This operation only initializes the file. PutRange should be used to add contents
    #
    # + fileShareName - Name of the fileShare.
    # + azureFileName - Name of the file.
    # + fileSizeInByte - Size of the file in Bytes.
    # + azureDirectoryPath - Path of the Azure direcoty. 
    # + return - If success, returns true, else returns error.
    remote function createFile(string fileShareName, string azureFileName, int fileSizeInByte, 
        string? azureDirectoryPath = ()) returns @tainted boolean|error {
        return createFileInternal(self.httpClient, fileShareName, azureFileName, fileSizeInByte, self.azureConfig, 
        azureDirectoryPath);
    }

    # Writes the content (a range of bytes) to a file initialized earlier.
    #
    # + fileShareName - Name of the FileShare.
    # + localFilePath - Path of the local direcoty. 
    # + azureFileName - Name of the file in azure. 
    # + azureDirectoryPath - Path of the azure directory.
    # + return - If success, returns true, else returns error
    remote function putRange(string fileShareName, string localFilePath, string azureFileName, 
            string? azureDirectoryPath = ()) returns @tainted boolean|error {
        file:MetaData fileMetaData = check file:getMetaData(localFilePath);
        int fileSizeInByte = fileMetaData.size;
        return check putRangeInternal(self.httpClient, fileShareName, localFilePath, azureFileName, self.azureConfig, 
        fileSizeInByte, azureDirectoryPath);
    }

    # Provides a list of valid ranges (in bytes) for a file.
    #
    # + fileShareName - Name of the FileShare.
    # + fileName - Name of the file name. 
    # + azureDirectoryPath - Path of the Azure directory. 
    # + return - If success, returns RangeList record, else returns error.
    remote function listRange(string fileShareName, string fileName, string? azureDirectoryPath = ()) returns @tainted 
            RangeList|error {
        string requestPath = azureDirectoryPath is () ? (SLASH + fileShareName + SLASH + fileName + QUESTION_MARK + 
        LIST_FILE_RANGE) : (SLASH + fileShareName + SLASH + azureDirectoryPath + SLASH + 
        fileName + QUESTION_MARK + LIST_FILE_RANGE);
        http:Request request = new();
         if(self.isSharedKeyUsed) {
            map<string> requiredURIParameters ={}; 
            requiredURIParameters[COMP] = RANGE_LIST;
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + fileName) : (fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_GET,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            prepareAuthorizationHeaders(authorizationDetail);     
        } else {
            requestPath = stringLib:concat(requestPath, AMPERSAND + self.sharedKeyOrSASToken); 
        }
        http:Response response = <http:Response>check self.httpClient->get(requestPath,request);
        if (response.statusCode == http:STATUS_OK ) {
            xml responseBody = check response.getXmlPayload();
            if (responseBody.length() == 0) {
                fail error(NO_RANAGE_LIST_FOUND);
            }
            json convertedJsonContent = check jsonlib:fromXML(responseBody);
            return <RangeList>check convertedJsonContent.cloneWithType(RangeList);
        } else {
            fail error(getErrorMessage(response));
        }
    }

    # Deletes a file from the fileshare.
    #
    # + fileShareName - Name of the FileShare.
    # + fileName - Name of the file.
    # + azureDirectoryPath - Path of the Azure directory.
    # + return - If success, returns true, else returns error.
    remote function deleteFile(string fileShareName, string fileName, string? azureDirectoryPath = ()) 
            returns @tainted boolean|error {
        http:Request request = new;
        string requestPath = SLASH + fileShareName;
        requestPath = azureDirectoryPath is () ? requestPath : (requestPath + SLASH + azureDirectoryPath);
        requestPath = requestPath + SLASH + fileName;
         if(self.isSharedKeyUsed) {
            map<string> requiredURIParameters ={}; 
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + fileName) : (fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_DELETE,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            prepareAuthorizationHeaders(authorizationDetail);      
        } else {
            requestPath = stringLib:concat(requestPath, QUESTION_MARK + self.sharedKeyOrSASToken); 
        }
        http:Response response = <http:Response>check self.httpClient->delete(requestPath, request);
        if (response.statusCode == http:STATUS_ACCEPTED) {
            return true;
        } else {
            fail error(getErrorMessage(response));
        }
    }

    # Downloads a file from fileshare to a specified location.
    #
    # + fileShareName - Name of the FileShare. 
    # + fileName - Name of the file.
    # + azureDirectoryPath - Path of azure directory.
    # + localFilePath - Path to the local destination location. 
    # + return -  If success, returns true, else returns error.
    remote function getFile(string fileShareName, string fileName, string localFilePath, 
            string? azureDirectoryPath = ()) returns @tainted boolean|error {
        string requestPath = azureDirectoryPath is () ? (SLASH + fileShareName + SLASH + fileName) : (SLASH + fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);    
        http:Request request = new;
        if(self.isSharedKeyUsed) {
            map<string> requiredURIParameters ={}; 
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + fileName) : (fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_GET,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            prepareAuthorizationHeaders(authorizationDetail);      
        } else {
            requestPath = stringLib:concat(requestPath, QUESTION_MARK + self.sharedKeyOrSASToken); 
        }
        http:Response response = <http:Response>check self.httpClient->get(requestPath, request);
        if (response.statusCode == http:STATUS_OK ) {
            byte[] responseBody = check response.getBinaryPayload();
            if (responseBody.length() == 0) {
                fail error(AN_EMPTY_FILE_FOUND);
            }
            return writeFile(localFilePath, responseBody);
        } else {
            fail error(getErrorMessage(response));
        }
    }

    # Copies a file to another destination in fileShare. 
    #
    # + fileShareName - Name of the fileShare.
    # + sourceURL - source file url from the fileShare.
    # + destFileName - Name of the destination file. 
    # + destDirectoryPath - Path of the destination in fileShare.
    # + return - If success, returns true, else returns error.
    remote function copyFile(string fileShareName, string sourceURL, string destFileName, string? destDirectoryPath = ()) 
            returns @tainted boolean|error {

        string requestPath = destDirectoryPath is () ? (SLASH + fileShareName + SLASH + destFileName) : (SLASH + fileShareName + SLASH + destDirectoryPath + SLASH + destFileName);
        string sourcePath = sourceURL;
        if(!self.isSharedKeyUsed) {
            sourcePath = sourceURL+ QUESTION_MARK + self.sharedKeyOrSASToken;
        }
        http:Request request = new;
        map<string> requiredSpecificHeaderes = {[X_MS_COPY_SOURCE]: sourcePath};
        setSpecficRequestHeaders(request, requiredSpecificHeaderes);
        if(self.isSharedKeyUsed) {
            map<string> requiredURIParameters ={}; 
            string resourcePathForSharedkeyAuth = destDirectoryPath is () ? (fileShareName + SLASH + destFileName) : (fileShareName + SLASH + destDirectoryPath + SLASH + destFileName);
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_PUT,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            prepareAuthorizationHeaders(authorizationDetail);       
        } else {
            requestPath = stringLib:concat(requestPath, QUESTION_MARK + self.sharedKeyOrSASToken); 
        }
        http:Response response = <http:Response>check self.httpClient->put(requestPath, request);
        if (response.statusCode == http:STATUS_ACCEPTED) {
            return true;
        } else {
            fail error(getErrorMessage(response));
        }
    }

    remote function directUpload(string fileShareName, string localFilePath, string azureFileName, 
            string? azureFilePath = ()) returns @tainted boolean|error {
        file:MetaData fileMetaData = check file:getMetaData(localFilePath);
        int fileSizeInByte = fileMetaData.size;
        var createFileResponse = self->createFile(fileShareName, azureFileName, fileSizeInByte, azureFilePath);
        if (createFileResponse == true) {
            var uploadResult = putRangeInternal(self.httpClient, fileShareName, localFilePath, azureFileName,self.azureConfig, fileSizeInByte, azureFilePath);
            return uploadResult;
        } else {
            return createFileResponse;
        }

    }
}

function createFileInternal(http:Client httpClient, string fileShareName, string fileName, int fileSizeInByte, 
        AzureConfiguration azureConfig, string? azureDirectoryPath = ()) returns @tainted boolean|error {
    string requestPath = SLASH + fileShareName;
    requestPath = azureDirectoryPath is () ? requestPath : (requestPath + SLASH + azureDirectoryPath);
    requestPath = requestPath + SLASH + fileName;
    http:Request request = new;
    map<string> requiredSpecificHeaderes = {
        [X_MS_FILE_PERMISSION]: INHERIT,
        [x_MS_FILE_ATTRIBUTES]: NONE,
        [X_MS_FILE_CREATION_TIME]: NOW,
        [X_MS_FILE_LAST_WRITE_TIME]: NOW,
        [CONTENT_LENGTH]: ZERO,
        [X_MS_CONTENT_LENGTH]: fileSizeInByte.toString(),
        [X_MS_TYPE]: FILE_TYPE
    };
    setSpecficRequestHeaders(request, requiredSpecificHeaderes);
    if(azureConfig.isSharedKeySet) {
            map<string> requiredURIParameters ={}; 
            string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + fileName) : (fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: azureConfig,
                httpVerb: http:HTTP_PUT,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            prepareAuthorizationHeaders(authorizationDetail);     
        } else {
            requestPath = stringLib:concat(requestPath, azureConfig.sharedKeyOrSASToken); 
        }
    http:Response response = <http:Response>check httpClient->put(requestPath, request);
    if (response.statusCode == http:STATUS_CREATED) {
        return true;
    } else {
        fail error(getErrorMessage(response));
    }
}

function putRangeInternal(http:Client httpClient, string fileShareName, string localFilePath, string azureFileName, 
        AzureConfiguration azureConfig, int fileSizeInByte, string? azureDirectoryPath = ()) returns @tainted boolean|error {
    string requestPath = SLASH + fileShareName;
    requestPath = azureDirectoryPath is () ? requestPath : (requestPath + SLASH + azureDirectoryPath);
    requestPath = requestPath + SLASH + azureFileName + QUESTION_MARK + PUT_RANGE_PATH;
    stream<io:Block> fileStream = check io:fileReadBlocksAsStream(localFilePath, MAX_UPLOADING_BYTE_SIZE);
    int index = 0;
    boolean isFirstRequest = true;
    int remainingBytesAmount = fileSizeInByte;
    boolean updateStatusFlag = false;
        error? e = fileStream.forEach(function(io:Block byteBlock) {
            if (remainingBytesAmount > MAX_UPLOADING_BYTE_SIZE) {
                http:Request request = new;
                map<string> requiredSpecificHeaderes = {
                    [X_MS_RANGE]: string `bytes=${index.toString()}-${(index + MAX_UPLOADING_BYTE_SIZE - 1).toString()}`,
                    [CONTENT_LENGTH]: MAX_UPLOADING_BYTE_SIZE.toString(),
                    [X_MS_WRITE]: UPDATE 
                };
                log:print("X-Range: "+requiredSpecificHeaderes.get(X_MS_RANGE).toString());
                setSpecficRequestHeaders(request, requiredSpecificHeaderes);
                request.setBinaryPayload(byteBlock);
                if(azureConfig.isSharedKeySet) {
                    map<string> requiredURIParameters = {}; 
                    requiredURIParameters[COMP] = RANGE;
                    request.setHeader(CONTENT_TYPE, APPLICATION_STREAM);
                    request.setHeader(X_MS_VERSION, FILES_AUTHORIZATION_VERSION);
                    request.setHeader(X_MS_DATE, storage_utils:getCurrentDate());
                    string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + azureFileName) : (fileShareName + SLASH + azureDirectoryPath + SLASH + azureFileName);
                    AuthorizationDetail  authorizationDetail = {
                        azureRequest: request,
                        azureConfig: azureConfig,
                        httpVerb: http:HTTP_PUT,
                        resourcePath: resourcePathForSharedkeyAuth,
                        requiredURIParameters: requiredURIParameters
                    };
                    prepareAuthorizationHeaders(authorizationDetail);       
                } else {
                    if(isFirstRequest){
                        string tokenWithAmphasand = stringLib:concat(AMPERSAND, stringLib:substring(azureConfig.sharedKeyOrSASToken, startIndex = 1));
                        requestPath = stringLib:concat(requestPath,tokenWithAmphasand);
                        isFirstRequest = false;
                    } 
                }
                http:Response response = <http:Response>checkpanic httpClient->put(requestPath, request);
                if (response.statusCode == http:STATUS_CREATED) {
                    index = index + MAX_UPLOADING_BYTE_SIZE;
                    remainingBytesAmount = remainingBytesAmount - MAX_UPLOADING_BYTE_SIZE;
                }
            } else if (remainingBytesAmount < MAX_UPLOADING_BYTE_SIZE) {
                log:print(remainingBytesAmount.toString());
                byte[] lastUploadRequest = arrays:slice(byteBlock, 0, fileSizeInByte - 
                index);
                
                map<string> lastRequiredSpecificHeaderes = {
                    [X_MS_RANGE]: string `bytes=${index.toString()}-${(fileSizeInByte - 1).toString()}`,
                    [CONTENT_LENGTH]: lastUploadRequest.length().toString(),
                    [X_MS_WRITE]: UPDATE
                };
                log:print("x-Range :" + lastRequiredSpecificHeaderes.get(X_MS_RANGE).toString());
                http:Request lastRequest = new;
                setSpecficRequestHeaders(lastRequest, lastRequiredSpecificHeaderes);
                lastRequest.setBinaryPayload(lastUploadRequest);

                if(azureConfig.isSharedKeySet) {
                    map<string> requiredURIParameters = {}; 
                    requiredURIParameters[COMP] = RANGE;
                    lastRequest.setHeader(CONTENT_TYPE, APPLICATION_STREAM);
                    lastRequest.setHeader(X_MS_VERSION, FILES_AUTHORIZATION_VERSION);
                    lastRequest.setHeader(X_MS_DATE, storage_utils:getCurrentDate());
                    string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + azureFileName) : (fileShareName + SLASH + azureDirectoryPath + SLASH + azureFileName);
                    AuthorizationDetail  authorizationDetail = {
                        azureRequest: lastRequest,
                        azureConfig: azureConfig,
                        httpVerb: http:HTTP_PUT,
                        resourcePath: resourcePathForSharedkeyAuth,
                        requiredURIParameters: requiredURIParameters
                    };
                    prepareAuthorizationHeaders(authorizationDetail);    
                } else {
                    if(isFirstRequest){
                        string tokenWithAmphasand = stringLib:concat(AMPERSAND, stringLib:substring(azureConfig.sharedKeyOrSASToken, startIndex = 1));
                        requestPath = stringLib:concat(requestPath, tokenWithAmphasand);
                        isFirstRequest = false;
                    } 

                }
                http:Response responseLast = <http:Response>checkpanic httpClient->put(requestPath, lastRequest);
                if (responseLast.statusCode == http:STATUS_CREATED) {
                    updateStatusFlag = true;
                } else {
                    log:printError(responseLast.getXmlPayload().toString(), statusCode = 
                    responseLast.statusCode);
                }
            } else {
                updateStatusFlag = true;
            }
        });
    return updateStatusFlag;
}


public client class ServiceLevelClient {
    private string sharedKeyOrSASToken;
    private string baseUrl;
    private http:Client httpClient;
    private boolean isSharedKeyUsed;
    private AzureConfiguration azureConfig;

    # Initalize Azure Client using the provided azureConfiguration by user
    #
    # + azureConfig - AzureConfiguration record
    public function init(AzureConfiguration azureConfig) {
        http:ClientSecureSocket? secureSocketConfig = azureConfig?.secureSocketConfig;
        self.sharedKeyOrSASToken = stringLib:substring(azureConfig.sharedKeyOrSASToken, startIndex = 1);
        self.baseUrl = string `https://${azureConfig.storageAccountName}.file.core.windows.net/`;
        self.isSharedKeyUsed = azureConfig.isSharedKeySet;
        self.azureConfig = azureConfig;
        if (secureSocketConfig is http:ClientSecureSocket) {
            self.httpClient = new (self.baseUrl, {
                http1Settings: {chunking: http:CHUNKING_NEVER},
                secureSocket: secureSocketConfig
            });
        } else {
            self.httpClient = new (self.baseUrl, {http1Settings: {chunking: http:CHUNKING_NEVER}});
        }
    }

    # Lists all the file shares in the  storage account
    #
    # + return - If success, returns ShareList record with basic details, else returns an error
    remote function listShares(ListShareURIParameters uriParameters = {}) returns @tainted SharesList|error {
        string? appendedUriParameters = setoptionalURIParametersFromRecord(uriParameters);
        string getListPath = appendedUriParameters is () ? (LIST_SHARE_PATH ) : (LIST_SHARE_PATH + appendedUriParameters);
        http:Request request = new;
        if(self.isSharedKeyUsed){
            map<string> requiredURIParameters = {};
            requiredURIParameters[COMP] = LIST;
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http: HTTP_GET,
                uriParameterRecord: uriParameters,
                requiredURIParameters: requiredURIParameters
            };
            prepareAuthorizationHeaders(authorizationDetail);     
        } else {
            getListPath = stringLib:concat(getListPath, AMPERSAND + self.sharedKeyOrSASToken); 
        }
        http:Response response = <http:Response>check self.httpClient->get(<@untainted>getListPath,request);
        if (response.statusCode == http:STATUS_OK ) {
            xml formattedXML = check xmlFormatter(check response.getXmlPayload()/<Shares>);
            json jsonValue = check jsonlib:fromXML(formattedXML);
            return <SharesList>check jsonValue.cloneWithType(SharesList);
        } else {
            fail error(getErrorMessage(response));
        }
    }

    # Gets the File service properties for the storage account
    #
    # + return - If success, returns FileServicePropertiesList record with details, else returns error
    remote function getFileServiceProperties() returns @tainted FileServicePropertiesList|error {
        string getListPath = GET_FILE_SERVICE_PROPERTIES;
        map<string> requiredURIParameters = {}; 
        http:Request request = new;
        if(self.isSharedKeyUsed) {
            requiredURIParameters[RESTYPE] = SERVICE;
            requiredURIParameters[COMP] = PROPERTIES;     
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_GET,
                requiredURIParameters: requiredURIParameters
            };
            prepareAuthorizationHeaders(authorizationDetail);    
        } else {
            getListPath = stringLib:concat(getListPath, AMPERSAND + self.sharedKeyOrSASToken); 
        }
        http:Response response = <http:Response>check self.httpClient->get(getListPath, request);
        if (response.statusCode == http:STATUS_OK ) {
            xml responseBody = check response.getXmlPayload();
            xml formattedXML = check xmlFormatter(responseBody);
            json jsonValue = check jsonlib:fromXML(formattedXML);
            return <FileServicePropertiesList>check jsonValue.cloneWithType(FileServicePropertiesList);
        } else {
            fail error(getErrorMessage(response));
        }
    }

    # Sets the File service properties for the storage account.
    #
    # + fileServicePropertiesList - fileServicePropertiesList record with deatil to be set.
    # + return - If success, returns true, else returns error.
    remote function setFileServiceProperties(FileServicePropertiesList fileServicePropertiesList) 
            returns @tainted boolean|error {
        string requestPath = GET_FILE_SERVICE_PROPERTIES;
        xml requestBody = check convertRecordToXml(fileServicePropertiesList);
        http:Request request = new;
        request.setXmlPayload(<@untainted>requestBody);
        byte[] payload = check request.getBinaryPayload();
        request.setHeader(CONTENT_LENGTH, payload.length().toString());
        request.setHeader(CONTENT_TYPE, APPLICATION_XML);
        if(self.isSharedKeyUsed){
            map<string> requiredURIParameters = {}; 
            requiredURIParameters[RESTYPE] = SERVICE;
            requiredURIParameters[COMP] = PROPERTIES;
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_PUT,
                requiredURIParameters: requiredURIParameters
            };
            prepareAuthorizationHeaders(authorizationDetail);        
        } else {
            requestPath = stringLib:concat(requestPath, AMPERSAND + self.sharedKeyOrSASToken); 
        }
        http:Response response = <http:Response>check self.httpClient->put(requestPath, request);
        if (response.statusCode == http:STATUS_ACCEPTED) {
            return true;
        } else {
            fail error(getErrorMessage(response));
        }
    }

    # Creates a new share in a storage account.
    #
    # + fileShareName - Name of the fileshare.
    # + CreateShareHeaders - map of the user defined optional headers.
    # + return - If success, returns true, else returns error.
    remote function createShare(string fileShareName, CreateShareHeaders createShareHeaders = {}) 
            returns @tainted boolean|error {
        string requestPath = SLASH + fileShareName + QUESTION_MARK + CREATE_GET_DELETE_SHARE;
        http:Request request = new;
        setAzureRequestHeaders(request, createShareHeaders);
        if(self.isSharedKeyUsed) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[RESTYPE] = SHARE;
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_PUT,
                requiredURIParameters: requiredURIParameters,
                resourcePath: fileShareName

            };
            prepareAuthorizationHeaders(authorizationDetail); 
        } else {
            requestPath = stringLib:concat(requestPath, AMPERSAND + self.sharedKeyOrSASToken); 
        }
        http:Response response = <http:Response>check self.httpClient->put(<@untainted>requestPath, request);
        if (response.statusCode == http:STATUS_CREATED) {
            return true;
        } else {
            fail error(getErrorMessage(response));
        }
    }

    # Returns all user-defined metadata and system properties of a share.
    #
    # + fileShareName - Name of the FileShare.
    # + return - If success, returns FileServicePropertiesList record with Details, else returns error.
    remote function getShareProperties(string fileShareName) returns @tainted FileServicePropertiesList|error {
        string requestPath = SLASH + fileShareName + CREATE_GET_DELETE_SHARE;
        http:Request request = new;
        if(self.isSharedKeyUsed) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[RESTYPE] = SHARE;
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_GET,
                requiredURIParameters: requiredURIParameters,
                resourcePath: fileShareName
            };
            prepareAuthorizationHeaders(authorizationDetail);       
        } else {
            requestPath = stringLib:concat(requestPath, AMPERSAND + self.sharedKeyOrSASToken); 
        }
        http:Response response = <http:Response>check self.httpClient->get(requestPath, request);
        if (response.statusCode == http:STATUS_OK ) {
            xml responseBody = check response.getXmlPayload();
            xml formattedXML = check xmlFormatter(responseBody);
            json jsonValue = check jsonlib:fromXML(formattedXML);
            return <FileServicePropertiesList>check jsonValue.cloneWithType(FileServicePropertiesList);
        } else {
            fail error(getErrorMessage(response));
        }
    }

    # Deletes the share and any files and directories that it contains.
    #
    # + fileShareName - Name of the Fileshare.
    # + return - Return Value Description
    remote function deleteShare(string fileShareName) returns @tainted boolean|error {
        string requestPath = SLASH + fileShareName + QUESTION_MARK + CREATE_GET_DELETE_SHARE;
        http:Request request = new;
        if(self.isSharedKeyUsed) {
            map<string> requiredURIParameters = {};
            requiredURIParameters[RESTYPE] = SHARE;
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: self.azureConfig,
                httpVerb: http:HTTP_DELETE,
                requiredURIParameters: requiredURIParameters,
                resourcePath: fileShareName
            };
            prepareAuthorizationHeaders(authorizationDetail);        
        } else {
            requestPath = stringLib:concat(requestPath, AMPERSAND + self.sharedKeyOrSASToken); 
        }
        http:Response response = <http:Response>check self.httpClient->delete(requestPath, request);
        if (response.statusCode == http:STATUS_ACCEPTED) {
            return true;
        } else {
            fail error(getErrorMessage(response));
        }
    }
}
