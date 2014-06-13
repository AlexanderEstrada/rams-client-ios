//
//  IMInterceptionMovementVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/28/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMTableViewController.h"
#import "InterceptionGroup+Extended.h"


@interface IMInterceptionMovementHistoryVC : IMTableViewController

@property (nonatomic, strong) InterceptionGroup *group;
@property (nonatomic, copy) void (^onClose)(void);

- (id)initWithInterceptionGroup:(InterceptionGroup *)group onClose:(void (^)(void))onClose;

@end