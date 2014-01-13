//
//  IMNewInterceptionVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 7/19/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMTableViewController.h"
#import "InterceptionData+Extended.h"

@interface IMEditInterceptionVC : IMTableViewController

@property (nonatomic, strong) InterceptionData *interceptionData;

@end