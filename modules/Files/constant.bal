//Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
//API urls
# Holds the value for URL of refresh token end point.
const string LIST_SHARE_PATH = "/?comp=list";
const string GET_FILE_SERVICE_PROPERTIES = "/?restype=service&comp=properties";
const string CREATE_GET_DELETE_SHARE = "restype=share";
const string LIST_FILES_DIRECTORIES_PATH = "?restype=directory&comp=list";
const string CREATE_DELETE_DIRECTORY_PATH = "?restype=directory";
const string PUT_RANGE_PATH = "comp=range";
const string LIST_FILE_RANGE = "comp=rangelist";

#Constants response codes
const int ACCEPTED = 202;
const int OK = 200;
const int CREATED = 201;

#Constants values
const int MAX_UPLOADING_BYTE_SIZE = 4194304;

#Constant symbols
const string AMPERSAND = "&";
const string SLASH = "/";
const string QUESTION_MARK = "?";

#Remote Operations' names 
const string LIST_SHARES = "listShares";
const string CREATE_SHARE = "createShare";
const string GET_DIRECTORY_LIST = "getDirectoryList";
const string GET_FILE_LIST = "getFileList";
const string CREATE_DIRECTORY  = "createDirectory";

#Request Headers' names
const string X_MS_META_NAME = "x-ms-meta-name";
const string X_MS_HARE_QUOTA = "x-ms-share-quota";
const string X_MS_ACCESS_TIER= "x-ms-access-tier";
const string X_MS_ENABLED_PRTOCOLS = "x-ms-enabled-protocols";
