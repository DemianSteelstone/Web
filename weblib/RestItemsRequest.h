//
//  ItemRequest.h
//  photomovie
//
//  Created by Evgeny Rusanov on 24.11.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ItemsRequestSubclass.h"

@interface RestItemsRequest : ItemsRequestSubclass

@property (nonatomic,strong) NSDictionary *requestParams;
@property (nonatomic,strong) NSString *countParamName;
@property (nonatomic,strong) NSString *offsetParamsName;
@property (nonatomic) NSInteger itemsInRequest;

@property (nonatomic, copy) NSError*(^unexpectedContentErrorBuilder)(id content);

-(id)initWithURL:(NSString*)url resourcePath:(NSString*)resourcePath;

@end
