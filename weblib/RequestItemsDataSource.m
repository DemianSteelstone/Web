//
//  RequestItemsTableViewDelegate.m
//  photoexplorer
//
//  Created by Evgeny Rusanov on 17.04.14.
//  Copyright (c) 2014 Evgeny Rusanov. All rights reserved.
//

#import "RequestItemsDataSource.h"

#import "ItemsRequest.h"

#import "ErrorAlertView.h"

@interface RequestItemsDataSource ()

@property (nonatomic) BOOL isRequestingPortion;

@end

@implementation RequestItemsDataSource
{
    NSMutableArray *_items;
}

#pragma mark - Properties

-(void)setItemsRequest:(ItemsRequest *)itemsRequest
{
    [self.itemsRequest cancel];
    self.isRequestingPortion = NO;
    _itemsRequest = itemsRequest;
    [self reloadContainer];
}

#pragma mark - 

-(void)reloadContainer
{
    if (self.reloadContainerBlock)
        self.reloadContainerBlock();
}

-(BOOL)isRefreshControllRefreshing
{
    if (self.isRefreshControllRefreshingBlock)
        return self.isRefreshControllRefreshingBlock();
    return NO;
}

-(void)refreshControllEnd
{
    if (self.refreshControllEndBlock)
        self.refreshControllEndBlock();
}

#pragma mark -

-(void)addItems:(NSArray*)newItems
{
    [_items addObjectsFromArray:newItems];
    [self reloadContainer];
}

-(void)reloadData
{
    [self.itemsRequest cancel];
    
    _items = [NSMutableArray array];
    
    __weak typeof(self) pself = self;
    
    [self.itemsRequest prepare:^(NSArray *newItems, NSError *error) {
        if (!error)
        {
            [pself addItems:newItems];
        }
        else
        {
            [ErrorAlertView showError:error realError:YES];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            pself.isRequestingPortion = NO;
            if ([pself isRefreshControllRefreshing])
                [pself refreshControllEnd];
            
            [pself reloadContainer];
        });
    }];
    
    if ([self isRefreshControllRefreshing])
        [self.itemsRequest nextPortion];
    
    [self reloadContainer];
}

-(void)requestNewPortionIfNeeded
{
    if (!self.isRequestingPortion)
    {
        self.isRequestingPortion = YES;
        [self.itemsRequest nextPortion];
    }
}

-(void)updateItem:(NSDictionary*)item withComparator:(BOOL (^)(NSDictionary* candidate, NSDictionary *newItem))comparator
{
    if (!comparator) return;
    
    for (int i=0; i<_items.count; i++)
    {
        if (comparator(_items[i],item))
        {
            [_items replaceObjectAtIndex:i withObject:item];
            [self reloadContainer];
            return;
        }
    }
}

#pragma mark - Cells generation

-(id)contentCellForIndex:(NSInteger)index forContainer:(id)container
{
    if (self.contentCellGeneratorBlock)
        return self.contentCellGeneratorBlock(_items[index],index,container);
    return nil;
}

-(id)loadingCellForIndex:(NSInteger)index forContainer:(id)container
{
    if (self.loadingCellGeneratorBlock)
        return self.loadingCellGeneratorBlock(index,container);
    return nil;
}

-(id)noItemsCell:(NSInteger)index forContainer:(id)container
{
    if (self.noItmesCellGeneratorBlock)
        return self.noItmesCellGeneratorBlock(index,container);
    return nil;
}

#pragma mark - DataSource methods

-(NSInteger)numberOfCells
{
    NSUInteger count = _items.count;
    
    if ((count == 0 || self.itemsRequest.isRequesting) && ![self isRefreshControllRefreshing])
        count++;
    
    return count;
}

-(id)generateCellForIndex:(NSInteger)index inContainer:(id)container
{
    if (index < _items.count)
        return [self contentCellForIndex:index forContainer:container];
    
    if (self.itemsRequest.isRequesting)
    {
        [self requestNewPortionIfNeeded];
        return [self loadingCellForIndex:index forContainer:container];
    }
    
    return [self noItemsCell:index forContainer:container];
}

@end
