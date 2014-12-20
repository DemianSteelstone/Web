//
//  XWLRangeRequest.m
//  DownloaderPlus
//
//  Created by Evgeny Rusanov on 03.12.14.
//  Copyright (c) 2014 Macsoftex. All rights reserved.
//

#import "XWLRangeRequest.h"

NSString * const XWLErrorDomain = @"XWLErrorDomain";

@interface XWLRangeRequest () <NSURLConnectionDelegate>
@property (nonatomic,strong) NSURLConnection *connection;
@property (nonatomic,strong) NSOperationQueue *connectionQueue;
@end

@implementation XWLRangeRequest
{
    NSURL *_url;
    NSURLResponse *_resultResponse;
    NSError *_resultError;
    
    dispatch_semaphore_t _syncSemaphore;
    dispatch_queue_t _syncQueue;
    
    NSMutableData *_data;
    
    long long _fileSize;
}

-(instancetype)initWithURL:(NSURL *)url
{
    if (self = [super init])
    {
        _url = url;
        
        _syncSemaphore = dispatch_semaphore_create(0);
        _syncQueue = dispatch_queue_create("com.macsoftex.XWLRangeRequest.sync", 0);
        
        _connectionQueue = [[NSOperationQueue alloc] init];
        _connectionQueue.maxConcurrentOperationCount = 1;
        
        _fileSize = -1;
    }
    
    return self;
}

-(void)parseFileSize:(NSURLResponse*)response
{
    if (_fileSize > 0)
        return;
    
    NSError *error;
    
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@".*?-.*?/(.*)"
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:&error];
    
    if (error)
        return;
    
    NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse*)response;
    NSString *rangeString = urlResponse.allHeaderFields[@"Content-Range"];
    
    NSTextCheckingResult *match = [regexp firstMatchInString:rangeString options:0 range:NSMakeRange(0, rangeString.length)];
    if (match.numberOfRanges>1)
    {
        _fileSize = [[rangeString substringWithRange:[match rangeAtIndex:1]] longLongValue];
        if (_fileSize<=0)
            _fileSize = -1;
    }

}

-(NSMutableURLRequest*)buildRequest
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:_url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    if (self.requestPresetBlock)
        self.requestPresetBlock(request);
    
    return request;
}

-(NSData*)requestRange:(NSRange)range response:(NSURLResponse**)response error:(NSError**)error
{
    NSMutableURLRequest *request = [self buildRequest];
    
    NSString *rangeString = [NSString stringWithFormat:@"bytes=%lu-%lu", (unsigned long)range.location, (unsigned long)range.location+range.length-1];
    [request setValue:rangeString forHTTPHeaderField:@"Range"];
    
    return [self sendRequest:request response:response error:error];
}

-(NSData*)sendRequest:(NSURLRequest*)request response:(NSURLResponse**)response error:(NSError**)error
{
    __block NSData *result = nil;
    
    dispatch_sync(_syncQueue, ^{
        _resultResponse = nil;
        _resultError = nil;
        
        _data = [NSMutableData data];
        
        _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        [_connection setDelegateQueue:_connectionQueue];
        [_connection start];
        
        dispatch_semaphore_wait(_syncSemaphore, DISPATCH_TIME_FOREVER);
        
        result = [_data copy];
        
        if (response != NULL)
            *response = _resultResponse;
        if (error != NULL)
            *error = _resultError;
        
        if (_resultError == nil)
            [self parseFileSize:_resultResponse];
    });
    
    return result;
}

-(long long)requestSize
{
    if (_fileSize > 0)
        return _fileSize;
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    [self requestRange:NSMakeRange(0,256) response:&response error:&error];
    
    if (error !=nil || ![XWLRangeRequest isValidResponde:response])
        return -1;
    
    [self parseFileSize:response];
    
    return _fileSize;
}

+(BOOL)isValidResponde:(NSURLResponse*)response
{
    NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse*)response;
    return urlResponse.statusCode>=200 && urlResponse.statusCode<300;
}

-(void)didEndWithError:(NSError*)error
{
    _resultError = error;
    dispatch_semaphore_signal(_syncSemaphore);
}

- (void)cancelWithCode:(NSInteger)code {    
    [_connection cancel];
    
    NSString *errorLocalDes=nil;
    if (code==403) {
        errorLocalDes=NSLocalizedString(@"Forbidden Request",@"");
    }
    else if (code==500) {
        errorLocalDes=NSLocalizedString(@"Unexpected condition, Internal Server Error", @"");
    }
    NSDictionary *dic=nil;
    if (errorLocalDes!=nil) {
        dic=[NSDictionary dictionaryWithObject:errorLocalDes forKey:NSLocalizedDescriptionKey];
    }
    NSError *error=[NSError errorWithDomain:XWLErrorDomain code:code userInfo:dic];
    [self didEndWithError:error];
}

#pragma mark - Connection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self didEndWithError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _resultResponse = response;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSInteger code = [(NSHTTPURLResponse *)response statusCode];
        //        NSDictionary *dic=connection.currentRequest.allHTTPHeaderFields;
        //        NSLog(@"header:%@",dic);
        
        if (code >= 400)
        {
            [self cancelWithCode:code];
            return;
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self didEndWithError:nil];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    BOOL result = [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodDefault] ||
    [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic] ||
    [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest] ||
    [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
    
    return result;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if (self.credentialForChallenge != nil)
    {
        NSURLCredential* credential = self.credentialForChallenge(challenge);
        if (credential != nil)
            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
        else
            [challenge.sender cancelAuthenticationChallenge:challenge];
    }
    else
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

@end
