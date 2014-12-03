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

-(NSData*)sendRequestRange:(NSRange)range
{
    _resultError = nil;
    _resultResponse = nil;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:_url];
    if (self.requestPresetBlock)
        self.requestPresetBlock(request);
    
    NSString *rangeString = [NSString stringWithFormat:@"bytes=%lu-%lu", (unsigned long)range.location, (unsigned long)range.location+range.length-1];
    [request setValue:rangeString forHTTPHeaderField:@"Range"];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    _resultError = error;
    _resultResponse = response;
    
    return data;
}

@end
