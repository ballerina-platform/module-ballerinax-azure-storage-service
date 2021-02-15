// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/log;
import ballerina/jsonutils;
import ballerina/lang.'array;
import ballerina/lang.'xml;
import ballerina/file;
import ballerina/io;

# Azure Storage Blob Client Object.
#
# + httpClient - The HTTP Client for Azure Storage Blob
# + sharedAccessSignature - Shared Access Signature for the Azure Storage Account
# + accessKey - Azure Stoage Access Key
# + accountName - Azure Storage Account Name
# 
public client class BlobClient {
    http:Client httpClient;
    string sharedAccessSignature;
    string accessKey;
    string accountName;
    string authorizationMethod;

    public function init(AzureBlobServiceConfiguration blobServiceConfig) {
        self.sharedAccessSignature = blobServiceConfig.sharedAccessSignature;
        self.httpClient = new (blobServiceConfig.baseURL, {http1Settings: {chunking: http:CHUNKING_NEVER}});
        self.accessKey = blobServiceConfig.accessKey;
        self.accountName = blobServiceConfig.accountName;
        self.authorizationMethod = blobServiceConfig.authorizationMethod;
    }

    # Get list of containers of a storage account.
    # 
    # + maxResults - Optional. Maximum number of containers to return.
    # + marker - Optional. nextMarker value specified in the previous response.
    # + prefix - Optional. filters results to return only containers whose name begins with the specified prefix.
    # + return - If successful, returns ListContainerResult. Else returns Error. 
    remote function listContainers(int? maxResults = (), string? marker = (), string? prefix = ())
                                    returns @tainted ListContainerResult|error {
        http:Request request = new ();
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = LIST;
        if (maxResults is int) {
            uriParameterMap[MAXRESULTS] = maxResults.toString();
        } 
        if (marker is string) {
            uriParameterMap[MARKER] = marker;
        }
        if (prefix is string) {
            uriParameterMap[PREFIX] = prefix;
        }

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, EMPTY_STRING, uriParameterMap);
        }
        
        string resourcePath = FORWARD_SLASH_SYMBOL;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        xml xmlListContainerResponse = <xml>check handleResponse(response);
        // Since some xml tags contains double quotes, they are removed to avoid error
        xml cleanXMLContainerList = check removeDoubleQuotesFromXML(xmlListContainerResponse/<Containers>);
        
        ListContainerResult listContainerResult = {};
        json jsonContainerList = check jsonutils:fromXML(cleanXMLContainerList);
        listContainerResult.containerList = check convertJSONToContainerArray(jsonContainerList.Containers.Container);
        listContainerResult.nextMarker =  (xmlListContainerResponse/<NextMarker>/*).toString();
        listContainerResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return listContainerResult;
    }

    # Get list of containers as a stream.
    # 
    # + maxResults - Optional. Maximum number of containers to return.
    # + marker - Optional. nextMarker value specified in the previous response.
    # + prefix - Optional. filters results to return only containers whose name begins with the specified prefix.
    # + return - If successful, returns ListContainerResult. Else returns Error. 
    remote function listContainersStream(int? maxResults = (), string? marker = (), string? prefix = ()) 
                                            returns @tainted stream<Container>|error {
        http:Request request = new ();
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = LIST;
        if (maxResults is int) {
            uriParameterMap[MAXRESULTS] = maxResults.toString();
        } 
        if (marker is string) {
            uriParameterMap[MARKER] = marker;
        }
        if (prefix is string) {
            uriParameterMap[PREFIX] = prefix;
        }

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, EMPTY_STRING, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        xml xmlListContainerResponse = <xml>check handleResponse(response);
        // Since some xml tags contains double quotes, they are removed to avoid error
        xml cleanXMLContainerList = check removeDoubleQuotesFromXML(xmlListContainerResponse/<Containers>);

        json jsonContainerList = check jsonutils:fromXML(cleanXMLContainerList);
        Container[] containerList =  check convertJSONToContainerArray(jsonContainerList.Containers.Container);
        return containerList.toStream();
    }

    # Get list of blobs of a from a container.
    # 
    # + containerName - name of the container
    # + maxResults - Optional. Maximum number of containers to return.
    # + marker - Optional. nextMarker value specified in the previous response.
    # + prefix - Optional. filters results to return only containers whose name begins with the specified prefix.
    # + return - If successful, returns ListBlobResult Else returns Error. 
    remote function listBlobs(string containerName, int? maxResults = (), string? marker = (), string? prefix = ()) 
                                returns @tainted ListBlobResult|error {
        http:Request request = new ();
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = LIST;
        uriParameterMap[RESTYPE] = CONTAINER;
        if (maxResults is int) {
            uriParameterMap[MAXRESULTS] = maxResults.toString();
        } 
        if (marker is string) {
            uriParameterMap[MARKER] = marker;
        }
        if (prefix is string) {
            uriParameterMap[PREFIX] = prefix;
        }

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, containerName, 
                    uriParameterMap);
        }
        
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        xml xmlListBlobsResponse = <xml>check handleResponse(response);
        // Since some xml tags contains double quotes, they are removed to avoid error
        xml cleanXMLBlobList = check removeDoubleQuotesFromXML(xmlListBlobsResponse/<Blobs>);

        ListBlobResult listBlobResult = {};
        json jsonBlobList = check jsonutils:fromXML(cleanXMLBlobList);
        listBlobResult.blobList = check convertJSONToBlobArray(jsonBlobList.Blobs.Blob);
        listBlobResult.nextMarker = (xmlListBlobsResponse/<NextMarker>/*).toString();
        listBlobResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return listBlobResult;
    }

    # Get a blob from a from a container.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + startByte - Optional. From which byte to get blob content. Both startByte and endByte have to be given. 
    # + endByte - Optional. Upto which byte to get blob content.
    # + return - If successful, returns blob as a byte array. Else returns Error. 
    remote function getBlob(string containerName, string blobName, int? startByte = (), int? endByte = ()) 
                            returns @tainted BlobResult|error {
        http:Request request = new ();
        check setDefaultHeaders(request);
        
        if (startByte is int && endByte is int) {
            string range = BYTES + EQUAL_SYMBOL + startByte.toString() + DASH + endByte.toString();
            request.setHeader(X_MS_RANGE, range);
        } else {
            log:print("Entire blob contents are returned. startByte and endByte has to be provided to get a specified " 
                        + "range of bytes.");
        }

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, {});
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, {}, resourcePath);                 
        http:Response response = <http:Response> check self.httpClient->get(path, request);

        BlobResult blobResult = {};
        blobResult.blobContent = <byte[]>check handleGetBlobResponse(response);
        blobResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return blobResult;
    }

    # Get Blob Metadata.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + return - If successful, returns Blob Metadata. Else returns Error. 
    remote function getBlobMetadata(string containerName, string blobName) returns @tainted BlobMetadataResult|error {
        http:Request request = new ();
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = METADATA;

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, HEAD, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }
        
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->head(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToBlobMetadataResult(response);
    }
    
    # Get Blob Properties.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + return - If successful, returns Blob Properties. Else returns Error. 
    remote function getBlobProperties(string containerName, string blobName) returns @tainted Result|error {                          
        http:Request request = new ();
        check setDefaultHeaders(request);

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, HEAD, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, {});
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, {}, resourcePath);
        http:Response response = <http:Response> check self.httpClient->head(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Get Block List.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + return - If successful, returns Block List. Else returns Error. 
    remote function getBlockList(string containerName, string blobName) returns @tainted BlockListResult|error {                                
        http:Request request = new ();
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[BLOCKLISTTYPE] = ALL;
        uriParameterMap[COMP] = BLOCKLIST;

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        
        xml blockListXML = <xml> check handleResponse(response);
        json blockListJson = check jsonutils:fromXML(blockListXML);
        BlockListResult blockListResult = {};
        blockListResult.blockList = blockListJson;
        blockListResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return blockListResult;
    }

    # Upload a blob to a container as a single byte array.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + blob - blob as a byte[]
    # + blobType - type of the Blob ("BlockBlob" or "AppendBlob" or "PageBlob")
    # + pageBlobLength - Optional. Length of PageBlob. (Required only for Page Blobs)
    # + return - If successful, returns true. Else returns Error. 
    remote function putBlob(string containerName, string blobName, string blobType, byte[] blob = [],
                            int? pageBlobLength = ()) returns @tainted Result|error {   
        if (blob.length() > MAX_BLOB_UPLOAD_SIZE) {
            return error(AZURE_BLOB_ERROR_CODE, message = ("Blob content exceeds max supported size of 50MB"));
        } 
                              
        http:Request request = new ();
        check setDefaultHeaders(request);
        
        if (blobType == BLOCK_BLOB) {
            request.setHeader(CONTENT_LENGTH, blob.length().toString());
            request.setBinaryPayload(<@untainted>blob);
        } else if (blobType == PAGE_BLOB) {
            if (pageBlobLength is int) {
                request.setHeader(X_MS_BLOB_CONTENT_LENGTH, pageBlobLength.toString());
                request.setHeader(CONTENT_LENGTH, ZERO);      
            } else {
                return error(AZURE_BLOB_ERROR_CODE, message = ("pageBlobLength has to be specified for PageBlob"));
            }    
        } else if (blobType == APPEND_BLOB) {
            request.setHeader(CONTENT_LENGTH, ZERO);
        } else {
            return error(AZURE_BLOB_ERROR_CODE, message = (blobType + "is not a valid Blob Type. It should be " + 
                            APPEND_BLOB + VERTICAL_BAR + BLOCK_BLOB + VERTICAL_BAR + PAGE_BLOB));
        }
        
        request.setHeader(X_MS_BLOB_TYPE, blobType);
        
        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, {});
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, {}, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Put Blob From URL - creates a new Block Blob where the content of the blob is read from a given URL.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + sourceBlobURL - url of source blob
    # + return - If successful, returns true. Else returns Error. 
    remote function putBlobFromURL(string containerName, string blobName, string sourceBlobURL)
                                    returns @tainted Result|error {                                                      
        http:Request request = new ();
        check setDefaultHeaders(request);

        request.setHeader(CONTENT_LENGTH, ZERO);
        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, {});
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, {}, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Delete a blob from a container.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + return - If successful, returns true. Else returns Error. 
    remote function deleteBlob (string containerName, string blobName) returns @tainted Result|error {                           
        http:Request request = new ();
        check setDefaultHeaders(request);

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, DELETE, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, {});
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, {}, resourcePath);    
        http:Response response = <http:Response> check self.httpClient->delete(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Copy a blob from a URL.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + sourceBlobURL - URL of source blob
    # + return - If successful, returns Response Headers. Else returns Error. 
    remote function copyBlob (string containerName, string blobName, string sourceBlobURL)
                                returns @tainted CopyBlobResult|error {                          
        http:Request request = new ();
        check setDefaultHeaders(request);
        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, {});
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, {}, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToCopyBlobResult(response);
    }

    # Commits a new block to be commited as part of a blob.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + blockId - a string value that identifies the block (should be less than 64 bytes in size)
    # + content - blob content
    # + return - If successful, returns Response Headers. Else returns Error.
    remote function putBlock(string containerName, string blobName, string blockId, byte[] content) 
                                returns @tainted Result|error {
        http:Request request = new ();
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = BLOCK;
        string encodedBlockId = 'array:toBase64(blockId.toBytes());
        uriParameterMap[BLOCKID] = encodedBlockId;
        request.setBinaryPayload(content);
        request.setHeader(CONTENT_LENGTH, content.length().toString());

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Commits a new block to be commited as part of a blob where the content is read from a URL.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + blockId - a string value that identifies the block (should be less than 64 bytes in size)
    # + sourceBlobURL - URL of the source blob
    # + startByte - Optional. From which byte to get blob content. Both startByte and endByte have to be given. 
    # + endByte - Optional. Upto which byte to get blob content
    # + return - If successful, returns Response Headers. Else returns Error.
    remote function putBlockFromURL(string containerName, string blobName, string blockId, string sourceBlobURL, 
                                    int? startByte = (), int? endByte = ())returns @tainted Result|error {
        http:Request request = new ();
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = BLOCK;
        string encodedBlockId = 'array:toBase64(blockId.toBytes());
        uriParameterMap[BLOCKID] = encodedBlockId;

        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);
        request.setHeader(CONTENT_LENGTH, ZERO);

        if (startByte is int && endByte is int) {
            string sourceRange = BYTES + EQUAL_SYMBOL + startByte.toString() + DASH + endByte.toString();
            request.setHeader(X_MS_SOURCE_RANGE, sourceRange);
        }

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Writes a blob by specifying the list of blockIDs that make up the blob.
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + blockIdList - list of blockIds
    # + return - If successful, returns Response Headers. Else returns Error.
    remote function putBlockList(string containerName, string blobName, string[] blockIdList) 
                                    returns @tainted Result|error {
        if (blockIdList.length() < 1) {
            return error(AZURE_BLOB_ERROR_CODE, message = ("blockIdList cannot be empty"));
        }
    
        http:Request request = new ();
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = BLOCKLIST;

        xml blockListElement =  xml `<BlockList></BlockList>`;
        'xml:Element blockListXML = <'xml:Element> blockListElement; 
        string firstBlockId = 'array:toBase64(blockIdList[0].toBytes());
        xml blockIdXML =  xml `<Latest>${firstBlockId}</Latest>`;
        
        int i = 1;
        while (i < blockIdList.length()) {
            string encodedBlockId = 'array:toBase64(blockIdList[i].toBytes());
            blockIdXML =  'xml:concat(blockIdXML, xml `<Latest>${encodedBlockId}</Latest>`);
            i = i + 1;
        }
        blockListXML.setChildren(blockIdXML);

        request.setXmlPayload(blockListXML);      
        request.setHeader(CONTENT_TYPE, APPLICATION_SLASH_XML); // have to fix issue in shared key token generation
        int xmlContentLength = blockListXML.toString().toBytes().length();
        request.setHeader(CONTENT_LENGTH, xmlContentLength.toString());

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        Result result = {};
        result.success = <boolean> check handleResponse(response);
        result.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return result;
    }

    # Commits a new block to be commited as part of a blob.
    # 
    # + containerName - name of the container
    # + pageBlobName - name of the page blob
    # + operation - It can be update or clear
    # + startByte - From which byte to start writing
    # + endByte - Uppt which byte to write
    # + content - blob content
    # + return - If successful, returns Response Headers. Else returns Error.
    remote function putPage(string containerName, string pageBlobName, string operation, int startByte, int endByte, 
                            byte[]? content = ()) returns @tainted PutPageResult|error {
        http:Request request = new ();
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = PAGE;

        if (operation == UPDATE) {
            if (content is byte[]) {
                request.setBinaryPayload(content);
                request.setHeader(CONTENT_LENGTH, content.length().toString());
            } else {
                return error(AZURE_BLOB_ERROR_CODE, message = ("The required parameter for UPDATE operation "
                                + "'content' is not provided"));
            }
        } else if (operation == CLEAR) {
            request.setHeader(CONTENT_LENGTH, ZERO);
        } else {
            return error(AZURE_BLOB_ERROR_CODE, message = (operation + "is not a valid operationType. It should be " 
                            + "either 'update' or 'clear'."));
        }

        request.setHeader(X_MS_PAGE_WRITE, operation);
        string range = BYTES + EQUAL_SYMBOL + startByte.toString() + DASH + endByte.toString();
        request.setHeader(X_MS_RANGE, range);

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + pageBlobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + pageBlobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToPutPageResult(response);
    }

    # Get list of valid page ranges for a page blob.
    # 
    # + containerName - name of the container
    # + blobName - name of the page blob
    # + startByte - Optional. Start of the range of bytes to list ranges. Both startByte and endByte have to be given. 
    # + endByte - Optional. End of the range of bytes to list ranges.
    # + return - If successful, returns page ranges. Else returns Error. 
    remote function getPageRanges(string containerName, string blobName, int? startByte = (), int? endByte = ()) 
                                    returns @tainted PageRangeResult|error {                           
        http:Request request = new ();
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = PAGELIST;

        if (startByte is int && endByte is int) {
            string range = BYTES + EQUAL_SYMBOL + startByte.toString() + DASH + endByte.toString();
            request.setHeader(X_MS_RANGE, range);
        }

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, GET, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;

        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        xml pageRangesXML = <xml> check handleResponse(response);
        json pageRangesJson = check jsonutils:fromXML(pageRangesXML);
        PageRangeResult pageRangeResult = {};
        pageRangeResult.pageList = pageRangesJson;
        pageRangeResult.responseHeaders = getHeaderMapFromResponse(<http:Response>response);
        return pageRangeResult;
    }

    # Commits a new block of data to the end of an existing append blob.
    # 
    # + containerName - name of the container
    # + blobName - name of the append blob
    # + block - content of the block
    # + return - If successful, returns Response Headers. Else returns Error. 
    remote function appendBlock(string containerName, string blobName, byte[] block)
                                returns @tainted AppendBlockResult|error {
        http:Request request = new ();
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = APPENDBLOCK;

        request.setBinaryPayload(<@untainted>block);
        request.setHeader(CONTENT_LENGTH, block.length().toString());

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;

        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToAppendBlockResult(response);
    }

    # Commits a new block of data (from a URL) to the end of an existing append blob.
    # 
    # + containerName - name of the container
    # + blobName - name of the append blob
    # + sourceBlobURL - URL of the source blob
    # + return - If successful, returns Response Headers. Else returns Error. 
    remote function appendBlockFromURL(string containerName, string blobName, string sourceBlobURL) 
                                        returns @tainted AppendBlockResult|error {
        http:Request request = new ();
        check setDefaultHeaders(request);
        
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = APPENDBLOCK;

        request.setHeader(CONTENT_LENGTH, ZERO);
        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);

        if (self.authorizationMethod == SHARED_KEY) {
            check addAuthorizationHeader(request, PUT, self.accountName, self.accessKey, containerName + 
                    FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.sharedAccessSignature, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToAppendBlockResult(response);
    }

    # Upload large blob from a file path
    # 
    # + containerName - name of the container
    # + blobName - name of the blob
    # + filePath - path to the file which should be uploaded
    # + return - true if successful
    remote function uploadLargeBlob(string containerName, string blobName, string filePath) 
                                    returns @tainted boolean|error {
        file:MetaData fileMetaData = check file:getMetaData(filePath);
        int fileSize = fileMetaData.size;
        log:print("File size: " + fileSize.toString() + "Bytes");

        int i = 0; // Index of current block
        int remainingBytes = fileSize; // Remaining bytes to upload
        string[] blockIdArray = []; // List of blockIds

        stream<io:Block> fileStream = check io:fileReadBlocksAsStream(filePath, MAX_BLOB_UPLOAD_SIZE);
        error? upload = fileStream.forEach(function(io:Block byteBlock) {
            string blockId = blobName + COLON_SYMBOL + i.toString();
            blockIdArray[i] = blockId;
                    
            if (remainingBytes < MAX_BLOB_UPLOAD_SIZE) {
                byte[] lastByteArray = 'array:slice(byteBlock, 0, remainingBytes);
                Result response = checkpanic self->putBlock(containerName, blobName, blockId, lastByteArray);
                log:print("Upload successful");
            } else {
                Result response = checkpanic self->putBlock(containerName, blobName, blockId, byteBlock);
                remainingBytes -= MAX_BLOB_UPLOAD_SIZE;
                log:print("Remaining bytes to upload: " + remainingBytes.toString() + "Bytes");
                i += 1;  
            }             
        });
        Result putBlockListResponse = check self->putBlockList(containerName, blobName, blockIdArray);
        return true;
    }
}
