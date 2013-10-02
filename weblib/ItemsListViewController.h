//
//  ItemsListViewController.h
//  photomovie
//
//  Created by Evgeny Rusanov on 24.11.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ItemsRequest.h"

@interface ItemsListViewController : UITableViewController

@property (nonatomic,strong) ItemsRequest *itemsRequest;

-(void)reloadData;

-(UITableViewCell*)loadingCell:(UITableView*)tableView;
-(UITableViewCell*)noItemsCell:(UITableView*)tableView;

-(UITableViewCell*)contentCell:(NSDictionary*)item tableView:(UITableView*)tableView forIndexPath:(NSIndexPath*)indexPath;

-(float)cellHeightForItem:(NSDictionary*)item cellWidth:(float)width;

-(void)itemSelected:(NSDictionary*)item;

@end
