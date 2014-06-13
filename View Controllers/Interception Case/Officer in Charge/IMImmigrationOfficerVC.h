//
//  IMImmigrationOfficerVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/20/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMTableViewController.h"
#import "ImmigrationOfficer+Extended.h"


@interface IMImmigrationOfficerVC : IMTableViewController

@property (nonatomic, copy) void (^onSave)(ImmigrationOfficer *immigrationOfficer);
@property (nonatomic, copy) void (^onCancel)(void);
@property (nonatomic, strong) ImmigrationOfficer *immigrationOfficer;

@end