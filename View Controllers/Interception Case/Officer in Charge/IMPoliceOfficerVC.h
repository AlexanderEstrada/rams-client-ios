//
//  IMPoliceOfficerVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/26/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMTableViewController.h"
#import "PoliceOfficer+Extended.h"

@interface IMPoliceOfficerVC : IMTableViewController

@property (nonatomic, copy) void (^onSave)(PoliceOfficer *policeOfficer);
@property (nonatomic, copy) void (^onCancel)(void);
@property (nonatomic, strong) PoliceOfficer *policeOfficer;

@end