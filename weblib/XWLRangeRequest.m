//
//  XWLRangeRequest.m
//  DownloaderPlus
//
//  Created by Evgeny Rusanov on 03.12.14.
//  Copyright (c) 2014 Macsoftex. All rights reserved.
//

#import "XWLRangeRequest.h"

@implementation XWLRangeRequest
{
    NSURL *_url;
}

-(instancetype)initWithURL:(NSURL *)url
{
    if (self = [super init])
    {
        _url = url;
    }
    
    return self;
}

-(NSMutableURLRequest*)buildRequest
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:_url];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.requestPresetBlock)
            self.requestPresetBlock(request,^{
                dispatch_semaphore_signal(semaphore);
            });
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return request;
}

-(NSData*)requestRange:(NSRange)range
{
    _resultError = nil;
    _resultResponse = nil;
    
    NSMutableURLRequest *request = [self buildRequest];
    
    NSString *rangeString = [NSString stringWithFormat:@"bytes=%lu-%lu", (unsigned long)range.location, (unsigned long)range.location+range.length-1];
    [request setValue:rangeString forHTTPHeaderField:@"Range"];
    
    return [self sendRequest:request];
}

-(NSData*)sendRequest:(NSURLRequest*)request
{
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    _resultError = error;
    _resultResponse = response;
    
    return data;
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

@end
