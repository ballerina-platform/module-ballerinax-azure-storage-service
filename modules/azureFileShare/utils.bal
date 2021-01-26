import ballerina/lang.'xml as xmllib;
import ballerina/io;
import ballerina/stringutils;
import ballerina/jsonutils as jsonlib;
import ballerina/xmlutils;
import ballerina/http;

#Format the xml payload to be converted into json.
#
# + xmlPayload - The xml Payload.
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

# Customize the azure fileshare connector error.
#
# + message - The error message to be dispayed.
# + err -  Actual error.
# + return - A customized connector error.
isolated function prepareError(string message, error? err = ()) returns Error {
    Error fileShareError;
    if (err is error) {
        fileShareError = FileShareError(message, err);
    } else {
        fileShareError = FileShareError(message);
    }
    return fileShareError;
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
    xml responseBody = <xml>response.getXmlPayload();
    xml reason = responseBody;
    return reason.toString();
}

# Writes the file content to the local destination.
#
# + filePath - Path to the destination direcoty.
# + payload - The content to be written.
# + isAppend - Check for appending or replacing the content.
# + return - if success returns true else the error.
function writeFile(string filePath, byte[] payload, boolean isAppend = false) returns @tainted boolean|error {
    io:WritableByteChannel writeableFile = check io:openWritableFile(filePath, isAppend);
    int i = 0;
    while (i < payload.length()) {
        int result = check writeableFile.write(payload, i);
        i = i + result;
    }
    return writeableFile.close() ?: true;

}
