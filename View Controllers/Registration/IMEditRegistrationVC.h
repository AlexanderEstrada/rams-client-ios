//
//  IMEditRegistrationVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 29/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMViewController.h"


@class Registration;
@interface IMEditRegistrationVC : IMViewController 

@property (nonatomic, strong) Registration *registration;
//@property (nonatomic, strong) Registration *LastReg;
@property (nonatomic) BOOL  isMigrant;
@property (nonatomic, strong) NSMutableArray *previewingPhotos;

@property (nonatomic, copy) void (^registrationSave)(BOOL remove);
@property (nonatomic, copy) void (^registrationLast)(Registration *registration);
@property (nonatomic, copy) void (^registrationCancel)(void);


@end