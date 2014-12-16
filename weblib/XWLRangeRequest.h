//
//  XWLRangeRequest.h
//  DownloaderPlus
//
//  Created by Evgeny Rusanov on 03.12.14.
//  Copyright (c) 2014 Macsoftex. All rights reserved.
//

#import "MDPFileCategory.h"

extern NSString * const XWLErrorDomain;

@interface XWLRangeRequest : MDPFileCategory

-(instancetype)initWithURL:(NSURL*)url;

@property (nonatomic,copy) void (^requestPresetBlock)(NSMutableURLRequest *request);
@property (nonatomic,copy) NSURLCredential* (^credentialForChallenge)(NSURLAuthenticationChallenge *challenge);

-(NSData*)requestRange:(NSRange)range response:(NSURLResponse**)response error:(NSError**)error;
-(long long)requestSize;

+(BOOL)isValidResponde:(NSURLResponse*)response;

@end
