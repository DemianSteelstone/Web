//
//  PostBodyBuilder.h
//  photomovie
//
//  Created by Evgeny Rusanov on 08.09.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kStringBoundary     @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f"

@interface HttpBodyBuilder : NSObject

-(id)initWithFileStream:(BOOL)streamToFile;

-(void)appendFile:(NSString*)path fileName:(NSString*)fileName fileKey:(NSString*)fileKey contentType:(NSString*)contentType;
-(void)appendURLFile:(NSURL*)path fileName:(NSString*)fileName fileKey:(NSString*)fileKey contentType:(NSString*)contentType;
-(void)appendData:(NSData*)data fileName:(NSString*)fileName fileKey:(NSString*)fileKey contentType:(NSString*)contentType;

-(void)finish;
-(NSInputStream*)postBodyStream;
-(long long)length;

@end
