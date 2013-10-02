//
//  ItemsRequest.m
//  photomovie
//
//  Created by Evgeny Rusanov on 03.12.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import "ItemsRequest.h"

@implementation ItemsRequest

-(void)prepare:(void (^)(NSArray *, NSError *))itemsLoaded
{
    [self doesNotRecognizeSelector:_cmd];
}

-(void)nextPortion
{
    [self doesNotRecognizeSelector:_cmd];
}

-(void)cancel
{
    [self doesNotRecognizeSelector:_cmd];
}

@end
