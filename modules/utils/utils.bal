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

import ballerina/time;
import ballerina/crypto;
import ballerina/lang.'array;
import ballerina/http;
import ballerina/lang.'xml;
import ballerina/stringutils;

// Get current date and time string
public isolated function getCurrentDate() returns string { 
    time:Time standardTime = checkpanic time:toTimeZone(time:currentTime(), GMT);
    return checkpanic time:format(standardTime, STORAGE_SERVICE_DATE_FORMAT);
}

// Get current system time in milliseconds
public isolated function getCurrentTime() returns string {
    return time:currentTime().time.toString();
}

// Generate canonicalized header string from a header map
public isolated function generateCanonicalizedHeadersString(map<string> headers) returns string {
    string result = EMPTY_STRING;
    string[] allHeaderNames = 'array:sort(headers.keys());
    foreach string k in allHeaderNames {
        if (k.indexOf(X_MS) == 0) {
            result = result + k.toLowerAscii()+ COLON_SYMBOL + headers.get(k) + NEW_LINE;
        }
    }
    return result;
}

// Generate uri parameters string from a uriParameters map
public isolated function generateUriParamStringForSharedKey(map<string> uriParameters) returns string {
    string result = EMPTY_STRING;
    string[] allURIParams = 'array:sort(uriParameters.keys());
    foreach string uriParameter in allURIParams {
        result = result + NEW_LINE + uriParameter + COLON_SYMBOL + uriParameters.get(uriParameter);
    }
    return result;
}

// Generate signature for Shared Key Authorization method
public isolated function generateSharedKeySignature (string accountName, string accountKey, string verb, 
                            string resourcePath, map<string> uriParameters, map<string> headers) returns string|error {                     
    string canonicalozedHeaders = generateCanonicalizedHeadersString(headers);
    string uriParameterString = generateUriParamStringForSharedKey(uriParameters);
    string canonicalizedResources = FORWARD_SLASH_SYMBOL + accountName + FORWARD_SLASH_SYMBOL + resourcePath 
                                        + uriParameterString;

    string contentEncoding = EMPTY_STRING;
    if (headers.hasKey(CONTENT_ENCODING)) {
        contentEncoding  =  headers.get(CONTENT_ENCODING);
    }

    string contentLanguage = EMPTY_STRING;
    if (headers.hasKey(CONTENT_LANGUAGE)) {
        contentLanguage  =  headers.get(CONTENT_LANGUAGE);
    }

    string contentLength = EMPTY_STRING;
    if (headers.hasKey(CONTENT_LENGTH)) {
        // If content-length is 0, it should be an empty string
        contentLength  =  headers.get(CONTENT_LENGTH);
        if (contentLength == ZERO) {
            contentLength = EMPTY_STRING;
        }
    }

    string contentMD5 = EMPTY_STRING;
    if (headers.hasKey(CONTENT_MD5)) {
        contentMD5  =  headers.get(CONTENT_MD5);
    }

    string contentType = EMPTY_STRING;
    if (headers.hasKey(CONTENT_TYPE)) {
        contentType  =  headers.get(CONTENT_TYPE);
    }

    // Since x-ms-date header is added for all the requests, this header is not required.
    // Even this header is provided as an optional header by the user, azure will ignore this and take x-ms-date
    string date = EMPTY_STRING;
    if (headers.hasKey(DATE)) {
        date  =  headers.get(DATE);
    }

    string ifModifiedSince = EMPTY_STRING;
    if (headers.hasKey(IF_MODIFIED_SINCE)) {
        ifModifiedSince  =  headers.get(IF_MODIFIED_SINCE);
    }

    string ifMatch = EMPTY_STRING;
    if (headers.hasKey(IF_MATCH)) {
        ifMatch  =  headers.get(IF_MATCH);
    }

    string ifNoneMatch = EMPTY_STRING;
    if (headers.hasKey(IF_NONE_MATCH)) {
        ifNoneMatch  =  headers.get(IF_NONE_MATCH);
    }

    string ifUnmodifiedSince = EMPTY_STRING;
    if (headers.hasKey(IF_UNMODIFIED_SINCE)) {
        ifUnmodifiedSince  =  headers.get(IF_UNMODIFIED_SINCE);
    }

    string range = EMPTY_STRING;
    if (headers.hasKey(RANGE)) {
        range  =  headers.get(RANGE);
    }

    string stringToSign = verb.toUpperAscii() + NEW_LINE + contentEncoding + NEW_LINE + contentLanguage + NEW_LINE
                            + contentLength + NEW_LINE + contentMD5 + NEW_LINE + contentType + NEW_LINE + date
                            + NEW_LINE + ifModifiedSince + NEW_LINE + ifMatch + NEW_LINE + ifNoneMatch + NEW_LINE
                            + ifUnmodifiedSince + NEW_LINE + range + NEW_LINE + canonicalozedHeaders 
                            + canonicalizedResources;
    return 'array:toBase64(crypto:hmacSha256(stringToSign.toBytes(), check 'array:fromBase64(accountKey)));
}

# Removes double quotes from an XML object.
#
# + xmlObject - XML Object
# + return - Returns clean XML Object.
public isolated function removeDoubleQuotesFromXML(xml xmlObject) returns xml|error {
    string cleanedStringXMLObject = stringutils:replaceAll(xmlObject.toString(), APOSTROPHE_SYMBOL, EMPTY_STRING);
    return 'xml:fromString(cleanedStringXMLObject);
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

// Create a map of headers from an HTTP Request
public isolated function populateHeaderMapFromRequest(http:Request request) returns @tainted map<string>{
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
public isolated function setRequestHeaders(http:Request request, map<string> headerMap) returns http:Request{
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

    string date = getCurrentDate();
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

// Get metaData headers from a request
public isolated function getMetaDataHeaders(http:Response response) returns @tainted map<string> {
    map<string> metaDataHeaders = {};
    string[] headerNames = response.getHeaderNames();
    foreach string k in headerNames {
        if (k.indexOf(X_MS_META) == 0) {
            metaDataHeaders[k] = response.getHeader(k);
        }   
    }
    return metaDataHeaders;
}
