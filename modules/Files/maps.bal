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

#Stores the URI parameter names and the releavnt remote function names that URI parameter can be used.
map<string[]> uriParameters =  {
  prefix: [LIST_SHARES, GET_DIRECTORY_LIST, GET_FILE_LIST],
  marker: [LIST_SHARES, GET_DIRECTORY_LIST, GET_FILE_LIST],
  maxresults:[LIST_SHARES, GET_DIRECTORY_LIST, GET_FILE_LIST],
  include: [LIST_SHARES],
  timeout: [LIST_SHARES, GET_DIRECTORY_LIST, GET_FILE_LIST]
};

#Stores the header names and the releavnt remote function names that headers can be used.
map<string[]> requestHeaders = {
    X_MS_META_NAME: [CREATE_SHARE, CREATE_DIRECTORY],
    X_MS_HARE_QUOTA: [CREATE_SHARE],
    X_MS_ACCESS_TIER: [CREATE_SHARE],
    X_MS_ENABLED_PRTOCOLS: [CREATE_SHARE]
};