//
//  IMDatePickerVC.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/5/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMDatePickerVC.h"

@interface IMDatePickerVC ()

@property (nonatomic, strong) UIDatePicker *datePicker;

@end


@implementation IMDatePickerVC


- (void)dateChanged
{
    _date = self.datePicker.date;
    if (self.onDateChanged) self.onDateChanged(self.date);
}

- (void)setMaximumDate:(NSDate *)maximumDate
{
    _maximumDate = maximumDate ? maximumDate : [NSDate date];
    self.datePicker.maximumDate = maximumDate;
}

- (void)setMinimumDate:(NSDate *)minimumDate
{
    _minimumDate = minimumDate;
    self.datePicker.minimumDate = minimumDate;
}

- (void)setDate:(NSDate *)date
{
    _date = date ? date : [NSDate date];
    self.datePicker.date = self.date;
}


#pragma mark View Lifecycle
- (id)initWithAction:(void (^)(NSDate *selectedDate))action
{
    self = [super init];
    
    self.onDateChanged = action;
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeDate;
    [self.datePicker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.datePicker];
    
    self.title = @"Select Date";
    
    return self;
}

- (id)initWithDoneHandler:(void (^)(NSDate *selectedDate))doneHandler onCancel:(void(^)(void))onCancel
{
    self = [super init];
    
    self.onDone = doneHandler;
    self.onCancel = onCancel;
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeDate;
    [self.datePicker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.datePicker];
    
    self.title = @"Select Date";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.preferredContentSize = CGSizeMake(320, 216);
}

- (void)done
{
    if (self.onDone) self.onDone(self.date);
}

- (void)cancel
{
    if (self.onCancel) self.onCancel();
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.date) self.date = self.maximumDate;
    [self dateChanged];
}

@end