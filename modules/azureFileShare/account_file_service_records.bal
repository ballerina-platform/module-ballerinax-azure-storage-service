import ballerina/http;

# Represents a list of FileShares
#
# + Shares - Shares type record
public type SharesList record {
    Shares Shares;
};

#Represents a File share or FileShare array
#
# + Share - An array of shares or a share record
public type Shares record {
    ShareItem[]|ShareItem Share;
};

#Represents a share 
#
# + Name - Name of the share
# + Properties - Properties of the share
public type ShareItem record {
    string Name;
    PropertiesItem Properties;
};

#Represents Properties of the share
#
# + 'Last\-Modified - Last Modified date and time.
# + Quota - Quota of the fileShare
# + Etag - Etag given by the fileShare
# + AccessTier - AccessTier of the fileShare
public type PropertiesItem record {
    string 'Last\-Modified;
    string Quota;
    string Etag?;
    string AccessTier?;
};

#Represents the file service properties list
#
# + StorageServiceProperties - Storage Service Properties record
public type FileServicePropertiesList record {
    StorageServicePropertiesType StorageServiceProperties;
};

#Represents the storage service properties type record
#
# + HourMetrics - Provides a summary of request statistics grouped by API in hourly aggregates
# + MinuteMetrics - Provides a summary of request statistics grouped by API for each minute.
# + Cors - Groups all CORS rules.
# + ProtocolSettings - Groups the settings for file system protocols.
public type StorageServicePropertiesType record {
    MetricsType HourMetrics?;
    MetricsType MinuteMetrics?;
    string|CorsType Cors?;
    ProtocolSettingsType ProtocolSettings?;
};

#Represents the Storage Analytics HourMetrics/MinuteMetrics settings
#
# + Version - The version of Storage Analytics to configure
# + Enabled - Indicates whether metrics are enabled for the File service.
# + IncludeAPIs -Indicates whether metrics should generate summary statistics for called API operations.
# + RetentionPolicy - Indicates whether metrics should generate summary statistics for called API operations.
public type MetricsType record {
    string Version;
    string|boolean Enabled?;
    string|boolean IncludeAPIs?;
    RetentionPolicyType RetentionPolicy?;
};

#Contains the CORS rules
#
# + CorsRules - Represents the CORS rules
public type CorsType record {
    CoreRulesType CorsRules?;
};

#Contains the Retention Policy details
#
# + Enabled - Indicates whether metrics are enabled for the File service.
# + Days - Indicates the number of days that metrics data should be retained.
public type RetentionPolicyType record {
    string Enabled?;
    string Days?;
};

#Represents a CORS rules
#
# + AllowedOrigins - A comma-separated list of origin domains that will be allowed via CORS, or "*" to allow all domains.
# + AllowedMethods - A comma-separated list of response headers to expose to CORS clients.
# + MaxAgeInSeconds - The number of seconds that the client/browser should cache a preflight response.
# + AllowedHeaders - A comma-separated list of headers allowed to be part of the cross-origin request.
# + ExposedHeaders - A comma-separated list of HTTP methods that are allowed to be executed by the origin. 
public type CoreRulesType record {
    string AllowedOrigins?;
    string AllowedMethods?;
    string MaxAgeInSeconds?;
    string AllowedHeaders?;
    string ExposedHeaders?;
};

#Groups the settings for file system protocols.
#
# + SMB - Represents SMB type variable 
public type ProtocolSettingsType record {
    SMBType SMB?;
};

#Groups the settings for SMB
#
# + Multichannel - Contains multi channel type record
public type SMBType record {
    MultichannelType Multichannel?;
};

#Contains the settings for SMB multichannel
#
# + Enabled - Toggles the state of SMB multichannel
public type MultichannelType record {
    string Enabled?;
};

# The types of records, which support the  azure operations.
public type AzureRecord FileServicePropertiesList|SharesList;

# The type description of the nested records.
public type AzureRecordType typedesc<AzureRecord>;

# Represents the azure error. This will be returned if an error occurred on Fileshare operations.
public type FileShareError distinct error;

# Represents the FileShare module related error.
public type Error FileShareError;

#Represents the azure connection configuration record
#
# + secureSocketConfig - Holds ClientSecureSocket type details
# + sasToken - Shared Access Signature Token for the fileShare access
# + baseUrl -  Base URL of the fileshare
public type AzureConfiguration record {
    http:ClientSecureSocket secureSocketConfig?;
    string sasToken;
    string baseUrl;
};
