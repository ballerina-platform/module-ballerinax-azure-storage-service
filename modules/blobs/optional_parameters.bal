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

// Holder of optional headers and optional uri parameters
public type OptionsHolder record {|
    map<string> optionalHeaders = {};
    map<string> optionalURIParameters = {};
|};

// List Containers Options
public type ListContainersOptions record {|
    // uri parameters
    string prefix = "";
    string marker = "";
    string maxresults = "";
    string timeout = "";

    // headers
    string clientRequestId = "";
|};

// Add optional parameters for List Containers operation
isolated function prepareListContainersOptions(ListContainersOptions? optionalParams) returns OptionsHolder {
    OptionsHolder holder = {};
    if (optionalParams is ListContainersOptions) {
        // Add optional URI Parameters
        if (optionalParams.prefix != "") {
            holder.optionalURIParameters[PREFIX] = optionalParams.prefix;
        }

        if (optionalParams.marker != "") {
            holder.optionalURIParameters[MARKER] = optionalParams.marker;
        }

        if (optionalParams.maxresults != "") {
            holder.optionalURIParameters[MAXRESULTS] = optionalParams.maxresults;
        }

        if (optionalParams.timeout != "") {
            holder.optionalURIParameters[TIMEOUT] = optionalParams.timeout;
        }

        // Add optional headers
        if (optionalParams.clientRequestId != "") {
            holder.optionalHeaders[X_MS_CLIENT_REQUEST_ID] = optionalParams.clientRequestId;
        }
    }
    return holder;
}

// List Blobs Options
public type ListBlobsOptions record {|
    // uri parameters
    string prefix = "";
    string marker = "";
    string maxresults = "";
    string timeout = "";
    
    // headers
    string clientRequestId = "";
|};

// Add optional parameters for List Blobs operation
isolated function prepareListBlobsOptions(ListBlobsOptions? optionalParams) returns OptionsHolder {
    OptionsHolder holder = {};
    if (optionalParams is ListBlobsOptions) {
        // Add optional URI Parameters
        if (optionalParams.prefix != "") {
            holder.optionalURIParameters[PREFIX] = optionalParams.prefix;
        }

        if (optionalParams.marker != "") {
            holder.optionalURIParameters[MARKER] = optionalParams.marker;
        }

        if (optionalParams.maxresults != "") {
            holder.optionalURIParameters[MAXRESULTS] = optionalParams.maxresults;
        }

        if (optionalParams.timeout != "") {
            holder.optionalURIParameters[TIMEOUT] = optionalParams.timeout;
        }

        // Add optional headers
        if (optionalParams.clientRequestId != "") {
            holder.optionalHeaders[X_MS_CLIENT_REQUEST_ID] = optionalParams.clientRequestId;
        }
    }
    return holder;
}

// Get Blob Options
public type GetBlobOptions record {|
    // uri parameters
    string snapshot = "";
    string versionid = "";
    string timeout = "";

    // headers
    string range = "";
    string leaseId = "";
    string origin = "";
    string clientRequestId = "";
|};

// Add optional parameters for Get Blob operation
isolated function prepareGetBlobOptions(GetBlobOptions? optionalParams) returns OptionsHolder {
    OptionsHolder holder = {};
    if (optionalParams is GetBlobOptions) {
        // Add optional URI Parameters
        if (optionalParams.snapshot != "") {
            holder.optionalURIParameters[SNAPSHOT] = optionalParams.snapshot;
        }

        if (optionalParams.versionid != "") {
            holder.optionalURIParameters[VERSION_ID] = optionalParams.versionid;
        }

        if (optionalParams.timeout != "") {
            holder.optionalURIParameters[TIMEOUT] = optionalParams.timeout;
        }

        // Add optional headers
        if (optionalParams.range != "") {
            holder.optionalHeaders[X_MS_RANGE] = optionalParams.range;
        }
        
        if (optionalParams.leaseId != "") {
            holder.optionalHeaders[X_MS_LEASE_ID] = optionalParams.leaseId;
        }

        if (optionalParams.origin != "") {
            holder.optionalHeaders[ORIGIN] = optionalParams.origin;
        }

        if (optionalParams.clientRequestId != "") {
            holder.optionalHeaders[X_MS_CLIENT_REQUEST_ID] = optionalParams.clientRequestId;
        }  
    }
    return holder;
}

// Get Blob Metadata Options
public type GetBlobMetadataOptions record {|
    // uri parameters
    string snapshot = "";
    string versionid = "";
    string timeout = "";

    // headers
    string leaseId = "";
    string clientRequestId = "";
|};

// Add optional parameters for Get Blob Metadata operation
isolated function prepareGetBlobMetadataOptions(GetBlobMetadataOptions? optionalParams) returns OptionsHolder {
    OptionsHolder holder = {};
    if (optionalParams is GetBlobMetadataOptions) {
        // Add optional URI Parameters
        if (optionalParams.snapshot != "") {
            holder.optionalURIParameters[SNAPSHOT] = optionalParams.snapshot;
        }

        if (optionalParams.versionid != "") {
            holder.optionalURIParameters[VERSION_ID] = optionalParams.versionid;
        }

        if (optionalParams.timeout != "") {
            holder.optionalURIParameters[TIMEOUT] = optionalParams.timeout;
        }

        // Add optional headers
        if (optionalParams.leaseId != "") {
            holder.optionalHeaders[X_MS_LEASE_ID] = optionalParams.leaseId;
        }

        if (optionalParams.clientRequestId != "") {
            holder.optionalHeaders[X_MS_CLIENT_REQUEST_ID] = optionalParams.clientRequestId;
        }
    }
    return holder;
}

// Get Blob Properties Options
public type GetBlobPropertiesOptions record {|
    // uri parameters
    string snapshot = "";
    string versionid = "";
    string timeout = "";

    // headers
    string leaseId = "";
    string clientRequestId = "";
|};

// Add optional parameters for Get Blob Properties operation 
isolated function prepareGetBlobPropertiesOptions(GetBlobPropertiesOptions? optionalParams) returns OptionsHolder {
    OptionsHolder holder = {};
    if (optionalParams is GetBlobPropertiesOptions) {
        // Add optional URI Parameters
        if (optionalParams.snapshot != "") {
            holder.optionalURIParameters[SNAPSHOT] = optionalParams.snapshot;
        }

        if (optionalParams.versionid != "") {
            holder.optionalURIParameters[VERSION_ID] = optionalParams.versionid;
        }

        if (optionalParams.timeout != "") {
            holder.optionalURIParameters[TIMEOUT] = optionalParams.timeout;
        }

        // Add optional headers
        if (optionalParams.leaseId != "") {
            holder.optionalHeaders[X_MS_LEASE_ID] = optionalParams.leaseId;
        }

        if (optionalParams.clientRequestId != "") {
            holder.optionalHeaders[X_MS_CLIENT_REQUEST_ID] = optionalParams.clientRequestId;
        }
    }
    return holder;
}

// Get Block List Options
public type GetBlockListOptions record {|
    // uri parameters
    string snapshot = "";
    string versionid = "";
    string timeout = ""; 

    // headers
    string leaseId = "";
    string clientRequestId = "";
|};

// Add optional parameters for Get Block List operation
isolated function prepareGetBlockListOptions(GetBlockListOptions? optionalParams) returns OptionsHolder {
    OptionsHolder holder = {};
    if (optionalParams is GetBlockListOptions) {
        // Add optional URI Parameters
        if (optionalParams.snapshot != "") {
            holder.optionalURIParameters[SNAPSHOT] = optionalParams.snapshot;
        }

        if (optionalParams.versionid != "") {
            holder.optionalURIParameters[VERSION_ID] = optionalParams.versionid;
        }

        if (optionalParams.timeout != "") {
            holder.optionalURIParameters[TIMEOUT] = optionalParams.timeout;
        }

        // Add optional headers
        if (optionalParams.leaseId != "") {
            holder.optionalHeaders[X_MS_LEASE_ID] = optionalParams.leaseId;
        }

        if (optionalParams.clientRequestId != "") {
            holder.optionalHeaders[X_MS_CLIENT_REQUEST_ID] = optionalParams.clientRequestId;
        }
    }
    return holder;
}

// Put Blob Options
public type PutBlobOptions record {|
    // uri parameters
    string timeout = "";

    // headers
    string contentType = "";
    string contentEncoding = "";
    string contentLanguage = "";
    string leaseId = "";
    string origin = "";
    string accessTier = "";
    string clientRequestId = "";
    // Headers only for pageblobs
    string pageBlobLength = ""; // Required
    string sequenceNumber = "";
|};

// Add optional parameters for Put Blob operation
isolated function preparePutBlobOptions(PutBlobOptions? optionalParams) returns OptionsHolder {
    OptionsHolder holder = {};
    if (optionalParams is PutBlobOptions) {
        // Add optional URI Parameters
        if (optionalParams.timeout != "") {
            holder.optionalURIParameters[TIMEOUT] = optionalParams.timeout;
        }

        // Add optional headers
        if (optionalParams.leaseId != "") {
            holder.optionalHeaders[X_MS_LEASE_ID] = optionalParams.leaseId;
        }

        if (optionalParams.origin != "") {
            holder.optionalHeaders[ORIGIN] = optionalParams.origin;
        }

        if (optionalParams.accessTier != "") {
            holder.optionalHeaders[X_MS_ACCESS_TIER] = optionalParams.accessTier;
        }

        if (optionalParams.clientRequestId != "") {
            holder.optionalHeaders[X_MS_CLIENT_REQUEST_ID] = optionalParams.clientRequestId;
        }

        if (optionalParams.sequenceNumber != "") {
            holder.optionalHeaders[X_MS_BLOB_SEQUENCE_NUMBER] = optionalParams.sequenceNumber;
        }

        if (optionalParams.pageBlobLength != "") {
            holder.optionalHeaders[X_MS_BLOB_CONTENT_LENGTH] = optionalParams.pageBlobLength;
        }
    }
    return holder;
}

// Put Blob from URL Options
public type PutBlobFromURLOptions record {|
    // uri parameters
    string timeout = ""; 

    // headers
    string contentType = "";
    string contentEncoding = "";
    string contentLanguage = "";
    string origin = "";
    string accessTier = "";
    string clientRequestId = "";
|};

// Add optional parameters for Put blob from url operation
isolated function preparePutBlobFromURLOptions(PutBlobFromURLOptions? optionalParams) returns OptionsHolder {
    OptionsHolder holder = {};
    if (optionalParams is PutBlobFromURLOptions) {
        // Add optional URI Parameters
        if (optionalParams.timeout != "") {
            holder.optionalURIParameters[TIMEOUT] = optionalParams.timeout;
        }

        // Add optional headers
        if (optionalParams.contentType != "") {
            holder.optionalHeaders[X_MS_BLOB_CONTENT_TYPE] = optionalParams.contentType;
        }

        if (optionalParams.contentEncoding != "") {
            holder.optionalHeaders[X_MS_BLOB_CONTENT_ENCODING] = optionalParams.contentEncoding;
        }

        if (optionalParams.contentLanguage != "") {
            holder.optionalHeaders[X_MS_BLOB_CONTENT_LANGUAGE] = optionalParams.contentLanguage;
        }

        if (optionalParams.origin != "") {
            holder.optionalHeaders[ORIGIN] = optionalParams.origin;
        }

        if (optionalParams.accessTier != "") {
            holder.optionalHeaders[X_MS_ACCESS_TIER] = optionalParams.accessTier;
        }

        if (optionalParams.clientRequestId != "") {
            holder.optionalHeaders[X_MS_CLIENT_REQUEST_ID] = optionalParams.clientRequestId;
        }
    }
    return holder;
}

// Delete Blob Options
public type DeleteBlobOptions record {|
    // uri parameters
    string snapshot = "";
    string versionid = "";
    string timeout = "";  

    // headers
    string leaseId = "";
    string clientRequestId = "";
|};

// Add optional parameters for Delete Blob Operation
isolated function prepareDeleteBlobOptions(DeleteBlobOptions? optionalParams) returns OptionsHolder {
    OptionsHolder holder = {};
    if (optionalParams is DeleteBlobOptions) {
        // Add optional URI Parameters
        if (optionalParams.snapshot != "") {
            holder.optionalURIParameters[SNAPSHOT] = optionalParams.snapshot;
        }

        if (optionalParams.versionid != "") {
            holder.optionalURIParameters[VERSION_ID] = optionalParams.versionid;
        }

        if (optionalParams.timeout != "") {
            holder.optionalURIParameters[TIMEOUT] = optionalParams.timeout;
        }

        // Add optional headers
        if (optionalParams.leaseId != "") {
            holder.optionalHeaders[X_MS_LEASE_ID] = optionalParams.leaseId;
        }

        if (optionalParams.clientRequestId != "") {
            holder.optionalHeaders[X_MS_CLIENT_REQUEST_ID] = optionalParams.clientRequestId;
        }
    }
    return holder;
}

// Copy Blob Options
public type CopyBlobOptions record {|
    // uri parameters
    string timeout = ""; 

    // headers
    string leaseId = "";
    string accessTier = "";
    string rehydratePriority = "";
    string clientRequestId = "";
|};

// Add optional parameters for Copy Blob operation
isolated function prepareCopyBlobOptions(CopyBlobOptions? optionalParams) returns OptionsHolder {
    OptionsHolder holder = {};
    if (optionalParams is CopyBlobOptions) {
        // Add optional URI Parameters
        if (optionalParams.timeout != "") {
            holder.optionalURIParameters[TIMEOUT] = optionalParams.timeout;
        }

        // Add optional headers
        if (optionalParams.accessTier != "") {
            holder.optionalHeaders[X_MS_ACCESS_TIER] = optionalParams.accessTier;
        }

        if (optionalParams.rehydratePriority != "") {
            holder.optionalHeaders[X_MS_REHYDRATE_PRIORITY] = optionalParams.rehydratePriority;
        }

        if (optionalParams.leaseId != "") {
            holder.optionalHeaders[X_MS_LEASE_ID] = optionalParams.leaseId;
        }

        if (optionalParams.clientRequestId != "") {
            holder.optionalHeaders[X_MS_CLIENT_REQUEST_ID] = optionalParams.clientRequestId;
        }
    }
    return holder;
}

// Get Page Ranges Options
public type GetPageRangesOptions record {|
    // uri parameters
    string snapshot = "";
    string prevsnapshot = "";
    string timeout = ""; 

    // headers
    string range = "";
    string leaseId = "";
    string previousSnapshotURL = "";
    string clientRequestId = "";
|};

// Add optional parameters for Get Page Ranges operation
isolated function prepareGetPageRangesOptions(GetPageRangesOptions? optionalParams) returns OptionsHolder {
    OptionsHolder holder = {};
    if (optionalParams is GetPageRangesOptions) {
        // Add optional URI Parameters
        if (optionalParams.snapshot != "") {
            holder.optionalURIParameters[SNAPSHOT] = optionalParams.snapshot;
        }

        if (optionalParams.prevsnapshot != "") {
            holder.optionalURIParameters[PREVSNAPSHOT] = optionalParams.prevsnapshot;
        }

        if (optionalParams.timeout != "") {
            holder.optionalURIParameters[TIMEOUT] = optionalParams.timeout;
        }

        //Add optional headers
        if (optionalParams.range != "") {
           holder.optionalHeaders[X_MS_RANGE] = optionalParams.range;
        }

        if (optionalParams.leaseId != "") {
            holder.optionalHeaders[X_MS_LEASE_ID] = optionalParams.leaseId;
        }

        if (optionalParams.previousSnapshotURL != "") {
            holder.optionalHeaders[X_MS_PREVIOUS_SNAPSHOT_URL] = optionalParams.previousSnapshotURL;
        }

        if (optionalParams.clientRequestId != "") {
            holder.optionalHeaders[X_MS_CLIENT_REQUEST_ID] = optionalParams.clientRequestId;
        } 
    }
    return holder;
}

// Put Block from URL Options
public type PutBlockFromURLOptions record {|
    // uri parameters
    string timeout = "";

    // headers
    string sourceRange = "";
    string leaseId = "";
    string clientRequestId = "";
|};

// Add optional parameters for Put Block from URL operation
isolated function preparePutBlockFromURLOptions(PutBlockFromURLOptions? optionalParams) returns OptionsHolder {
    OptionsHolder holder = {};
    if (optionalParams is PutBlockFromURLOptions) {
        // Add optional URI Parameters
        if (optionalParams.timeout != "") {
            holder.optionalURIParameters[TIMEOUT] = optionalParams.timeout;
        }

        // Add optional headers
        if (optionalParams.sourceRange != "") {
            holder.optionalHeaders[X_MS_SOURCE_RANGE] = optionalParams.sourceRange;
        }

        if (optionalParams.leaseId != "") {
            holder.optionalHeaders[X_MS_LEASE_ID] = optionalParams.leaseId;
        }

        if (optionalParams.clientRequestId != "") {
            holder.optionalHeaders[X_MS_CLIENT_REQUEST_ID] = optionalParams.clientRequestId;
        }
    }
    return holder;
}
