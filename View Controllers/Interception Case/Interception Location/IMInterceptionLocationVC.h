//
//  IMInterceptionLocationVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 7/29/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMViewController.h"
#import "InterceptionLocation+Extended.h"

@interface IMInterceptionLocationVC : IMViewController

@property (nonatomic, strong) InterceptionLocation *selectedLocation;
@property (nonatomic, copy) void (^onSelected)(InterceptionLocation *selectedLocation);

- (id)initWithAction:(void (^)(InterceptionLocation *selectedLocation))onSelected;

@end