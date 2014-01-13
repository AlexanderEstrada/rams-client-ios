//
//  IMCityChooserVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/8/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMViewController.h"

@interface IMAccommodationFilterVC : IMViewController

@property (nonatomic, copy) void (^onSelected)(NSPredicate *basePredicate);

- (id)initWithAction:(void (^)(NSPredicate *basePredicate))onSelected;

@end
