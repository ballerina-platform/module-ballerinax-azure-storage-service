////Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  PLEASE NOTE THAT WE HAVE USED CAPITAL LETTERS AS THE FIRST LETTER OF A VARIABLES DUE TO AN WORKAROUND OF         ////  "cloneWithType" FUNCTION THAT USED IN THE PROCESS OF CONVERTING XML RESPONSE TO RECORD TYPE                      //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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
# + secureSocketConfig - Holds ClientSecureSocket type details.
# + sharedKeyOrSASToken - Shared key or Shared Access Signature Token for the file service access.
# + storageAccountName - Name of the Azure Storage account.
# + isSharedKeySet - Holds true if Shared key is used else it is false for SAS token by default.
public type AzureConfiguration record {
    http:ClientSecureSocket secureSocketConfig?;
    string sharedKeyOrSASToken;
    string storageAccountName;
    boolean isSharedKeySet = false;
};

#Represnts an azure directory 
# 
# + Name - Name of the azure directory
# + Properties - Properties of the directory
public type Directory record {|
    string Name;
    PropertiesFileItem|"" Properties?;
|};

#Represents a azure file
#
# + Name - Name of the azure file
# + Properties - Properties of the azure file
public type File record {|
    string Name;
    PropertiesFileItem|"" Properties?;
|};

#Represents the details of the Properties
#
# + 'Content\-Length - Content Length of the file
public type PropertiesFileItem record {
    string 'Content\-Length?;
};

#Represents a list of files
#
# + File - A file of list of files
# + Marker - Marker for the list
# + MaxResults - limits number of results in the list
public type FileList record {|
    File[]|File File;
    string Marker?;
    int MaxResults?;
|};

#Represents a list of  azure direcotories
#
# + Directory - A directory or a list of directory
# + Marker - Marker for the list
# + MaxResults - limits number of results in the list
public type DirectoryList record {|
    Directory[]|Directory Directory;
    string Marker?;
    int MaxResults?;
|};

#Represents a range of a file content
#
# + Ranges - A list of Ranges
public type RangeList record {
    string|RangeItemList Ranges;
};

#Represents a range item list as a record
#
# + Range - Range item
public type RangeItemList record {|
    RangeItem Range;
|};

#Represents a range item as a record
#
# + Start - Start byte
# + End - End byte
public type RangeItem record {|
    string Start;
    string End;
|};

#Represents different types of  Request parameters
#
# + fileShareName - Name of the fileshare
# + azureDirectoryName - Name of the azure directory
# + azureFileNamestring - Name of the file name
# + azureDirectoryPath - Path of the azure directory
# + SearchPrefix - Search prefix word
# + maxResult - Maximum number of search results in the response
# + marker - Marker to the left items if any
# + newDirectoryName - Name of the new directory to be created 
# + fileSizeInByte - Size of the file in bytes
# + localFilePath - Path to the local location of a file
public type RequestParameterList record {|
    string fileShareName;
    string azureDirectoryName?;
    string azureFileNamestring?;
    string azureDirectoryPath?;
    string SearchPrefix?;
    int maxResult?;
    int marker?;
    string newDirectoryName?;
    int fileSizeInByte?;
    string localFilePath?;
|};
