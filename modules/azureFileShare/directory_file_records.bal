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
# + Content \-Length - Content Length of the file
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
public type DirecotyList record {|
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
