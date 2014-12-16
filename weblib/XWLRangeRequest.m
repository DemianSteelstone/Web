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
    
    dispatch_semaphore_t _syncSemaphore;
    
    NSMutableData *_data;
}

-(instancetype)initWithURL:(NSURL *)url
{
    if (self = [super init])
    {
        _url = url;
        
        _syncSemaphore = dispatch_semaphore_create(0);
        _connectionQueue = [[NSOperationQueue alloc] init];
        _connectionQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

-(NSMutableURLRequest*)buildRequest
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:_url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    if (self.requestPresetBlock)
        self.requestPresetBlock(request);
    
    return request;
}

-(NSData*)requestRange:(NSRange)range
{
    NSMutableURLRequest *request = [self buildRequest];
    
    NSString *rangeString = [NSString stringWithFormat:@"bytes=%lu-%lu", (unsigned long)range.location, (unsigned long)range.location+range.length-1];
    [request setValue:rangeString forHTTPHeaderField:@"Range"];
    
    return [self sendRequest:request];
}

-(NSData*)sendRequest:(NSURLRequest*)request
{
    _resultResponse = nil;
    _resultError = nil;
    
    _data = [NSMutableData data];
    
    __weak typeof(self) weakSelf = self;
    [_connectionQueue addOperationWithBlock:^{
        weakSelf.connection = [[NSURLConnection alloc] initWithRequest:request delegate:weakSelf startImmediately:NO];
        [weakSelf.connection setDelegateQueue:weakSelf.connectionQueue];
        [weakSelf.connection start];
    }];
    
    dispatch_semaphore_wait(_syncSemaphore, DISPATCH_TIME_FOREVER);
    
    return _data;
}

-(long long)requestSize
{
    _resultError = nil;
    _resultResponse = nil;
    
    NSMutableURLRequest *request = [self buildRequest];
    [request setHTTPMethod:@"HEAD"];
    [self sendRequest:request];
    
    NSHTTPURLResponse *response = (NSHTTPURLResponse*)self.resultResponse;
    
    if (![self isValidResponde])
        return -1;
    
    return response.expectedContentLength;
}

-(BOOL)isValidResponde
{
    NSHTTPURLResponse *response = (NSHTTPURLResponse*)self.resultResponse;
    return response.statusCode>=200 && response.statusCode<300;
}

-(void)didEndWithError:(NSError*)error
{
    _resultError = error;
    dispatch_semaphore_signal(_syncSemaphore);
}

- (void)cancelWithCode:(NSInteger)code {
    [self willChangeValueForKey:@"isCancelled"];
    
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
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSInteger code = [(NSHTTPURLResponse *)response statusCode];
        //        NSDictionary *dic=connection.currentRequest.allHTTPHeaderFields;
        //        NSLog(@"header:%@",dic);
        
        if (code >= 400) {
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
