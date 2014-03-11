//
//  RestResponse.h
//  photomovie
//
//  Created by Evgeny Rusanov on 12.11.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RestRequest;

@interface RestResponse : NSObject

+(RestResponse*)responseWithURLResponse:(NSURLResponse*)urlResponse
                                  data:(NSData*)data
                                 error:(NSError*)error
                            forRequest:(RestRequest*)request;


-(NSInteger)statusCode;
-(NSError*)error;
-(NSData*)body;
-(id)parsedBody:(NSError**)error;
-(RestRequest*)request;


@end
