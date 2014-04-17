//
//  ItemsListViewController.m
//  photomovie
//
//  Created by Evgeny Rusanov on 24.11.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import "RequestedItemsListViewController.h"

#import "UITableViewCell+Helpers.h"

#import "RequestItemsDataSource.h"

#import "ODRefreshControl.h"

@implementation RequestedItemsListViewController
{
    ODRefreshControl *odoRefresh;
    
    RequestItemsDataSource *dataSource;
}

-(void)setup
{
    _autoDeselectRows = YES;
    _refreshControlEnabled = YES;
    
    [self initDataSource];
}

-(void)initDataSource
{
    dataSource = [RequestItemsDataSource new];
    
    __weak typeof(self) pself = self;
    [dataSource setReloadContainerBlock:^{
        [pself.tableView reloadData];
    }];
    [dataSource setIsRefreshControllRefreshingBlock:^BOOL{
        return [pself refreshControlisRefreshing];
    }];
    [dataSource setRefreshControllEndBlock:^{
        [pself refreshControlEnd];
    }];
    [dataSource setContentCellGeneratorBlock:^id(NSDictionary *item, NSInteger index, id container) {
        return [pself contentCell:item tableView:container forIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    }];
    [dataSource setLoadingCellGeneratorBlock:^id(NSInteger index, id container) {
        return [pself loadingCell:container];
    }];
    [dataSource setNoItmesCellGeneratorBlock:^id(NSInteger index, id container) {
        return [pself noItemsCell:container];
    }];
}

-(id)init
{
    if (self = [super init])
    {
        [self setup];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setup];
    }
    return self;
}

#define VERSION_MORE_THAN_5     [[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."][0] intValue]>5

-(BOOL)refreshControlisRefreshing
{
    if (VERSION_MORE_THAN_5)
        return self.refreshControl.isRefreshing;
    
    return odoRefresh.isRefreshing;
}

-(void)refreshControlBegin
{
    if (VERSION_MORE_THAN_5)
        [self.refreshControl beginRefreshing];
    else
        [odoRefresh beginRefreshing];
}

-(void)refreshControlEnd
{
    if (VERSION_MORE_THAN_5)
        [self.refreshControl endRefreshing];
    else
        [odoRefresh endRefreshing];
}

-(void)initRefreshControl
{
    if (!self.refreshControlEnabled)
        return;
    
    if (VERSION_MORE_THAN_5)
    {
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self
                                action:@selector(reloadData)
                      forControlEvents:UIControlEventValueChanged];
    }
    else
    {
        odoRefresh = [[ODRefreshControl alloc] initInScrollView:self.tableView];
        [odoRefresh addTarget:self
                       action:@selector(reloadData)
             forControlEvents:UIControlEventValueChanged];
    }
}

-(void)setRefreshControlEnabled:(BOOL)refreshControlEnabled
{
    _refreshControlEnabled = refreshControlEnabled;
    
    if (_refreshControlEnabled)
        [self initRefreshControl];
    else
    {
        if (VERSION_MORE_THAN_5)
            self.refreshControl = nil;
        else
        {
            [odoRefresh removeFromSuperview];
            odoRefresh = nil;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initRefreshControl];
}

#pragma mark - Properties

-(void)setItemsRequest:(ItemsRequest *)itemsRequest
{
    dataSource.itemsRequest = itemsRequest;
}

-(ItemsRequest*)itemsRequest
{
    return dataSource.itemsRequest;
}

-(NSArray*)items
{
    return dataSource.items;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [dataSource numberOfCells];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [dataSource generateCellForIndex:indexPath.row inContainer:tableView];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.items.count)
        return [self cellHeightForItem:[self.items objectAtIndex:indexPath.row] cellWidth:[UITableViewCell groupedCellWidth:self.interfaceOrientation]];
    return tableView.rowHeight;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.autoDeselectRows)
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < self.items.count)
        [self itemSelected:[self.items objectAtIndex:indexPath.row]];
}

#pragma mark - Overload

-(float)cellHeightForItem:(NSDictionary*)item cellWidth:(float)width
{
    return self.tableView.rowHeight;
}

-(UITableViewCell*)loadingCell:(UITableView*)tableView
{
    return nil;
}

-(UITableViewCell*)noItemsCell:(UITableView*)tableView
{
    return nil;
}

-(UITableViewCell*)contentCell:(NSDictionary*)item tableView:(UITableView*)tableView forIndexPath:(NSIndexPath*)indexPath
{
    return nil;
}

-(void)itemSelected:(NSDictionary*)item
{
    
}

@end
