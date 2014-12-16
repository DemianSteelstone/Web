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

@property (nonatomic,strong,readonly) NSURLResponse *resultResponse;
@property (nonatomic,strong,readonly) NSError *resultError;

@property (nonatomic,copy) void (^requestPresetBlock)(NSMutableURLRequest *request);
@property (nonatomic,copy) NSURLCredential* (^credentialForChallenge)(NSURLAuthenticationChallenge *challenge);

-(NSData*)requestRange:(NSRange)range;
-(long long)requestSize;

-(BOOL)isValidResponde;

@end
