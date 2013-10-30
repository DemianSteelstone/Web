//
//  RequestedItemsCollectionViewController.h
//  photomovie
//
//  Created by Evgeny Rusanov on 30.10.13.
//  Copyright (c) 2013 Macsoftex. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ItemsRequest.h"

@interface RequestedItemsCollectionViewController : UICollectionViewController

@property (nonatomic,strong) ItemsRequest *itemsRequest;
@property (nonatomic, strong, readonly) NSArray *items;

-(void)reloadData;

// Overload

-(CGSize)cellSizeForItem:(NSDictionary*)item;
-(CGSize)loadingCellSize;
-(CGSize)noitemsCellSize;
-(UICollectionViewCell*)loadingCell:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath;
-(UICollectionViewCell*)noItemsCell:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath;
-(UICollectionViewCell*)contentCell:(NSDictionary*)item collectionView:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath;
-(void)itemSelected:(NSDictionary*)item;

@end
