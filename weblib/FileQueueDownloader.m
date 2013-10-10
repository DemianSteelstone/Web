//
//  FileQeueDownloader.m
//  VKSearch
//
//  Created by Evgeny Rusanov on 30.06.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import "FileQueueDownloader.h"

@implementation FileQueueDownloader
{
    NSOperationQueue *operations;
}

-(id)init
{
    if (self = [super init])
    {
        self.maxDownloadingFiles = 4;
        self.downloadToFile = NO;
        
        operations = [[NSOperationQueue alloc] init];
        operations.maxConcurrentOperationCount = self.maxDownloadingFiles;
    }
    return self;
}

-(void)setMaxDownloadingFiles:(int)maxDownloadingFiles
{
    _maxDownloadingFiles = maxDownloadingFiles;
    operations.maxConcurrentOperationCount = self.maxDownloadingFiles;
}

-(void)clearQueue
{
    [operations cancelAllOperations];
}

-(void)addLink:(NSString *)link userData:(id)userData
{
    if (!link.length) return;
    
    NSDictionary *item =[NSDictionary dictionaryWithObjectsAndKeys:
                         link,@"link",
                         userData,@"userData",
                         nil];
    
    __weak id pself = self;
    
    [operations addOperationWithBlock:^{
        HTTPrequest *request = [[HTTPrequest alloc] init];
        request.delegate = pself;
        request.userData = item;
        request.downloadToFile = self.downloadToFile;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [request sendRequest:[item valueForKey:@"link"]];
        }];
    }];
}

#pragma mark - HTTPRequest Delegate

-(void)httpRequest:(HTTPrequest *)request dataLoaded:(NSMutableData *)data
{
    if (self.delegate)
        [self.delegate queueDownloader:self
                        fileDownloaded:[request.userData valueForKey:@"link"]
                              userData:[request.userData valueForKey:@"userData"]
                              fileData:data];
}

-(void)httpRequest:(HTTPrequest *)request dataFileLoaded:(NSString *)path
{
    if (self.delegate)
        [self.delegate queueDownloader:self
                        fileDownloaded:[request.userData valueForKey:@"link"]
                              userData:[request.userData valueForKey:@"userData"]
                              filePath:path];
}

-(void)httpRequest:(HTTPrequest *)request error:(NSError *)errorCode
{
    if ([errorCode.domain isEqualToString:NSURLErrorDomain] && errorCode.code == NSURLErrorTimedOut)
    {
        [self addLink:[request.userData valueForKey:@"link"] userData:[request.userData valueForKey:@"userData"]];
        return;
    }
    
    if (self.delegate)
        [self.delegate queueDownloader:self
                                 error:errorCode
                                  file:[request.userData valueForKey:@"link"]
                              userData:[request.userData valueForKey:@"userData"]];
}

@end
