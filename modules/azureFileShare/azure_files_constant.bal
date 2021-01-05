//API urls
# Holds the value for URL of refresh token end point.
const string LIST_SHARE_PATH = "/?comp=list";
const string GET_FILE_SERVICE_PROPERTIES = "/?restype=service&comp=properties";
const string CREATE_GET_DELETE_SHARE = "restype=share";
const string LIST_FILES_DIRECTORIES_PATH = "?restype=directory&comp=list";
const string CREATE_DIRECTORY_PATH = "?restype=directory";
const string PUT_RANGE_PATH = "comp=range";
const string LIST_FILE_RANGE = "comp=rangelist";
#Constants response codes
const int ACCEPTED = 202;
const int OK = 200;
const int CREATED = 201;
