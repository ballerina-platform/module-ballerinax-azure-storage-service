// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/http;
import ballerina/file;
import ballerina/io;
import ballerina/log;

public client class AzureFileShareClient {
    private string sasToken;
    private string baseUrl;
    private http:Client httpClient;

    # Initalize Azure Client using the provided azureConfiguration by user
    #
    # + azureConfig - AzureConfiguration record
    public function init(AzureConfiguration azureConfig) {
        http:ClientSecureSocket? secureSocketConfig = azureConfig?.secureSocketConfig;
        self.sasToken = azureConfig.sasToken;
        self.baseUrl = azureConfig.baseUrl;
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
    remote function listShares() returns @tainted SharesList|error {
        string getListPath = LIST_SHARE_PATH + AMPERSAND + self.sasToken;
        http:Response response = <http:Response> check self.httpClient->get(getListPath);
        if (response.statusCode == OK) {
            //xml responseBody = check response.getXmlPayload();
            xml formattedXML = check  xmlFormatter(check response.getXmlPayload()/<Shares>);
            json jsonValue = check jsonlib:fromXML(formattedXML);
            return <SharesList>check jsonValue.cloneWithType(SharesList);
        } else {
            fail error(response.getXmlPayload().toString() + ", Azure St Code:" + response.statusCode.toString());
        }
    }

    # Gets the File service properties for the storage account
    #
    # + return - If success, returns FileServicePropertiesList record with details, else returns error
    remote function getFileServiceProperties() returns @tainted FileServicePropertiesList|error {
        string getListPath = GET_FILE_SERVICE_PROPERTIES + AMPERSAND + self.sasToken;
        http:Response response =  <http:Response> check self.httpClient->get(getListPath);
        if (response.statusCode == OK) {
            xml responseBody = check response.getXmlPayload();
            xml formattedXML =  check xmlFormatter(responseBody);
            json jsonValue = check jsonlib:fromXML(formattedXML);
            return <FileServicePropertiesList>check jsonValue.cloneWithType(FileServicePropertiesList);
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Sets the File service properties for the storage account.
    #
    # + fileServicePropertiesList - fileServicePropertiesList record with deatil to be set.
    # + return - If success, returns true, else returns error.
    remote function setFileServiceProperties(FileServicePropertiesList fileServicePropertiesList) returns @tainted boolean|error {
        string requestPath = GET_FILE_SERVICE_PROPERTIES + AMPERSAND + self.sasToken;
        xml requestBody = check convertRecordToXml(fileServicePropertiesList);
        http:Response response = <http:Response>check self.httpClient->put(requestPath, <@untainted>requestBody);
        if (response.statusCode == ACCEPTED) {
            return true;
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }       
    }

    # Creates a new share in a storage account.
    #
    # + parameterList - RequestParameterList record with detail to be used to create a new share.
    # + return - If success, returns true, else returns error.
    remote function createShare(RequestParameterList parameterList) returns @tainted boolean|error {
        string requestPath = SLASH + parameterList.fileShareName + QUESTION_MARK + CREATE_GET_DELETE_SHARE + AMPERSAND + self.sasToken;
        http:Response response = <http:Response>check self.httpClient->put(requestPath, ());
        if (response.statusCode == CREATED) {
            return true;
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Returns all user-defined metadata and system properties of a share.
    #
    # + fileShareName - Name of the FileShare.
    # + return - If success, returns FileServicePropertiesList record with Details, else returns error.
    remote function getShareProperties(string fileShareName) returns @tainted FileServicePropertiesList|error {
        string requestPath = SLASH + fileShareName + CREATE_GET_DELETE_SHARE + AMPERSAND + self.sasToken;
        http:Response response = <http:Response> check self.httpClient->get(requestPath);
        if (response.statusCode == OK) {
            xml responseBody = check response.getXmlPayload();
            xml formattedXML = check xmlFormatter(responseBody);
            json jsonValue = check jsonlib:fromXML(formattedXML);
            return <FileServicePropertiesList>check jsonValue.cloneWithType(FileServicePropertiesList);
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Deletes the share and any files and directories that it contains.
    #
    # + parameterList - RequestParameterList record with detail to be used to delete the share.
    # + return - Return Value Description
    remote function deleteShare(RequestParameterList parameterList) returns @tainted boolean|error {
        string requestPath = SLASH + parameterList.fileShareName + QUESTION_MARK + CREATE_GET_DELETE_SHARE + AMPERSAND + self.sasToken;
        http:Response response = <http:Response> check self.httpClient->delete(requestPath, ());
        if (response.statusCode == ACCEPTED) {
            return true;
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Lists directories within the share or specified directory 
    #
    # + fileShareName - Name of the FileShare.
    # + azureDirectoryPath -Path of the Azure directory.
    # + prefix - Prefix to filter direcoty list by name.
    # + maxResult - Maximum number of result expected.
    # + marker - Marker to be provieded in next request to retrieve left results.
    # + return -  If success, returns DirecotyList record with Details and the marker, else returns error.
    remote function getDirectoryList(string fileShareName, string azureDirectoryPath = "", string prefix = "",       int maxResult = 5000, string marker = "") returns @tainted DirecotyList|error {
        string requestPath = "";
        if (azureDirectoryPath == "") {
            requestPath = SLASH + fileShareName + SLASH + LIST_FILES_DIRECTORIES_PATH + AMPERSAND + self.sasToken;
        } else {
            requestPath = SLASH + fileShareName + SLASH + azureDirectoryPath + SLASH + LIST_FILES_DIRECTORIES_PATH + AMPERSAND + self.sasToken;
        }
        if (prefix != "") {
            requestPath = requestPath + "&prefix=" + prefix;
        }
        if (maxResult > 0 && maxResult != 5000) {
            requestPath = requestPath + "&maxresults=" + maxResult.toString();
        }
        if (marker != "") {
            requestPath = requestPath + "&marker=" + marker;
        }
        http:Response response = <http:Response> check self.httpClient->get(requestPath);
        if (response.statusCode == OK) {
            xml responseBody  = check response.getXmlPayload();
            xml formattedXML = responseBody/<Entries>/<Directory>;
            if (formattedXML.length() == 0) {
                fail error("No directories found in recieved azure response");
            }
            json convertedJsonContent = check jsonlib:fromXML(formattedXML);
            return <DirecotyList>check convertedJsonContent.cloneWithType(DirecotyList);
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Lists files within the share or specified directory 
    #
    # + fileShareName - Name of the FileShare. 
    # + azureDirectoryPath - Path of the Azure directory.
    # + prefix - Prefix to filter File list by name.
    # + maxResult - Maximum number of result expected.
    # + marker -  Marker to be provieded in next request to retrieve left results. 
    # + return -  If success, returns FileList record with Details and the marker, else returns error.
    remote function getFileList(string fileShareName, string azureDirectoryPath = "", string prefix = "", 
                                int maxResult = 5000, string marker = "") returns @tainted FileList|error {
        string requestPath = "";
        if (azureDirectoryPath == "") {
            requestPath = SLASH + fileShareName + SLASH + LIST_FILES_DIRECTORIES_PATH + AMPERSAND + self.sasToken;
        } else {
            requestPath = SLASH + fileShareName + SLASH + azureDirectoryPath + SLASH + LIST_FILES_DIRECTORIES_PATH + AMPERSAND + 
            self.sasToken;
        }
        if (prefix != "") {
            requestPath = requestPath + "&prefix=" + prefix;
        }
        if (maxResult > 0 && maxResult != 5000) {
            requestPath = requestPath + "&maxresults=" + maxResult.toString();
        }
        http:Response response = <http:Response> check self.httpClient->get(requestPath);
        if (response.statusCode == OK) {
            xml responseBody = check response.getXmlPayload();
            xml formattedXML = responseBody/<Entries>/<File>;
                if (formattedXML.length() == 0) {
                    fail error("No files found in recieved azure response");
                }
                json convertedJsonContent = check jsonlib:fromXML(formattedXML);
                return <FileList>check convertedJsonContent.cloneWithType(FileList);
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Creates a directory in the share or parent directory.
    #
    # + parameterList - RequestParameterList record with detail to be used to create a directory.
    # + return - If success, returns true, else returns error.
    remote function createDirectory(RequestParameterList parameterList) returns @tainted boolean|error {
        http:Request request = new;
        string requestPath = "";
        if (parameterList.fileShareName == "") {
            return prepareError("No FileShare name");
        } else {
            requestPath = SLASH + parameterList.fileShareName;
        }
        if (parameterList?.azureDirectoryPath != "") {
            requestPath = requestPath + SLASH + <string>parameterList?.azureDirectoryPath;
        }
        if (parameterList?.newDirectoryName == "") {
            return prepareError("No new directory name provided");
        }
        requestPath = requestPath + SLASH + <string>parameterList?.newDirectoryName + CREATE_DIRECTORY_PATH + AMPERSAND + self.
        sasToken;
        request.setHeader("x-ms-file-permission", "inherit");
        request.setHeader("x-ms-file-attributes", "Directory");
        request.setHeader("x-ms-file-creation-time", "now");
        request.setHeader("x-ms-file-last-write-time", "now");
        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        if (response.statusCode == CREATED) {
            return true;
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Deletes the directory. Only supported for empty directories.
    #
    # + fileShareName - Name of the FileShare.
    # + directoryName - Name of the Direcoty to be deleted.
    # + azureDirectoryPath - Path of the Azure directory.
    # + return - If success, returns true, else returns error.
    remote function deleteDirectory(string fileShareName, string directoryName, string azureDirectoryPath = "") returns @tainted boolean|error {
        http:Request request = new;
        string requestPath = "";
        if (fileShareName == "") {
            return prepareError("No FileShare name");
        } else {
            requestPath = SLASH + fileShareName;
        }
        if (azureDirectoryPath != "") {
            requestPath = requestPath + SLASH + azureDirectoryPath;
        }
        if (directoryName == "") {
            return prepareError("No new directory name provided");
        }
        requestPath = requestPath + SLASH + directoryName + CREATE_DIRECTORY_PATH + AMPERSAND + self.sasToken;
        http:Response response = <http:Response>check self.httpClient->delete(requestPath);
        if (response.statusCode == ACCEPTED) {
            return true;
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Creates a new file or replaces a file.This operation only initializes the file. PutRange should be used to add contents
    #
    # + fileShareName - Name of the fileShare.
    # + fileName - Name of the file.
    # + fileSizeInByte - Size of the file in Bytes.
    # + azureDirectoryPath - Path of the Azure direcoty. 
    # + return - If success, returns true, else returns error.
    remote function createFile(string fileShareName, string azureFileName, int fileSizeInByte, string azureDirectoryPath = "") returns @tainted boolean|error {
        return createFileInternal(self.httpClient, fileShareName, azureFileName, fileSizeInByte, self.
        sasToken, azureDirectoryPath);
    }

    # Writes the content (a range of bytes) to a file initialized earlier.
    #
    # + fileShareName - Name of the FileShare.
    # + localFilePath - Path of the local direcoty. 
    # + azureFileName - Name of the file in azure. 
    # + azureDirectoryPath - Path of the azure directory.
    # + return - If success, returns true, else returns error
    remote function putRange(string fileShareName, string localFilePath, string azureFileName, string azureDirectoryPath = "") returns @tainted boolean|error {
        http:Request request = new;
        string requestPath = "";
        if (fileShareName == "") {
            return prepareError("No fileShare name");
        } else {
            requestPath = SLASH + fileShareName;
        }
        if (azureDirectoryPath != "") {
            requestPath = requestPath + SLASH + azureDirectoryPath;
        }
        if (azureFileName == "") {
            return prepareError("No file name provided");
        }
        request.setFileAsPayload(localFilePath);
        requestPath = requestPath + SLASH + azureFileName + QUESTION_MARK + PUT_RANGE_PATH + AMPERSAND + self.sasToken;
        byte[] range = check request.getBinaryPayload();
        request.setHeader("x-ms-range", "bytes=0-" + (range.length() - 1).toString());
        request.setHeader("Content-Length", range.length().toString());
        request.setHeader("x-ms-write", "Update");
        http:Response response = <http:Response>check self.httpClient->put(requestPath, request);
        if (response.statusCode == CREATED) {
            return true;
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Provides a list of valid ranges (in bytes) for a file.
    #
    # + fileShareName - Name of the FileShare.
    # + fileName - Name of the file name. 
    # + azureDirectoryPath - Path of the Azure directory. 
    # + return - If success, returns RangeList record, else returns error.
    remote function listRange(string fileShareName, string fileName, string azureDirectoryPath = "") returns @tainted 
    RangeList|error {
        string requestPath = "";
        if (azureDirectoryPath == "") {
            requestPath = SLASH + fileShareName + SLASH + fileName + QUESTION_MARK + LIST_FILE_RANGE + AMPERSAND + self.sasToken;
        } else {
            requestPath = SLASH + fileShareName + SLASH + azureDirectoryPath + SLASH + fileName + QUESTION_MARK + LIST_FILE_RANGE + AMPERSAND + 
            self.sasToken;
        }
        http:Response response = <http:Response>check self.httpClient->get(requestPath);
        if (response.statusCode == OK) {
            xml responseBody = check response.getXmlPayload();
                if (responseBody.length() == 0) {
                    fail error("No files found in recieved azure response");
                }
                json convertedJsonContent =check jsonlib:fromXML(responseBody);
                return <RangeList>check convertedJsonContent.cloneWithType(RangeList);
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Deletes a file from the fileshare.
    #
    # + fileShareName - Name of the FileShare.
    # + fileName - Name of the file.
    # + azureDirectoryPath - Path of the Azure directory.
    # + return - If success, returns true, else returns error.
    remote function deleteFile(string fileShareName, string fileName, string azureDirectoryPath = "") returns @tainted boolean|error {
        http:Request request = new;
        string requestPath = "";
        if (fileShareName == "") {
            fail error("No fileShare name");
        } else {
            requestPath = SLASH + fileShareName;
        }
        if (azureDirectoryPath != "") {
            requestPath = requestPath + SLASH + azureDirectoryPath;
        }
        if (fileName == "") {
            fail error("No file name was provided");
        }
        requestPath = requestPath + SLASH + fileName + QUESTION_MARK + self.sasToken;
        http:Response response = <http:Response>check self.httpClient->delete(requestPath);
        if (response.statusCode == ACCEPTED) {
            return true;
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Downloads a file from fileshare to a specified location.
    #
    # + fileShareName - Name of the FileShare. 
    # + fileName - Name of the file.
    # + azureDirectoryPath - Path of azure directory.
    # + localFilePath - Path to the local destination location. 
    # + return -  If success, returns true, else returns error.
    remote function getFile(string fileShareName, string fileName, string azureDirectoryPath = "", string localFilePath = "") returns @tainted boolean|error {
        string requestPath = "";
        //Use ELvis
        if (azureDirectoryPath == "") {
            requestPath = SLASH + fileShareName + SLASH + fileName + QUESTION_MARK + self.sasToken;

        } else {
            requestPath = SLASH + fileShareName + SLASH + azureDirectoryPath + SLASH + fileName + QUESTION_MARK + self.sasToken;
        }
        http:Response response = <http:Response> self.httpClient->get(requestPath);
        if (response.statusCode == OK) {
            byte[] responseBody = check response.getBinaryPayload();
            if (responseBody.length() == 0) {
                fail error("An empty file found in recieved azure response");
            }
            return check writeFile(localFilePath, responseBody);
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Copies a file to another destination in fileShare. 
    #
    # + fileShareName - Name of the fileShare.
    # + sourceURL - source file url from the fileShare.
    # + destFileName - Name of the destination file. 
    # + destDirectoryPath - Path of the destination in fileShare.
    # + return - If success, returns true, else returns error.
    remote function copyFile(string fileShareName, string sourceURL, string destFileName, string destDirectoryPath) returns @tainted boolean|error {
        http:Request request = new;
        string requestPath = "";
        string sourcePath = "";
        if (fileShareName == "") {
            fail  error("No fileShare name");
        } else {
            requestPath = SLASH + fileShareName;
        }
        if (destDirectoryPath != "") {
            requestPath = requestPath + SLASH + destDirectoryPath;
        }
        if (destFileName == "") {
            fail error("No file name provided");
        }
        requestPath = requestPath + SLASH + destFileName + QUESTION_MARK + self.sasToken;
        sourcePath = sourceURL + QUESTION_MARK + self.sasToken;
        request.setHeader("x-ms-copy-source", sourcePath);
        http:Response response = <http:Response> check self.httpClient->put(requestPath, request);
        if (response.statusCode == ACCEPTED) {
            return true;
        } else {
            fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
        }
    }

    remote function directUpload(string fileShareName, string localFilePath, string azureFileName, 
                                 string azureFilePath = "") returns @tainted boolean|error {
        file:MetaData fileMetaData = check file:getMetaData(localFilePath);
        int fileSizeInByte=fileMetaData.size;
        var createFileResponse = createFileInternal(self.httpClient, fileShareName, azureFileName, fileSizeInByte, self.
        sasToken, azureFilePath);
        if (createFileResponse == true) {
            var uploadResult = putRangeInternal(self.httpClient, fileShareName, localFilePath, azureFileName, self.
            sasToken, fileSizeInByte, azureFilePath);
            return uploadResult;
        } else {
            return createFileResponse;
        }

    }
}

function createFileInternal(http:Client httpClient, string fileShareName, string fileName, int fileSizeInByte, 
                            string sasToken, string azureDirectoryPath = "") returns @tainted boolean|error {
    http:Request request = new;
    string requestPath = "";
    if (fileShareName == "") {
        return prepareError("No FileShare name");
    } else {
        requestPath = SLASH + fileShareName;
    }
    if (azureDirectoryPath != "") {
        requestPath = requestPath + SLASH + azureDirectoryPath;
    }
    if (fileName == "") {
        return prepareError("No new file name provided");
    }
    requestPath = requestPath + SLASH + fileName + QUESTION_MARK + sasToken;
    request.setHeader("x-ms-file-permission", "inherit");
    request.setHeader("x-ms-file-attributes", "None");
    request.setHeader("x-ms-file-creation-time", "now");
    request.setHeader("x-ms-file-last-write-time", "now");
    request.setHeader("Content-Length", "0");
    request.setHeader("x-ms-content-length", fileSizeInByte.toString());
    request.setHeader("x-ms-type", "file");
    http:Response response = <http:Response>check httpClient->put(requestPath, request);
    if (response.statusCode == CREATED) {
        io:println("creation ok");
        return true;
    } else {
        fail error(response.getXmlPayload().toString() + " Azure Statue Code:" + response.statusCode.toString());
    }
}

function putRangeInternal(http:Client httpClient, string fileShareName, string localFilePath, string azureFileName, 
                          string sasToken, int fileSizeInByte, string azureDirectoryPath = "") returns @tainted boolean|
error {

    string requestPath = "";
    if (fileShareName == "") {
        return prepareError("No fileShare name");
    } else {
        requestPath = SLASH + fileShareName;
    }
    if (azureDirectoryPath != "") {
        requestPath = requestPath + SLASH + azureDirectoryPath;
    }
    if (azureFileName == "") {
        return prepareError("No file name provided");
    }
    requestPath = requestPath + SLASH + azureFileName + QUESTION_MARK + PUT_RANGE_PATH + AMPERSAND + sasToken;
    stream<io:Block>|io:Error fileStream = io:fileReadBlocksAsStream(localFilePath, 4194304);
    int index = 0;
    int byteLeft = fileSizeInByte;
    boolean update = false;
    if (fileStream is stream<io:Block>) {
        error? e = fileStream.forEach(function(io:Block byteBlock) {
            if (byteLeft > MAX_UPLOADING_BYTE_SIZE) {
                http:Request request = new;
                request.setHeader("x-ms-range", "bytes=" + index.toString() + "-" + (
                index + MAX_UPLOADING_BYTE_SIZE - 1).toString());
                request.setHeader("Content-Length", MAX_UPLOADING_BYTE_SIZE.toString());
                request.setHeader("x-ms-write", "update");
                request.setBinaryPayload(byteBlock);
                var result = httpClient->put(requestPath, request);
                http:Response response = <http:Response>result;
                if (response.statusCode == CREATED) {
                    io:println(byteLeft.toString() + " " + index.toString());
                    index = index + MAX_UPLOADING_BYTE_SIZE - 1;
                    byteLeft = byteLeft - MAX_UPLOADING_BYTE_SIZE;
                    io:println(byteLeft.toString() + " " + index.toString());
                }
            } else if (byteLeft < MAX_UPLOADING_BYTE_SIZE) {
                http:Request requestLast = new;
                byte[] lastone = arrays:slice(byteBlock, 0, fileSizeInByte - index);
                io:println("left size:" + lastone.length().toString());
                requestLast.setBinaryPayload(lastone);
                requestLast.setHeader("x-ms-range", "bytes=" + index.toString() + "-" + (
                fileSizeInByte - 1).toString());
                requestLast.setHeader("Content-Length", byteLeft.toString());
                requestLast.setHeader("x-ms-write", "update");

                requestLast.setBinaryPayload(lastone);
                var resultLast = httpClient->put(requestPath, requestLast);
                if(resultLast is error){
                    //responseLast=<error>resultLast;
                    return;
                }
                http:Response|error responseLast = <http:Response>resultLast;
                if (responseLast is http:Response && responseLast.statusCode == CREATED) {
                    update = true;
                }
                else{
                    log:printError("Fail to upload",x=199);
                }      
            } else {
                update = true;
            }
       });
    }
    if (update == true) {
        return update;
    } else {
        fail error("Upload Failed");
    }
}
