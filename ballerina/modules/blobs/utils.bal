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

import azure.storage.utils as storage_utils;
import ballerina/http;
import ballerina/lang.'xml;
import ballerina/regex;
import ballerina/xmldata;

# Handles the HTTP response.
#
# + response - Http response
# + return - If successful and has xml payload, returns xml response. If successful but no payload, returns true.
# Else returns error.
isolated function handleResponse(http:Response response) returns xml|boolean|Error {
    if (response.getXmlPayload() is xml) {
        if (response.statusCode == http:STATUS_OK) {
            xml<xml:Element|xml:Comment|xml:ProcessingInstruction|xml:Text>|http:ClientError xmlPayload = response.getXmlPayload();
            if xmlPayload is http:ClientError {
                return error ProcessingError("Error while getting xmlpayload from respose", xmlPayload);
            } else {
                return xmlPayload;
            }
        } else {
            return createErrorFromXMLResponse(response);
        }
    } else if (response.statusCode == http:STATUS_OK || response.statusCode == http:STATUS_CREATED || response
        .statusCode == http:STATUS_ACCEPTED) {
        return true;
    } else {
        return error(AZURE_BLOB_ERROR_CODE, message = (STATUS_CODE + COLON_SYMBOL + WHITE_SPACE + response.statusCode
            .toString() + WHITE_SPACE + response.reasonPhrase));
    }
}

isolated function setPropertyHeaders(http:Request request, Properties properties) {
    if properties.metadata is map<string> {
        setMetaDataHeaders(request, <map<string>>properties.metadata);
    }
    if properties.blobContentEncoding is string {
        request.setHeader(X_MS_BLOB_CONTENT_ENCODING, <string>properties.blobContentEncoding);
    }
    if properties.blobContentMd5 is string {
        request.setHeader(X_MS_BLOB_CONTENT_MD5, <string>properties.blobContentMd5);
    }
    if properties.blobContentType is string {
        request.setHeader(X_MS_BLOB_CONTENT_TYPE, <string>properties.blobContentType);
    }
}

# Set metadata headers to a request
#
# + request - HTTP request 
# + metadata - Metadata as name-value pairs
public isolated function setMetaDataHeaders(http:Request request, map<string> metadata) {
    foreach [string, string] [name, value] in metadata.entries() {
        request.setHeader(META_DATA_PREFIX + name, value);
    }
}

isolated function getBlobPropertyHeaders(http:Response response) returns Properties {
    Properties properties = {};
    string[] headerNames = response.getHeaderNames();
    foreach string header in headerNames {
        match header {
            CONTENT_TYPE => {
                properties.blobContentType = getHeaderFromResponse(response, header);
            }
            CONTENT_ENCODING => {
                properties.blobContentEncoding = getHeaderFromResponse(response, header);
            }
            CONTENT_MD5 => {
                properties.blobContentMd5 = getHeaderFromResponse(response, header);
            }
        }
    }
    properties.metadata = getMetaDataHeaders(response);
    return properties;
}

# Handles the HTTP response for getBlob operation.
#
# + response - Http response
# + return - If successful, returns byte[]. Else returns error.
isolated function handleGetBlobResponse(http:Response response) returns byte[]|Error {
    if (response.statusCode == http:STATUS_OK || response.statusCode == http:STATUS_PARTIAL_CONTENT) {
        return response.getBinaryPayload();
    } else if (response.getXmlPayload() is xml) {
        return createErrorFromXMLResponse(response);
    } else {
        return error(AZURE_BLOB_ERROR_CODE, message = (STATUS_CODE + COLON_SYMBOL + WHITE_SPACE + response.statusCode
            .toString() + WHITE_SPACE + response.reasonPhrase));
    }
}

# Removes double quotes from an XML object.
#
# + xmlObject - XML Object
# + return - Returns clean XML Object
isolated function removeDoubleQuotesFromXML(xml xmlObject) returns xml|ProcessingError {
    string cleanedStringXMLObject = regex:replaceAll(xmlObject.toString(), QUOTATION_MARK, EMPTY_STRING);
    do {
        return check 'xml:fromString(cleanedStringXMLObject);
    } on fail error e {
        return error ProcessingError("Error while formatiing XML", e);
    }
}

isolated function convertXMLToJson(xml input) returns json|ProcessingError {
    json|xmldata:Error jsonResult = xmldata:toJson(input);
    if jsonResult is xmldata:Error {
        return error ProcessingError("Error while convertiong XML data to Json");
    } else {
        return jsonResult;
    }
}

# Check HTTP response and generate errors as required.
#
# + response - Http response
# + return - If unsuccessful, error
isolated function checkAndHandleErrors(http:Response response) returns ServerError|ClientError? {
    int statusCode = response.statusCode;
    if (statusCode == http:STATUS_OK
        || statusCode == http:STATUS_CREATED
        || statusCode == http:STATUS_ACCEPTED
        || statusCode == http:STATUS_NO_CONTENT) {
    } else if (response.getXmlPayload() is xml) {
        return createErrorFromXMLResponse(response);
    } else {
        return error ServerError("Unknown server error occured", httpStatus = statusCode, errorCode = "undefined",
            message = response.reasonPhrase);
    }
}

# Create error from xml response
#
# + response - Http response
# + return - Error
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
        http:STATUS_PRECONDITION_FAILED => {
            return error PreconditionFailedError("Pre-conditions failed.",
            errorCode = errorCode, message = message, httpStatus = 412);
        }
        http:STATUS_CONFLICT => {
            return error ConflictError("Conflict occurred.",
                errorCode = errorCode, message = message, httpStatus = 409);
        }
        http:STATUS_NOT_FOUND => {
            return error NotFoundError("Resource not found.",
                errorCode = errorCode, message = message, httpStatus = 404);
        }
        http:STATUS_BAD_REQUEST => {
            return error BadRequestError("Bad request received.",
                errorCode = errorCode, message = message, httpStatus = 400);
        }
        http:STATUS_INTERNAL_SERVER_ERROR => {
            return error InternalServerError("Internal server error occurred.",
                errorCode = errorCode, message = message, httpStatus = 500);
        }
        http:STATUS_RANGE_NOT_SATISFIABLE => {
            return error RequestedRangeNotSatisfiableError("Request range is invalid.",
                errorCode = errorCode, message = message, httpStatus = 416);
        }
        http:STATUS_FORBIDDEN => {
            return error ForbiddenError("Forbidden. ", errorCode = errorCode, message = message, httpStatus = 403);
        }
        _ => {
            return error ServerError("Undefined error occured", httpStatus = statusCode, errorCode = errorCode,
            message = message);
        }
    }
}

# Creates a map<json> of headers from an http response.
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

# Creates a header map from an HTTP Request.
#
# + request - Http request
# + return - Returns header map
isolated function populateHeaderMapFromRequest(http:Request request) returns map<string> {
    map<string> headerMap = {};
    string[] headerNames = request.getHeaderNames();
    foreach var header in headerNames {
        headerMap[header] = getHeaderFromRequest(request, header);
    }
    return headerMap;
}

# Adds optional headers and values to an HTTP request from given header map.
#
# + request - HTTP request
# + headerMap - headers and values as map<string>
isolated function setRequestHeaders(http:Request request, map<string> headerMap) {
    foreach var [header, value] in headerMap.entries() {
        request.setHeader(header, value);
    }
}

# Generates URI parameter string from the given map<string> uriParameters.
#
# + uriParameters - URI parameters as a map<string>
# + return - Returns URI Parameter string
public isolated function generateUriParametersString(map<string> uriParameters) returns string {
    string result = EMPTY_STRING;
    foreach var [param, value] in uriParameters.entries() {
        result = result + param + EQUAL_SYMBOL + value + AMPERSAND_SYMBOL;
    }
    if (result.endsWith(AMPERSAND_SYMBOL)) {
        result = result.substring(0, result.length() - 1);
    }
    return result;
}

# Create path according to the authorization method.
#
# + authorizationMethod - Authorization method
# + accessKeyOrSAS - Azure Storage account's Access Key or Shared Access Signature
# + uriParameters - URI parameters as a map<string>
# + resourcePath - Resource path
# + return - Returns path
public isolated function preparePath(string authorizationMethod, string accessKeyOrSAS, map<string> uriParameters,
        string resourcePath) returns string {
    string path = EMPTY_STRING;
    if (authorizationMethod == SAS) {
        path = resourcePath + accessKeyOrSAS + AMPERSAND_SYMBOL;
    } else {
        path = resourcePath + QUESTION_MARK;
    }
    path = path + generateUriParametersString(uriParameters);
    return path;
}

# Add default headers to the request.
#
# + request - HTTP request
public isolated function setDefaultHeaders(http:Request request) {
    request.setHeader(X_MS_VERSION, STORAGE_SERVICE_VERSION);
    request.setHeader(X_MS_DATE, storage_utils:getCurrentDate());
}

# Add authentication header to the request if it uses Shared Key Authentication.
#
# + request - HTTP request
# + verb - HTTP verb
# + accountName - Azure account name
# + accessKey - Shared Key
# + resourceString - Resource String
# + uriParameters - URI parameters as map<string>
# + return - Returns error if unsuccessful
public isolated function addAuthorizationHeader(http:Request request, http:HttpOperation verb, string accountName,
        string accessKey, string resourceString, map<string> uriParameters)
                                                    returns ProcessingError? {
    map<string> headerMap = populateHeaderMapFromRequest(request);
    string|error sharedKeySignature = storage_utils:generateSharedKeySignature(accountName, accessKey, verb,
        resourceString, uriParameters, headerMap);
    if sharedKeySignature is error {
        return error ProcessingError("Error while generating shared key signature", sharedKeySignature);
    }
    request.setHeader(AUTHORIZATION, SHARED_KEY + WHITE_SPACE + accountName + COLON_SYMBOL + sharedKeySignature);
}

# Get metaData headers from a request.
#
# + response - HTTP response
# + return - Metadata headers as map<string>
public isolated function getMetaDataHeaders(http:Response response) returns map<string> {
    map<string> metadataHeaders = {};
    string[] headerNames = response.getHeaderNames();
    foreach string header in headerNames {
        if (header.startsWith(META_DATA_PREFIX)) {
            metadataHeaders[header.substring(META_DATA_PREFIX.length())] = getHeaderFromResponse(response, header);
        }
    }
    return metadataHeaders;
}

public isolated function setOptionalHeaders(http:Request request, string? clientRequestId, string? leaseId = (),
        AccessLevel? accessLevel = (), map<string>? metadata = ()) {
    if accessLevel is AccessLevel {
        request.setHeader(BLOB_PUBLIC_ACCESS, accessLevel);
    }
    if metadata is map<string> {
        foreach [string, string] [name, value] in metadata.entries() {
            request.setHeader(META_DATA_PREFIX + name, value);
        }
    }
    if clientRequestId is string {
        request.setHeader(REQUEST_ID, clientRequestId);
    }
    if leaseId is string {
        request.setHeader(LEASE_ID, leaseId);
    }
}
