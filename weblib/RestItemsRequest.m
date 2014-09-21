//
//  ItemRequest.m
//  photomovie
//
//  Created by Evgeny Rusanov on 24.11.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import "RestItemsRequest.h"

#import "RestRequest.h"

@implementation RestItemsRequest
{
    id context;
    
    RestRequest *request;
}

-(void)setup
{
    self.itemsInRequest = 20;
    self.countParamName = @"count";
    self.offsetParamsName = @"offset";
    
    _isRequesting = NO;
    _isFinished = NO;
    
    self.currentOffset = 0;
    
    _items = [NSMutableArray arrayWithCapacity:self.itemsInRequest];
    
    self.unexpectedContentErrorBuilder = nil;
}

-(id)initWithURL:(NSString*)url resourcePath:(NSString*)resourcePath
{
    if (self = [super init])
    {
        [self setup];
        
        request = [RestRequest requestWithBase:url];
        request.resourcePath = resourcePath;
    }
    
    return self;
}

-(NSDictionary*)paramsForCurrentPortion
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.requestParams];
    
    if (self.itemsInRequest>0)
    {
        if (self.offsetParamsName.length)
            [params setValue:[NSString stringWithFormat:@"%ld",(long)self.currentOffset]
                      forKey:self.offsetParamsName];
        if (self.countParamName.length)
            [params setValue:[NSString stringWithFormat:@"%ld",(long)self.itemsInRequest]
                      forKey:self.countParamName];
    }
    
    return params;
}

-(void)nextPortion
{
    request.params = [self paramsForCurrentPortion];
    
    __weak typeof(self) weakSelf = self;
    
    [request send:^(RestResponse *response) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        
        if (response.error)
        {
            [strongSelf errorInRequest:response.error];
            return;
        }
        
        NSError *error = nil;
        
        id parsedObject = [response parsedBody:&error];
        if (error)
        {
            [strongSelf errorInRequest:error];
            return;
        }
        
        if ([parsedObject isKindOfClass:[NSArray class]])
        {
            NSArray *newItems = parsedObject;
            
            if (newItems.count)
            {
                strongSelf.currentOffset += strongSelf.itemsInRequest;
            }
            
            if (!newItems.count || strongSelf.itemsInRequest<=0)
            {
                [strongSelf stopRequesting];
            }
            
            strongSelf.portionLoadedBlock(newItems,nil);
        }
        else if (strongSelf.unexpectedContentErrorBuilder)
        {
            [strongSelf errorInRequest:strongSelf.unexpectedContentErrorBuilder(parsedObject)];
            return;
        }
    }];
}

-(void)cancel
{
    if (self.isRequesting)
    {
        [request cancel];
        [self stopRequesting];
    }
}

@end
