import sandudstest/azureStorageService.Files as files;
import ballerina/config;
import ballerina/log;

public function main() {
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Setting up the configuration.                                                                                  //
    //* User can select one of the authorization methods from Shared key and Shared Access Signature provided.        //
    //* If user selects Shared Key as the authorization methods, the user needs to make isSharedKeySet field as true. //
    //* User needs to provide the storage account name and the baseUrl will be created using it.                      //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    files:AzureConfiguration configuration = {
        sharedKeyOrSASToken: config:getAsString("SHARED_KEY_OR_SAS_TOKEN"),
        storageAccountName: config:getAsString("STORAGE_ACCOUNT_NAME"),
        isSharedKeySet : false
    };

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Operations have be divided into two main categarites as Service level and non service level.                    //
    //Creating a non-service level client using the configuration.                                                    //
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    files:FileShareClient azureClient = new (configuration);
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //* Before Run this sample user needs to creat a fileshare in an Azure storage account file service and the       ////  created fileshare should be used for the non-service level operations.                                        //
    //* User needs to add necessary parameters which is indicated within <> symbols.                                  //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var result = azureClient->deleteFile(fileShareName = "<FileShareName>", fileName = "<FileNameInAzure>");
    if (result is boolean) {
        log:print(result.toString());
    } else {
        log:printError(result.message());
    }
}
