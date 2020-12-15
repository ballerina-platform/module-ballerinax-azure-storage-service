import ballerina/time;
import ballerina/crypto;
import ballerina/lang.'array;

// Get current date and time string
public isolated function getCurrentDateString() returns string|error {
    string DATE_TIME_FORMAT = STORAGE_SERVICE_DATE_FORMAT;
    time:Time time = time:currentTime();
    time:Time standardTime = check time:toTimeZone(time, GMT);
    return time:format(standardTime, DATE_TIME_FORMAT);
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
    foreach var [param, value] in uriParameters.entries() {
        result = result + NEW_LINE + param + COLON_SYMBOL + value;
    }
    return result;
}

// Generate signature for Shared Key Authorization method
public isolated function generateSharedKeySignature (string accountName, string accountKey, string verb, string resourcePath,
                         map<string> uriParameters, map<string> headers) returns string|error {
    string canonicalozedHeaders = generateCanonicalizedHeadersString(headers);
    string uriParameterString = generateUriParamStringForSharedKey(uriParameters);
    string canonicalizedResources = FORWARD_SLASH_SYMBOL + accountName + FORWARD_SLASH_SYMBOL + resourcePath 
                                        + uriParameterString;

    string contentEncoding = EMPTY_STRING;
    string contentLanguage = EMPTY_STRING;
    string contentLength = EMPTY_STRING;
    if (headers.hasKey(CONTENT_LENGTH)) {
        contentLength  =  headers.get(CONTENT_LENGTH);
        if (contentLength == ZERO) {
            contentLength = EMPTY_STRING; // Temporary Fix
        }
    }

    string contentMD5 = EMPTY_STRING;
    string contentType = EMPTY_STRING;
    //contentType  =  "application/octet-stream";
    if (headers.hasKey(X_MS_BLOB_TYPE)) {
        if (headers.get(X_MS_BLOB_TYPE) == "BlockBlob") {
            contentType  =  "application/octet-stream"; /// Temporary Fix for put block (BlockBlob)
        }   
    }

    string signatureDate = EMPTY_STRING;
    string ifModifiedSince = EMPTY_STRING;
    string ifMatch = EMPTY_STRING;
    string ifNoneMatch = EMPTY_STRING;
    string ifUnmodifiedSince = EMPTY_STRING;
    string range = EMPTY_STRING;

    string stringToSign = verb.toUpperAscii() + NEW_LINE + contentEncoding + NEW_LINE + contentLanguage + NEW_LINE
                            + contentLength + NEW_LINE + contentMD5 + NEW_LINE + contentType + NEW_LINE + signatureDate
                            + NEW_LINE + ifModifiedSince + NEW_LINE + ifMatch + NEW_LINE + ifNoneMatch + NEW_LINE
                            + ifUnmodifiedSince + NEW_LINE + range + NEW_LINE + canonicalozedHeaders 
                            + canonicalizedResources;

    return 'array:toBase64(crypto:hmacSha256(stringToSign.toBytes(), check 'array:fromBase64(accountKey)));
}