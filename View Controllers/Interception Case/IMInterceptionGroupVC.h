//
//  IMInterceptionGroupVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/20/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMTableViewController.h"
#import "InterceptionGroup+Extended.h"


@interface IMInterceptionGroupVC : IMTableViewController

@property (nonatomic, strong) InterceptionGroup *group;
@property (nonatomic, copy) void (^onSave)(InterceptionGroup *group, BOOL editing);

- (id)initWithInterceptionGroup:(InterceptionGroup *)group action:(void (^)(InterceptionGroup *group, BOOL editing))onSave;

@end