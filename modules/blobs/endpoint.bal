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

import ballerina/file;
import ballerina/http;
import ballerina/io;
import ballerina/jsonutils;
import ballerina/lang.'xml;
import ballerina/log;

# Azure Storage Blob Client Object.
#
# + httpClient - The HTTP Client for Azure Storage Blob Service
# + accessKeyOrSAS - Access Key or Shared Access Signature for the Azure Storage Account
# + accountName - Azure Storage Account Name
# + authorizationMethod - If authorization method is accessKey or SAS
# 
@display {label: "Azure Storage Blob Client", iconPath: "AzureStorageBlobLogo.png"}
public client class BlobClient {
    http:Client httpClient;
    string accountName;
    string accessKeyOrSAS;
    AuthorizationMethod authorizationMethod;

    public function init(AzureBlobServiceConfiguration blobServiceConfig) returns error? {
        string baseURL = string `https://${blobServiceConfig.accountName}.blob.core.windows.net`;

        self.httpClient = check new (baseURL, {http1Settings: {chunking: http:CHUNKING_NEVER}});
        self.accessKeyOrSAS = blobServiceConfig.accessKeyOrSAS;
        self.accountName = blobServiceConfig.accountName;
        self.authorizationMethod = blobServiceConfig.authorizationMethod;
    }

    # Get list of containers of a storage account.
    # 
    # + maxResults - Optional. Maximum number of containers to return.
    # + marker - Optional. nextMarker value specified in the previous response.
    # + prefix - Optional. filters results to return only containers whose name begins with the specified prefix.
    # + return - If successful, returns ListContainerResult. Else returns Error. 
    @display {label: "Get list of containers"}
    remote function listContainers(@display {label: "Max number of results"} int? maxResults = (), 
                                   @display {label: "nextMarker value from previous response"} string? marker = (), 
                                   @display {label: "Filter by prefix"} string? prefix = ()) 
                                   returns @tainted @display {label: "Container list"} ListContainerResult|error {
        http:Request request = new;
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

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_GET, self.accountName, self.accessKeyOrSAS, EMPTY_STRING, 
                uriParameterMap);
        }
        
        string resourcePath = FORWARD_SLASH_SYMBOL;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        xml xmlListContainerResponse = <xml>check handleResponse(response);
        
        // Since some xml tags contains double quotes, they are removed to avoid error
        xml cleanXMLContainerList = check removeDoubleQuotesFromXML(xmlListContainerResponse/<Containers>);
        json jsonContainerList = check jsonutils:fromXML(cleanXMLContainerList);
        ListContainerResult listContainerResult = {
            containerList: check convertJSONToContainerArray(jsonContainerList.Containers.Container),
            nextMarker: (xmlListContainerResponse/<NextMarker>/*).toString(),
            responseHeaders: getHeaderMapFromResponse(response)
        };
        return listContainerResult;
    }

    # Get list of blobs of a from a container.
    # 
    # + containerName - Name of the container
    # + maxResults - Optional. Maximum number of containers to return.
    # + marker - Optional. nextMarker value specified in the previous response.
    # + prefix - Optional. filters results to return only containers whose name begins with the specified prefix.
    # + return - If successful, returns ListBlobResult Else returns Error. 
    @display {label: "Get list of blobs"}
    remote function listBlobs(@display {label: "Container name"} string containerName, 
                              @display {label: "Max number of results"} int? maxResults = (), 
                              @display {label: "nextMarker value from previous response"} string? marker = (), 
                              @display {label: "Filter by prefix"} string? prefix = ()) 
                              returns @tainted @display {label: "List of blobs"} ListBlobResult|error {
        http:Request request = new;
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

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_GET, self.accountName, self.accessKeyOrSAS, containerName, 
                uriParameterMap);
        }
        
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        xml xmlListBlobsResponse = <xml>check handleResponse(response);

        // Since some xml tags contains double quotes, they are removed to avoid error
        xml cleanXMLBlobList = check removeDoubleQuotesFromXML(xmlListBlobsResponse/<Blobs>);
        json jsonBlobList = check jsonutils:fromXML(cleanXMLBlobList);
        ListBlobResult listBlobResult = {
            blobList: check convertJSONToBlobArray(jsonBlobList.Blobs.Blob),
            nextMarker: (xmlListBlobsResponse/<NextMarker>/*).toString(),
            responseHeaders: getHeaderMapFromResponse(response)
        };
        return listBlobResult;
    }

    # Get a blob from a from a container.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the blob
    # + byteRange - Optional. The range of the byte to get. If not given, entire blob content will be returned.
    # + return - If successful, returns blob as a byte array. Else returns Error. 
    @display {label: "Get a blob"}
    remote function getBlob(@display {label: "Container name"} string containerName, 
                            @display {label: "Blob name"} string blobName, 
                            @display {label: "Byte range"} ByteRange? byteRange = ()) 
                            returns @tainted @display {label: "Blob"} BlobResult|error {
        http:Request request = new;
        check setDefaultHeaders(request);
        
        if (byteRange is ByteRange) {
            string range = BYTES + EQUAL_SYMBOL + byteRange.startByte.toString() + DASH + byteRange.endByte.toString();
            request.setHeader(X_MS_RANGE, range);
        }

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_GET, self.accountName, self.accessKeyOrSAS, containerName 
                + FORWARD_SLASH_SYMBOL + blobName, {});
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, {}, resourcePath);                 
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        BlobResult blobResult = {
            blobContent: <byte[]>check handleGetBlobResponse(response),
            responseHeaders: getHeaderMapFromResponse(response)
        };
        return blobResult;
    }

    # Get Blob Metadata.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the blob
    # + return - If successful, returns Blob Metadata. Else returns Error. 
    @display {label: "Get blob metadata"}
    remote function getBlobMetadata(@display {label: "Container name"} string containerName, 
                                    @display {label: "Blob name"} string blobName) 
                                    returns @tainted @display {label: "Blob metadata"} BlobMetadataResult|error {
        http:Request request = new;
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = METADATA;

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_HEAD, self.accountName, self.accessKeyOrSAS, containerName 
                + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }
        
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->head(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToBlobMetadataResult(response);
    }
    
    # Get Blob Properties.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the blob
    # + return - If successful, returns Blob Properties. Else returns Error. 
    @display {label: "Get blob properties"}
    remote function getBlobProperties(@display {label: "Container name"} string containerName, 
                                      @display {label: "Blob name"} string blobName) 
                                      returns @tainted @display {label: "Blob properties"} map<json>|error {                          
        http:Request request = new;
        check setDefaultHeaders(request);

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_HEAD, self.accountName, self.accessKeyOrSAS, containerName  
                + FORWARD_SLASH_SYMBOL + blobName, {});
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, {}, resourcePath);
        http:Response response = <http:Response> check self.httpClient->head(path, request);
        _ = check handleResponse(response);
        return getHeaderMapFromResponse(response);
    }

    # Get Block List.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the blob
    # + return - If successful, returns Block List. Else returns Error. 
    @display {label: "Get list of blocks"}
    remote function getBlockList(@display {label: "Container name"} string containerName, 
                                 @display {label: "Blob name"} string blobName) 
                                 returns @tainted @display {label: "Block list"} BlockListResult|error {                                
        http:Request request = new;
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[BLOCKLISTTYPE] = ALL;
        uriParameterMap[COMP] = BLOCKLIST;

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_GET, self.accountName, self.accessKeyOrSAS, containerName  
                + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        BlockListResult blockListResult = {
            blockList: check jsonutils:fromXML(<xml> check handleResponse(response)),
            responseHeaders: getHeaderMapFromResponse(response)
        };
        return blockListResult;
    }

    # Upload a blob to a container as a single byte array.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the blob
    # + blob - Blob as a byte[]
    # + blobType - Type of the Blob ("BlockBlob" or "AppendBlob" or "PageBlob")
    # + pageBlobLength - Optional. Length of PageBlob. (Required only for Page Blobs)
    # + return - If successful, returns Response. Else returns Error. 
    @display {label: "Upload a blob as a byte[]"}
    remote function putBlob(@display {label: "Container name"} string containerName, 
                            @display {label: "Blob name"} string blobName, 
                            @display {label: "Blob type"} BlobType blobType, 
                            @display {label: "Blob content"} byte[] blob = [],
                            @display {label: "Page blob length (only required for Page blob)"} int? pageBlobLength = ()) 
                            returns @tainted @display {label: "Response"} map<json>|error {   
        if (blob.length() > MAX_BLOB_UPLOAD_SIZE) {
            return error(AZURE_BLOB_ERROR_CODE, message = ("Blob content exceeds max supported size of 50MB"));
        } 
                              
        http:Request request = new;
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
        }
        
        request.setHeader(X_MS_BLOB_TYPE, blobType);
        
        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_PUT, self.accountName, self.accessKeyOrSAS, containerName  
                + FORWARD_SLASH_SYMBOL + blobName, {});
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, {}, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        _ = check handleResponse(response);
        return getHeaderMapFromResponse(response);
    }

    # Put Blob From URL - creates a new Block Blob where the content of the blob is read from a given URL.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the blob
    # + sourceBlobURL - Url of source blob
    # + return - If successful, returns Response. Else returns Error. 
    @display {label: "Create Block blob and get content from a URL"}
    remote function putBlobFromURL(@display {label: "Container name"} string containerName, 
                                   @display {label: "Blob name"} string blobName, 
                                   @display {label: "Source blob URL"} string sourceBlobURL) 
                                   returns @tainted @display {label: "Response"} map<json>|error {                                                      
        http:Request request = new;
        check setDefaultHeaders(request);

        request.setHeader(CONTENT_LENGTH, ZERO);
        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_PUT, self.accountName, self.accessKeyOrSAS, containerName  
                + FORWARD_SLASH_SYMBOL + blobName, {});
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, {}, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        _ = check handleResponse(response);
        return getHeaderMapFromResponse(response);
    }

    # Delete a blob from a container.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the blob
    # + return - If successful, returns Response. Else returns Error. 
    @display {label: "Delete a blob"}
    remote function deleteBlob (@display {label: "Container name"} string containerName, 
                                @display {label: "Blob name"} string blobName) 
                                returns @tainted @display {label: "Response"} map<json>|error {                           
        http:Request request = new;
        check setDefaultHeaders(request);

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_DELETE, self.accountName, self.accessKeyOrSAS, containerName  
                + FORWARD_SLASH_SYMBOL + blobName, {});
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, {}, resourcePath);    
        http:Response response = <http:Response> check self.httpClient->delete(path, request);
        _ = check handleResponse(response);
        return getHeaderMapFromResponse(response);
    }

    # Copy a blob from a URL.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the blob
    # + sourceBlobURL - URL of source blob
    # + return - If successful, returns Response Headers. Else returns Error. 
    @display {label: "Copy a blob from URL"}
    remote function copyBlob (@display {label: "Container name"} string containerName, 
                              @display {label: "Blob name"} string blobName, 
                              @display {label: "Source blob URL"} string sourceBlobURL) 
                              returns @tainted @display {label: "Response"} CopyBlobResult|error {                          
        http:Request request = new;
        check setDefaultHeaders(request);
        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_PUT, self.accountName, self.accessKeyOrSAS, containerName 
                + FORWARD_SLASH_SYMBOL + blobName, {});
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, {}, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToCopyBlobResult(response);
    }

    # Commits a new block to be commited as part of a blob.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the blob
    # + blockId - A string value that identifies the block (should be less than 64 bytes in size)
    # + content - Blob content
    # + return - If successful, returns Response Headers. Else returns Error.
    @display {label: "Upload a block"}
    remote function putBlock(@display {label: "Container name"} string containerName, 
                             @display {label: "Blob name"} string blobName, 
                             @display {label: "Block ID"} string blockId, 
                             @display {label: "Blob content"} byte[] content) 
                             returns @tainted @display {label: "Response"} map<json>|error {
        http:Request request = new;
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = BLOCK;
        string encodedBlockId = blockId.toBytes().toBase64();
        uriParameterMap[BLOCKID] = encodedBlockId;
        request.setBinaryPayload(content);
        request.setHeader(CONTENT_LENGTH, content.length().toString());

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_PUT, self.accountName, self.accessKeyOrSAS, containerName  
                + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        _ = check handleResponse(response);
        return getHeaderMapFromResponse(response);
    }

    # Commits a new block to be commited as part of a blob where the content is read from a URL.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the blob
    # + blockId - A string value that identifies the block (should be less than 64 bytes in size)
    # + sourceBlobURL - URL of the source blob
    # + byteRange - Optional. The byte range to get blob content. If not given, entire blob content will be added.
    # + return - If successful, returns Response Headers. Else returns Error.
    @display {label: "Commit a new block from URL"}
    remote function putBlockFromURL(@display {label: "Container name"} string containerName, 
                                    @display {label: "Blob name"} string blobName, 
                                    @display {label: "Block id"} string blockId, 
                                    @display {label: "Source blob URL"} string sourceBlobURL, 
                                    @display {label: "Byte range"} ByteRange? byteRange = ())
                                    returns @tainted @display {label: "Response"} map<json>|error {
        http:Request request = new;
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = BLOCK;
        string encodedBlockId = blockId.toBytes().toBase64();
        uriParameterMap[BLOCKID] = encodedBlockId;

        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);
        request.setHeader(CONTENT_LENGTH, ZERO);

        if (byteRange is ByteRange) {
            string sourceRange = BYTES + EQUAL_SYMBOL + byteRange.startByte.toString() + DASH + byteRange.endByte
                .toString();
            request.setHeader(X_MS_SOURCE_RANGE, sourceRange);
        }

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_PUT, self.accountName, self.accessKeyOrSAS, containerName 
                + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }
        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        _ = check handleResponse(response);
        return getHeaderMapFromResponse(response);
    }

    # Writes a blob by specifying the list of blockIDs that make up the blob.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the blob
    # + blockIdList - List of blockIds
    # + return - If successful, returns Response Headers. Else returns Error.
    @display {label: "Create a blob by giving a list of block IDs"}
    remote function putBlockList(@display {label: "Container name"} string containerName, 
                                 @display {label: "Blob name"} string blobName, 
                                 @display {label: "List of block IDs"} string[] blockIdList) 
                                 returns @tainted @display {label: "Response"} map<json>|error {
        if (blockIdList.length() < 1) {
            return error(AZURE_BLOB_ERROR_CODE, message = ("blockIdList cannot be empty"));
        }
    
        http:Request request = new;
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = BLOCKLIST;

        xml blockListElement =  xml `<BlockList></BlockList>`;
        'xml:Element blockListXML = <'xml:Element> blockListElement; 
        string firstBlockId = blockIdList[0].toBytes().toBase64();
        xml blockIdXML =  xml `<Latest>${firstBlockId}</Latest>`;
        
        int i = 1;
        while (i < blockIdList.length()) {
            string encodedBlockId = blockIdList[i].toBytes().toBase64();
            blockIdXML =  blockIdXML.concat(xml `<Latest>${encodedBlockId}</Latest>`);
            i = i + 1;
        }
        blockListXML.setChildren(blockIdXML);

        request.setXmlPayload(blockListXML);      
        request.setHeader(http:CONTENT_TYPE, APPLICATION_SLASH_XML);
        int xmlContentLength = blockListXML.toString().toBytes().length();
        request.setHeader(CONTENT_LENGTH, xmlContentLength.toString());

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_PUT, self.accountName, self.accessKeyOrSAS, containerName 
                + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        _ = check handleResponse(response);
        return getHeaderMapFromResponse(response);
    }

    # Update or add a new page Blob.
    # 
    # + containerName - Name of the container
    # + pageBlobName - Name of the page blob
    # + operation - It can be 'update' or 'clear'
    # + byteRange - Byte range to write
    # + content - Blob content
    # + return - If successful, returns Response Headers. Else returns Error.
    @display {label: "Update or add a new page blob"}
    remote function putPage(@display {label: "Container name"} string containerName, 
                            @display {label: "Page blob name"} string pageBlobName, 
                            @display {label: "Page operation"} PageOperation operation, 
                            @display {label: "Byte range"} ByteRange byteRange,
                            @display {label: "Blob content"} byte[]? content = ()) 
                            returns @tainted @display {label: "Response"} PutPageResult|error {
        http:Request request = new;
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
        }

        request.setHeader(X_MS_PAGE_WRITE, operation);
        string range = BYTES + EQUAL_SYMBOL + byteRange.startByte.toString() + DASH + byteRange.endByte.toString();
        request.setHeader(X_MS_RANGE, range);

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_PUT, self.accountName, self.accessKeyOrSAS, containerName 
                + FORWARD_SLASH_SYMBOL + pageBlobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + pageBlobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToPutPageResult(response);
    }

    # Get list of valid page ranges for a page blob.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the page blob
    # + byteRange - Optional. The byte range over which to list ranges.
    # + return - If successful, returns page ranges. Else returns Error. 
    @display {label: "Get list of valid page ranges for a page blob"}
    remote function getPageRanges(@display {label: "Container name"} string containerName, 
                                  @display {label: "Page blob name"} string blobName, 
                                  @display {label: "Byte range"} ByteRange? byteRange = ()) 
                                  returns @tainted @display {label: "Page ranges"} PageRangeResult|error {                           
        http:Request request = new;
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = PAGELIST;

        if (byteRange is ByteRange) {
            string range = BYTES + EQUAL_SYMBOL + byteRange.startByte.toString() + DASH + byteRange.endByte.toString();
            request.setHeader(X_MS_RANGE, range);
        }

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_GET, self.accountName, self.accessKeyOrSAS, containerName 
                + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->get(path, request);
        PageRangeResult pageRangeResult = {
            pageList: check jsonutils:fromXML(<xml> check handleResponse(response)),
            responseHeaders: getHeaderMapFromResponse(response)
        };
        return pageRangeResult;
    }

    # Commits a new block of data to the end of an existing append blob.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the append blob
    # + block - Content of the block
    # + return - If successful, returns Response Headers. Else returns Error. 
    @display {label: "Append a block"}
    remote function appendBlock(@display {label: "Container name"} string containerName, 
                                @display {label: "Blob name"} string blobName, 
                                @display {label: "Content of the block"} byte[] block) 
                                returns @tainted @display {label: "Response"} AppendBlockResult|error {
        http:Request request = new;
        check setDefaultHeaders(request);
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = APPENDBLOCK;

        request.setBinaryPayload(<@untainted>block);
        request.setHeader(CONTENT_LENGTH, block.length().toString());

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_PUT, self.accountName, self.accessKeyOrSAS, containerName 
                + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;

        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToAppendBlockResult(response);
    }

    # Commits a new block of data (from a URL) to the end of an existing append blob.
    # 
    # + containerName - Name of the container
    # + blobName - Name of the append blob
    # + sourceBlobURL - URL of the source blob
    # + return - If successful, returns Response Headers. Else returns Error. 
    @display {label: "Append block from URL"}
    remote function appendBlockFromURL(@display {label: "Container name"} string containerName, 
                                       @display {label: "Blob name"} string blobName, 
                                       @display {label: "Source blob URL"} string sourceBlobURL) 
                                       returns @tainted @display {label: "Response"} AppendBlockResult|error {
        http:Request request = new;
        check setDefaultHeaders(request);
        
        map<string> uriParameterMap = {};
        uriParameterMap[COMP] = APPENDBLOCK;

        request.setHeader(CONTENT_LENGTH, ZERO);
        request.setHeader(X_MS_COPY_SOURCE, sourceBlobURL);

        if (self.authorizationMethod == ACCESS_KEY) {
            check addAuthorizationHeader(request, http:HTTP_PUT, self.accountName, self.accessKeyOrSAS, containerName 
                + FORWARD_SLASH_SYMBOL + blobName, uriParameterMap);
        }

        string resourcePath = FORWARD_SLASH_SYMBOL + containerName + FORWARD_SLASH_SYMBOL + blobName;
        string path = preparePath(self.authorizationMethod, self.accessKeyOrSAS, uriParameterMap, resourcePath);
        http:Response response = <http:Response> check self.httpClient->put(path, request);
        check handleHeaderOnlyResponse(response);
        return convertResponseToAppendBlockResult(response);
    }

    # Upload large blob from a file path.
    # 
    # + containerName - name of the container
    # + blobName - Name of the blob
    # + filePath - Path to the file which should be uploaded
    # + return - error if unsuccessful
    @display {label: "Upload a blob using file path"}
    remote function uploadLargeBlob(@display {label: "Container name"} string containerName, 
                                    @display {label: "Blob name"} string blobName, 
                                    @display {label: "File path"} string filePath) returns error? {
        file:MetaData fileMetaData = check file:getMetaData(filePath);
        int fileSize = fileMetaData.size;
        log:print("File size: " + fileSize.toString() + "Bytes");

        int i = 0; // Index of current block
        int remainingBytes = fileSize; // Remaining bytes to upload
        string[] blockIdArray = []; // List of blockIds

        var fileStream = check io:fileReadBlocksAsStream(filePath, MAX_BLOB_UPLOAD_SIZE);
        if (fileStream is stream<io:Block>) {
            _ = fileStream.forEach(function(io:Block byteBlock) {
                string blockId = blobName + COLON_SYMBOL + i.toString();
                blockIdArray[i] = blockId;
                    
                if (remainingBytes < MAX_BLOB_UPLOAD_SIZE) {
                    byte[] lastByteArray = byteBlock.slice(0, remainingBytes);
                    _ = checkpanic self->putBlock(containerName, blobName, blockId, lastByteArray);
                    log:print("Upload successful");
                } else {
                    _ = checkpanic self->putBlock(containerName, blobName, blockId, byteBlock);
                    remainingBytes -= MAX_BLOB_UPLOAD_SIZE;
                    log:print("Remaining bytes to upload: " + remainingBytes.toString() + "Bytes");
                    i += 1;  
                }             
            });
            _ = check self->putBlockList(containerName, blobName, blockIdArray);
        } else {
            return error(AZURE_BLOB_ERROR_CODE, message = (fileStream.toString()));
        }        
    }
}
