//
//  FilesCache.h
//  photomovie
//
//  Created by Evgeny Rusanov on 17.12.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FileQueueDownloader.h"

@interface FilesCache : NSObject <FileQueueDownloaderDelegate>

-(id)initWithFile:(NSString*)file;

-(NSString*)fileFromCache:(NSString*)url;
-(void)getFile:(NSString*)url resultBlock:(void (^)(NSString *path))resultBlock;

-(void)clearCache;

@end
