//
//  IMEditRegistrationDataVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 29/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMTableViewController.h"

@class Registration;
@interface IMEditRegistrationDataVC : IMTableViewController

@property (nonatomic, strong) Registration *registration;
//@property (nonatomic, strong) Registration *lastReg;
@property (nonatomic) BOOL useLastData;
@end