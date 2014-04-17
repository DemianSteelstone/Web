//
//  ItemsRequestSubclass.h
//  photomovie
//
//  Created by Evgeny Rusanov on 03.12.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import "ItemsRequest.h"

@interface ItemsRequestSubclass : ItemsRequest

@property (nonatomic) int currentOffset;
@property (nonatomic,copy) void (^portionLoadedBlock)(NSArray*,NSError*);

-(void)beginRequesting;
-(void)stopRequesting;
-(void)errorInRequest:(NSError*)error;

@end
