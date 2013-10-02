//
//  RestRequest.h
//  photomovie
//
//  Created by Evgeny Rusanov on 12.11.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RestResponse.h"

/**
 * HTTP methods for requests
 */
typedef enum eRequestMethod {
    RequestMethodGET = 0,
    RequestMethodPOST,
    RequestMethodPUT,
    RequestMethodDELETE,
    RequestMethodUPDATE,
    RequestMethodHEAD
} RequestMethod;

@interface RestRequest : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic) RequestMethod method;          // default GET
@property (nonatomic,strong) NSDictionary *params;
@property (nonatomic,strong) NSString *resourcePath;

+(RestRequest*)requestWithBase:(NSString*)url;

-(void)appendFile:(NSString*)path fileName:(NSString*)fileName fileKey:(NSString*)fileKey contentType:(NSString*)contentType;
-(void)appendData:(NSData*)data fileName:(NSString*)fileName fileKey:(NSString*)fileKey contentType:(NSString*)contentType;

-(void)send:(void(^)(RestResponse *response))completitionHandler;
-(void)cancel;

@end
