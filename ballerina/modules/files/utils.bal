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
import ballerina/xmldata;

# Removes double quotes from an XML object.
#
# + xmlPayload - XML payload
# + return - If success, returns formatted xml else error
isolated function removeDoubleQuotesFromXML(xml xmlPayload) returns xml|ProcessingError {
    string cleanedStringXMLObject = regex:replaceAll(xmlPayload.toString(), QUOTATION_MARK, EMPTY_STRING);
    do {
        return check 'xml:fromString(cleanedStringXMLObject);
    } on fail error e {
        return error ProcessingError("Error while formatiing XML", e);
    }
}

# Converts records to xml.
#
# + recordContent - Contents to be converted
# + return - If success, returns xml. Else the error.
isolated function convertRecordToXml(anydata recordContent) returns xml|ProcessingError {
    json|error convertedContent = recordContent.cloneWithType(json);
    if (convertedContent is json) {
        var xmlData = xmldata:fromJson(convertedContent);
        if (xmlData is xml) {
            return xmlData;
        } else {
            return error ProcessingError("Error while converting record to json", xmlData);
        }
    } else {
        return error ProcessingError("Error while converting record to json", convertedContent);
    }
}

# Check HTTP response and generate errors as required.
#
# + response - Http response to inspect
# + return - If checks are failed returns error
isolated function checkAndHandleErrors(http:Response response) returns ServerError|ClientError? {
    int statusCode = response.statusCode;
    if (statusCode == http:STATUS_OK
        || statusCode == http:STATUS_CREATED
        || statusCode == http:STATUS_ACCEPTED
        || statusCode == http:STATUS_NO_CONTENT) {
    } else if (response.getXmlPayload() is xml) {
        return createErrorFromXMLResponse(response);
    } else {
        return error ServerError("Undefined error occured", httpStatus = statusCode,
            errorCode = "Undefined", message = "Unknown");
    }
}

# Create error from xml response.
#
# + response - Http response to construct error from
# + return - FileServerError or FileServiceErrorGeneric type of error
isolated function createErrorFromXMLResponse(http:Response response) returns ServerError|ClientError {
    string errorCode = "undefined";
    string message = "unknown";
    if response.getXmlPayload() is xml {
        xml xmlResponse = check response.getXmlPayload();
        errorCode = (xmlResponse/<Code>/*).toString();
        message = (xmlResponse/<Message>/*).toString();
    }
    int statusCode = response.statusCode;

    match statusCode {
        http:STATUS_CONFLICT => {
            return error ConflictError("Conflict occurred.", httpStatus = 409, errorCode = errorCode, message = message);
        }
        http:STATUS_NOT_FOUND => {
            return error NotFoundError("Resource not found.", httpStatus = 404, errorCode = errorCode, message = message);
        }
        http:STATUS_BAD_REQUEST => {
            return error BadRequestError("Bad request received.", httpStatus = 400, errorCode = errorCode, message = message);
        }
        http:STATUS_INTERNAL_SERVER_ERROR => {
            return error InternalServerError("Internal server error occurred.", httpStatus = 500, errorCode = errorCode, message = message);
        }
        http:STATUS_FORBIDDEN => {
            return error ForbiddenError("Forbidden. ", httpStatus = 403, errorCode = errorCode, message = message);
        }
        _ => {
            return error ServerError("Undefined error occured", httpStatus = statusCode, errorCode = errorCode,
            message = message);
        }
    }
}

# Writes the file content to the local destination.
#
# + filePath - Path to the destination directory
# + payload - The content to be written
# + return - if success returns true else the error
isolated function writeFile(string filePath, byte[] payload) returns io:Error? {
    io:WritableByteChannel writeableFile = check io:openWritableFile(filePath);
    int index = 0;
    while (index < payload.length()) {
        int result = check writeableFile.write(payload, index);
        index = index + result;
    }
    return writeableFile.close();
}

# Sets the optional request headers.
#
# + request - Request object reference
# + requestHeaders - Request headers as a key value map
isolated function setAzureRequestHeaders(http:Request request, RequestHeaders requestHeaders) {
    request.setHeader(X_MS_HARE_QUOTA, requestHeaders?.'x\-ms\-share\-quota.toString());
    request.setHeader(X_MS_ACCESS_TIER, requestHeaders?.'x\-ms\-access\-tier.toString());
    request.setHeader(X_MS_ENABLED_PROTOCOLS, requestHeaders?.x\-ms\-enabled\-protocols.toString());
}

# Sets required request headers.
#
# + request - Request object reference
# + specificRequiredHeaders - Request headers as a key value map
isolated function setSpecificRequestHeaders(http:Request request, map<string> specificRequiredHeaders) {
    string[] keys = specificRequiredHeaders.keys();
    foreach string keyItem in keys {
        request.setHeader(keyItem, specificRequiredHeaders.get(keyItem));
    }
}

# Prepares the authorized header for the Shared key authorization.
#
# + authDetail - The records that includes the necessary detail for the authorization header creation
# + return - Returns error if unsuccessful
isolated function prepareAuthorizationHeaders(AuthorizationDetail authDetail) returns ProcessingError? {
    map<string> headerMap = populateHeaderMapFromRequest(authDetail.azureRequest);
    URIRecord? uriRecord = authDetail?.uriParameterRecord;
    map<string> uriMap = {};
    if (uriRecord is ()) {
        uriMap = convertRecordtoStringMap(requiredURIParameters = authDetail.requiredURIParameters);
    } else {
        uriMap = convertRecordtoStringMap(<URIRecord>uriRecord, authDetail.requiredURIParameters);
    }
    string azureResourcePath = authDetail?.resourcePath is () ? (EMPTY_STRING) : authDetail?.resourcePath.toString();
    string|error sharedKeySignature = storage_utils:generateSharedKeySignature(authDetail.azureConfig
        .accountName, authDetail.azureConfig.accessKeyOrSAS, authDetail.httpVerb, azureResourcePath, uriMap,
        headerMap);
    if sharedKeySignature is error {
        return error ProcessingError("Error while generating shared key signature", sharedKeySignature);
    }
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
    } else if (typeof uriParameters is typedesc<GetDirectoryListURIParameters> || typeof uriParameters is
        typedesc<GetFileListURIParameters>) {
        stringMap[PREFIX] = uriParameters?.prefix.toString();
        stringMap[MARKER] = uriParameters?.marker.toString();
        stringMap[MAX_RESULTS] = uriParameters?.maxresults.toString();
        stringMap[SHARES_SNAPSHOT] = uriParameters?.sharesnapshot.toString();
        stringMap[TIMEOUT] = uriParameters?.timeout.toString();
    }
    if (requiredURIParameters.length() != 0) {
        string[] keys = requiredURIParameters.keys();
        foreach string keyItem in keys {
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
isolated function populateHeaderMapFromRequest(http:Request request) returns map<string> {
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
isolated function getHeaderFromRequest(http:Request request, string headerName) returns string {
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
isolated function setOptionalURIParametersFromRecord(URIRecord uriRecord) returns string? {
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
    } else if (typeof uriRecord is typedesc<GetDirectoryListURIParameters> || typeof uriRecord is
        typedesc<GetFileListURIParameters>) {
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
    } else {
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
isolated function createFileInternal(http:Client httpClient, string fileShareName, string fileName, int fileSizeInByte,
        ConnectionConfig azureConfig, string? azureDirectoryPath = ()) returns Error? {
    string requestPath = SLASH + fileShareName;
    requestPath = azureDirectoryPath is () ? requestPath : (requestPath + SLASH + azureDirectoryPath);
    requestPath = requestPath + SLASH + fileName;
    http:Request request = new;
    map<string> requiredSpecificHeaders = {
        [X_MS_FILE_PERMISSION] : INHERIT,
        [x_MS_FILE_ATTRIBUTES] : NONE,
        [X_MS_FILE_CREATION_TIME] : NOW,
        [X_MS_FILE_LAST_WRITE_TIME] : NOW,
        [CONTENT_LENGTH] : ZERO,
        [X_MS_CONTENT_LENGTH] : fileSizeInByte.toString(),
        [X_MS_TYPE] : FILE_TYPE
    };
    setSpecificRequestHeaders(request, requiredSpecificHeaders);
    if (azureConfig.authorizationMethod == ACCESS_KEY) {
        map<string> requiredURIParameters = {};
        string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH + fileName)
            : (fileShareName + SLASH + azureDirectoryPath + SLASH + fileName);
        AuthorizationDetail authorizationDetail = {
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
    http:Response response = <http:Response>check httpClient->put(requestPath, request);
    check checkAndHandleErrors(response);
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
isolated function putRangeInternal(http:Client httpClient, string fileShareName, string localFilePath,
        string azureFileName, ConnectionConfig azureConfig,
        int fileSizeInByte, string? azureDirectoryPath = ()) returns ClientError? {
    string requestPath = SLASH + fileShareName;
    requestPath = azureDirectoryPath is () ? requestPath : (requestPath + SLASH + azureDirectoryPath);
    requestPath = requestPath + SLASH + azureFileName + QUESTION_MARK + PUT_RANGE_PATH;
    stream<io:Block, io:Error?>|io:Error fileStream = io:fileReadBlocksAsStream(localFilePath, MAX_UPLOADING_BYTE_SIZE);
    if fileStream is io:Error {
        return error ProcessingError("Error while reading file as stream path = " + localFilePath, fileStream);
    }
    check iterateFileStream(httpClient, fileStream, fileSizeInByte, requestPath, fileShareName, azureFileName, azureConfig,
        azureDirectoryPath);
}

isolated function putRangeAsByteArray(http:Client httpClient, string fileShareName, byte[] fileContent,
        string azureFileName, ConnectionConfig azureConfig,
        int fileSizeInByte, string? azureDirectoryPath = ()) returns ClientError|ServerError? {
    string requestPath = SLASH + fileShareName;
    requestPath = azureDirectoryPath is () ? requestPath : (requestPath + SLASH + azureDirectoryPath);
    requestPath = requestPath + SLASH + azureFileName + QUESTION_MARK + PUT_RANGE_PATH;
    http:Request request = new;
    int index = 0;
    addPutRangeMandatoryHeaders(index, request, fileContent.length(), fileContent);
    if (azureConfig.authorizationMethod == ACCESS_KEY) {
        check addPutRangeHeadersForSharedKey(request, fileShareName, azureFileName, azureConfig, azureDirectoryPath);
    } else {
        string tokenWithAmpersand = AMPERSAND.concat(azureConfig.accessKeyOrSAS.substring(1));
        requestPath = requestPath.concat(tokenWithAmpersand);
    }
    http:Response response = <http:Response>check httpClient->put(requestPath, request);
    check checkAndHandleErrors(response);
}

isolated function iterateFileStream(http:Client httpClient, stream<byte[] & readonly, io:Error?> fileStream,
        int fileSizeInByte, string requestPathParent, string fileShareName,
        string azureFileName, ConnectionConfig azureConfig,
        string? azureDirectoryPath = ()) returns ClientError? {
    int index = 0;
    boolean isFirstRequest = true;
    int remainingBytesAmount = fileSizeInByte;
    boolean isOver = false;
    string requestPath = requestPathParent;
    while !isOver {
        record {|byte[] & readonly value;|}|io:Error? byteBlock = fileStream.next();
        if (byteBlock is io:Error) {
            return error ProcessingError("Error while reading file stream", byteBlock);
        }
        if (byteBlock is ()) {
            isOver = true;
        } else {
            if (remainingBytesAmount > MAX_UPLOADING_BYTE_SIZE) {
                http:Request request = new;
                addPutRangeMandatoryHeaders(index, request, (index + MAX_UPLOADING_BYTE_SIZE), byteBlock.value);
                if (azureConfig.authorizationMethod == ACCESS_KEY) {
                    check addPutRangeHeadersForSharedKey(request, fileShareName, azureFileName, azureConfig,
                                                        azureDirectoryPath);
                } else {
                    if (isFirstRequest) {
                        string tokenWithAmpersand = AMPERSAND.concat(azureConfig.accessKeyOrSAS.substring(1));
                        requestPath = requestPath.concat(tokenWithAmpersand);
                        isFirstRequest = false;
                    }
                }
                http:Response response = <http:Response>check httpClient->put(requestPath, request);
                if (response.statusCode == http:STATUS_CREATED) {
                    index = index + MAX_UPLOADING_BYTE_SIZE;
                    remainingBytesAmount = remainingBytesAmount - MAX_UPLOADING_BYTE_SIZE;
                }
            } else if (remainingBytesAmount < MAX_UPLOADING_BYTE_SIZE) {
                byte[] lastUploadRequest = array:slice(byteBlock.value, 0, fileSizeInByte - index);
                http:Request lastRequest = new;
                addPutRangeMandatoryHeaders(index, lastRequest, fileSizeInByte, lastUploadRequest);
                if (azureConfig.authorizationMethod == ACCESS_KEY) {
                    check addPutRangeHeadersForSharedKey(lastRequest, fileShareName, azureFileName, azureConfig,
                        azureDirectoryPath);
                } else {
                    if (isFirstRequest) {
                        string tokenWithAmpersand = AMPERSAND.concat(azureConfig.accessKeyOrSAS.substring(1));
                        requestPath = requestPath.concat(tokenWithAmpersand);
                        isFirstRequest = false;
                    }
                }
                http:Response responseLast = <http:Response>check httpClient->put(requestPath, lastRequest);
                if (responseLast.statusCode != http:STATUS_CREATED) {
                    xml errorMessage = check responseLast.getXmlPayload();
                    log:printError(errorMessage.toString(), statusCode = responseLast.statusCode);
                }
            }
        }

    }
}

# Set mandatory headers for putRange request.
#
# + startIndex - Starting index of the byte content
# + request - HTTP request 
# + lastIndex - Last inded of the byte content
# + byteContent - Byte array of content
isolated function addPutRangeMandatoryHeaders(int startIndex, http:Request request, int lastIndex, byte[] byteContent) {
    map<string> requiredSpecificHeaders = {
        [X_MS_RANGE] : string `bytes=${startIndex.toString()}-${(lastIndex - 1).toString()}`,
        [CONTENT_LENGTH] : byteContent.length().toString(),
        [X_MS_WRITE] : UPDATE
    };
    log:printDebug("Uplodaing Byte-Range: " + requiredSpecificHeaders.get(X_MS_RANGE).toString());
    setSpecificRequestHeaders(request, requiredSpecificHeaders);
    request.setBinaryPayload(byteContent);
}

# Set sharedKey related headers for putRange request.
#
# + request - HTTP request
# + fileShareName - Fileshare name
# + azureFileName - File name in azure
# + azureConfig - Azure configuration
# + azureDirectoryPath - Directory path in azure
# + return - If success, returns null.  Else returns error
isolated function addPutRangeHeadersForSharedKey(http:Request request, string fileShareName, string azureFileName,
        ConnectionConfig azureConfig, string? azureDirectoryPath =
                                                ()) returns ProcessingError? {
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
    check prepareAuthorizationHeaders(authorizationDetail);
}

# Gets the header value from an HTTP response.
#
# + response - HTTP response
# + headerName - Name of the header
# + return - Returns header value
isolated function getHeaderFromResponse(http:Response response, string headerName) returns string {
    var value = response.getHeader(headerName);
    if (value is string) {
        return value;
    } else {
        return EMPTY_STRING;
    }
}

# Creates a map<string> of headers from an http response.
#
# + response - HTTP response
# + return - Returns header map
isolated function getHeaderMapFromResponse(http:Response response) returns map<string> {
    map<string> headerMap = {};
    string[] headerNames = response.getHeaderNames();
    foreach string header in headerNames {
        headerMap[header] = getHeaderFromResponse(response, header);
    }
    return headerMap;
}

isolated function getResponseHeaders(http:Response response) returns ResponseHeaders {
    map<string> headers = getHeaderMapFromResponse(response);
    ResponseHeaders responseHeaders = {
        Date: "",
        x\-ms\-request\-id: "",
        x\-ms\-version: ""
    };
    foreach var [header, value] in headers.entries() {
        responseHeaders[header] = value;
    }
    return responseHeaders;
}

# Get metaData headers from a request.
#
# + response - HTTP response
# + return - Metadata headers as map<string>
isolated function getMetaDataHeaders(http:Response response) returns map<string> {
    map<string> metadataHeaders = {};
    string[] headerNames = response.getHeaderNames();
    foreach string header in headerNames {
        if (header.indexOf(X_MS_META) == 0) {
            metadataHeaders[header] = getHeaderFromResponse(response, header);
        }
    }
    return metadataHeaders;
}

# Creates FileMetadataResult from http response.
#
# + response - Validated http response
# + return - Returns FileMetadataResult type
isolated function getMetadataFromResponse(http:Response response) returns FileMetadataResult {
    FileMetadataResult fileMetadataResult = {
        metadata: getMetaDataHeaders(response),
        eTag: getHeaderFromResponse(response, ETAG),
        lastModified: getHeaderFromResponse(response, LAST_MODIFIED),
        responseHeaders: getResponseHeaders(response)
    };
    return fileMetadataResult;
}

isolated function convertXMLToJson(xml input) returns json|ProcessingError {
    json|xmldata:Error jsonResult = xmldata:toJson(input);
    if jsonResult is xmldata:Error {
        return error ProcessingError("Error while convertiong XML data to Json");
    } else {
        return jsonResult;
    }
}
