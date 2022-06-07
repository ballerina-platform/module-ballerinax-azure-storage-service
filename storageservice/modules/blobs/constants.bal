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

// Azure Storage Service constants
const string STORAGE_SERVICE_VERSION = "2019-12-12";

# Represents the authorization method used to access azure blob service.
# 
# + ACCESS_KEY - One of the access keys of the azure storage account
# + SAS - Shared Access Signature
public enum AuthorizationMethod {
    ACCESS_KEY = "accessKey",
    SAS = "SAS"
}

# Represents the type of a blob.
# 
# + APPEND_BLOB - Append blob
# + BLOCK_BLOB - Block blob
# + PAGE_BLOB - Page blob
public enum BlobType {
    APPEND_BLOB = "AppendBlob",
    BLOCK_BLOB = "BlockBlob",
    PAGE_BLOB = "PageBlob"
}

# Represents an operation done on page blob.
# 
# + CLEAR - Clear the specified range and release the space used in storage for that range
# + UPDATE - Write the bytes specified by the request body into the specified range
public enum PageOperation {
    CLEAR = "clear",
    UPDATE = "update"
}

// Azure Storage URI Strings
const string COMP = "comp";
const string RESTYPE = "restype";
const string LIST = "list";
const string CONTAINER = "container";
const string METADATA = "metadata";
const string BLOCK = "block";
const string BLOCKID = "blockid";
const string PROPERTIES = "properties";
const string ACCOUNT = "account";
const string SERVICE = "service";
const string ACL = "acl";
const string ALL = "all";
const string BLOCKLIST = "blocklist";
const string BLOCKLISTTYPE = "blocklisttype";
const string PAGELIST = "pagelist";
const string APPENDBLOCK = "appendblock";
const string PAGE = "page";

// Azure Storage Headers
const string X_MS_ACCOUNT_KIND = "x-ms-account-kind";
const string X_MS_BLOB_APPEND_OFFSET = "x-ms-blob-append-offset";
const string X_MS_BLOB_COMMITTED_BLOCK_COUNT = "x-ms-blob-committed-block-count";
const string X_MS_BLOB_SEQUENCE_NUMBER = "x-ms-blob-sequence-number";
const string X_MS_BLOB_TYPE = "x-ms-blob-type";
const string X_MS_BLOB_CONTENT_LENGTH = "x-ms-blob-content-length";
const string X_MS_BLOB_PUBLIC_ACCESS = "x-ms-blob-public-access";
const string X_MS_COPY_ID = "x-ms-copy-id";
const string X_MS_COPY_SOURCE = "x-ms-copy-source";
const string X_MS_COPY_STATUS = "x-ms-copy-status";

const string X_MS_DATE = "x-ms-date";
const string X_MS_HAS_IMMUTABILITY_POLICY = "x-ms-has-immutability-policy";
const string X_MS_HAS_LEGAL_HOLD = "x-ms-has-legal-hold";
const string X_MS_IS_HNS_ENABLED = "x-ms-is-hns-enabled";
const string X_MS_LEASE_DURATION = "x-ms-lease-duration";
const string X_MS_LEASE_ID = "x-ms-lease-id";
const string X_MS_LEASE_STATE = "x-ms-lease-state";
const string X_MS_LEASE_STATUS = "x-ms-lease-status";
const string X_MS_PAGE_WRITE = "x-ms-page-write";
const string X_MS_RANGE = "x-ms-range";
const string X_MS_SKU_NAME = "x-ms-sku-name";
const string X_MS_SOURCE_RANGE = "x-ms-source-range";
const string X_MS_VERSION = "x-ms-version";
const string X_MS_META = "x-ms-meta";
const string LAST_MODIFIED = "Last-Modified";
const string CONTENT_LENGTH = "Content-Length";
const string ETAG = "ETag";
const string PREFIX = "prefix";
const string MARKER = "marker";
const string MAXRESULTS = "maxresults";
const int MAX_BLOB_UPLOAD_SIZE = 52428800;

const string BLOB_PUBLIC_ACCESS = "x-ms-blob-public-access";
const string META_DATA = "x-ms-meta-";
const string REQUEST_ID = "x-ms-client-request-id";
const string LEASE_ID = "x-ms-lease-id";

// Error Code
const string AZURE_BLOB_ERROR_CODE = "(ballerinax/azure-storage-service)BlobError";

// Commonly used string constants
const string COLON_SYMBOL = ":";
const string WHITE_SPACE = " ";
const string EMPTY_STRING = "";
const string QUOTATION_MARK = "\"";
const string NEW_LINE = "\n";
const string FORWARD_SLASH_SYMBOL = "/";
const string VERTICAL_BAR = "|";
const string DASH = "-";
const string QUESTION_MARK = "?";
const string EQUAL_SYMBOL = "=";
const string AMPERSAND_SYMBOL = "&";
const string STATUS_CODE = "Status Code";
const string BYTES = "bytes";
const string AUTHORIZATION = "Authorization";
const string SHARED_KEY = "SharedKey";
const string ZERO = "0";
const string APPLICATION_SLASH_XML = "application/xml";
