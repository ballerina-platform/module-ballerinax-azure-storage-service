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

import ballerina/http;
import ballerinax/'client.config;

# Azure Blob Service Configuration.
@display {label: "Connection Config"}
public type ConnectionConfig record {|
    *config:ConnectionConfig;
    never auth?;
    # Access key or Shared Access Signature for Azure Storage Account
    @display {
        label: "",
        kind: "password"
    }
    string accessKeyOrSAS;
    # Name of the Azure Storage account
    string accountName;
    # Holds the used authorization method from the enum AuthorizationMethod
    AuthorizationMethod authorizationMethod;
    # The HTTP version understood by the client
    http:HttpVersion httpVersion = http:HTTP_1_1;
|};

# Represents Azure Storage Account Information.
#
# + skuName - skuName of the specified account
# + accountKind - accountKind of the specified account
# + isHNSEnabled - indicates if the account has a hierarchical namespace enabled
# + responseHeaders - reponse headers and values related to the operation
public type AccountInformationResult record {
    string skuName;
    string accountKind;
    string isHNSEnabled;
    ResponseHeaders responseHeaders;
};

# Represents Response headers.
#
# + Date - A UTC date/time value that indicates the time at which the response was initiated
# + x\-ms\-version - Indicates the version of Blob Storage used to run the request
# + x\-ms\-request\-id - Uniquely identifies the request that was made, and can be used for troubleshooting
public type ResponseHeaders record {
    string Date;
    string x\-ms\-version;
    string x\-ms\-request\-id;
};

# Represents Azure Storage Container.
#
# + Name - The name of the container
# + Version - Container version
# + Deleted - Is the container deleted
# + Properties - Properties of the container
# + Metadata - Container Metadata
public type Container record {
    string Name;
    map<json> Properties;
    string Version?;
    string Deleted?;
    map<json> Metadata?;
};

# Represents Azure Storage Blob.
#
# + Name - Name of the Blob
# + Snapshot - A date time value
# + VersionId - A date time value
# + IsCurrentVersion - if it is the current version or not
# + Deleted - If it is deleted or not
# + Properties - Properties of the blob
public type Blob record {
    string Name;
    map<json> Properties;
    string Snapshot?;
    string VersionId?;
    string IsCurrentVersion?;
    string Deleted?;

};

# Represents Azure Storage Blob Properties.
#
# + Etag - Etag
# + BlobType - Type of the blob
# + AccessTier - AccessTier of the blob
# + AccessTierInferred - AccessTierInferred of the blob
# + LeaseStatus - LeaseStatus of the Blob
# + LeaseState - LeaseState of the blob
# + ServerEncrypted - indicates if the server is encrypted
public type BlobProperties record {
    string Etag;
    string BlobType;
    string AccessTier;
    string AccessTierInferred;
    string LeaseStatus;
    string LeaseState;
    string ServerEncrypted;
};

# Represents List Container Result.
#
# + containerList - List of Containers
# + nextMarker - Offset value
# + responseHeaders - Response headers from Azure
public type ListContainerResult record {|
    Container[] containerList;
    string nextMarker;
    ResponseHeaders responseHeaders;
|};

# Represents List Blob Result.
#
# + blobList - List of Blobs
# + nextMarker - Offset value
# + responseHeaders - Response headers from Azure
public type ListBlobResult record {
    Blob[] blobList;
    string nextMarker;
    ResponseHeaders responseHeaders;
};

# Represents Blob Service Properties Result.
#
# + storageServiceProperties - Storage Service properties
# + responseHeaders - Response headers from Azure
public type BlobServicePropertiesResult record {
    json storageServiceProperties;
    ResponseHeaders responseHeaders;
};

# Represents Blob Result.
#
# + blobContent - Content of the blob
# + properties - Blob properties
# + responseHeaders - Response headers from Azure
public type BlobResult record {|
    byte[] blobContent;
    ResponseHeaders responseHeaders;
    Properties properties;
|};

# Represents additional properties of a blob.
#
# + blobContentType - Blob Content Type
# + blobContentEncoding - Blob Content Encoding
# + blobContentMd5 - Blob Content MD5
# + metadata - Blob metadata as name-value pairs
public type Properties record {|
    string blobContentType?;
    string blobContentEncoding?;
    string blobContentMd5?;
    map<string> metadata?;
|};

# Represents Container Properties Result.
#
# + eTag - ETag
# + lastModified - Date/time that the blob was last modified
# + leaseStatus - Lease status of the container
# + leaseState - Lease state of the container
# + leaseDuration - Lease duration of the container
# + publicAccess - Public access of the container
# + hasImmutabilityPolicy - If it has immutability policy
# + hasLegalHold - If it has legal hold
# + metaData - Meta data of container
# + responseHeaders - Response headers from Azure
public type ContainerPropertiesResult record {
    string eTag;
    string lastModified;
    string leaseStatus;
    string leaseState;
    string leaseDuration?;
    string publicAccess?;
    string hasImmutabilityPolicy;
    string hasLegalHold;
    map<string> metaData;
    ResponseHeaders responseHeaders;
};

# Represents Container Metadata Result.
#
# + metadata - Metadata of container
# + eTag - ETag
# + lastModified - Date/time that the blob was last modified
# + responseHeaders - Response headers from Azure
public type ContainerMetadataResult record {
    map<string> metadata;
    string eTag;
    string lastModified;
    ResponseHeaders responseHeaders;
};

# Represents Blob Metadata Result.
#
# + metadata - Metadata of blob
# + eTag - ETag
# + lastModified - Date/time that the blob was last modified
# + responseHeaders - Response headers from Azure
public type BlobMetadataResult record {
    map<string> metadata;
    string eTag;
    string lastModified;
    ResponseHeaders responseHeaders;
};

# Represents Container ACL Result.
#
# + signedIdentifiers - Signed Identifiers
# + lastModified - Date/time that the blob was last modified
# + eTag - ETag
# + publicAccess - Public access of container
# + responseHeaders - Response headers from Azure
public type ContainerACLResult record {
    json signedIdentifiers?;
    string publicAccess?;
    string eTag;
    string lastModified;
    ResponseHeaders responseHeaders;
};

# Represents Block List Result.
#
# + blockList - List of Blocks
# + responseHeaders - Response headers from Azure
public type BlockListResult record {
    json blockList;
    ResponseHeaders responseHeaders;
};

# Represents Copy Blob Result.
#
# + copyId - String identifier for this copy operation
# + copyStatus - State of the copy operation
# + lastModified - Date/time that the blob was last modified
# + eTag - ETag
# + responseHeaders - Response headers from Azure
public type CopyBlobResult record {
    string copyId;
    string copyStatus;
    string lastModified;
    string eTag;
    ResponseHeaders responseHeaders;
};

# Represents Page Range Result.
#
# + pageList - List of page ranges
# + responseHeaders - Response headers from Azure
public type PageRangeResult record {
    json pageList;
    ResponseHeaders responseHeaders;
};

# Represents PutPage Result.
#
# + blobSequenceNumber - The current sequence number for the page blob
# + eTag - ETag
# + lastModified - Date/time that the blob was last modified
# + responseHeaders - Response headers from Azure
public type PutPageResult record {
    string blobSequenceNumber;
    string eTag;
    string lastModified;
    ResponseHeaders responseHeaders;
};

# Represents AppendBlock Result.
#
# + blobAppendOffset - Offset at which the block was committed, in bytes
# + blobCommitedBlockCount - The number of committed blocks present in the blob
# + eTag - ETag
# + lastModified - Date/time that the blob was last modified
# + responseHeaders - Response headers from Azure
public type AppendBlockResult record {
    string blobAppendOffset;
    string blobCommitedBlockCount;
    string eTag;
    string lastModified;
    ResponseHeaders responseHeaders;
};

# Represents Byte Range of a blob
#
# + startByte - From which byte
# + endByte - Upto which byte
@display {label: "Byte Range"}
public type ByteRange record {
    @display {label: "Start Byte"}
    int startByte;
    @display {label: "End Byte"}
    int endByte;
};

public enum AccessLevel {
    CONTAINER = "container",
    BLOB = "blob"
}

# Defines the details of an error message.
#
# + httpStatus - HTTP status code associated with the error
# + errorCode - Azure Blob Storage error code
# + message - Associated error message
public type ServerErrorDetail record {|
    int httpStatus;
    string errorCode;
    string message;
|};

# Super type error returned by connector
public type Error ServerError|ClientError;

# Error created by connector depending on server responses
public type ServerError distinct error<ServerErrorDetail>;

# Error created by connector when processing or invoking
public type ClientError ProcessingError|http:ClientError;

# Error created by connector when processing, transforming data
public type ProcessingError distinct error;

# Error types as per https://learn.microsoft.com/en-us/rest/api/storageservices/blob-service-error-codes

# Error for Http Status 412
public type PreconditionFailedError distinct ServerError;

# Error for Http Status 409
public type ConflictError distinct ServerError;

# Error for Http Status 404
public type NotFoundError distinct ServerError;

# Error for Http Status 400
public type BadRequestError distinct ServerError;

# Error for Http Status 500
public type InternalServerError distinct ServerError;

# Error for Http Status 416
public type RequestedRangeNotSatisfiableError distinct ServerError;

# Error for Http Status 403
public type ForbiddenError distinct ServerError;
