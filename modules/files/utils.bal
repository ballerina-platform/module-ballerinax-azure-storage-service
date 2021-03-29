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

import azure_storage_service.utils as storage_utils;
import ballerina/http;
import ballerina/io;
import ballerina/lang.array;
import ballerina/lang.'xml;
import ballerina/log;
import ballerina/regex;
import ballerina/xmlutils;

# Removes double quotes from an XML object.
#
# + xmlPayload - XML payload
# + return - If success, returns formated xml else error
isolated function removeDoubleQuotesFromXML(xml xmlPayload) returns @tainted xml|error {
    return 'xml:fromString(regex:replaceAll(xmlPayload.toString(), QUOTATION_MARK, EMPTY_STRING));
}

# Coverts records to xml.
#
# + recordContent - Contents to be converted
# + return - If success, returns xml. Else the error.
isolated function convertRecordToXml(anydata recordContent) returns @tainted xml|error {
    json|error convertedContent = recordContent.cloneWithType(json);
    if (convertedContent is json) {
        return xmlutils:fromJSON(convertedContent);
    } else {
        return convertedContent;
    }
}

# Get the error message from the xml response.
#
# + response - Receievd xml response
# + return - Returns error message as a string value
isolated function getErrorMessage(http:Response response) returns @tainted string|error {
    xml errorMessage = check response.getXmlPayload();
    return (errorMessage.toString() + ", Status Code:" + response.statusCode.toString());
}

# Writes the file content to the local destination.
#
# + filePath - Path to the destination direcoty
# + payload - The content to be written
# + return - if success returns true else the error
function writeFile(string filePath, byte[] payload) returns @tainted boolean|error {
    io:WritableByteChannel writeableFile = check io:openWritableFile(filePath);
    int index = 0;
    while (index < payload.length()) {
        int result = check writeableFile.write(payload, index);
        index = index + result;
    }
    return writeableFile.close() ?: true;
}

# Sets the optional request headers.
#
# + request - Request object reference
# + requestHeader - Request headers as a key value map
isolated function setAzureRequestHeaders(http:Request request, RequestHeader requestHeader) {
    request.setHeader(X_MS_HARE_QUOTA, requestHeader?.'x\-ms\-share\-quota.toString());
    request.setHeader(X_MS_ACCESS_TIER, requestHeader?.'x\-ms\-access\-tier.toString());
    request.setHeader(X_MS_ENABLED_PRTOCOLS, requestHeader?.x\-ms\-enabled\-protocols.toString());
}

# Sets required request headers.
# 
# + request - Request object reference
# + specificRequiredHeaders - Request headers as a key value map
isolated function setSpecficRequestHeaders(http:Request request, map<string> specificRequiredHeaders) {
    string[] keys = specificRequiredHeaders.keys();
    foreach string keyItem in keys {
        request.setHeader(keyItem, specificRequiredHeaders.get(keyItem));
    }
}

# Prepares the authorized header for the Shared key authorization.
# 
# + authDetail - The records that includes the necessary detail for the authorization header creation
# + return - Returns error if unsuccessful
isolated function prepareAuthorizationHeaders(AuthorizationDetail authDetail) returns error? {
    map<string> headerMap = populateHeaderMapFromRequest(authDetail.azureRequest);
    URIRecord? test = authDetail?.uriParameterRecord;
    map<string> uriMap = {};
    if (test is ()) {
       uriMap = convertRecordtoStringMap(requiredURIParameters = authDetail.requiredURIParameters);
    } else {
       uriMap = convertRecordtoStringMap(<URIRecord>test, authDetail.requiredURIParameters);
    }
    string azureResourcePath = authDetail?.resourcePath is () ? (EMPTY_STRING) : authDetail?.resourcePath.toString();
    string sharedKeySignature = check storage_utils:generateSharedKeySignature(authDetail.azureConfig
        .accountName, authDetail.azureConfig.accessKeyOrSAS, authDetail.httpVerb, azureResourcePath, uriMap,
        headerMap);
    authDetail.azureRequest.setHeader(AUTHORIZATION, SHARED_KEY + WHITE_SPACE + authDetail.azureConfig.accountName 
        + COLON_SYMBOL + sharedKeySignature);
}

# Converts a record to string type map.
# 
# + uriParameters - The record of type URIRecord
# + requiredURIParameters - The string type map of required URI Parameters
# + return - If success, returns map<string>. Else empty map.
isolated function convertRecordtoStringMap(URIRecord? uriParameters = (), map<string> requiredURIParameters = {}) 
                                           returns map<string> {
    map<string> stringMap = {};
    if (typeof uriParameters is typedesc<ListShareURIParameters>) {
        stringMap[PREFIX] = uriParameters?.prefix.toString();
        stringMap[MARKER] = uriParameters?.marker.toString();
        stringMap[MAX_RESULTS] = uriParameters?.maxresults.toString();
        stringMap[INCLUDE] = uriParameters?.include.toString();
        stringMap[TIMEOUT] = uriParameters?.timeout.toString();
    } else if (typeof uriParameters is typedesc<GetDirectoryListURIParamteres> || typeof uriParameters is 
        typedesc<GetFileListURIParamters>) {
        stringMap[PREFIX] = uriParameters?.prefix.toString();
        stringMap[MARKER] = uriParameters?.marker.toString();
        stringMap[MAX_RESULTS] = uriParameters?.maxresults.toString();
        stringMap[SHARES_SNAPSHOT] = uriParameters?.sharesnapshot.toString();
        stringMap[TIMEOUT] = uriParameters?.timeout.toString();
    } 
    if (requiredURIParameters.length() != 0) {
        string[] keys = requiredURIParameters.keys();
        foreach string keyItem in keys  {
           stringMap[keyItem] = requiredURIParameters.get(keyItem); 
        }
    }
    map<string> filteredMap = {};
    string[] keySet = stringMap.keys();
    foreach string keyItem in keySet {
        string member = stringMap.get(keyItem);
        if (member != EMPTY_STRING) {
            filteredMap[keyItem] = member;
        }
    }
    return filteredMap;
}

# Gets the headers from a request as a map.
# 
# + request - http:Request type object reference
# + return - If success, returns map<string>. Else empty map.
isolated function populateHeaderMapFromRequest(http:Request request) returns @tainted map<string> {
    map<string> headerMap = {};
    request.setHeader(X_MS_VERSION, FILES_AUTHORIZATION_VERSION);
    request.setHeader(X_MS_DATE, storage_utils:getCurrentDate());
    string[] headerNames = request.getHeaderNames();
    foreach var name in headerNames {
        headerMap[name] = getHeaderFromRequest(request, name);
    }
    return headerMap;
}

# Gets the header value from an HTTP request.
#
# + request - HTTP response
# + headerName - Name of the header
# + return - Returns header value
isolated function getHeaderFromRequest(http:Request request, string headerName) returns @tainted string {
    var value = request.getHeader(headerName);
    if (value is string) {
        return value;
    } else {
        return EMPTY_STRING;
    }
}

# Sets the opitional URI parameters.
# 
# + uriRecord - URL parameters as records
# + return - if success returns the appended URI paramteres as a string else an error
isolated function setOptionalURIParametersFromRecord(URIRecord uriRecord) returns @tainted string? {
    string optionalURIs = EMPTY_STRING;
    if (typeof uriRecord is typedesc<ListShareURIParameters>) {
        optionalURIs = uriRecord?.prefix is () ? optionalURIs : (optionalURIs + AMPERSAND + PREFIX + EQUALS_SIGN 
            + uriRecord?.prefix.toString());
        optionalURIs = uriRecord?.marker is () ? optionalURIs : (optionalURIs + AMPERSAND + MARKER + EQUALS_SIGN 
            + uriRecord?.marker.toString());
        optionalURIs = uriRecord?.maxresults is () ? optionalURIs : (optionalURIs + AMPERSAND + MAX_RESULTS 
            + EQUALS_SIGN + uriRecord?.maxresults.toString());
        optionalURIs = uriRecord?.include is () ? optionalURIs : (optionalURIs + AMPERSAND + INCLUDE + EQUALS_SIGN 
            + uriRecord?.include.toString());
        optionalURIs = uriRecord?.timeout is () ? optionalURIs : (optionalURIs + AMPERSAND + TIMEOUT + EQUALS_SIGN 
            + uriRecord?.timeout.toString());
        return optionalURIs;      
    } else if (typeof uriRecord is typedesc<GetDirectoryListURIParamteres> || typeof uriRecord is 
        typedesc<GetFileListURIParamters>) {
        optionalURIs = uriRecord?.prefix is () ? optionalURIs : (optionalURIs + AMPERSAND + PREFIX + EQUALS_SIGN
            + uriRecord?.prefix.toString());
        optionalURIs = uriRecord?.sharesnapshot is () ? optionalURIs : (optionalURIs + AMPERSAND + SHARES_SNAPSHOT 
            + EQUALS_SIGN + uriRecord?.sharesnapshot.toString());
        optionalURIs = uriRecord?.marker is () ? optionalURIs : (optionalURIs + AMPERSAND + MARKER + EQUALS_SIGN 
            + uriRecord?.marker.toString());
        optionalURIs = uriRecord?.maxresults is () ? optionalURIs : (optionalURIs + AMPERSAND + MAX_RESULTS 
            + EQUALS_SIGN + uriRecord?.maxresults.toString());
        optionalURIs = uriRecord?.timeout is () ? optionalURIs : (optionalURIs + AMPERSAND + TIMEOUT + EQUALS_SIGN 
            + uriRecord?.timeout.toString());
        return optionalURIs;
    } else  {
        return;
    }
}

# Send request to create a file in the azure file share with the given size in byte.
# 
# + httpClient - Http client type reference 
# + fileShareName - Name of the fileShare
# + fileName - Name of the File in Azure to be created
# + fileSizeInByte - File Size
# + azureConfig - Azure Configuration
# + azureDirectoryPath - Directory path in Azure to the file
# + return - if success returns true as a string else the error
function createFileInternal(http:Client httpClient, string fileShareName, string fileName, int fileSizeInByte, 
                            AzureFileServiceConfiguration azureConfig, string? azureDirectoryPath = ()) 
                            returns @tainted boolean|error {
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
    if (azureConfig.authorizationMethod == ACCESS_KEY) {
        map<string> requiredURIParameters ={}; 
        string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + fileName) 
            : (fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);
            AuthorizationDetail  authorizationDetail = {
                azureRequest: request,
                azureConfig: azureConfig,
                httpVerb: http:HTTP_PUT,
                resourcePath: resourcePathForSharedkeyAuth,
                requiredURIParameters: requiredURIParameters
            };
            check prepareAuthorizationHeaders(authorizationDetail);     
        } else {
            requestPath = requestPath.concat(azureConfig.accessKeyOrSAS);
        }
    http:Response response = <http:Response> check httpClient->put(requestPath, request);
    if (response.statusCode == http:STATUS_CREATED) {
        return true;
    } else {
        fail error(check getErrorMessage(response));
    }
}

# Send request to create a file in the azure file share with the given size in byte.
# 
# + httpClient - Http client type reference 
# + fileShareName - Name of the fileShare
# + localFilePath - Path of the file in local that is uploaded to azure
# + azureFileName - Name of the File in Azure to be created
# + fileSizeInByte - File Size
# + azureConfig - Azure Configuration
# + azureDirectoryPath - Directory path in Azure to the file
# + return - if success returns true else the error
function putRangeInternal(http:Client httpClient, string fileShareName, string localFilePath, string azureFileName, 
                            AzureFileServiceConfiguration azureConfig, int fileSizeInByte, 
                            string? azureDirectoryPath = ()) returns @tainted boolean|error {
    string requestPath = SLASH + fileShareName;
    requestPath = azureDirectoryPath is () ? requestPath : (requestPath + SLASH + azureDirectoryPath);
    requestPath = requestPath + SLASH + azureFileName + QUESTION_MARK + PUT_RANGE_PATH;
    stream<io:Block, io:Error> fileStream = check io:fileReadBlocksAsStream(localFilePath, MAX_UPLOADING_BYTE_SIZE);
    int index = 0;
    boolean isFirstRequest = true;
    int remainingBytesAmount = fileSizeInByte;
    boolean updateStatusFlag = false;
        error? e = fileStream.forEach(function(io:Block byteBlock) {
            if (remainingBytesAmount > MAX_UPLOADING_BYTE_SIZE) {
                http:Request request = new;
                addPutRangeMandatoryHeaders(index, request, (index + MAX_UPLOADING_BYTE_SIZE), byteBlock);
                if (azureConfig.authorizationMethod == ACCESS_KEY) {
                    addPutRangeHeadersForSharedKey(request, fileShareName, azureFileName, azureConfig, 
                        azureDirectoryPath);      
                } else {
                    if (isFirstRequest) {
                        string tokenWithAmphasand = AMPERSAND.concat(azureConfig.accessKeyOrSAS.substring(1));
                        requestPath = requestPath.concat(tokenWithAmphasand);
                        isFirstRequest = false;
                    } 
                }
                http:Response response = <http:Response> checkpanic httpClient->put(requestPath, request);
                if (response.statusCode == http:STATUS_CREATED) {
                    index = index + MAX_UPLOADING_BYTE_SIZE;
                    remainingBytesAmount = remainingBytesAmount - MAX_UPLOADING_BYTE_SIZE;
                }
            } else if (remainingBytesAmount < MAX_UPLOADING_BYTE_SIZE) {
                byte[] lastUploadRequest = array:slice(byteBlock, 0, fileSizeInByte - index);
                http:Request lastRequest = new;
                addPutRangeMandatoryHeaders(index, lastRequest, fileSizeInByte, lastUploadRequest);
                if (azureConfig.authorizationMethod == ACCESS_KEY) {
                    addPutRangeHeadersForSharedKey(lastRequest, fileShareName, azureFileName, azureConfig, 
                        azureDirectoryPath);  
                } else {
                    if (isFirstRequest) {
                        string tokenWithAmphasand = AMPERSAND.concat(azureConfig.accessKeyOrSAS.substring(1));
                        requestPath = requestPath.concat(tokenWithAmphasand);
                        isFirstRequest = false;
                    } 
                }
                http:Response responseLast = <http:Response> checkpanic httpClient->put(requestPath, lastRequest);
                if (responseLast.statusCode == http:STATUS_CREATED) {
                    updateStatusFlag = true;
                } else {
                    xml errorMessage = checkpanic responseLast.getXmlPayload();
                    log:printError(errorMessage.toString(), statusCode = responseLast.statusCode);
                }
            } else {
                updateStatusFlag = true;
            }
        });
    return updateStatusFlag;
}

# Set mandatory headers for putRange request.
# 
# + startIndex - Starting index of the byte content
# + request - HTTP request 
# + lastIndex - Last inded of the byte content
# + byteContent - Byte array of content
isolated function addPutRangeMandatoryHeaders(int startIndex, http:Request request, int lastIndex, byte[] byteContent) {
    map<string> requiredSpecificHeaders = {
        [X_MS_RANGE]: string `bytes=${startIndex.toString()}-${(lastIndex - 1).toString()}`,
        [CONTENT_LENGTH]: byteContent.length().toString(),
        [X_MS_WRITE]: UPDATE 
    };
    log:print("Uplodaing Byte-Range: " + requiredSpecificHeaders.get(X_MS_RANGE).toString());
    setSpecficRequestHeaders(request, requiredSpecificHeaders);
    request.setBinaryPayload(byteContent);
}

# Set sharedKey related headers for putRange request.
# 
# + request - HTTP request
# + fileShareName - Fileshare name
# + azureFileName - File name in azure
# + azureConfig - Azure configuration
# + azureDirectoryPath - Directory path in azure
isolated function addPutRangeHeadersForSharedKey(http:Request request, string fileShareName, string azureFileName, 
                                                 AzureFileServiceConfiguration azureConfig, string? azureDirectoryPath = 
                                                 ()) {
    map<string> requiredURIParameters = {}; 
    requiredURIParameters[COMP] = RANGE;
    request.setHeader(CONTENT_TYPE, APPLICATION_STREAM);
    request.setHeader(X_MS_VERSION, FILES_AUTHORIZATION_VERSION);
    request.setHeader(X_MS_DATE, storage_utils:getCurrentDate());
    string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + azureFileName) : 
        (fileShareName + SLASH + azureDirectoryPath + SLASH + azureFileName);
    AuthorizationDetail authorizationDetail = {
        azureRequest: request,
        azureConfig: azureConfig,
        httpVerb: http:HTTP_PUT,
        resourcePath: resourcePathForSharedkeyAuth,
        requiredURIParameters: requiredURIParameters
    };
    checkpanic prepareAuthorizationHeaders(authorizationDetail); 
}