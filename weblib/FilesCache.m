//
//  FilesCache.m
//  photomovie
//
//  Created by Evgeny Rusanov on 17.12.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import "FilesCache.h"
#import "FileSystem.h"

@implementation FilesCache
{
    NSString *cacheDBFile;
    
    NSMutableDictionary *cacheData;
    NSMutableDictionary *completitionHandlers;
    
    FileQueueDownloader *downloader;
}

+(NSString*)cachesFolder
{
    return [[FileSystem sharedFileSystem] cachesPathForFile:@"FilesCaches"];
}

-(id)initWithFile:(NSString*)file
{
    if (self = [super init])
    {
        NSString *cacheDir = [FilesCache cachesFolder];
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
        cacheDBFile = [NSString stringWithFormat:@"%@/%@",cacheDir,file];
        
        cacheData = [NSMutableDictionary dictionaryWithContentsOfFile:cacheDBFile];
        if (!cacheData)
            cacheData = [NSMutableDictionary dictionary];
        
        completitionHandlers = [NSMutableDictionary dictionary];
        downloader = [[FileQueueDownloader alloc] init];
        downloader.delegate = self;
        downloader.downloadToFile = YES;
    }
    return self;
}

-(void)storeCache
{
    [cacheData writeToFile:cacheDBFile atomically:YES];
}

-(NSString*)fileFromCache:(NSString*)url
{
     return [cacheData valueForKey:url];
}

-(void)getFile:(NSString*)url resultBlock:(void (^)(NSString *filePath))resultBlock
{
    NSMutableArray *handlers = [completitionHandlers valueForKey:url];
    if (!handlers)
    {
        handlers = [NSMutableArray array];
        [completitionHandlers setValue:handlers forKey:url];
    }
    [handlers addObject:[resultBlock copy]];
    
    [downloader addLink:url userData:nil];
}

-(void)clearCache
{
    for (NSString *path in cacheData.allValues)
    {
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    }
    [cacheData removeAllObjects];
    [self storeCache];
}

-(void)url:(NSString*)url loadedTo:(NSString*)path
{
    NSMutableArray *handlers = [completitionHandlers valueForKey:url];
    for (void (^handler)(NSString*) in handlers)
        handler(path);
    [completitionHandlers removeObjectForKey:url];
}

-(void)url:(NSString*)url tempFile:(NSString*)tmpFile
{
    NSString *cacheDir = [FilesCache cachesFolder];
    NSString *resultPath = [FileSystem randomFilePathIn:cacheDir extension:tmpFile.pathExtension];
    
    [[NSFileManager defaultManager] moveItemAtPath:tmpFile
                                            toPath:resultPath
                                             error:NULL];
    
    [cacheData setValue:resultPath forKey:url];
    [self storeCache];
    [self url:url loadedTo:resultPath];
}

#pragma mark - FileQueueDownloaderDelegate

-(void)queueDownloader:(FileQueueDownloader*)downloader fileDownloaded:(NSString*)url userData:(id)userData fileData:(NSData*)data
{}

-(void)queueDownloader:(FileQueueDownloader *)downloader fileDownloaded:(NSString *)url userData:(id)userData filePath:(NSString *)filePath
{
    [self url:url tempFile:filePath];
}

-(void)queueDownloader:(FileQueueDownloader*)downloader error:(NSError*)error file:(NSString*)url userData:(id)userData
{
    [self url:url loadedTo:nil];
}

@end
