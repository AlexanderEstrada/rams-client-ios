//
//  IMInterceptionMapDetailVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/1/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMTableViewController.h"
#import "IMInterceptionDataSource.h"

@interface IMinterceptionInfoVC : IMTableViewController

@property (nonatomic, assign) id<IMInterceptionDelegate> delegate;

- (id)initWithData:(NSArray *)data title:(NSString *)title delegate:(id<IMInterceptionDelegate>)delegate;
- (void)setData:(NSArray *)data forTitle:(NSString *)title;

@end
