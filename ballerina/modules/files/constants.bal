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
// under the License.

# Holds the value for URL of end point.
const string LIST_SHARE_PATH = "/?comp=list";
const string GET_FILE_SERVICE_PROPERTIES = "/?restype=service&comp=properties";
const string CREATE_GET_DELETE_SHARE = "restype=share";
const string LIST_FILES_DIRECTORIES_PATH = "?restype=directory&comp=list";
const string CREATE_DELETE_DIRECTORY_PATH = "?restype=directory";
const string PUT_RANGE_PATH = "comp=range";
const string LIST_FILE_RANGE = "comp=rangelist";
const string GET_FILE_METADATA = "?comp=metadata";

# Constant String values
const int MAX_UPLOADING_BYTE_SIZE = 4194300;
const string SHARED_KEY = "SharedKey";
const string WHITE_SPACE = " ";
const string COLON_SYMBOL = ":";
const string FILES_AUTHORIZATION_VERSION = "2019-12-12";
const string RESTYPE = "restype";
const string DIRECTORY = "directory";
const string METADATA = "metadata";
const string COMP = "comp";
const string LIST = "list";
const string RANGE_LIST = "rangelist";
const string RANGE = "range";
const string SERVICE = "service";
const string PROPERTIES = "properties";
const string SHARE  = "share";
const string INHERIT = "inherit";
const string NOW = "now";
const string NONE = "none";
const string APPLICATION_XML = "application/xml";
const string APPLICATION_STREAM = "application/octet-stream";
const string ZERO = "0";
const string FILE_TYPE = "file";
const string X_MS_COPY_SOURCE = "x-ms-copy-source";
const string UPDATE = "update";
const string EMPTY_STRING = "";

# Constant symbols
const string AMPERSAND = "&";
const string SLASH = "/";
const string QUOTATION_MARK = "\"";
const string QUESTION_MARK = "?";
const string EQUALS_SIGN = "=";

# Request Headers' names
const string X_MS_META_NAME = "x-ms-meta-name";
const string X_MS_HARE_QUOTA = "x-ms-share-quota";
const string X_MS_ACCESS_TIER = "x-ms-access-tier";
const string X_MS_ENABLED_PROTOCOLS = "x-ms-enabled-protocols";
const string AUTHORIZATION = "Authorization";
const string X_MS_VERSION = "x-ms-version";
const string X_MS_DATE = "x-ms-date";
const string X_MS_FILE_PERMISSION = "x-ms-file-permission";
const string x_MS_FILE_ATTRIBUTES = "x-ms-file-attributes";
const string X_MS_FILE_CREATION_TIME = "x-ms-file-creation-time";
const string X_MS_FILE_LAST_WRITE_TIME = "x-ms-file-last-write-time";
const string CONTENT_LENGTH = "Content-Length";
const string CONTENT_TYPE = "content-type";
const string X_MS_RANGE = "x-ms-range";
const string X_MS_WRITE = "x-ms-write";
const string X_MS_TYPE = "x-ms-type";
const string X_MS_CONTENT_LENGTH = "x-ms-content-length";
const string PREFIX = "prefix";
const string MARKER  = "marker";
const string MAX_RESULTS = "maxresults";
const string INCLUDE = "include";
const string TIMEOUT = "timeout";
const string SHARES_SNAPSHOT = "sharesnapshot";
const string X_MS_META = "x-ms-meta";
const string LAST_MODIFIED = "Last-Modified";
const string ETAG = "ETag";

# Error Messages
const string NO_SHARES_FOUND = "No any shares found in storage account";
const string NO_DIRECTORIES_FOUND = "No directories found in received azure response";
const string NO_FILE_FOUND = "No files found in received azure response";
const string NO_RANGE_LIST_FOUND = "No range list found in azure response";
const string AN_EMPTY_FILE_FOUND = "An empty file found in azure response";
const string OPERATION_FAILED = "Operation Failed";
const string FILE_UPLOAD_AS_BYTE_ARRAY_FAILED = "Uploading file content as a Byte array was not successful!";
const string XML_TO_JSON_CONVERSION_ERROR = "An error in xml conversion";

const int CHUNK_SIZE = 4 * 1024 * 1024; // 4MB in bytes

# Azure storage service authorization methods
public enum AuthorizationMethod {
    ACCESS_KEY = "accessKey",
    SAS = "SAS"
}
