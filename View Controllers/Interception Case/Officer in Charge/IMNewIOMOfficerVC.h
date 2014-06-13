//
//  IMIOMOfficerVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/20/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMTableViewController.h"
#import "IomOfficer+Extended.h"


@interface IMNewIOMOfficerVC : IMTableViewController

@property (nonatomic, copy) void (^onSelected)(IomOfficer *iomOfficer);

- (id)initWithAction:(void (^)(IomOfficer *officer))onSelected;

@end