public type OptionalParameterMapsHolder record {|
    map<string> optionalHeaders = {};
    map<string> optionalURIParameters = {};
|};

public type ListContainersOptionalParameters record {|
    // uri parameters
    string prefix = "";
    string marker = "";
    string maxresults = "";
    string timeout ="";

    // header parameters
    string clientRequestId ="";
|};

isolated function prepareListContainersOptParams(ListContainersOptionalParameters? optionalParams) 
        returns OptionalParameterMapsHolder {
    OptionalParameterMapsHolder holder = {};

    if (optionalParams is ListContainersOptionalParameters) {
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

public type ListBlobsOptionalParameters record {
    // uri parameters
    string prefix;
    string marker;
    string maxresults;
    string timeout;
    
    // header parameters
    string clientRequestId;
};

isolated function prepareListBlobsOptParams(ListBlobsOptionalParameters? optionalParams) 
        returns OptionalParameterMapsHolder {
    OptionalParameterMapsHolder holder = {};

    if (optionalParams is ListBlobsOptionalParameters) {
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

public type GetBlobOptionalParameters record {
    string snapshot;
    string versionid;
    string timeout;
    //
    string range;
    string leaseId;
    string origin;
    string clientRequestId;
};

isolated function prepareGetBlobOptParams(GetBlobOptionalParameters? optionalParams) 
        returns OptionalParameterMapsHolder {
    OptionalParameterMapsHolder holder = {};

    if (optionalParams is GetBlobOptionalParameters) {
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

public type GetBlobServicePropertiesOptionalParameters record {
    string timeout;
    //
    string clientRequestId;
};

public type GetBlobServiceStatsOptionalParameters record {
    string timeout;
    //
    string clientRequestId;
};

public type GetContainerPropertiesOptionalParameters record {
    string timeout;
    //
    string leaseId;
    string clientRequestId;
};

public type GetContainerMetadataOptionalParameters record {
    string timeout;
    //
    string leaseId;
    string clientRequestId;
};

public type GetBlobMetadataOptionalParameters record {
    string snapshot;
    string versionid;
    string timeout;
    //
    string leaseId;
    string clientRequestId;
};

isolated function prepareGetBlobMetadataOptParams(GetBlobMetadataOptionalParameters? optionalParams) 
        returns OptionalParameterMapsHolder {
    OptionalParameterMapsHolder holder = {};
    if (optionalParams is GetBlobMetadataOptionalParameters) {
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

public type GetContainerACLOptionalParameters record {
    string timeout;
    //
    string leaseId;
    string clientRequestId;
};

public type GetBlobPropertiesOptionalParameters record {
    string snapshot;
    string versionid;
    string timeout;
    //
    string leaseId;
    string clientRequestId;
};

isolated function prepareGetBlobPropertiesOptParams(GetBlobPropertiesOptionalParameters? optionalParams) 
        returns OptionalParameterMapsHolder {
    OptionalParameterMapsHolder holder = {};
    if (optionalParams is GetBlobMetadataOptionalParameters) {
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

public type GetBlockListOptionalParameters record {
    string snapshot;
    string versionid;
    string timeout; 
    //
    string leaseId;
    string clientRequestId;
};

isolated function prepareGetBlockListOptParams(GetBlockListOptionalParameters? optionalParams) 
        returns OptionalParameterMapsHolder {
    OptionalParameterMapsHolder holder = {};
    if (optionalParams is GetBlobMetadataOptionalParameters) {
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

public type PutBlobOptionalParameters record {
    string timeout;
    //
    string contentType;
    string contentEncoding;
    string contentLanguage;
    // Check about metadata
    //
    string leaseId;
    string origin;
    string accessTier;
    string clientRequestId;
    //Only for pageblobs
    string contentLengthBytes;
    string sequenceNumber;

};

public type PutBlobFromURLOptionalParameters record {
    string timeout; 
    //
    string contentType;
    string contentEncoding;
    string contentLanguage;
    string origin;
    string accessTier;
    string clientRequestId;
};

public type CreateContainerOptionalParameters record {
    string timeout;
    //
    string publicAccess;
    string clientRequestId;
};

public type DeleteContainerOptionalParameters record {
    string timeout; 
    //
    string leaseId;
    string clientRequestId;
};

public type DeleteBlobOptionalParameters record {
    string snapshot;
    string versionid;
    string timeout;  
    //
    string leaseId;
    string clientRequestId;
};

isolated function prepareDeleteBlobOptParams(DeleteBlobOptionalParameters? optionalParams) 
        returns OptionalParameterMapsHolder {
    OptionalParameterMapsHolder holder = {};
    if (optionalParams is GetBlobMetadataOptionalParameters) {
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

public type CopyBlobOptionalParameters record {
    string timeout; 
    //
    string leaseId;
    string accessTier;
    string rehydratePriority;
    string clientRequestId;
};

public type CopyBlobFromURLOptionalParameters record {
    string timeout; 
    //
    string leaseId;
    string clientRequestId;
};

public type GetPageRangesOptionalParameters record {
    string snapshot;
    string prevsnapshot;
    string timeout;  
    //
    string range;
    string leaseId;
    string previousSnapshotURL;
    string clientRequestId;
};

isolated function prepareGetPageRangesOptParams(GetPageRangesOptionalParameters? optionalParams) 
        returns OptionalParameterMapsHolder {
    OptionalParameterMapsHolder holder = {};
    if (optionalParams is GetPageRangesOptionalParameters) {
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

public type AppendBlockOptionalParameters record {
    string timeout;  
    //
    string leaseId;
    string clientRequestId;
};

public type AppendBlockFromURLOptionalParameters record {
    string timeout;   
    //
    string clientRequestId;
};

public type PutBlockOptionalParameters record {
    string timeout; 
    //
    string leaseId;
    string clientRequestId;
};

public type PutBlockFromURLOptionalParameters record {
    string timeout;
    //
    string sourceRange;
    string leaseId;
    string clientRequestId;
};

public type PutPageOptionalParameters record {
    string timeout;
    //
    string clientRequestId;
};
