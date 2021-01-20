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

//Azure Storage Service constants
const string STORAGE_SERVICE_VERSION = "2019-12-12";
const string STORAGE_SERVICE_DATE_FORMAT = "EEE, dd MMM yyyy HH:mm:ss z";

// Resources
const string LIST_CONTAINERS_RESOURCE = "&comp=list";
const string LIST_BLOBS_RESOURCE = "&restype=container&comp=list";
const string GET_ACCOUNT_INFO_RESOURCE = "&restype=account&comp=properties";
const string GET_BLOB_TAGS_RESOURCE = "&comp=tags";
const string GET_BLOCK_LIST_RESOURCE = "&blocklisttype=all&comp=blocklist";
const string CONTAINER_RESOURCE = "&restype=container";
const string APPEND_BLOCK_RESOURCE = "&comp=appendBlock";
const string GET_PAGE_RANGE_RESOURCE = "&comp=pagelist";
const string COMP_METADATA = "&comp=metadata";
const string COMP_ACL = "&comp=acl";
const string BLOB_SERVICE_PROPERTIES_RESOURCE = "&restype=service&comp=properties";
const string BLOB_SERVICE_STATS_RESOURCE = "&restype=service&comp=stats";
const string ABORT_COPY_RESOURCE = "&comp=copy&copyid=";
const string UNDELETE_RESOURCE = "&comp=undelete";
const string PUT_PAGE_RESOURCE = "&comp=page";
const string PUT_BLOCK_RESOURCE = "&comp=block&blockid=";

// Azure Storage URI Strings
const string COMP = "comp";
const string RESTYPE = "restype";
const string LIST = "list";
const string CONTAINER = "container";
const string METADATA = "metadata";
const string TAGS = "tags";
const string BLOCK = "block";
const string BLOCKID = "blockid";
const string PROPERTIES = "properties";
const string ACCOUNT = "account";
const string SERVICE = "service";
const string STATS = "stats";
const string ACL = "acl";
const string ALL = "all";
const string BLOCKLIST = "blocklist";
const string BLOCKLISTTYPE = "blocklisttype";
const string UNDELETE = "undelete";
const string COPY = "copy";
const string COPYID = "copyid";
const string PAGELIST = "pagelist";
const string PREVSNAPSHOT = "prevsnapshot";
const string APPENDBLOCK = "appendblock";
const string PAGE = "page";

// Azure Storage Headers
const string X_MS_ACCESS_TIER = "x-ms-access-tier";
const string X_MS_ACCOUNT_KIND = "x-ms-account-kind";
const string X_MS_BLOB_APPEND_OFFSET = "x-ms-blob-append-offset";
const string X_MS_BLOB_COMMITTED_BLOCK_COUNT = "x-ms-blob-committed-block-count";
const string X_MS_BLOB_SEQUENCE_NUMBER = "x-ms-blob-sequence-number";
const string X_MS_BLOB_TYPE = "x-ms-blob-type";
const string X_MS_BLOB_CONTENT_ENCODING = "x-ms-blob-content-encoding";
const string X_MS_BLOB_CONTENT_LANGUAGE = "x-ms-blob-content-language";
const string X_MS_BLOB_CONTENT_LENGTH = "x-ms-blob-content-length";
const string X_MS_BLOB_CONTENT_TYPE = "x-ms-blob-content-type";
const string X_MS_BLOB_PUBLIC_ACCESS = "x-ms-blob-public-access";
const string X_MS_CLIENT_REQUEST_ID = "x-ms-client-request-id";
const string X_MS_COPY_ACTION = "x-ms-copy-action";
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
const string X_MS_PREVIOUS_SNAPSHOT_URL = "x-ms-previous-snapshot-url";
const string X_MS_RANGE = "x-ms-range";
const string X_MS_REQUIRES_SYNC = "x-ms-requires-sync";
const string X_MS_REHYDRATE_PRIORITY = "x-ms-rehydrate-priority";
const string X_MS_SKU_NAME = "x-ms-sku-name";
const string X_MS_SOURCE_RANGE = "x-ms-source-range";
const string X_MS_VERSION = "x-ms-version";
const string X_MS = "x-ms";
const string X_MS_META = "x-ms-meta";
const string LAST_MODIFIED = "Last-Modified";
const string CONTENT_LENGTH = "Content-Length";
const string CONTENT_ENCODING = "Content-Encoding";
const string CONTENT_LANGUAGE = "Content-Language";
const string CONTENT_MD5 = "Content-MD5";
const string CONTENT_TYPE = "content-type";
const string ETAG = "ETag";
const string IF_MODIFIED_SINCE = "If-Modified_Since";
const string IF_MATCH = "If-Match";
const string IF_NONE_MATCH = "If-None-Match";
const string IF_UNMODIFIED_SINCE = "If-Unmodified-Since";
const string PREFIX = "prefix";
const string MARKER = "marker";
const string MAXRESULTS = "maxresults";
const string SNAPSHOT = "snapshot";
const string TIMEOUT = "timeout";
const string VERSION_ID = "versionid";
const string ORIGIN = "Origin";
const string RANGE = "Range";
const string DATE = "Date";

// Azure Storage Strings
const string APPEND_BLOB = "AppendBlob";
const string BLOCK_BLOB = "BlockBlob";
const string PAGE_BLOB = "PageBlob";

// Error Messages
const string AZURE_BLOB_ERROR_CODE = "(ballerinax/azure-storage-service)BlobError";
const string REST_API_ERROR_MESSAGE = "Error occured while invoking the REST API.";

// Commonly used string constants
const string COLON_SYMBOL = ":";
const string SEMICOLON_SYMBOL = ";";
const string WHITE_SPACE = " ";
const string EMPTY_STRING = "";
const string QUOTATION_MARK = "\"";
const string NEW_LINE = "\n";
const string FORWARD_SLASH_SYMBOL = "/";
const string VERTICAL_BAR = "|";
const string QUESTION_MARK = "?";
const string EQUAL_SYMBOL = "=";
const string AMPERSAND_SYMBOL = "&";
const string STATUS_CODE = "Status Code";
const string ABORT = "abort";
const string CLEAR = "clear";
const string UPDATE = "update";
const string AUTHORIZATION = "Authorization";
const string SHARED_KEY = "SharedKey";
const string SHARED_ACCESS_SIGNATURE = "SharedAccessSignature";
const string ZERO = "0";
const string GMT = "GMT";
const string GET = "GET";
const string PUT = "PUT";
const string HEAD = "HEAD";
const string DELETE = "DELETE";
