//
//  RestResponse.m
//  photomovie
//
//  Created by Evgeny Rusanov on 12.11.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import "RestResponse.h"

@implementation RestResponse
{
    NSHTTPURLResponse *httpResponse;
    NSError *_error;
    NSData *_data;
    RestRequest *_request;
}

-(id)initWithURLResponse:(NSURLResponse*)urlResponse
                                   data:(NSData*)data
                                  error:(NSError*)error
                             forRequest:(RestRequest*)request
{
    if (self = [super init])
    {
        if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]])
            httpResponse = (NSHTTPURLResponse*)urlResponse;
        _error = error;
        _data = data;
        _request = request;
    }
    
    return self;
}

+(RestResponse*)responseWithURLResponse:(NSURLResponse*)urlResponse
                                   data:(NSData*)data
                                  error:(NSError*)error
                             forRequest:(RestRequest*)request
{
    return [[RestResponse alloc] initWithURLResponse:urlResponse
                                                data:data
                                               error:error
                                          forRequest:request];
}


-(NSInteger)statusCode
{
    return httpResponse.statusCode;
}

-(NSError*)error
{
    return _error;
}

-(NSData*)body
{
    return _data;
}

-(id)parsedBody:(NSError**)error
{
    return [NSJSONSerialization JSONObjectWithData:_data
                                           options:0
                                             error:error];
}

-(RestRequest*)request
{
    return _request;
}

@end
