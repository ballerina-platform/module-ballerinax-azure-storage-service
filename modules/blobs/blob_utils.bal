// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/lang.'xml;
import ballerina/stringutils;

# Handles the HTTP response.
#
# + response - Http response
# + return - If successful and has xml payload, returns xml response. If successful but no payload, returns true.
# Else returns error.
isolated function handleResponse(http:Response|http:Payload|error response) returns @tainted xml|boolean|error {
    if (response is http:Response) {
        if (response.getXmlPayload() is xml) {
            xml xmlResponse = check response.getXmlPayload();
            if (response.statusCode == http:STATUS_OK) {
                return <xml>xmlResponse;
            } else {
                string code = (xmlResponse/<Code>/*).toString();
                string message = (xmlResponse/<Message>/*).toString();

                string errorMessage = STATUS_CODE + COLON_SYMBOL + WHITE_SPACE + response.statusCode.toString() 
                                        + WHITE_SPACE + response.reasonPhrase + NEW_LINE + code + WHITE_SPACE + message 
                                        + NEW_LINE + xmlResponse.toString();
                return error(AZURE_BLOB_ERROR_CODE, message = errorMessage);
            }
        } else if (response.statusCode == http:STATUS_OK || response.statusCode == http:STATUS_CREATED || 
                    response.statusCode == http:STATUS_ACCEPTED) {
            return true;
        } else {
            return error(AZURE_BLOB_ERROR_CODE, message = (STATUS_CODE + COLON_SYMBOL + WHITE_SPACE 
                            + response.statusCode.toString() + WHITE_SPACE + response.reasonPhrase));
        }
    } else {
        return error(AZURE_BLOB_ERROR_CODE, message = REST_API_ERROR_MESSAGE);
    }
}

# Handles the HTTP response for getBlob operation.
#
# + response - Http response
# + return - If successful, returns byte[]. Else returns error.
isolated function handleGetBlobResponse(http:Response|http:Payload|error response) returns @tainted byte[]|error? {
    if (response is http:Response) {
        if (response.statusCode == http:STATUS_OK || response.statusCode == http:STATUS_PARTIAL_CONTENT) {
            return response.getBinaryPayload();
        } else if (response.getXmlPayload() is xml) {
            xml xmlResponse = check response.getXmlPayload();
            string code = (xmlResponse/<Code>/*).toString();
            string message = (xmlResponse/<Message>/*).toString();

            string errorMessage = STATUS_CODE + COLON_SYMBOL + WHITE_SPACE + response.statusCode.toString() 
                                    + WHITE_SPACE + response.reasonPhrase + NEW_LINE + code + WHITE_SPACE + message 
                                    + NEW_LINE + xmlResponse.toString();
            return error(AZURE_BLOB_ERROR_CODE, message = errorMessage);
        } else {
            return error(AZURE_BLOB_ERROR_CODE, message = (STATUS_CODE + COLON_SYMBOL + WHITE_SPACE 
                                + response.statusCode.toString() + WHITE_SPACE + response.reasonPhrase));
        }
    } else {
        return error(AZURE_BLOB_ERROR_CODE, message = REST_API_ERROR_MESSAGE);
    }
}

# Removes double quotes from an XML object.
#
# + xmlObject - XML Object
# + return - Returns clean XML Object.
isolated function removeDoubleQuotesFromXML(xml xmlObject) returns xml|error {
    string cleanedStringXMLObject = stringutils:replaceAll(xmlObject.toString(), APOSTROPHE_SYMBOL, EMPTY_STRING);
    return 'xml:fromString(cleanedStringXMLObject);
}

# Handles the HTTP response which has only headers and no body.
#
# + response - Http response
# + return - If successful, returns response. Else returns error.
isolated function handleHeaderOnlyResponse(http:Response|http:Payload|error response) 
                    returns @tainted http:Response|error {
    if (response is http:Response) {
        if (response.statusCode == http:STATUS_OK || response.statusCode == http:STATUS_CREATED || 
                    response.statusCode == http:STATUS_ACCEPTED || response.statusCode == http:STATUS_NO_CONTENT) {
            return response;
        } else if (response.getXmlPayload() is xml) {
            xml xmlResponse = check response.getXmlPayload();
            string code = (xmlResponse/<Code>/*).toString();
            string message = (xmlResponse/<Message>/*).toString();

            string errorMessage = STATUS_CODE + COLON_SYMBOL + WHITE_SPACE + response.statusCode.toString() 
                                    + WHITE_SPACE + response.reasonPhrase + NEW_LINE + code + WHITE_SPACE + message 
                                    + NEW_LINE + xmlResponse.toString();
            return error(AZURE_BLOB_ERROR_CODE, message = errorMessage);
        } else {
            return error(AZURE_BLOB_ERROR_CODE, message = (STATUS_CODE + COLON_SYMBOL + WHITE_SPACE 
                                + response.statusCode.toString() + WHITE_SPACE + response.reasonPhrase));
        }
    } else {
        return error(AZURE_BLOB_ERROR_CODE, message = REST_API_ERROR_MESSAGE + response.toString());
    }
}

# Creates a map<json> of headers from an http response.
#
# + response - HTTP response
# + return - Returns header map.
isolated function getHeaderMapFromResponse(http:Response response) returns @tainted map<json> {
    map<json> headerMap = {};
    string[] headerNames = response.getHeaderNames();
    foreach string k in headerNames {
        headerMap[k] = response.getHeader(k);
    }
    return headerMap;
}

isolated function populateHeaderMapFromRequest(http:Request request) returns @tainted map<string>{
    map<string> headerMap = {};
    string[] headerNames = request.getHeaderNames();
    foreach var k in headerNames {
        headerMap[k] = request.getHeader(k);
    }
    return headerMap;
}

# Adds optional headers and values to an HTTP request from given header map.
#
# + request - HTTP request
# + headerMap - headers and values as map<string>
# + return - Returns http request.
isolated function setRequestHeaders(http:Request request, map<string> headerMap) returns http:Request{
    foreach var [header, value] in headerMap.entries() {
        request.setHeader(header, value);
    }
    return request;
}

// Generates URI parameter string from the given map<string> uriParameters
public isolated function generateUriParametersString(map<string> uriParameters) returns string {
    string result = EMPTY_STRING;
    foreach var [param, value] in uriParameters.entries() {
        result = result + param + EQUAL_SYMBOL + value + AMPERSAND_SYMBOL;
    }
    if (result.endsWith(AMPERSAND_SYMBOL)) {
        result = 'string:substring(result, 0, result.length()-1);
    }
    return result;
}

// Create path according to the authorization method
public isolated function preparePath (string authorizationMethod, string sharedAccessSignature,
                            map<string> uriParameters, string resourcePath) returns string {
    string path = EMPTY_STRING;
    if (authorizationMethod == SHARED_ACCESS_SIGNATURE) {
        path = resourcePath + sharedAccessSignature + AMPERSAND_SYMBOL;  
    } else {
        path = resourcePath + QUESTION_MARK;
    }
    path = path + generateUriParametersString(uriParameters);
    return path;
}

// Create an HTTP Request and add default and optional headers
public isolated function createRequest (map<string>? optionalHeaders) returns http:Request|error {
    http:Request request = new ();
    if (optionalHeaders is map<string>) {
        request = setRequestHeaders(request, optionalHeaders);
    }

    string date = check getCurrentDateString();
    request.setHeader(X_MS_VERSION, STORAGE_SERVICE_VERSION);
    request.setHeader(X_MS_DATE, date);
    return request;
}

// Add authentication header to the request if it uses Shared Key Authentication
public isolated function prepareAuthorizationHeader (http:Request request, string verb, string authorizationMethod, 
                            string accountName, string accessKey, string resourceString, map<string> uriParameters) 
                            returns http:Request|error {
    if (authorizationMethod == SHARED_KEY) {
        map<string> headerMap = populateHeaderMapFromRequest(request);
        string sharedKeySignature = check generateSharedKeySignature(accountName, accessKey, verb, resourceString,
                                uriParameters, headerMap);
        request.setHeader(AUTHORIZATION, SHARED_KEY + WHITE_SPACE + accountName + COLON_SYMBOL + sharedKeySignature);
    }
    return request;
}

// Add optional uri parameters to the uriParamter map
public isolated function addOptionalURIParameters( map<string>? optionalURIParamters) returns map<string> {
    if (optionalURIParamters is map<string>) {
        return optionalURIParamters;
    }
    return{};
}
