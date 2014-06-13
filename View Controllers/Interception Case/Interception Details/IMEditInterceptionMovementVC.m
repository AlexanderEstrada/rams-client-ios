//
//  IMEditInterceptionMovementVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/28/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMEditInterceptionMovementVC.h"
#import "IMDBManager.h"
#import "Accommodation+Extended.h"
#import "IMFormCell.h"
#import "NSDate+Relativity.h"
#import "InterceptionGroup+Extended.h"
#import "IMDatePickerVC.h"
#import "IMOptionChooserViewController.h"
#import "IMAccommodationChooserVC.h"
#import "IMInterceptionDataUpdater.h"


@interface IMEditInterceptionMovementVC ()<UIPopoverControllerDelegate>

@property (nonatomic, strong) NSDate *movementDate;
@property (nonatomic, strong) NSString *movementType;
@property (nonatomic, strong) Accommodation *destination;
@property (nonatomic) int adult;
@property (nonatomic) int children;
@property (nonatomic) int male;
@property (nonatomic) int female;
@property (nonatomic) int uam;
@property (nonatomic) int medical;

@property (nonatomic, strong) UIPopoverController *popover;

@end


@implementation IMEditInterceptionMovementVC

#pragma mark Actions
- (void)save
{
    if (![self validate]) {
        [self showAlertWithTitle:@"Invalid Input" message:@"Please check your input and ensure total migrants by age group equal to total migrants by gender."];
        return;
    }
    
    NSMutableDictionary *movementDict = [NSMutableDictionary dictionary];
    [movementDict setObject:@(self.adult) forKey:@"adult"];
    [movementDict setObject:@(self.children) forKey:@"child"];
    [movementDict setObject:@(self.male) forKey:@"male"];
    [movementDict setObject:@(self.female) forKey:@"female"];
    [movementDict setObject:@(self.uam) forKey:@"unaccompaniedMinor"];
    [movementDict setObject:@(self.medical) forKey:@"medicalCondition"];
    [movementDict setObject:self.movementType forKey:@"type"];
    [movementDict setObject:[self.movementDate toUTCString] forKey:@"date"];
    if (self.destination) [movementDict setObject:self.destination.accommodationId forKey:@"destination"];
    if (self.movement.interceptionMovementId) [movementDict setObject:self.movement.interceptionMovementId forKey:@"id"];
    
    NSDictionary *params = @{@"groupId":self.group.interceptionGroupId, @"movement":movementDict};
    IMInterceptionDataUpdater *updater = [[IMInterceptionDataUpdater alloc] init];
    updater.successHandler = ^{
        [self hideLoadingView];
        [self.navigationController popViewControllerAnimated:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil userInfo:nil];
    };
    
    updater.failureHandler = ^(NSError *error){
        NSLog(@"Error saving movement: %@", [error description]);
        [self hideLoadingView];
        [self showAlertWithTitle:@"Failed Saving Movement" message:@"Error occurred while saving movement. Please check your internet connection and try again. If problem persist, please contact administrator."];
    };
    
    [self showLoadingView];
    [updater submitMovement:params];
}

- (BOOL)validate
{
    int totalAgeGroup = self.adult + self.children;
    int totalGender = self.male + self.female;
    BOOL stat = totalAgeGroup == totalGender;
    stat &= self.movementDate && self.movementType;
    
    if ([self.movementType isEqualToString:@"Transfer"]) stat &= self.destination != nil;
    
    return stat;
}


#pragma mark Table View Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section ? 6 : ([self.movementType isEqualToString:@"Transfer"] ? 3 : 2);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellIdentifier";
    IMFormCell *cell = nil;
    
    switch (indexPath.section) {
        case 0:
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            switch (indexPath.row) {
                case 0:
                    cell.labelTitle.text = @"Date";
                    cell.labelValue.text = [self.movementDate longFormatted];
                    break;
                case 1:
                    cell.labelTitle.text = @"Type";
                    cell.labelValue.text = self.movementType;
                    break;
                case 2:
                    cell.labelTitle.text = @"Transfer Destination";
                    cell.labelValue.text = [self.destination description];
                    break;
            }
            break;
        case 1:
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeStepper reuseIdentifier:cellIdentifier];
            cell.stepper.minimumValue = 0;
            cell.stepper.tintColor = [UIColor IMRed];
            
            if (indexPath.row == 0) {
                cell.labelTitle.text = @"Adult";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", self.adult];
                cell.stepper.value = self.adult;
                cell.onStepperValueChanged = ^(int value){ self.adult = value; };
                cell.stepper.maximumValue = self.movement ? self.group.currentAdult + self.adult : self.group.currentAdult;
            }else if (indexPath.row == 1) {
                cell.labelTitle.text = @"Children";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", self.children];
                cell.stepper.value = self.children;
                cell.onStepperValueChanged = ^(int value){ self.children = value; };
                cell.stepper.maximumValue = self.movement ? self.group.currentChildren + self.children : self.group.currentChildren;
            }else if (indexPath.row == 2) {
                cell.labelTitle.text = @"Male";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", self.male];
                cell.stepper.value = self.male;
                cell.onStepperValueChanged = ^(int value){ self.male = value; };
                cell.stepper.maximumValue = self.movement ? self.group.currentMale + self.male : self.group.currentMale;
            }else if (indexPath.row == 3) {
                cell.labelTitle.text = @"Female";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", self.female];
                cell.stepper.value = self.female;
                cell.onStepperValueChanged = ^(int value){ self.female = value; };
                cell.stepper.maximumValue = self.movement ? self.group.currentFemale + self.female : self.group.currentFemale;
            }else if (indexPath.row == 4) {
                cell.labelTitle.text = @"Unaccompanied Minor";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", self.uam];
                cell.stepper.value = self.uam;
                cell.onStepperValueChanged = ^(int value){ self.uam = value; };
                cell.stepper.maximumValue = self.movement ? self.group.currentUAM + self.uam : self.group.currentUAM;
            }else if (indexPath.row == 5) {
                cell.labelTitle.text = @"Requires Medical Attention";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", self.medical];
                cell.stepper.value = self.medical;
                cell.onStepperValueChanged = ^(int value){ self.medical = value; };
                cell.stepper.maximumValue = self.movement ? self.group.currentMedicalAttention + self.medical : self.group.currentMedicalAttention;
            }
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section) return;
    
    switch (indexPath.row) {
        case 0: [self editMovementDate:indexPath]; break;
        case 1: [self editMovementType:indexPath]; break;
        case 2: [self editTranferDestination:indexPath]; break;
    }
}

#pragma mark Row Actions
- (void)editMovementDate:(NSIndexPath *)indexPath
{
    IMDatePickerVC *vc = [[IMDatePickerVC alloc] initWithAction:^(NSDate *selectedDate){
        IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.labelValue.text = [selectedDate longFormatted];
        self.movementDate = selectedDate;
    }];
    
    vc.maximumDate = [NSDate date];
    vc.date = [NSDate date];
    
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
}

- (void)editMovementType:(NSIndexPath *)indexPath
{
    IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithOptions:[InterceptionMovement movementTypes]
                                                                              onOptionSelected:^(NSString *selectedValue){
                                                                                  IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                                                                                  cell.labelValue.text = selectedValue;
                                                                                  self.movementType = selectedValue;
                                                                                  
                                                                                  if (![self.movementType isEqualToString:@"Transfer"]) {
                                                                                      self.destination = nil;
                                                                                  }
                                                                                  
                                                                                  [self.popover dismissPopoverAnimated:YES];
                                                                                  [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                              }];
    
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
}

- (void)editTranferDestination:(NSIndexPath *)indexPath
{
    IMAccommodationChooserVC *vc = [[IMAccommodationChooserVC alloc] initWithBasePredicate:nil presentAsModal:NO];
    vc.onSelected = ^(Accommodation *accommodation){
        IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.labelValue.text = accommodation.name;
        self.destination = accommodation;
        [self.navigationController popViewControllerAnimated:YES];
    };
    
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark Popover
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    _popover = nil;
    if ([self.tableView indexPathForSelectedRow]) {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}

- (void)showPopoverFromRect:(CGRect)rect withViewController:(UIViewController *)vc navigationController:(BOOL)useNavigation
{
    rect = CGRectMake(rect.size.width - 150, rect.origin.y, rect.size.width, rect.size.height);
    
    if (useNavigation) {
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:navCon];
    }else {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    }
    
    self.popover.delegate = self;
    [self.popover presentPopoverFromRect:rect inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}


#pragma mark View Lifecycle
- (id)initWithMovement:(InterceptionMovement *)movement forGroup:(InterceptionGroup *)group
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.movement = movement;
    self.group = group;
    
    self.title = self.movement ? @"Edit Movement" : @"New Movement";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.preferredContentSize = CGSizeMake(500, 420);
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 20, 0, 0);
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
}

- (void)setMovement:(InterceptionMovement *)movement
{
    _movement = movement;
    
    if (self.movement) {
        self.adult = self.movement.adult.intValue;
        self.children = self.movement.child.intValue;
        self.male = self.movement.male.intValue;
        self.female = self.movement.female.intValue;
        self.uam = self.movement.unaccompaniedMinor.intValue;
        self.medical = self.movement.medicalAttention.intValue;
        self.movementType = self.movement.type;
        self.destination = self.movement.transferLocation;
        self.movementDate = self.movement.date;
    }
}

@end