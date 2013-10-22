//
//  ItemsListViewController.m
//  photomovie
//
//  Created by Evgeny Rusanov on 24.11.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import "RequestedItemsListViewController.h"

#import "UITableViewCell+Helpers.h"

#import "ErrorAlertView.h"

#import "ODRefreshControl.h"

@implementation RequestedItemsListViewController
{
    NSMutableArray *items;
    
    BOOL isRequestingPortion;
    
    ODRefreshControl *odoRefresh;
}

#define VERSION_MORE_THAN_5     [[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."][0] intValue]>5

-(BOOL)refreshControllIsRefreshing
{
    if (VERSION_MORE_THAN_5)
        return self.refreshControl.isRefreshing;
    
    return odoRefresh.isRefreshing;
}

-(void)refreshControllBegin
{
    if (VERSION_MORE_THAN_5)
        [self.refreshControl beginRefreshing];
    else
        [odoRefresh beginRefreshing];
}

-(void)refreshContrllEnd
{
    if (VERSION_MORE_THAN_5)
        [self.refreshControl endRefreshing];
    else
        [odoRefresh endRefreshing];
}

-(void)initRefreshControll
{
    NSLog(@"%@",[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."][0]);
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initRefreshControll];
}

-(void)reloadData
{
    [self.itemsRequest cancel];
    
    items = [NSMutableArray array];
    
    [self.itemsRequest prepare:^(NSArray *newItems, NSError *error) {
        if (!error)
        {
            [items addObjectsFromArray:newItems];
        }
        else
        {
            [ErrorAlertView showError:error realError:YES];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            isRequestingPortion = NO;
            if ([self refreshControllIsRefreshing])
                [self refreshContrllEnd];
            
            [self.tableView reloadData];
        });
    }];
    
    if (self.refreshControl.refreshing)
        [self.itemsRequest nextPortion];
    
    [self.tableView reloadData];
}

-(void)requestNewPortionIfNeeded
{
    if (!isRequestingPortion)
    {
        isRequestingPortion = YES;
        [self.itemsRequest nextPortion];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int count = items.count;
    
    if ((count == 0 || self.itemsRequest.isRequesting) && ![self refreshControllIsRefreshing])
        count++;
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < items.count)
        return [self contentCell:[items objectAtIndex:indexPath.row] tableView:tableView forIndexPath:(NSIndexPath*)indexPath];
    
    if (self.itemsRequest.isRequesting)
    {
        [self requestNewPortionIfNeeded];
        return [self loadingCell:tableView];
    }
    
    return [self noItemsCell:tableView];
}

-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < items.count)
        return [self cellHeightForItem:[items objectAtIndex:indexPath.row] cellWidth:[UITableViewCell groupedCellWidth:self.interfaceOrientation]];
    return tableView.rowHeight;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < items.count)
        [self itemSelected:[items objectAtIndex:indexPath.row]];
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
