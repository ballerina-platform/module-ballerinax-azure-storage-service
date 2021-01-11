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

isolated function getListContainerOptParams(ListContainersOptionalParameters? optionalParams) 
        returns OptionalParameterMapsHolder {
    OptionalParameterMapsHolder holder = {};

    if (optionalParams is ListContainersOptionalParameters) {
        // Add optional URI Parameters
        if (optionalParams.prefix != "") {
            holder.optionalURIParameters["prefix"] = optionalParams.prefix;
        }

        if (optionalParams.marker != "") {
            holder.optionalURIParameters["marker"] = optionalParams.marker;
        }

        if (optionalParams.maxresults != "") {
            holder.optionalURIParameters["maxresults"] = optionalParams.maxresults;
        }

        if (optionalParams.timeout != "") {
            holder.optionalURIParameters["timeout"] = optionalParams.timeout;
        }

        // Add optional headers
        if (optionalParams.clientRequestId != "") {
            holder.optionalHeaders["x-ms-client-request-id"] = optionalParams.clientRequestId;
        }
    }
    return holder;
}

public type ListBlobsOptionalParameters record {
    string prefix;
    string marker;
    string maxresults;
    string timeout;
    //
    string clientRequestId;
};

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

public type GetAccountInformationOptionalParameters record {
     
    //
    string clientRequestId;
};

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

public type GetBlockListOptionalParameters record {
    string snapshot;
    string versionid;
    string timeout; 
    //
    string leaseId;
    string clientRequestId;
};

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
