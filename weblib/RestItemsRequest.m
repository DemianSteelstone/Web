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
    
    currentOffset = 0;
    
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
            [params setValue:[NSString stringWithFormat:@"%d",currentOffset]
                      forKey:self.offsetParamsName];
        if (self.countParamName.length)
            [params setValue:[NSString stringWithFormat:@"%d",self.itemsInRequest]
                      forKey:self.countParamName];
    }
    
    return params;
}

-(void)nextPortion
{
    request.params = [self paramsForCurrentPortion];
    
    [request send:^(RestResponse *response) {
        if (response.error)
        {
            [self errorInRequest:response.error];
            return;
        }
        
        NSError *error = nil;
        
        id parsedObject = [response parsedBody:&error];
        if (error)
        {
            [self errorInRequest:error];
            return;
        }
        
        if ([parsedObject isKindOfClass:[NSArray class]])
        {
            NSArray *newItems = parsedObject;
            
            if (newItems.count)
            {
                currentOffset+=self.itemsInRequest;
            }
            
            if (!newItems.count || self.itemsInRequest<=0)
            {
                [self stopRequesting];
            }
            
            portionLoadedBlock(newItems,nil);
        }
        else if (self.unexpectedContentErrorBuilder)
        {
            [self errorInRequest:self.unexpectedContentErrorBuilder(parsedObject)];
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
