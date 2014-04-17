//
//  ItemsRequest.h
//  photomovie
//
//  Created by Evgeny Rusanov on 03.12.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ItemsRequest : NSObject
{
    BOOL _isRequesting;
    BOOL _isFinished;
    
    NSMutableArray *_items;
}

@property (nonatomic,strong,readonly) NSArray *items;
@property (nonatomic,readonly) BOOL isRequesting;
@property (nonatomic,readonly) BOOL isFinished;

-(void)prepare:(void (^) (NSArray*,NSError*))portionLoaded;
-(void)cancel;
-(void)nextPortion;

@end