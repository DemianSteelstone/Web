//
//  RequestedItemsCollectionViewController.m
//  photomovie
//
//  Created by Evgeny Rusanov on 30.10.13.
//  Copyright (c) 2013 Macsoftex. All rights reserved.
//

#import "RequestedItemsCollectionViewController.h"
#import "RequestItemsDataSource.h"

@interface RequestedItemsCollectionViewController()

@property (nonatomic) BOOL isRequestingPortion;
@property (nonatomic,strong) UIRefreshControl *refreshControl;
@end

@implementation RequestedItemsCollectionViewController
{
    RequestItemsDataSource *dataSource;
}

-(void)initDataSource
{
    dataSource = [RequestItemsDataSource new];
    
    __weak typeof(self) pself = self;
    [dataSource setReloadContainerBlock:^{
        [pself.collectionView reloadData];
    }];
    [dataSource setIsRefreshControllRefreshingBlock:^BOOL{
        return pself.refreshControl.isRefreshing;
    }];
    [dataSource setRefreshControllEndBlock:^{
        [pself.refreshControl endRefreshing];
    }];
    [dataSource setContentCellGeneratorBlock:^id(NSDictionary *item, NSInteger index, id container) {
        return [pself contentCell:item
                   collectionView:container
                     forIndexPath:[NSIndexPath indexPathForRow:index inSection:[pself contentSection]]];
    }];
    [dataSource setLoadingCellGeneratorBlock:^id(NSInteger index, id container) {
        return [pself loadingCell:container
                     forIndexPath:[NSIndexPath indexPathForRow:index inSection:[pself contentSection]]];
    }];
    [dataSource setNoItmesCellGeneratorBlock:^id(NSInteger index, id container) {
        return [pself noItemsCell:container
                     forIndexPath:[NSIndexPath indexPathForRow:index inSection:[pself contentSection]]];
    }];
}

-(id)init
{
    if (self = [super init])
    {
        [self initDataSource];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self initDataSource];
    }
    return self;
}

#pragma mark - Properties

-(NSArray*)items
{
    return dataSource.items;
}

-(void)setItemsRequest:(ItemsRequest *)itemsRequest
{
    dataSource.itemsRequest = itemsRequest;
}

-(ItemsRequest*)itemsRequest
{
    return dataSource.itemsRequest;
}

#pragma mark-

-(void)setRefreshControlEnabled:(BOOL)refreshControlEnabled
{
    _refreshControlEnabled = refreshControlEnabled;
    
    if (_refreshControlEnabled)
        [self initRefreshControl];
    else
        self.refreshControl = nil;
}

-(void)initRefreshControl
{
    if (!self.refreshControlEnabled)
        return;
    
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

-(void)addItems:(NSArray *)newItems
{
    [dataSource addItems:newItems];
}

-(void)updateItem:(NSDictionary *)item withComparator:(BOOL (^)(NSDictionary *, NSDictionary *))comparator
{
    [dataSource updateItem:item withComparator:comparator];
}

-(void)reloadData
{
    [dataSource reloadData];
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

-(int)numberOfCellsInNonContentSection:(NSInteger)section
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
        return dataSource.numberOfCells;
    return [self numberOfCellsInNonContentSection:section];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == [self contentSection])
    {
        return [dataSource generateCellForIndex:indexPath.row inContainer:collectionView];
    }
    
    return [self nonContentCell:collectionView forIndexPath:indexPath];
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == [self contentSection])
    {
        if (indexPath.row < self.items.count)
            return [self cellSizeForItem:self.items[indexPath.row]];
        
        if (self.itemsRequest.isRequesting)
        {
            return [self loadingCellSize];
        }
        
        return [self noitemsCellSize];
    }
    
    return [self nonContentCellSize:collectionView forIndexPath:indexPath];
}

@end
