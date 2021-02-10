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
import ballerina/lang.'xml as xmllib;
import ballerina/io;
import ballerina/log;
import ballerina/stringutils;
import ballerina/jsonutils as jsonlib;
import ballerina/xmlutils;
import ballerina/http;
import ballerina/lang.'string as stringlib;
import azure_storage_service.utils as storage_utils;
//import ballerina/lang.'map as mapLib;

#Format the xml payload to be converted into json.
#
# + xmlPayload - The xml payload.
# + return - If success, returns formated xml else error
isolated function xmlFormatter(xml xmlPayload) returns @tainted xml|error {
    return xmllib:fromString(stringutils:replace(xmlPayload.toString(), "\"", ""));
}

# Extract the details from the error message.
#
# + errorMessage - The receievd error payload from azure. 
# + return - If success, returns string type error message else the error occured when extracting.
isolated function exactFromError(xml errorMessage) returns string|error {
    xml convertedMesssgage = xmllib:strip(errorMessage);
    json ss = check jsonlib:fromXML(convertedMesssgage);
    return ss.toString();
}

# Coverts records to xml.
#
# + recordContent - contents to be converted. 
# + return - if success, returns xml else the error.
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
# + response - Receievd xml response.
# + return - Returns error message as a string value.
isolated function getErrorMessage(http:Response response) returns @tainted string {
    return (response.getXmlPayload().toString() + ", Azure Status Code:" + response.statusCode.toString());
}

# Writes the file content to the local destination.
#
# + filePath - Path to the destination direcoty.
# + payload - The content to be written.
# + return - if success returns true else the error.
function writeFile(string filePath, byte[] payload) returns @tainted boolean|error {
    io:WritableByteChannel writeableFile = check io:openWritableFile(filePath);
    int index = 0;
    while (index < payload.length()) {
        int result = check writeableFile.write(payload, index);
        index = index + result;
    }
    return writeableFile.close() ?: true;

}

#Sets the opitional URI parameters.
# 
# + operationName - Name of the function that calles the function
# + uriParameterSet - URL parameters as a key value map
# + return - if success returns the appended URI paramteres as a string else an error
function setoptionalURIParameters(string operationName, map<any> uriParameterSet, boolean needValidMap = false) returns @tainted string? {
    string[] keys = uriParameterSet.keys();
    string optionalURIs = "";
    foreach string keyItem in keys {
        boolean hasKeyItem = uriParameters.hasKey(keyItem);
        if (hasKeyItem) {
            string[] operationNameSet = uriParameters.get(keyItem);
            boolean operationFound = false;
            foreach string operationNameItem in operationNameSet {
                if (operationNameItem == operationName) {
                    optionalURIs = stringlib:concat(optionalURIs, 
                    createURIAppends(keyItem, uriParameterSet.get(keyItem)));
                    operationFound = true;
                } 
            }
            if(!operationFound) {
                var removedMember = uriParameterSet.remove(keyItem);
                log:print("Invalidated key :" + keyItem);
            }
        } else {
            var removedMember = uriParameterSet.remove(keyItem);
            log:print("URI parameter " + keyItem + ": invalid parameter for " + operationName);
        }
    }
    if (stringlib:length(optionalURIs) > 0) {
        return optionalURIs;
    } else {
        return;
    }       
}

#Creates the URI by appending the parameters
# 
# + key - URI parameter name
# + value - URI paramter value
# + return - Appended URI parameter as a string value
isolated function createURIAppends(string key, any value) returns string {
    return AMPERSAND + key + EQUALS_SIGN + value.toString();
}

#Sets the optional request headers
#
# + operationName - Name of the function that calles the function
# + request - Request object reference
# + userDefinedHeaders - Request headers as a key value map
function setAzureRequestHeaders(string operationName, http:Request request, map<any> userDefinedHeaders) {
    string[] keys = userDefinedHeaders.keys();
    foreach string headerName in keys {
        boolean keyValue = requestHeaders.hasKey(headerName);
        if (keyValue == true) {
            string[] functionNames = requestHeaders.get(headerName);
            foreach string functionNameItem in functionNames {
                if (functionNameItem == operationName) {
                    request.setHeader(headerName, userDefinedHeaders.get(headerName).toString());
                }
            }
        } else {
            log:print(headerName + ": is not supported header for " + operationName);
        }
    }
}

#Sets required request headers
# 
# + request - Request object reference
# + specificRequiredHeaders - Request headers as a key value map
isolated function setSpecficRequestHeaders(http:Request request, map<string> specificRequiredHeaders) {
    string[] keys = specificRequiredHeaders.keys();
    foreach string keyItem in keys {
        request.setHeader(keyItem, specificRequiredHeaders.get(keyItem));
    }
}

function prepareAuthorizationHeaders(http:Request request,AzureConfiguration azureConfig,string httpVerb, map<any> uriParameters, string? resourcePath = ()) {
    map<string> headerMap = populateHeaderMapFromRequest(request);
    string azureResourcePath = resourcePath is () ? "" : resourcePath;
    string sharedKeySignature = checkpanic storage_utils:generateSharedKeySignature(azureConfig.storageAccountName,azureConfig.sharedKeyOrSASToken,httpVerb, azureResourcePath, convertAnyTypetoStringMap(uriParameters), headerMap);
    string accountName  = azureConfig.storageAccountName;
    request.setHeader(AUTHORIZATION, SHARED_KEY + WHITE_SPACE + accountName + COLON_SYMBOL + sharedKeySignature);
}

function convertAnyTypetoStringMap(map<any> anyTyeMap) returns map<string> {
    string[] keys = anyTyeMap.keys();
    map<string> stringMap = {};
    foreach string index in keys {
        stringMap[index] = anyTyeMap.get(index).toString();
    }
    return stringMap;
}

isolated function populateHeaderMapFromRequest(http:Request request) returns @tainted map<string>{
    map<string> headerMap = {};
    request.setHeader(X_MS_VERSION, FILES_AUTHORIZATION_VERSION);
    request.setHeader(X_MS_DATE, storage_utils:getCurrentDate());
    string[] headerNames = request.getHeaderNames();
    foreach var name in headerNames {
        headerMap[name] = request.getHeader(name);
    }
    return headerMap;
}

