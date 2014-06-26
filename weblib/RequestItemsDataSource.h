//
//  RequestItemsTableViewDelegate.h
//  photoexplorer
//
//  Created by Evgeny Rusanov on 17.04.14.
//  Copyright (c) 2014 Evgeny Rusanov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ItemsRequest;

@interface RequestItemsDataSource : NSObject

@property (nonatomic,strong) ItemsRequest *itemsRequest;
@property (nonatomic, strong, readonly) NSArray *items;

@property (nonatomic,copy) void (^reloadContainerBlock)();

@property (nonatomic,copy) BOOL (^isRefreshControllRefreshingBlock)();
@property (nonatomic,copy) void (^refreshControllEndBlock)();

@property (nonatomic,copy) NSArray* (^preprocessItemsBlock)(NSArray *items);

-(void)addItems:(NSArray*)newItems;

-(void)reloadData;
-(void)updateItem:(NSDictionary*)item withComparator:(BOOL (^)(NSDictionary* candidate, NSDictionary *newItem))comparator;

-(void)updateItemFrom:(BOOL (^)(NSDictionary *candidate))comparator modificationBlock:(NSDictionary* (^)(NSDictionary* oldItem))modificationBlock;

@property (nonatomic,readonly) NSInteger numberOfCells;
-(id)generateCellForIndex:(NSInteger)index inContainer:(id)container;

@property (nonatomic,copy) id (^contentCellGeneratorBlock)(NSDictionary *item, NSInteger index, id container);
@property (nonatomic,copy) id (^loadingCellGeneratorBlock)(NSInteger index, id container);
@property (nonatomic,copy) id (^noItmesCellGeneratorBlock)(NSInteger index, id container);

@end
