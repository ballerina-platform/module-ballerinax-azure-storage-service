////Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/lang.array as arrays;
import ballerina/lang.'string as stringLib;
import ballerina/lang.'xml as xmllib;
import ballerina/log;
import ballerina/io;
import ballerina/regex;
import ballerina/jsonutils as jsonlib;
import ballerina/xmlutils;
import ballerina/http;

# Format the xml payload to be converted into json.
#
# + xmlPayload - The xml payload
# + return - If success, returns formated xml else error
isolated function xmlFormatter(xml xmlPayload) returns @tainted xml|error {
    return xmllib:fromString(regex:replaceAll(xmlPayload.toString(), "\"", ""));
}

# Extract the details from the error message.
#
# + errorMessage - The receievd error payload from azure
# + return - If success, returns string type error message else the error occured when extracting
isolated function exactFromError(xml errorMessage) returns string|error {
    xml convertedMesssgage = xmllib:strip(errorMessage);
    json ss = check jsonlib:fromXML(convertedMesssgage);
    return ss.toString();
}

# Coverts records to xml.
#
# + recordContent - contents to be converted
# + return - if success, returns xml else the error
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
isolated function getErrorMessage(http:Response response) returns @tainted string {
    xml errorMessage = checkpanic response.getXmlPayload();
    return ( errorMessage.toString() + ", Azure Status Code:" + response.statusCode.toString());
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
    request.setHeader("x-ms-meta-name", requestHeader?.'x\-ms\-meta\-name.toString());
    request.setHeader("x-ms-share-quota", requestHeader?.'x\-ms\-share\-quota.toString());
    request.setHeader("x-ms-access-tier", requestHeader?.'x\-ms\-access\-tier.toString());
    request.setHeader("x-ms-enabled-protocols", requestHeader?.x\-ms\-enabled\-protocols.toString());
}

# Sets required request headers
# 
# + request - Request object reference
# + specificRequiredHeaders - Request headers as a key value map
isolated function setSpecficRequestHeaders(http:Request request, map<string> specificRequiredHeaders) {
    string[] keys = specificRequiredHeaders.keys();
    foreach string keyItem in keys {
        request.setHeader(keyItem, specificRequiredHeaders.get(keyItem));
    }
}

# Prepares the authorized header for the Shared key authorization
# 
# + authDetail - The records that includes the necessary detail for the authorization header creation
isolated function prepareAuthorizationHeaders(AuthorizationDetail authDetail) {
    map<string> headerMap = populateHeaderMapFromRequest(authDetail.azureRequest);
    URIRecord? test = authDetail?.uriParameterRecord;
    map<string> uriMap = {};
    if (test is ()) {
       uriMap = convertRecordtoStringMap(requiredURIParameters=authDetail.requiredURIParameters);
    } else {
       uriMap = convertRecordtoStringMap(<URIRecord>test,authDetail.requiredURIParameters);
    }
    string azureResourcePath = authDetail?.resourcePath is () ? "" : authDetail?.resourcePath.toString();
    string sharedKeySignature = checkpanic storage_utils:generateSharedKeySignature(
        authDetail.azureConfig.storageAccountName, authDetail.azureConfig.sharedKeyOrSASToken, authDetail.httpVerb,
        azureResourcePath, uriMap, headerMap);
    string accountName  = authDetail.azureConfig.storageAccountName;
    authDetail.azureRequest.setHeader(AUTHORIZATION, SHARED_KEY + WHITE_SPACE + accountName + COLON_SYMBOL 
        + sharedKeySignature);
}

# Converts a record to string type map
# 
# + uriParameters - The record of type URIRecord
# + requiredURIParameters - The string type map of required URI Parameters
# + return - If success, returns map<string>, else empty map
isolated function convertRecordtoStringMap(URIRecord? uriParameters = (), map<string> requiredURIParameters = {}) 
                                           returns map<string> {
    map<string> stringMap = {};
    if(typeof uriParameters is typedesc<ListShareURIParameters>) {
        stringMap["prefix"] = uriParameters?.prefix.toString();
        stringMap["marker"] = uriParameters?.marker.toString();
        stringMap["maxresults"] = uriParameters?.maxresults.toString();
        stringMap["include"] = uriParameters?.include.toString();
        stringMap["timeout"] = uriParameters?.timeout.toString();
    } else if (typeof uriParameters is typedesc<GetDirectoryListURIParamteres> || typeof uriParameters is 
    typedesc<GetFileListURIParamteres>) {
        stringMap["prefix"] = uriParameters?.prefix.toString();
        stringMap["marker"] = uriParameters?.marker.toString();
        stringMap["maxresults"] = uriParameters?.maxresults.toString();
        stringMap["sharesnapshot"] = uriParameters?.sharesnapshot.toString();
        stringMap["timeout"] = uriParameters?.timeout.toString();
    } 
    if(requiredURIParameters.length() !=  0){
        string[] keys = requiredURIParameters.keys();
        foreach string keyItem in keys  {
           stringMap[keyItem] = requiredURIParameters.get(keyItem); 
        }
    }
    map<string> filteredMap = {};
    string[] keySet = stringMap.keys();
    foreach string keyItem in keySet {
        string member = stringMap.get(keyItem);
        if (member != "") {
            filteredMap[keyItem] = member;
        }
    }

    return filteredMap;
}

# Gets the headers from a request as a map
# 
# + request - http:Request type object reference
# + return - If success, returns map<string>, else empty map
isolated function populateHeaderMapFromRequest(http:Request request) returns @tainted map<string> {
    map<string> headerMap = {};
    request.setHeader(X_MS_VERSION, FILES_AUTHORIZATION_VERSION);
    request.setHeader(X_MS_DATE, storage_utils:getCurrentDate());
    string[] headerNames = request.getHeaderNames();
    foreach var name in headerNames {
        headerMap[name] = checkpanic request.getHeader(name);
    }
    return headerMap;
}

# Sets the opitional URI parameters.
# 
# + uriRecord - URL parameters as records
# + return - if success returns the appended URI paramteres as a string else an error
isolated function setoptionalURIParametersFromRecord(URIRecord uriRecord) returns @tainted string? {
    string optionalURIs ="";
    if(typeof uriRecord is typedesc<ListShareURIParameters>) {
        optionalURIs = uriRecord?.prefix is () ? optionalURIs : (optionalURIs + AMPERSAND +"prefix=" 
            + uriRecord?.prefix.toString());
        optionalURIs = uriRecord?.marker is () ? optionalURIs : (optionalURIs + AMPERSAND +"marker=" 
            + uriRecord?.marker.toString());
        optionalURIs = uriRecord?.maxresults is () ? optionalURIs : (optionalURIs + AMPERSAND +"maxresults=" 
            + uriRecord?.maxresults.toString());
        optionalURIs = uriRecord?.include is () ? optionalURIs : (optionalURIs + AMPERSAND + "include=" 
            + uriRecord?.include.toString());
        optionalURIs = uriRecord?.timeout is () ? optionalURIs : (optionalURIs + AMPERSAND +"timeout=" 
            + uriRecord?.timeout.toString());
        return optionalURIs;
        
    } else if (typeof uriRecord is typedesc<GetDirectoryListURIParamteres> || typeof uriRecord is 
    typedesc<GetFileListURIParamteres>) {
        optionalURIs = uriRecord?.prefix is () ? optionalURIs : (optionalURIs + AMPERSAND + "prefix=" 
            + uriRecord?.prefix.toString());
        optionalURIs = uriRecord?.sharesnapshot is () ? optionalURIs : (optionalURIs + AMPERSAND + "sharesnapshot=" 
            + uriRecord?.sharesnapshot.toString());
        optionalURIs = uriRecord?.marker is () ? optionalURIs : (optionalURIs + AMPERSAND + "marker=" 
            + uriRecord?.marker.toString());
        optionalURIs = uriRecord?.maxresults is () ? optionalURIs : (optionalURIs + AMPERSAND + "maxresults=" 
            + uriRecord?.maxresults.toString());
        optionalURIs = uriRecord?.timeout is () ? optionalURIs : (optionalURIs + AMPERSAND + "timeout=" 
            + uriRecord?.timeout.toString());
        return optionalURIs;
    } else  {
        return;
    }

}

function createFileInternal(http:Client httpClient, string fileShareName, string fileName, int fileSizeInByte, 
                            AzureConfiguration azureConfig, string? azureDirectoryPath = ()) 
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
    if(azureConfig.authorizationMethod == SHARED_ACCESS_KEY) {
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
        AzureConfiguration azureConfig, int fileSizeInByte, string? azureDirectoryPath = ()) returns @tainted boolean|
        error {
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
                map<string> requiredSpecificHeaderes = {
                    [X_MS_RANGE]: string `bytes=${index.toString()}-${(index + MAX_UPLOADING_BYTE_SIZE - 1).toString()}`,
                    [CONTENT_LENGTH]: MAX_UPLOADING_BYTE_SIZE.toString(),
                    [X_MS_WRITE]: UPDATE 
                };
                log:print("X-Range: "+requiredSpecificHeaderes.get(X_MS_RANGE).toString());
                setSpecficRequestHeaders(request, requiredSpecificHeaderes);
                request.setBinaryPayload(byteBlock);
                if(azureConfig.authorizationMethod == SHARED_ACCESS_KEY) {
                    map<string> requiredURIParameters = {}; 
                    requiredURIParameters[COMP] = RANGE;
                    request.setHeader(CONTENT_TYPE, APPLICATION_STREAM);
                    request.setHeader(X_MS_VERSION, FILES_AUTHORIZATION_VERSION);
                    request.setHeader(X_MS_DATE, storage_utils:getCurrentDate());
                    string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH 
                        + azureFileName) : (fileShareName + SLASH + azureDirectoryPath + SLASH + azureFileName);
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
                        string tokenWithAmphasand = stringLib:concat(AMPERSAND, stringLib:substring(
                            azureConfig.sharedKeyOrSASToken, startIndex = 1));
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
                byte[] lastUploadRequest = arrays:slice(byteBlock, 0, fileSizeInByte - index);
                map<string> lastRequiredSpecificHeaderes = {
                    [X_MS_RANGE]: string `bytes=${index.toString()}-${(fileSizeInByte - 1).toString()}`,
                    [CONTENT_LENGTH]: lastUploadRequest.length().toString(),
                    [X_MS_WRITE]: UPDATE
                };
                log:print("x-Range :" + lastRequiredSpecificHeaderes.get(X_MS_RANGE).toString());
                http:Request lastRequest = new;
                setSpecficRequestHeaders(lastRequest, lastRequiredSpecificHeaderes);
                lastRequest.setBinaryPayload(lastUploadRequest);
                if(azureConfig.authorizationMethod == SHARED_ACCESS_KEY) {
                    map<string> requiredURIParameters = {}; 
                    requiredURIParameters[COMP] = RANGE;
                    lastRequest.setHeader(CONTENT_TYPE, APPLICATION_STREAM);
                    lastRequest.setHeader(X_MS_VERSION, FILES_AUTHORIZATION_VERSION);
                    lastRequest.setHeader(X_MS_DATE, storage_utils:getCurrentDate());
                    string resourcePathForSharedkeyAuth = azureDirectoryPath is () ? (fileShareName + SLASH 
                        + azureFileName) : (fileShareName + SLASH + azureDirectoryPath + SLASH + azureFileName);
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
                        string tokenWithAmphasand = stringLib:concat(AMPERSAND, stringLib:substring(
                            azureConfig.sharedKeyOrSASToken, startIndex = 1));
                        requestPath = stringLib:concat(requestPath, tokenWithAmphasand);
                        isFirstRequest = false;
                    } 

                }
                http:Response responseLast = <http:Response>checkpanic httpClient->put(requestPath, lastRequest);
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



