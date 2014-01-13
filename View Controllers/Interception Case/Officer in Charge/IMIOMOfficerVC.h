//
//  IMIOMOfficerVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/20/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMViewController.h"
#import "IomOfficer+Extended.h"

@interface IMIOMOfficerVC : IMViewController

@property (nonatomic, strong) IomOfficer *selectedIomOfficer;
@property (nonatomic, copy) void (^onSelected)(IomOfficer *iomOfficer);

- (id)initWithAction:(void (^)(IomOfficer *iomOfficer))onSelected;

@end