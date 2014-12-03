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
    NSRange _range;
}

-(instancetype)initWithURL:(NSURL *)url range:(NSRange)range
{
    if (self = [super init])
    {
        _url = url;
        _range = range;
    }
    
    return self;
}

-(NSData*)sendRequest
{
    _resultError = nil;
    _resultResponse = nil;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:_url];
    if (self.requestPresetBlock)
        self.requestPresetBlock(request);
    
    NSString *rangeString = [NSString stringWithFormat:@"bytes=%lu-%lu", (unsigned long)_range.location, (unsigned long)_range.location+_range.length-1];
    [request setValue:rangeString forHTTPHeaderField:@"Range"];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    _resultError = error;
    _resultResponse = response;
    
    return data;
}

@end
