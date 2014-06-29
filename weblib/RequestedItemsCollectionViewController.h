//
//  RequestedItemsCollectionViewController.h
//  photomovie
//
//  Created by Evgeny Rusanov on 30.10.13.
//  Copyright (c) 2013 Macsoftex. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ItemsRequest.h"

@interface RequestedItemsCollectionViewController : UICollectionViewController <UICollectionViewDelegateFlowLayout>

@property (nonatomic,strong) ItemsRequest *itemsRequest;
@property (nonatomic, strong, readonly) NSArray *items;

@property (nonatomic) BOOL refreshControlEnabled;

-(void)addItems:(NSArray*)newItems;

-(void)reloadData;
-(void)updateItem:(NSDictionary*)item withComparator:(BOOL (^)(NSDictionary* candidate, NSDictionary *newItem))comparator;

// Overload

-(NSInteger)contentSection;
-(NSInteger)numberOfSections;
-(NSInteger)numberOfCellsInNonContentSection:(NSInteger)section;
-(UICollectionViewCell*)nonContentCell:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath;
-(CGSize)nonContentCellSize:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath;

-(CGSize)cellSizeForItem:(NSDictionary*)item;
-(CGSize)loadingCellSize;
-(CGSize)noitemsCellSize;
-(UICollectionViewCell*)loadingCell:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath;
-(UICollectionViewCell*)noItemsCell:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath;
-(UICollectionViewCell*)contentCell:(NSDictionary*)item collectionView:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath;

@end
