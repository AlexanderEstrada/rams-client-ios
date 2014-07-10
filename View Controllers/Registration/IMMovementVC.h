//
//  IMMovementVC.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 7/1/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMTableViewController.h"
#import "Migrant+Extended.h"
#import "Movement+Extended.h"

@interface IMMovementVC : IMTableViewController

@property (nonatomic, strong) Migrant *migrant;
@property (nonatomic, strong) Movement *movement;
@property (nonatomic, copy) void (^onSave)(Movement *movement, BOOL editing);

- (id)initWithMigrant:(Migrant *)migrant action:(void (^)(Movement *movement, BOOL editing))onSave;


@end
