//
//  IMDatePickerVC.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/5/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMViewController.h"

@interface IMDatePickerVC : IMViewController

@property (nonatomic, strong) NSDate *minimumDate;
@property (nonatomic, strong) NSDate *maximumDate;
@property (nonatomic, strong) NSDate *date;

@property (nonatomic, copy) void (^onDateChanged)(NSDate *selectedDate);
@property (nonatomic, copy) void (^onDone)(NSDate *selectedDate);
@property (nonatomic, copy) void (^onCancel)(void);

- (id)initWithAction:(void (^)(NSDate *selectedDate))action;
- (id)initWithDoneHandler:(void (^)(NSDate *selectedDate))doneHandler onCancel:(void(^)(void))onCancel;

@end
