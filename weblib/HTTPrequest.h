//
//  HTTPrequest.h
//  FreeBarcodeScanner
//
//  Created by Evgeny Rusanov on 11/24/09.
//  Copyright 2009 Macsoftex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol HTTPrequestDelegate;


@interface HTTPrequest : NSObject <NSURLConnectionDelegate>

@property(nonatomic,weak) id<HTTPrequestDelegate> delegate;
@property(nonatomic,strong) id userData;
@property(nonatomic)		NSInteger tag;

@property (nonatomic) BOOL downloadToFile;
@property (nonatomic,strong) NSString *tmpFileName;

@property(nonatomic, readonly) long long expectedContentLength;
@property(nonatomic,readonly) long long downloadedBytes;
@property(nonatomic,readonly) long long partialDownloadedSize;

- (void)prepareRequest:(NSString *)requestString;
- (void)sendRequest:(NSString *)requestString;
- (void)send;
- (void)cancel;
- (BOOL)stoped;

@end


@protocol HTTPrequestDelegate<NSObject>
@optional
- (void)httpRequest:(HTTPrequest *)request error:(NSError *)errorCode;
- (void)httpRequest:(HTTPrequest *)request dataLoaded:(NSMutableData *)data;
- (void)httpRequest:(HTTPrequest *)request dataFileLoaded:(NSString *)path;
- (void)httpRequest:(HTTPrequest *)request dataPortionAdded:(NSMutableData *)data;
@end
