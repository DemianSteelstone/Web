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
    NSMutableArray *queue;
    NSMutableDictionary *currentRequests;
}

-(void)dealloc
{
    for (HTTPrequest *request in [currentRequests allValues])
    {
        [request cancel];
    }
    [currentRequests removeAllObjects];
}

-(id)init
{
    if (self = [super init])
    {
        self.maxDownloadingFiles = 4;
        self.downloadToFile = NO;
        queue = [[NSMutableArray alloc] init];
        currentRequests = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)downloadNext
{
    if (currentRequests.allKeys.count < self.maxDownloadingFiles)
    {
        NSDictionary *firstFile = [queue objectAtIndex:0];
        
        HTTPrequest *request = [[HTTPrequest alloc] init];
        request.delegate = self;
        request.userData = firstFile;
        request.downloadToFile = self.downloadToFile;
        
        [request sendRequest:[firstFile valueForKey:@"link"]];
        
        [currentRequests setValue:request forKey:[firstFile valueForKey:@"link"]];
        
        [queue removeObjectAtIndex:0];
    }
}

-(void)checkQueue
{
    if (queue.count)
        [self downloadNext];
}

-(void)clearQueue
{
    [queue removeAllObjects];
}

-(BOOL)alreadyDownloaded:(NSString*)link
{
    for (NSDictionary *dict in queue)
    {
        if ([[dict valueForKey:@"link"] isEqualToString:link])
            return YES;
    }
    
    for (NSString *request in [currentRequests allKeys])
    {
        if ([request isEqualToString:link])
        {
            return YES;
        }
    }
    return NO;
}

-(void)addLink:(NSString *)link userData:(id)userData
{
    if ([self alreadyDownloaded:link]) return;
    
    [queue addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                      link,@"link",
                      userData,@"userData",
                      nil]];
    [self checkQueue];
}

-(void)requestDidEnd:(HTTPrequest*)request
{
    [currentRequests removeObjectForKey:[request.userData valueForKey:@"link"]];
    [self checkQueue];
}

#pragma mark - HTTPRequest Delegate

-(void)httpRequest:(HTTPrequest *)request dataLoaded:(NSMutableData *)data
{
    if (self.delegate)
        [self.delegate queueDownloader:self
                        fileDownloaded:[request.userData valueForKey:@"link"]
                              userData:[request.userData valueForKey:@"userData"]
                              fileData:data];
    [self requestDidEnd:request];
}

-(void)httpRequest:(HTTPrequest *)request dataFileLoaded:(NSString *)path
{
    if (self.delegate)
        [self.delegate queueDownloader:self
                        fileDownloaded:[request.userData valueForKey:@"link"]
                              userData:[request.userData valueForKey:@"userData"]
                              filePath:path];
    [self requestDidEnd:request];
}

-(void)httpRequest:(HTTPrequest *)request error:(NSError *)errorCode
{
    if (self.delegate)
        [self.delegate queueDownloader:self
                                 error:errorCode
                                  file:[request.userData valueForKey:@"link"]
                              userData:[request.userData valueForKey:@"userData"]];
    [self requestDidEnd:request];
}

@end
