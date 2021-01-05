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
import ballerina/http;

public client class Client {
    private string sasToken;
    private string baseUrl;
    http:Client azureClient;

    # Initalize Azure Client using the provided azureConfiguration by user
    #
    # + azureConfig - AzureConfiguration record
    public function init(AzureConfiguration azureConfig) {
        http:ClientSecureSocket? result = azureConfig?.secureSocketConfig;
        self.sasToken = azureConfig.sasToken;
        self.baseUrl = azureConfig.baseUrl;
        if (result is http:ClientSecureSocket) {
            self.azureClient = new (self.baseUrl, {
                http1Settings: {chunking: http:CHUNKING_NEVER},
                secureSocket: result
            });
        } else {
            self.azureClient = new (self.baseUrl, {http1Settings: {chunking: http:CHUNKING_NEVER}});
        }
    }

    # Lists all the file shares in the  storage account
    #
    # + return - If success, returns ShareList record with basic details, else returns error
    remote function listShares() returns @tainted SharesList|Error {
        string getListPath = LIST_SHARE_PATH + "&" + self.sasToken;
        var result = self.azureClient->get(getListPath);
        if (result is error) {
            return prepareError(result.toString());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == OK) {
            var responseBody = <xml>response.getXmlPayload();
            xml|error formattedXML = xmlFormatter(responseBody/<Shares>);
            if (formattedXML is xml) {
                json|error jsonValue = jsonlib:fromXML(formattedXML);
                if (jsonValue is json) {
                    var resultList = jsonValue.cloneWithType(SharesList);
                    if (resultList is SharesList) {
                        return resultList;
                    } else {
                        return prepareError("Conversion error");
                    }

                } else {
                    return prepareError("No Valid json");
                }

            } else {
                return prepareError("xmlFormatter error", formattedXML);
            }
        } else {
            return prepareError(response.reasonPhrase + ", Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Gets the File service properties for the storage account
    #
    # + return - If success, returns FileServicePropertiesList record with details, else returns error
    remote function getFileServiceProperties() returns @tainted FileServicePropertiesList|Error {
        string getListPath = GET_FILE_SERVICE_PROPERTIES + "&" + self.sasToken;
        var result = self.azureClient->get(getListPath);
        if (result is error) {
            return prepareError(result.toString());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == OK) {
            var responseBody = <xml>response.getXmlPayload();
            xml|error formattedXML = xmlFormatter(responseBody);
            if (formattedXML is xml) {
                json|error jsonValue = jsonlib:fromXML(formattedXML);
                if (jsonValue is json) {
                    var resultList = jsonValue.cloneWithType(FileServicePropertiesList);
                    if (resultList is FileServicePropertiesList) {
                        return resultList;
                    } else {
                        return prepareError("Conversion error");
                    }

                } else {
                    return prepareError("No Valid json");
                }

            } else {
                return prepareError("xmlFormatter error", formattedXML);
            }
        } else {
            return prepareError(response.reasonPhrase + ", Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Sets the File service properties for the storage account.
    #
    # + fileServicePropertiesList - fileServicePropertiesList record with deatil to be set.
    # + return - If success, returns true, else returns error.
    remote function setFileServiceProperties(FileServicePropertiesList fileServicePropertiesList) returns @tainted boolean|
    Error {
        string requestPath = GET_FILE_SERVICE_PROPERTIES + "&" + self.sasToken;
        xml|error requestBody = convertRecordToXml(fileServicePropertiesList);
        if (requestBody is error) {
            return prepareError(requestBody.message());
        } else {
            var result = self.azureClient->put(requestPath, <@untainted>requestBody);
            if (result is error) {
                return prepareError(result.message());
            }
            http:Response response = <http:Response>result;
            if (response.statusCode == ACCEPTED) {
                return true;
            } else {
                xml responseBody = <xml>response.getXmlPayload();
                xml reason = responseBody/<Message>;
                return prepareError(reason.toString() + ", Azure Statue Code:" + response.statusCode.toString());
            }

        }
    }

    # Creates a new share in a storage account.
    #
    # + parameterList - RequestParameterList record with detail to be used to create a new share.
    # + return - If success, returns true, else returns error.
    remote function createShare(RequestParameterList parameterList) returns @tainted boolean|Error {
        string requestPath = "/" + parameterList.fileShareName + "?" + CREATE_GET_DELETE_SHARE + "&" + self.sasToken;
        var result = self.azureClient->put(requestPath, ());
        if (result is error) {
            return prepareError(result.message());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == CREATED) {
            return true;
        } else {
            return prepareError(getErrorMessage(response) + ", Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Returns all user-defined metadata and system properties of a share.
    #
    # + fileShareName - Name of the FileShare.
    # + return - If success, returns FileServicePropertiesList record with Details, else returns error.
    remote function getShareProperties(string fileShareName) returns @tainted FileServicePropertiesList|Error {
        string requestPath = "/" + fileShareName + CREATE_GET_DELETE_SHARE + "&" + self.sasToken;
        var result = self.azureClient->get(requestPath);
        if (result is error) {
            return prepareError(result.toString());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == OK) {
            var responseBody = <xml>response.getXmlPayload();
            xml|error formattedXML = xmlFormatter(responseBody);
            if (formattedXML is xml) {
                json|error jsonValue = jsonlib:fromXML(formattedXML);
                if (jsonValue is json) {
                    var resultList = jsonValue.cloneWithType(FileServicePropertiesList);
                    if (resultList is FileServicePropertiesList) {
                        return resultList;
                    } else {
                        return prepareError("Conversion error");
                    }

                } else {
                    return prepareError("No Valid json");
                }

            } else {
                return prepareError("xmlFormatter error", formattedXML);
            }
        } else {
            return prepareError(response.reasonPhrase + ", Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Deletes the share and any files and directories that it contains.
    #
    # + parameterList - RequestParameterList record with detail to be used to delete the share.
    # + return - Return Value Description
    remote function deleteShare(RequestParameterList parameterList) returns @tainted boolean|Error {
        string requestPath = "/" + parameterList.fileShareName + "?" + CREATE_GET_DELETE_SHARE + "&" + self.sasToken;
        var result = self.azureClient->delete(requestPath, ());
        if (result is error) {
            return prepareError(result.message());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == ACCEPTED) {
            return true;
        } else {
            return prepareError(getErrorMessage(response) + ", Azure Statue Code:" + response.statusCode.toString());
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
    remote function getDirectoryList(string fileShareName, string azureDirectoryPath = "", string prefix = "", 
                                     int maxResult = 5000, string marker = "") returns @tainted Error|DirecotyList {

        string requestPath = "";
        if (azureDirectoryPath == "") {
            requestPath = "/" + fileShareName + "/" + LIST_FILES_DIRECTORIES_PATH + "&" + self.sasToken;

        } else {
            requestPath = "/" + fileShareName + "/" + azureDirectoryPath + "/" + LIST_FILES_DIRECTORIES_PATH + "&" + 
            self.sasToken;
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

        var result = self.azureClient->get(requestPath);
        if (result is error) {
            return prepareError(result.toString());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == OK) {
            var responseBody = <xml>response.getXmlPayload();
            xml|error formattedXML = responseBody/<Entries>/<Directory>;
            if (formattedXML is xml) {
                if (formattedXML.length() == 0) {
                    return prepareError("No directories found in recieved azure response");
                }
                json|error convertedJsonContent = jsonlib:fromXML(formattedXML);
                if (convertedJsonContent is json) {

                    var resultList = convertedJsonContent.cloneWithType(DirecotyList);
                    if (resultList is DirecotyList) {
                        return resultList;
                    } else {
                        return prepareError("XML to Json conversion error");
                    }
                } else {
                    return prepareError("No valid json found");
                }
            } else {
                return prepareError("XmlFormatter error", formattedXML);
            }
        } else {
            return prepareError(response.reasonPhrase + ", Azure Statue Code:" + response.statusCode.toString());
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
                                int maxResult = 5000, string marker = "") returns @tainted FileList|Error {

        string requestPath = "";
        if (azureDirectoryPath == "") {
            requestPath = "/" + fileShareName + "/" + LIST_FILES_DIRECTORIES_PATH + "&" + self.sasToken;

        } else {
            requestPath = "/" + fileShareName + "/" + azureDirectoryPath + "/" + LIST_FILES_DIRECTORIES_PATH + "&" + 
            self.sasToken;
        }
        if (prefix != "") {
            requestPath = requestPath + "&prefix=" + prefix;
        }
        if (maxResult > 0 && maxResult != 5000) {
            requestPath = requestPath + "&maxresults=" + maxResult.toString();
        }

        var result = self.azureClient->get(requestPath);
        if (result is error) {
            return prepareError(result.toString());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == OK) {
            var responseBody = <xml>response.getXmlPayload();
            xml|error formattedXML = responseBody/<Entries>/<File>;
            if (formattedXML is xml) {
                if (formattedXML.length() == 0) {
                    return prepareError("No files found in recieved azure response");
                }
                json|error convertedJsonContent = jsonlib:fromXML(formattedXML);
                if (convertedJsonContent is json) {
                    var resultList = convertedJsonContent.cloneWithType(FileList);
                    if (resultList is FileList) {
                        return resultList;
                    } else {
                        return prepareError("XML to Json conversion error");
                    }
                } else {
                    return prepareError("No valid json found");
                }
            } else {
                return prepareError("XmlFormatter error", formattedXML);
            }
        } else {
            return prepareError(response.reasonPhrase + ", Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Creates a directory in the share or parent directory.
    #
    # + parameterList - RequestParameterList record with detail to be used to create a directory.
    # + return - If success, returns true, else returns error.
    remote function createDirectory(RequestParameterList parameterList) returns @tainted boolean|Error {
        http:Request request = new;
        string requestPath = "";
        if (parameterList.fileShareName == "") {
            return prepareError("No FileShare name");
        } else {
            requestPath = "/" + parameterList.fileShareName;
        }
        if (parameterList?.azureDirectoryPath != "") {
            requestPath = requestPath + "/" + <string>parameterList?.azureDirectoryPath;
        }
        if (parameterList?.newDirectoryName == "") {
            return prepareError("No new directory name provided");
        }
        requestPath = requestPath + "/" + <string>parameterList?.newDirectoryName + CREATE_DIRECTORY_PATH + "&" + self.
        sasToken;
        request.setHeader("x-ms-file-permission", "inherit");
        request.setHeader("x-ms-file-attributes", "Directory");
        request.setHeader("x-ms-file-creation-time", "now");
        request.setHeader("x-ms-file-last-write-time", "now");
        var result = self.azureClient->put(requestPath, request);
        if (result is error) {
            return prepareError(result.message());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == CREATED) {
            return true;
        } else {
            return prepareError(getErrorMessage(response) + ", Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Deletes the directory. Only supported for empty directories.
    #
    # + fileShareName - Name of the FileShare.
    # + directoryName - Name of the Direcoty to be deleted.
    # + azureDirectoryPath - Path of the Azure directory.
    # + return - If success, returns true, else returns error.
    remote function deleteDirectory(string fileShareName, string directoryName, string azureDirectoryPath = "") returns @tainted boolean|
    Error {
        http:Request request = new;
        string requestPath = "";
        if (fileShareName == "") {
            return prepareError("No FileShare name");
        } else {
            requestPath = "/" + fileShareName;
        }
        if (azureDirectoryPath != "") {
            requestPath = requestPath + "/" + azureDirectoryPath;
        }
        if (directoryName == "") {
            return prepareError("No new directory name provided");
        }
        requestPath = requestPath + "/" + directoryName + CREATE_DIRECTORY_PATH + "&" + self.sasToken;
        var result = self.azureClient->delete(requestPath);
        if (result is error) {
            return prepareError(result.message());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == ACCEPTED) {
            return true;
        } else {
            return prepareError(getErrorMessage(response) + ", Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Creates a new file or replaces a file.This operation only initializes the file. PutRange should be used to add contents
    #
    # + fileShareName - Name of the fileShare.
    # + fileName - Name of the file.
    # + fileSizeInByte - Size of the file in Bytes.
    # + azureDirectoryPath - Path of the Azure direcoty. 
    # + return - If success, returns true, else returns error.
    remote function createFile(string fileShareName, string fileName, int fileSizeInByte, string azureDirectoryPath = "") returns @tainted boolean|
    Error {
        http:Request request = new;
        string requestPath = "";
        if (fileShareName == "") {
            return prepareError("No FileShare name");
        } else {
            requestPath = "/" + fileShareName;
        }
        if (azureDirectoryPath != "") {
            requestPath = requestPath + "/" + azureDirectoryPath;
        }
        if (fileName == "") {
            return prepareError("No new file name provided");
        }
        requestPath = requestPath + "/" + fileName + "?" + self.sasToken;
        request.setHeader("x-ms-file-permission", "inherit");
        request.setHeader("x-ms-file-attributes", "None");
        request.setHeader("x-ms-file-creation-time", "now");
        request.setHeader("x-ms-file-last-write-time", "now");
        request.setHeader("x-ms-content-length", fileSizeInByte.toString());
        request.setHeader("x-ms-type", "file");
        var result = self.azureClient->put(requestPath, request);
        if (result is error) {
            return prepareError(result.message());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == CREATED) {
            return true;
        } else {
            return prepareError(getErrorMessage(response) + ", Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Writes the content (a range of bytes) to a file initialized earlier.
    #
    # + fileShareName - Name of the FileShare.
    # + localFilePath - Path of the local direcoty. 
    # + azureFileName - Name of the file in azure. 
    # + azureDirectoryPath - Path of the azure directory.
    # + return - If success, returns true, else returns error
    remote function putRange(string fileShareName, string localFilePath, string azureFileName, 
                             string azureDirectoryPath = "") returns @tainted boolean|Error {
        http:Request request = new;
        string requestPath = "";
        if (fileShareName == "") {
            return prepareError("No fileShare name");
        } else {
            requestPath = "/" + fileShareName;
        }
        if (azureDirectoryPath != "") {
            requestPath = requestPath + "/" + azureDirectoryPath;
        }
        if (azureFileName == "") {
            return prepareError("No file name provided");
        }
        request.setFileAsPayload(localFilePath);
        requestPath = requestPath + "/" + azureFileName + "?" + PUT_RANGE_PATH + "&" + self.sasToken;
        var range = request.getBinaryPayload();
        if (range is byte[]) {
            request.setHeader("x-ms-range", "bytes=0-" + (range.length() - 1).toString());
            request.setHeader("Content-Length", range.length().toString());
            request.setHeader("x-ms-write", "Update");
        }
        var result = self.azureClient->put(requestPath, request);

        if (result is error) {
            return prepareError(result.message());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == CREATED) {
            return true;
        } else {
            return prepareError(getErrorMessage(response) + ", Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Provides a list of valid ranges (in bytes) for a file.
    #
    # + fileShareName - Name of the FileShare.
    # + fileName - Name of the file name. 
    # + azureDirectoryPath - Path of the Azure directory. 
    # + return - If success, returns RangeList record, else returns error.
    remote function listRange(string fileShareName, string fileName, string azureDirectoryPath = "") returns @tainted 
    RangeList|Error {

        string requestPath = "";
        if (azureDirectoryPath == "") {
            requestPath = "/" + fileShareName + "/" + fileName + "?" + LIST_FILE_RANGE + "&" + self.sasToken;

        } else {
            requestPath = "/" + fileShareName + "/" + azureDirectoryPath + "/" + fileName + "?" + LIST_FILE_RANGE + "&" + 
            self.sasToken;
        }
        var result = self.azureClient->get(requestPath);
        if (result is error) {
            return prepareError(result.toString());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == OK) {
            var responseBody = <xml>response.getXmlPayload();
            xml|error formattedXML = responseBody;
            if (formattedXML is xml) {
                if (formattedXML.length() == 0) {
                    return prepareError("No files found in recieved azure response");
                }
                json|error convertedJsonContent = jsonlib:fromXML(formattedXML);
                if (convertedJsonContent is json) {
                    var resultList = convertedJsonContent.cloneWithType(RangeList);
                    if (resultList is RangeList) {
                        return resultList;
                    } else {
                        return prepareError("XML to Json conversion error");
                    }
                } else {
                    return prepareError("No valid json found");
                }
            } else {
                return prepareError("XmlFormatter error", formattedXML);
            }
        } else {
            return prepareError(response.reasonPhrase + ", Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Deletes a file from the fileshare.
    #
    # + fileShareName - Name of the FileShare.
    # + fileName - Name of the file.
    # + azureDirectoryPath - Path of the Azure directory.
    # + return - If success, returns true, else returns error.
    remote function deleteFile(string fileShareName, string fileName, string azureDirectoryPath = "") returns @tainted boolean|
    Error {
        http:Request request = new;
        string requestPath = "";
        if (fileShareName == "") {
            return prepareError("No FileShare name");
        } else {
            requestPath = "/" + fileShareName;
        }
        if (azureDirectoryPath != "") {
            requestPath = requestPath + "/" + azureDirectoryPath;
        }
        if (fileName == "") {
            return prepareError("Nof file name was provided");
        }
        requestPath = requestPath + "/" + fileName + "?" + self.sasToken;
        var result = self.azureClient->delete(requestPath);
        if (result is error) {
            return prepareError(result.message());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == ACCEPTED) {
            return true;
        } else {
            return prepareError(getErrorMessage(response) + ", Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Downloads a file from fileshare to a specified location.
    #
    # + fileShareName - Name of the FileShare. 
    # + fileName - Name of the file.
    # + azureDirectoryPath - Path of azure directory.
    # + localFilePath - Path to the local destination location. 
    # + return -  If success, returns true, else returns error.
    remote function getFile(string fileShareName, string fileName, string azureDirectoryPath = "", 
                            string localFilePath = "") returns @tainted boolean|Error {
        string requestPath = "";
        if (azureDirectoryPath == "") {
            requestPath = "/" + fileShareName + "/" + fileName + "?" + self.sasToken;

        } else {
            requestPath = "/" + fileShareName + "/" + azureDirectoryPath + "/" + fileName + "?" + self.sasToken;
        }
        var result = self.azureClient->get(requestPath);
        if (result is error) {
            return prepareError(result.toString());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == OK) {
            var responseBody = response.getBinaryPayload();
            if (responseBody is byte[]) {
                if (responseBody.length() == 0) {
                    return prepareError("An empty file found in recieved azure response");
                }
                var output = writeFile(localFilePath, responseBody);
                if (output is error) {

                    return prepareError(output.toString());
                } else {
                    return output;
                }
            } else {
                return prepareError("Error in payload extraction", responseBody);
            }
        } else {
            return prepareError(response.reasonPhrase + ", Azure Statue Code:" + response.statusCode.toString());
        }
    }

    # Copies a file to another destination in fileShare. 
    #
    # + fileShareName - Name of the fileShare.
    # + sourceURL - source file url from the fileShare.
    # + destFileName - Name of the destination file. 
    # + destDirectoryPath - Path of the destination in fileShare.
    # + return - If success, returns true, else returns error.
    remote function copyFile(string fileShareName, string sourceURL, string destFileName, string destDirectoryPath) returns @tainted boolean|
    Error {
        http:Request request = new;
        string requestPath = "";
        string sourcePath = "";
        if (fileShareName == "") {
            return prepareError("No fileShare name");
        } else {
            requestPath = "/" + fileShareName;
        }
        if (destDirectoryPath != "") {
            requestPath = requestPath + "/" + destDirectoryPath;
        }
        if (destFileName == "") {
            return prepareError("No file name provided");
        }
        requestPath = requestPath + "/" + destFileName + "?" + self.sasToken;
        sourcePath = sourceURL + "?" + self.sasToken;
        request.setHeader("x-ms-copy-source", sourcePath);
        var result = self.azureClient->put(requestPath, request);
        if (result is error) {
            return prepareError(result.message());
        }
        http:Response response = <http:Response>result;
        if (response.statusCode == ACCEPTED) {
            return true;
        } else {
            return prepareError(getErrorMessage(response) + ", Azure Statue Code:" + response.statusCode.toString());
        }
    }
}
