//
//  RestRequest.m
//  photomovie
//
//  Created by Evgeny Rusanov on 12.11.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import "RestRequest.h"

#import "URLParser.h"
#import "HttpBodyBuilder.h"

@implementation RestRequest
{
    id context;
    
    NSString *baseurl;
    
    NSMutableArray *filesArray;
    NSMutableArray *dataArray;
    
    NSURLConnection *connection;
    
    HttpBodyBuilder *_body;
    
    NSURLResponse *_response;
    NSError *_error;
    NSMutableData *recievedData;
    void (^completition)(RestResponse*);
}

-(id)initWithBaseUrl:(NSString*)url
{
    if (self = [super init])
    {
        baseurl = [url stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        
        filesArray = [NSMutableArray array];
        dataArray  = [NSMutableArray array];
        
        self.method = RequestMethodGET;
        self.params = nil;
    }
    return self;
}

+(RestRequest*)requestWithBase:(NSString*)url
{
    return [[RestRequest alloc] initWithBaseUrl:url];
}

-(void)appendFile:(NSString*)path fileName:(NSString*)fileName fileKey:(NSString*)fileKey contentType:(NSString*)contentType
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                path,@"path",
                                fileName,@"fileName",
                                fileKey,@"fileKey",
                                contentType,@"contentType",
                                nil];
    [filesArray addObject:dictionary];
}

-(void)appendData:(NSData*)data fileName:(NSString*)fileName fileKey:(NSString*)fileKey contentType:(NSString*)contentType
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                data,@"data",
                                fileName,@"fileName",
                                fileKey,@"fileKey",
                                contentType,@"contentType",
                                nil];
    [dataArray addObject:dictionary];
}

-(NSURL*)buildRequestURL
{
    NSString *url = baseurl;
    NSString *resource = @"";
    if (self.resourcePath.length)
    {
        resource = [self.resourcePath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        url = [url stringByAppendingFormat:@"/%@",resource];
    }
    
    url = [URLParser constructURL:url params:self.params];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return [NSURL URLWithString:url];
}

-(NSString*)httpRequestMethod
{
    switch (self.method)
    {
        case RequestMethodDELETE:
            return @"DELETE";
        case RequestMethodHEAD:
            return @"HEAD";
        case RequestMethodGET:
            return @"GET";
        case RequestMethodPOST:
            return @"POST";
        case RequestMethodPUT:
            return @"PUT";
        case RequestMethodUPDATE:
            return @"UPDATE";
    }
    
    return @"GET";
}

-(HttpBodyBuilder*)buildRequestBody
{
    if (filesArray.count==0 && dataArray.count==0)
        return nil;
    
    HttpBodyBuilder *builder = [[HttpBodyBuilder alloc] initWithFileStream:YES];
    
    for (NSDictionary *dictionary in filesArray)
    {
        [builder appendFile:[dictionary valueForKey:@"path"]
                   fileName:[dictionary valueForKey:@"fileName"]
                    fileKey:[dictionary valueForKey:@"fileKey"]
                contentType:[dictionary valueForKey:@"contentType"]];
    }
    
    for (NSDictionary *dictionary in dataArray)
    {
        [builder appendData:[dictionary valueForKey:@"data"]
                   fileName:[dictionary valueForKey:@"fileName"]
                    fileKey:[dictionary valueForKey:@"fileKey"]
                contentType:[dictionary valueForKey:@"contentType"]];
    }
    
    return builder;
}

-(NSURLRequest*)prepareRequest
{
    NSURL *url = [self buildRequestURL];
    NSLog(@"Request url: %@",url);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    request.HTTPMethod = [self httpRequestMethod];
    
    _body = [self buildRequestBody];
    if (_body)
    {
        NSString* contentType = [NSString
								 stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
		[request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        NSString *length = [NSString stringWithFormat:@"%d",[_body length]];
        [request setValue:length forHTTPHeaderField:@"Content-Length"];
        NSLog(@"%@",length);
        
        NSInputStream *stream = [_body postBodyStream];
        [request setHTTPBodyStream:stream];
    }
    
    return request;
}

-(void)send:(void (^)(RestResponse*))completitionHandler
{
    context = self;
    completition = [completitionHandler copy];
    
    NSURLRequest *request = [self prepareRequest];
    
    recievedData = [NSMutableData data];
    _response = nil;
    _error = nil;
    connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
//    [NSURLConnection sendAsynchronousRequest:request
//                                       queue:[NSOperationQueue mainQueue]
//                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
//                               if (completitionHandler)
//                                   completitionHandler([RestResponse responseWithURLResponse:response
//                                                                                        data:data
//                                                                                       error:error
//                                                                                  forRequest:self]);
//                               context = nil;
//                           }];
}

-(void)cancel
{
    [connection cancel];
}

-(void)gotResponse
{
    if (completition)
        completition([RestResponse responseWithURLResponse:_response
                                                             data:recievedData
                                                            error:_error
                                                       forRequest:self]);
    context = nil;
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _response = response;
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [recievedData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _error = error;
    [self gotResponse];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *debugStr = [[NSString alloc] initWithData:recievedData encoding:NSUTF8StringEncoding];
    NSLog(@"%@",debugStr);
    
    [self gotResponse];
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
}

@end
