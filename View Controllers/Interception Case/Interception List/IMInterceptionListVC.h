//
//  IMInterceptionListVC.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/11/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMTableViewController.h"
#import "IMInterceptionDataSource.h"

@interface IMInterceptionListVC : IMTableViewController

@property (nonatomic, assign) id<IMInterceptionDataSource> dataSource;
@property (nonatomic, assign) id<IMInterceptionDelegate> delegate;

- (void)reloadData;

@end