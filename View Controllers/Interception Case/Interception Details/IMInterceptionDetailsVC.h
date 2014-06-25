//
//  IMInterceptionDetailsVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/27/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMTableViewController.h"
#import "IMInterceptionDataSource.h"
#import "InterceptionData+Extended.h"

@interface IMInterceptionDetailsVC : IMTableViewController

@property (nonatomic, assign) id<IMInterceptionDelegate> delegate;
@property (nonatomic, strong) InterceptionData *interceptionData;
@property (nonatomic) BOOL allowsEditing;

@property (nonatomic, copy) void (^Cancel)(void);

- (id)initWithInterceptionData:(InterceptionData *)data delegate:(id<IMInterceptionDelegate>)delegate;

@end