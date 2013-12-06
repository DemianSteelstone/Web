//
//  RequestedItemsCollectionViewController.m
//  photomovie
//
//  Created by Evgeny Rusanov on 30.10.13.
//  Copyright (c) 2013 Macsoftex. All rights reserved.
//

#import "RequestedItemsCollectionViewController.h"
#import "ErrorAlertView.h"

@interface RequestedItemsCollectionViewController()

@property (nonatomic) BOOL isRequestingPortion;
@property (nonatomic,strong) UIRefreshControl *refreshControl;

@end

@implementation RequestedItemsCollectionViewController
{
    NSMutableArray *_items;
    
    UIRefreshControl *_refreshControl;
}

-(void)initRefreshControl
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(reloadData)
                  forControlEvents:UIControlEventValueChanged];
    self.refreshControl.tintColor = [UIColor grayColor];
    [self.collectionView addSubview:self.refreshControl];
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

-(void)updateItem:(NSDictionary*)item withComparator:(BOOL (^)(NSDictionary* candidate, NSDictionary *newItem))comparator
{
    if (!comparator) return;
    
    for (int i=0; i<_items.count; i++)
    {
        if (comparator(_items[i],item))
        {
            [_items replaceObjectAtIndex:i withObject:item];
            [self.collectionView reloadData];
            return;
        }
    }
}

-(void)addNewItems:(NSArray*)items
{
    [_items addObjectsFromArray:items];
}

-(void)reloadData
{
    [self.itemsRequest cancel];
    
    _items = [NSMutableArray array];
    
    __weak typeof(self) pself = self;
    
    [self.itemsRequest prepare:^(NSArray *newItems, NSError *error) {
        if (!error)
        {
            [pself addNewItems:newItems];
        }
        else
        {
            [ErrorAlertView showError:error realError:YES];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            pself.isRequestingPortion = NO;
            if (pself.refreshControl.isRefreshing)
                [pself.refreshControl endRefreshing];
            
                [pself.collectionView reloadData];
        });
    }];
    
    if (_refreshControl.isRefreshing)
        [self.itemsRequest nextPortion];
    
    [self.collectionView reloadData];
}

-(void)requestNewPortionIfNeeded
{
    if (!self.isRequestingPortion)
    {
        self.isRequestingPortion = YES;
        [self.itemsRequest nextPortion];
    }
}

#pragma mark - Overload

-(int)contentSection
{
    return 0;
}

-(int)numberOfSections
{
    return 1;
}

-(int)numberOfCellsInNonContentSection:(int)section
{
    return 0;
}

-(UICollectionViewCell*)nonContentCell:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath
{
    return nil;
}

-(CGSize)nonContentCellSize:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath
{
    return CGSizeMake(128,128);
}

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

#pragma mark - Collection delegate

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self numberOfSections];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == [self contentSection])
    {
        int count = _items.count;
        
        if ((count == 0 || self.itemsRequest.isRequesting) && !_refreshControl.isRefreshing)
            count++;
        
        return count;
    }
    
    return [self numberOfCellsInNonContentSection:section];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == [self contentSection])
    {
        if (indexPath.row < _items.count)
            return [self contentCell:[_items objectAtIndex:indexPath.row] collectionView:collectionView forIndexPath:(NSIndexPath*)indexPath];
        
        if (self.itemsRequest.isRequesting)
        {
            [self requestNewPortionIfNeeded];
            return [self loadingCell:collectionView forIndexPath:indexPath];
        }
        
        return [self noItemsCell:collectionView forIndexPath:indexPath];
    }
    
    return [self nonContentCell:collectionView forIndexPath:indexPath];
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == [self contentSection])
    {
        if (indexPath.row < _items.count)
            return [self cellSizeForItem:_items[indexPath.row]];
        
        if (self.itemsRequest.isRequesting)
        {
            return [self loadingCellSize];
        }
        
        return [self noitemsCellSize];
    }
    
    return [self nonContentCellSize:collectionView forIndexPath:indexPath];
}

@end
