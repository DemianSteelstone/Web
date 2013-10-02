//
//  ItemsRequestSubclass.m
//  photomovie
//
//  Created by Evgeny Rusanov on 03.12.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import "ItemsRequestSubclass.h"

@implementation ItemsRequestSubclass
{
    id context;
}

-(void)beginRequesting
{
    _isRequesting = YES;
    _isFinished = NO;
    context = self;
}

-(void)stopRequesting
{
    _isRequesting = NO;
    _isFinished = YES;
    context = nil;
}

-(void)errorInRequest:(NSError*)error
{
    [self stopRequesting];
    portionLoadedBlock(nil,error);
}

-(void)prepare:(void (^) (NSArray*,NSError*))portionLoaded
{
    [self beginRequesting];
    
    currentOffset = 0;
    
    portionLoadedBlock = [portionLoaded copy];
}

@end
