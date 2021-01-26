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

# Represents Azure Storage Account Configuration.
#
# + sharedAccessSignature - sharedAccessSignature for the azure storage account
# + baseURL - baseURL of the azure storage account
# + accountName - Azure Storage Account Name
# + accessKey - Azure Storage Account Accesskey
# + authorizationMethod - SharedKey or SharedAccessSignature
public type AzureStorageConfiguration record {
    string sharedAccessSignature = "";
    string baseURL = "";
    string accountName = "";
    string accessKey = "";
    string authorizationMethod = "";
};

# Represents Azure Storage Account Information.
#
# + skuName - skuName of the specified account
# + accountKind - accountKind of the specified account
# + isHNSEnabled - indicates if the account has a hierarchical namespace enabled.
# + responseHeaders - reponse Headers and values related to the operation
public type AccountInformationResult record {|
    string skuName = "";
    string accountKind = "";
    string isHNSEnabled = "";
    map<json> responseHeaders = {};
|};

# Represents Azure Storage Container.
#
# + Name - The name of the container
# + Version - Container Version
# + Deleted - Is the container deleted
# + Properties - Properties of the container
# + Metadata - Container Metadata
public type Container record {
    string Name = "";
    string Version = "";
    string Deleted = "";
    ContainerProperties Properties = {};
    json Metadata = {};
};

# Represents Azure Storage Container Properties.
#
# + Etag - Etag od the container
# + LeaseStatus - LeaseStatus of the container
# + LeaseState - LeaseState of the container
# + LeaseDuration - Lease Duration
# + PublicAccess - PublicAccess of the container
# + DefaultEncryptionScope - DefaultEncryptionScope of the container
# + DenyEncryptionScopeOverride - DenyEncryptionScopeOverride of the container
# + HasImmutabilityPolicy - ImmutabilityPolicy of the container
# + HasLegalHold - LegalHold of the container
# + DeletedTime - Date and Time of deletion
# + RemainingRetentionDays - No of remaining retention days
# + LastModified - LastModified date
public type ContainerProperties record {
    string Etag = "";
    string LeaseStatus = "";
    string LeaseState = "";
    string LeaseDuration = "";
    string PublicAccess = "";
    string DefaultEncryptionScope = "";
    string DenyEncryptionScopeOverride = "";
    string HasImmutabilityPolicy = "";
    string HasLegalHold = "";
    string DeletedTime = "";
    string RemainingRetentionDays = "";
    string Last\-Modified = "";
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
    string Name = "";
    string Snapshot = "";
    string VersionId = "";
    string IsCurrentVersion = "";
    string Deleted = "";
    BlobProperties Properties = {};
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
    string Etag = "";
    string BlobType = "";
    string AccessTier = "";
    string AccessTierInferred = "";
    string LeaseStatus = "";
    string LeaseState = "";
    string ServerEncrypted = "";
};

# Represents Storage Service Properties
# 
# + Logging - Groups the Azure Analytics Logging settings.
# + HourMetrics - Groups the Azure Analytics HourMetrics settings. 
# + MinuteMetrics - Groups the Azure Analytics MinuteMetrics settings. 
# + Cors - Groups all CORS rules.
# + DefaultServiceVersion - version to use if an incoming request’s version is not specified.
# + DeleteRetentionPolicy - Groups the Azure Delete settings. Applies only to the Blob service.
# + StaticWebsite - Groups the staticwebsite settings. Applies only to the Blob service.
public type StorageServiceProperties record {
    json Logging = {
        Version: (),
        Delete: (),
        Read: (),
        Write: (),
        RetentionPolicy: {
            Enabled: (),
            Days: ()
        }
    };
    json HourMetrics = {
        Version: (),
        Enabled: (),
        IncludeAPIs: (),
        RetentionPolicy: {
            Enabled: (),
            Days: ()
        }
    };
    json MinuteMetrics = {
        Version: (),
        Enabled: (),
        IncludeAPIs: (),
        RetentionPolicy: {
            Enabled: (),
            Days: ()
        }
    };
    json Cors = {
        AllowedOrigins: (),
        AllowedMethods: (),
        MaxAgeInSeconds: (),
        ExposedHeaders: (),
        AllowedHeaders: ()
    };
    string DefaultServiceVersion = "";
    json DeleteRetentionPolicy = {
        Enabled: (),
        Days: ()
    };
    json StaticWebsite = {
        Enabled: (),
        IndexDocument: (),
        DefaultIndexDocumentPath: (),
        ErrorDocument404Path: ()
    };
};

# Represents Storage Service Stats
# 
# + GeoReplication - Geo Replication detail
public type StorageServiceStats record {
    json GeoReplication = {
        Status: (),
        LastSyncTime: ()
    };
};

// Record type to return result for listContainers
public type ListContainerResult record {|
    Container[] containerList = [];
    string nextMarker = "";
    map<json> responseHeaders = {};
|};

// Record type to return result for listBlobs
public type ListBlobResult record {|
    Blob[] blobList = [];
    string nextMarker = "";
    map<json> responseHeaders = {};
|};

public type BlobServicePropertiesResult record {|
    StorageServiceProperties storageServiceProperties = {};
    map<json> responseHeaders = {};
|};

public type BlobResult record {|
    byte[] blobContent = [];
    map<json> responseHeaders = {};
|};

public type ContainerPropertiesResult record {
    string eTag = ""; 
    string lastModified = "";
    string leaseStatus = "";
    string leaseState = "";
    string leaseDuration = ""; 
    string publicAccess = "";
    string hasImmutabilityPolicy = "";
    string hasLegalHold = "";
    map<string> metaData = {};
    map<json> responseHeaders = {};
};

public type ContainerMetadataResult record {
    map<string> metadata = {};
    string eTag = "";
    string lastModified = "";
    map<json> responseHeaders = {};
};

public type BlobMetadataResult record {
    map<string> metadata = {};
    string eTag = "";
    string lastModified = "";
    map<json> responseHeaders = {};
};

public type ContainerACLResult record {
    json signedIdentifiers = {};
    string eTag = "";
    string lastModified = "";
    string publicAccess = "";
    map<json> responseHeaders = {};
};

public type BlockListResult record {
    json blockList = {};
    map<json> responseHeaders = {};
};

public type CopyBlobResult record {
    string copyId = "";
    string copyStatus = "";
    string lastModified = "";
    string eTag = "";
    map<json> responseHeaders = {};
};

public type PageRangeResult record {
    json pageList = {};
    map<json> responseHeaders = {};
};

public type PutPageResult record {
    string blobSequenceNumber = "";
    string eTag = "";
    string lastModified = "";
    map<json> responseHeaders = {};
};

public type AppendBlockResult record {
    string blobAppendOffset = "";
    string blobCommitedBlockCount = "";
    string eTag = "";
    string lastModified = "";
    map<json> responseHeaders = {};
};

public type Result record {|
    boolean success = false;
    map<json> responseHeaders = {};
|};
