//Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerinax/azure_storage_service.files as azure_files;
import ballerina/log;

configurable string accessKeyOrSAS = ?; 
configurable string accountName = ?;

public function main() returns error? {
    azure_files:AzureFileServiceConfiguration configuration = {
        accessKeyOrSAS: accessKeyOrSAS,
        accountName: accountName,
        authorizationMethod : "accessKey"
    };

    azure_files:FileClient fileClient =  check new (configuration);
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //* Before Run this sample user needs to create a fileshare in an Azure storage account file service and the      //
    //  created fileshare should be used for the non-service level operations.                                        //
    //* User needs to add necessary parameters which is indicated within <> symbols.                                  //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var result = fileClient->getFileList(fileShareName = "<fileShareName>");
    if (result is azure_files:FileList) {
        log:print(result.toString());
    } else {
        log:print(result.message());
    }
}
