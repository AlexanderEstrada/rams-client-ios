//
//  IMPortChooserVC.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 6/27/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMViewController.h"
#import "Port+Extended.h"

@interface IMPortChooserVC : IMViewController

@property (nonatomic) BOOL allowsCreate;
@property (nonatomic, strong) NSPredicate *basePredicate;

@property (nonatomic, copy) void (^onSelected)(Port *selectedPort);
@property (nonatomic, copy) void (^onCancel)(void);

- (id)initWithBasePredicate:(NSPredicate *)basePredicate presentAsModal:(BOOL)modal;


@end
