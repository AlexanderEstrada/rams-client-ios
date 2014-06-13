//
//  IMEditInterceptionMovementVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/28/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMTableViewController.h"
#import "InterceptionMovement+Extended.h"
#import "InterceptionGroup+Extended.h"


@interface IMEditInterceptionMovementVC : IMTableViewController

@property (nonatomic, strong) InterceptionGroup *group;
@property (nonatomic, strong) InterceptionMovement *movement;

- (id)initWithMovement:(InterceptionMovement *)movement forGroup:(InterceptionGroup *)group;

@end