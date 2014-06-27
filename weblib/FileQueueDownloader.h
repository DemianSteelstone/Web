//
//  FileQeueDownloader.h
//  VKSearch
//
//  Created by Evgeny Rusanov on 30.06.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HTTPrequest.h"

@class FileQueueDownloader;
@protocol FileQueueDownloaderDelegate <NSObject>
@optional
-(void)queueDownloader:(FileQueueDownloader*)downloader error:(NSError*)error file:(NSString*)url userData:(id)userData;
-(void)queueDownloader:(FileQueueDownloader*)downloader fileDownloaded:(NSString*)url userData:(id)userData fileData:(NSData*)data;
-(void)queueDownloader:(FileQueueDownloader*)downloader fileDownloaded:(NSString*)url userData:(id)userData filePath:(NSString*)filePath;
@end

@interface FileQueueDownloader : NSObject <HTTPrequestDelegate>

@property (nonatomic, weak) id<FileQueueDownloaderDelegate> delegate;
@property (nonatomic) NSInteger maxDownloadingFiles;
@property (nonatomic) BOOL downloadToFile;

-(void)addLink:(NSString*)link userData:(id)userData;

-(void)clearQueue;

@end
