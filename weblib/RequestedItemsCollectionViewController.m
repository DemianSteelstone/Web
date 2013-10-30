//
//  RequestedItemsCollectionViewController.m
//  photomovie
//
//  Created by Evgeny Rusanov on 30.10.13.
//  Copyright (c) 2013 Macsoftex. All rights reserved.
//

#import "RequestedItemsCollectionViewController.h"
#import "ErrorAlertView.h"

@implementation RequestedItemsCollectionViewController
{
    NSMutableArray *_items;
    BOOL isRequestingPortion;
    
    UIRefreshControl *_refreshControl;
}

-(void)initRefreshControl
{
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self
                            action:@selector(reloadData)
                  forControlEvents:UIControlEventValueChanged];
    _refreshControl.tintColor = [UIColor grayColor];
    [self.collectionView addSubview:_refreshControl];
    self.collectionView.alwaysBounceVertical = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self initRefreshControl];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 

-(void)reloadData
{
    [self.itemsRequest cancel];
    
    _items = [NSMutableArray array];
    
    [self.itemsRequest prepare:^(NSArray *newItems, NSError *error) {
        if (!error)
        {
            [_items addObjectsFromArray:newItems];
        }
        else
        {
            [ErrorAlertView showError:error realError:YES];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            isRequestingPortion = NO;
            if (_refreshControl.isRefreshing)
                [_refreshControl endRefreshing];
            
                [self.collectionView reloadData];
        });
    }];
    
    if (_refreshControl.isRefreshing)
        [self.itemsRequest nextPortion];
    
    [self.collectionView reloadData];
}

-(void)requestNewPortionIfNeeded
{
    if (!isRequestingPortion)
    {
        isRequestingPortion = YES;
        [self.itemsRequest nextPortion];
    }
}

#pragma mark - Overload

-(CGSize)cellSizeForItem:(NSDictionary*)item
{
    return CGSizeMake(128,128);
}

-(CGSize)loadingCellSize
{
    return CGSizeMake(128,128);
}

-(CGSize)noitemsCellSize
{
    return CGSizeMake(128,128);
}

-(UICollectionViewCell*)loadingCell:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath
{
    return nil;
}

-(UICollectionViewCell*)noItemsCell:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath
{
    return nil;
}

-(UICollectionViewCell*)contentCell:(NSDictionary*)item collectionView:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath
{
    return nil;
}

-(void)itemSelected:(NSDictionary*)item
{
    
}

#pragma mark - Collection delegate

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    int count = _items.count;
    
    if ((count == 0 || self.itemsRequest.isRequesting) && !_refreshControl.isRefreshing)
        count++;
    
    return count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < _items.count)
        return [self contentCell:[_items objectAtIndex:indexPath.row] collectionView:collectionView forIndexPath:(NSIndexPath*)indexPath];
    
    if (self.itemsRequest.isRequesting)
    {
        [self requestNewPortionIfNeeded];
        return [self loadingCell:collectionView forIndexPath:indexPath];
    }
    
    return [self noItemsCell:collectionView forIndexPath:indexPath];
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < _items.count)
        return [self cellSizeForItem:_items[indexPath.row]];
    
    if (self.itemsRequest.isRequesting)
    {
        return [self loadingCellSize];
    }
    
    return [self noitemsCellSize];
}

@end
