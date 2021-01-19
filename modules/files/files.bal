import ballerina/io;
import azure_storage_service.utils as utils;

isolated function testFile() {
    io:println("Hello World!");
    string|error x = utils:getCurrentDate();

}
