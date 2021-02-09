import ballerinax/azureStorageService.Files as files;
import ballerina/config;
import ballerina/log;

public function main() {
    
    // Setting up the configuration. 
    //User can select one of the authorization methods from Shared key and Shared Access Signature provided.
    //If user selects Shared Key as the authorization methods, the user needs to make isSharedKeySet field as true.
    //User needs to provide the storage account name and the baseUrl will be created using it.
    files:AzureConfiguration configuration = {
        sharedKeyOrSASToken: config:getAsString("SHARED_KEY_OR_SAS_TOKEN"),
        storageAccountName: config:getAsString("STORAGE_ACCOUNT_NAME"),
        isSharedKeySet : false
    };

    //Operations have be divided into two main categarites as Service level and non service level.
    //Creating a service level client using the configuration.
    files:ServiceLevelClient serviceLevelClient = new (configuration);

    //Service Level Operation
    //creation of a azure fileshare with the name : "demoshare"
    string fileshareName = "demoshare";
    log:print("Fileshare Creation");
    var creationResponse = serviceLevelClient->createShare(fileshareName);
    if(creationResponse is boolean){
        log:print("Status: " + creationResponse.toString());
    }else{
        log:print("Status: " + creationResponse.message());
    }
    

    //Service Level Operation
    //Getting a list of shares in the file service account
    //User can provide any optional uri paramteres and headers as separate maps respectively.
    //However, Connector only support some of them and Unsupported and invalid ones will be neglected even user provides
    log:print("Listing down shares");
    var listShareResponse = serviceLevelClient ->listShares();
    if(listShareResponse is files:SharesList) {
        log:print(listShareResponse.Shares.toString());
    } else {
        log:print("Status: " + listShareResponse.message());
    }
    
    //Service Level Operation
    //User can obtain service level properties
    log:print("Getting file service properties");
    var filePropertiesResponse = serviceLevelClient->getFileServiceProperties();
    if(filePropertiesResponse is files:FileServicePropertiesList) {
        log:print(filePropertiesResponse.toString());
    } else {
        log:print("Status: " + filePropertiesResponse.message());
    }
    //Service Level Operation
    //Preparing informations to be set as properties of the file service.
    log:print("Setting file service properties");
    files:MultichannelType multichannelType = {Enabled: "false"};
    files:SMBType smbType = {Multichannel: multichannelType};
    files:RetentionPolicyType mintRetentionPolicy = {Enabled: "false"};
    files:RetentionPolicyType hourRetentionPolicy = {
        Enabled: "true",
        Days: "7"
    };
    files:MetricsType hourMetrics = {
        Version: "1.0",
        Enabled: false,
        RetentionPolicy: mintRetentionPolicy
    };
    files:StorageServicePropertiesType storageServicePropertiesType = {HourMetrics: hourMetrics};
    files:FileServicePropertiesList fileService = {StorageServiceProperties: storageServicePropertiesType};
    //Use the operation to set the properties defined above.
    var settingResponse = serviceLevelClient->setFileServiceProperties(fileService);
    if (settingResponse is boolean) {
        log:print("Status: "+ settingResponse.toString());
    } else {
        log:print("Status: " + settingResponse.message());
    }

    //Service Level Operation
    //Deletion of the fileshare
    log:print("Deletion of the demo fileshare");
    var deletionResponse = serviceLevelClient->deleteShare(fileshareName);
    if(deletionResponse is boolean){
        log:print("Status: "+deletionResponse.toString());
    } else {
         log:print("Status: " + deletionResponse.toString());
    }
}

