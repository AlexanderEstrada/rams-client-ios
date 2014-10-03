//
//  IMEditRegistrationDataVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 29/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//


#import "IMEditRegistrationDataVC.h"
#import "Registration+Export.h"
#import "IMFormCell.h"
#import "IMDatePickerVC.h"
#import "IMCountryListVC.h"
#import "IMAccommodationChooserVC.h"
#import "IMOptionChooserViewController.h"
#import "IMDBManager.h"
#import "IomOffice+Extended.h"
#import "Migrant+Extended.h"
#import "Movement.h"
#import "Port.h"
#import "IMPortChooserVC.h"
#import "Port+Extended.h"
//#import "IMMovementVC.h"
#import "NSDate+Relativity.h"
#import "UIImage+ImageUtils.h"
#import "Accommodation+Extended.h"
#import "IMAuthManager.h"


typedef enum : NSUInteger {
    table_personal_info =0,
    table_unhcr_data,
    table_interception_data,
    table_migrant_location,
    table_movements,
    table_location
} tablePosition;

typedef enum : NSUInteger {
    row_use_last_data = 0,
    row_first_name,
    row_family_name,
    row_sex,
    row_status,
    row_date_of_birth,
    row_city_of_birth,
    row_country_of_birth,
    row_nationality,
    row_vulnerability,
    row_skip_finger
} table_personal_info_row;

static NSInteger total_row_table_personal_info = 10;
#define MAGIC_NUMBER 666

#define TOTAL_SECTION (5) // we remove table_location

@interface IMEditRegistrationDataVC ()<UIPopoverControllerDelegate, IMOptionChooserDelegate>

@property (nonatomic) BOOL underIOMCare;
@property (nonatomic) BOOL skipFinger;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) Migrant *migrant;
@property (nonatomic, strong) NSMutableArray *movementData;

@end


@implementation IMEditRegistrationDataVC


- (void)setRegistration:(Registration *)registration
{
    _registration = registration;
    _underIOMCare = self.registration.underIOMCare.boolValue;
    
    [self reloadData];
    
}

//- (void)setLastReg:(Registration *)lastReg
//{
//    _lastReg = lastReg;
//}

- (void) reloadData
{
    //get all movement from Migrant
    NSManagedObjectContext *workingContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    NSError *error;
    
    //get all movement
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Migrant"];
    request.predicate = [NSPredicate predicateWithFormat:@"registrationNumber = %@",self.registration.registrationId];
    request.returnsObjectsAsFaults = YES;
    
    NSArray *results = [workingContext executeFetchRequest:request error:&error];
    if ([results count]) {
        
        self.migrant = [results lastObject];
        
        if ([self.migrant.movements count]){
            //sort movement based on date create
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
            self.movementData = [[self.migrant.movements allObjects] mutableCopy];
            [self.movementData sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            sortDescriptor = Nil;
            
        }
        
    }
    if (error) {
        //show error
        NSLog(@"Error while Reload on IMEditRegistrationDataVC : %@", [error description]);
    }
    
    //delete unused pointer
    workingContext = Nil;
    request = Nil;
    results = Nil;
    error = Nil;
    
    [self.tableView reloadData];
}

- (void)setUseLastData:(BOOL)useLastData{
    _useLastData = useLastData;
    
    if(_useLastData == YES) {
//        //show alert
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Use Last Registration Data",Nil) message:NSLocalizedString(@"Are you sure want to last Registration Data ?",Nil) delegate:self cancelButtonTitle:NSLocalizedString(@"NO",Nil) otherButtonTitles:NSLocalizedString(@"YES",Nil), nil];
//        alert.tag = IMUseLastRegistrationData_Tag;
//        [alert show];
         [self saveData:YES];
    }else {
        //reset data to empty
        [self saveData:NO];
    }
    
}

- (void)setUnderIOMCare:(BOOL)underIOMCare
{
    _underIOMCare = underIOMCare;
    
    self.registration.underIOMCare = @(self.underIOMCare);
    
    //reload data
    [self reloadData];
}

- (void)setSkipFinger:(BOOL)skipFinger{
    _skipFinger = skipFinger;
    //    self.registration.skipFinger = @(_skipFinger);
    
    if(_skipFinger == YES) {
        //show alert
        //show alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning !!!",Nil) message:NSLocalizedString(@"Are you sure want to skip finger image ?",Nil) delegate:self cancelButtonTitle:NSLocalizedString(@"NO",Nil) otherButtonTitles:NSLocalizedString(@"YES",Nil), nil];
        alert.tag = IMSkipFinger_Tag;
        [alert show];
    }
    
}

- (NSArray *)vulnerabilityOptions
{
    NSMutableArray *options = [[IMConstants constantsForKey:CONST_VULNERABILITY] mutableCopy];
    
    if ([self.registration.bioData.gender isEqualToString:@"Male"]) {
        [options removeObject:@"Pregnant"];
    }else if ([self.registration.bioData.dateOfBirth age] < 12) {
        [options removeObject:@"Pregnant"];
    }
    
    if ([self.registration.bioData.dateOfBirth age] >= 18) {
        [options removeObject:@"Unaccompanied Minor"];
    }
    
    if ([self.registration.bioData.dateOfBirth age] <= 60) {
        [options removeObject:@"Elderly"];
    }
    
    return options;
}

- (void)updateVulnerability
{
    NSArray *options = [self vulnerabilityOptions];
    if (self.registration.vulnerability && ![options containsObject:self.registration.vulnerability]) {
        self.registration.vulnerability = nil;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row_vulnerability inSection:table_personal_info]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (NSInteger)numberOfSectionsInTableView
{
    NSUInteger numberOfMovement = [self.migrant.movements count];
    if (!numberOfMovement) return TOTAL_SECTION -1; //do not show movement section
    
    return TOTAL_SECTION + numberOfMovement;
}

#pragma mark Table View Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSUInteger numberOfMovement = [self.migrant.movements count];
    if (!numberOfMovement) {
        //do not show movement section
        return TOTAL_SECTION -1;
    }else return TOTAL_SECTION + numberOfMovement;
}

- (NSInteger)movementSectionFormula:(NSSet *) movements

{
    
    NSArray *items = [IMConstants constantsForKey:CONST_MOVEMENT_TYPE];
    int totalData = 2;
    NSUInteger item = 0;
    for (Movement * movement in movements) {
        item = [items indexOfObject:movement.type];
        switch (item) {
            case 0:
                // Escape
                break;
            case 1:
                // Transfer
                totalData += 7;
                break;
            case 2:
                // AVR
            case 3:
                //Resettlement
            case 4 :
                //Deportation
                totalData +=6;
                break;
            case 5:
                //Release
            case 6:
                //Decease
                totalData +=5;
                break;
                //only show movement type and date
            default:
                break;
        }
    }
    return totalData;
}

- (NSInteger) numberOfRow:(Movement *) movement orWithMovementType:(NSString *)movementType
{
    NSArray *items = [IMConstants constantsForKey:CONST_MOVEMENT_TYPE];
    int totalData = 2;
    NSUInteger item = 0;
    if (movement) {
        item = [items indexOfObject:movement.type];
        
    }else if (movementType){
        item = [items indexOfObject:movementType];
    }
    
    switch (item) {
        case 0:
            // Escape
            break;
        case 1:
            // Transfer
            totalData += 7;
            break;
        case 2:
            // AVR
        case 3:
            //Resettlement
        case 4 :
            //Deportation
            totalData +=6;
            break;
        case 5:
            //Release
        case 6:
            //Decease
            totalData +=5;
            break;
            
        default:
            break;
    }
    
    return totalData;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == table_personal_info) {
        return total_row_table_personal_info;
    }else if (section == table_unhcr_data || section == table_migrant_location){
        return 2;
    }else if (section == table_interception_data){
        return 6;
    }
    //    else if (section == table_movements){
    //        return 1;
    //    }
    else if ((section > table_movements) && [self.migrant.movements count]) {
        NSUInteger index = (section - table_location);
        Movement *movement = [self.movementData objectAtIndex:index];
        //get number of row
        return [self numberOfRow:movement orWithMovementType:Nil];
    }
    
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section != table_movements && section < table_movements) return 40;
    
    return 0;
}

- (void)deleteItem:(UIButton *)sender
{
    
    @try {
        if (sender.tag == table_migrant_location) {
            //clear transfer location and date
            self.registration.transferDestination = Nil;
            self.registration.transferDate = Nil;
            //reload data
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:0 inSection:sender.tag],[NSIndexPath indexPathForRow:1 inSection:sender.tag], nil] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception on deleteItem : %@",[exception description]);
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *headerIdentifier = @"registrationHeader";
    
    
    IMTableHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerIdentifier];
    
    if (section == table_personal_info) {
        headerView = [[IMTableHeaderView alloc] initWithTitle:@"" actionTitle:nil alignCenterY:YES reuseIdentifier:headerIdentifier];
        headerView.labelTitle.font = [UIFont thinFontWithSize:28];
        headerView.labelTitle.textAlignment = NSTextAlignmentCenter;
        headerView.labelTitle.textColor = [UIColor blackColor];
        headerView.backgroundView = [[UIView alloc] init];
        headerView.backgroundView.backgroundColor = [UIColor whiteColor];
        headerView.labelTitle.text = NSLocalizedString(@"Personal Information",Nil);
        
    }else if (section == table_unhcr_data){
        headerView = [[IMTableHeaderView alloc] initWithTitle:@"" actionTitle:nil alignCenterY:YES reuseIdentifier:headerIdentifier];
        headerView.labelTitle.font = [UIFont thinFontWithSize:28];
        headerView.labelTitle.textAlignment = NSTextAlignmentCenter;
        headerView.labelTitle.textColor = [UIColor blackColor];
        headerView.backgroundView = [[UIView alloc] init];
        headerView.backgroundView.backgroundColor = [UIColor whiteColor];
        headerView.labelTitle.text = NSLocalizedString(@"UNHCR Data",Nil);
    }else if (section == table_interception_data){
        headerView = [[IMTableHeaderView alloc] initWithTitle:@"" actionTitle:nil alignCenterY:YES reuseIdentifier:headerIdentifier];
        headerView.labelTitle.font = [UIFont thinFontWithSize:28];
        headerView.labelTitle.textAlignment = NSTextAlignmentCenter;
        headerView.labelTitle.textColor = [UIColor blackColor];
        headerView.backgroundView = [[UIView alloc] init];
        headerView.backgroundView.backgroundColor = [UIColor whiteColor];
        headerView.labelTitle.text = NSLocalizedString(@"Interception Data",Nil);
    }else if (section == table_migrant_location){
        headerView = [[IMTableHeaderView alloc] initWithTitle:@"" actionTitle:nil alignCenterY:YES reuseIdentifier:headerIdentifier];
        headerView.labelTitle.font = [UIFont thinFontWithSize:28];
        headerView.labelTitle.textAlignment = NSTextAlignmentCenter;
        headerView.labelTitle.textColor = [UIColor blackColor];
        headerView.backgroundView = [[UIView alloc] init];
        headerView.backgroundView.backgroundColor = [UIColor whiteColor];
        headerView.labelTitle.text = NSLocalizedString(@"Location",Nil);
        
        //add clear button
        headerView.buttonAction = [UIButton buttonWithType:UIButtonTypeCustom];
        [headerView.buttonAction setImage:[[UIImage imageNamed:@"icon-delete"] imageMaskWithColor:[UIColor IMMagenta]] forState:UIControlStateNormal];
        [headerView.buttonAction setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [headerView.buttonAction setTitle:Nil forState:UIControlStateNormal];
        [headerView.buttonAction setTranslatesAutoresizingMaskIntoConstraints:NO];
        [headerView.contentView addSubview:headerView.buttonAction];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAction attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:-20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
        
        [headerView.buttonAction addTarget:self action:@selector(deleteItem:) forControlEvents:UIControlEventTouchUpInside];
        headerView.buttonAction.tag = table_migrant_location;
        
        //hide if not under IOM care
        //        headerView.hidden = !_underIOMCare;
        
    }else if (section == table_movements){
        //        headerView = [[IMTableHeaderView alloc] initWithTitle:@"" actionTitle:nil alignCenterY:YES reuseIdentifier:@"movementHeader"];
        headerView = [[IMTableHeaderView alloc] initWithTitle:@"" actionTitle:nil alignCenterY:YES reuseIdentifier:headerIdentifier];
        headerView.labelTitle.font = [UIFont thinFontWithSize:28];
        headerView.labelTitle.textAlignment = NSTextAlignmentCenter;
        headerView.labelTitle.textColor = [UIColor blackColor];
        headerView.backgroundView = [[UIView alloc] init];
        headerView.backgroundView.backgroundColor = [UIColor whiteColor];
        // implement Add button for movement
        headerView.labelTitle.text = NSLocalizedString(@"Movements",Nil);
        //
        //        headerView.buttonAction = [UIButton buttonWithType:UIButtonTypeContactAdd];
        //        [headerView.buttonAction setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        //        headerView.buttonAction.tag = section;
        //        [headerView.buttonAction setTitle:Nil forState:UIControlStateNormal];
        //        [headerView.buttonAction setTranslatesAutoresizingMaskIntoConstraints:NO];
        //        [headerView.contentView addSubview:headerView.buttonAction];
        //
        //        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
        //        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAction attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:-20]];
        //        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        //
        //        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
        //
        //        [headerView.buttonAction addTarget:self action:@selector(addMoreMovement:) forControlEvents:UIControlEventTouchUpInside];
    }else if (section > table_movements){
        headerView = [[IMTableHeaderView alloc] initWithTitle:@"" actionTitle:nil alignCenterY:YES reuseIdentifier:@"movementHeader"];
        headerView.labelTitle.font = [UIFont boldFontWithSize:20];
        headerView.labelTitle.textAlignment = NSTextAlignmentLeft;
        headerView.labelTitle.text = [NSString stringWithFormat:NSLocalizedString(@"Movement Detail # %i",Nil),(section - table_location)+1];
    }
    
    return headerView;
}

//- (void)addMoreMovement:(UIButton *)sender
//{
//    IMMovementVC *vc = [[IMMovementVC alloc] initWithMigrant:nil
//                                                      action:^(Movement *movement, BOOL editing){
//                                                          [self.popover dismissPopoverAnimated:YES];
//                                                          self.popover = nil;
//
//                                                          if (movement && !editing) {
//
//                                                              //get all movement from Migrant
//                                                              NSManagedObjectContext *workingContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
//                                                              NSError *error;
//
//                                                              //get all movement
//                                                              NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Migrant"];
//                                                              request.predicate = [NSPredicate predicateWithFormat:@"registrationNumber = %@",self.registration.registrationId];
//                                                              request.returnsObjectsAsFaults = YES;
//
//                                                              NSArray *results = [workingContext executeFetchRequest:request error:&error];
//
//                                                              if (![results count]) {
//                                                                  //todo : add movement to migrant
//                                                                  if (!self.registration.registrationId) {
//                                                                      //set UUID as default registration ID
//                                                                      self.registration.registrationId = [[NSUUID UUID] UUIDString];
//                                                                  }
//                                                                  //create new migrant data
//                                                                  self.migrant = [Migrant newMigrantInContext:workingContext withId:self.registration.registrationId];
//
//                                                                  //deep copy new registration data to migrant
//                                                                  [Migrant saveMigrantInContext:workingContext withId:self.registration.registrationId andRegistrationData:self.registration];
//
//                                                                  //init movement data
//                                                                  self.movementData = [NSMutableArray array];
//                                                              }
//
//
//                                                              [self.migrant addMovementsObject:movement];
//                                                              //save to database
//                                                              if (![workingContext save:&error]) {
//                                                                  NSLog(@"Error saving context: %@", [error description]);
//                                                                  [self showAlertWithTitle:@"Failed Adding Movements" message:@"Please fill Personal Information."];
//                                                                  [workingContext rollback];
//                                                              }
//
//                                                              //delete unused pointer
//                                                              workingContext = Nil;
//                                                              results = Nil;
//                                                              request = Nil;
//
//                                                          }
//                                                          [self reloadData];
//                                                      }];
//    [self showPopoverFromRect:[self.tableView rectForHeaderInSection:3] withViewController:vc navigationController:YES];
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    IMFormCell *cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
    
    if (indexPath.section == table_personal_info) {
        if (indexPath.row == row_use_last_data) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeSwitch reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Use Last Data",Nil);
            cell.switcher.on = _useLastData;
            cell.onSwitcherValueChanged = ^(BOOL value){ self.useLastData = value;
            };
            cell.hidden= YES;
        }else if (indexPath.row == row_first_name) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"First Name",Nil);
            cell.textValue.placeholder = NSLocalizedString(@"e.g Jafar",Nil);
            cell.textValue.text = self.registration.bioData.firstName;
            cell.onTextValueReturn = ^(NSString *value){
                self.registration.bioData.firstName = value;
            };
            cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet]];
            cell.maxCharCount = 40;
        }else if (indexPath.row == row_family_name) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Family Name",Nil);
            cell.labelTitle.textColor = [UIColor grayColor];
            cell.textValue.placeholder = NSLocalizedString(@"e.g Muhammad",Nil);
            cell.textValue.text = self.registration.bioData.familyName;
            cell.onTextValueReturn = ^(NSString *value){ self.registration.bioData.familyName = value; };
            cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet]];
            cell.maxCharCount = 40;
        }else if (indexPath.row == row_sex) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            //            cell.labelTitle.text = @"Gender";
            cell.labelTitle.text = NSLocalizedString(@"Sex",Nil);
            cell.labelValue.text = self.registration.bioData.gender;
        }else if (indexPath.row == row_status) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Marital Status",Nil);
            cell.labelValue.text = self.registration.bioData.maritalStatus;
        }else if (indexPath.row == row_date_of_birth) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Date of Birth",Nil);
            cell.labelValue.text = [self.registration.bioData.dateOfBirth mediumFormatted];
        }else if (indexPath.row == row_city_of_birth) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"City of Birth",Nil);
            cell.textValue.placeholder = NSLocalizedString(@"e.g Kabul",Nil);
            cell.textValue.text = self.registration.bioData.placeOfBirth;
            cell.onTextValueReturn = ^(NSString *value){ self.registration.bioData.placeOfBirth = value; };
            cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet], [NSCharacterSet characterSetWithCharactersInString:@",-"]];
        }else if (indexPath.row == row_country_of_birth) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Country of Birth",Nil);
            cell.labelValue.text = self.registration.bioData.countryOfBirth.name;
        }else if (indexPath.row == row_nationality) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Nationality",Nil);
            cell.labelValue.text = self.registration.bioData.nationality.name;
        }else if (indexPath.row == row_vulnerability) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Vulnerability",Nil);
            cell.labelValue.text = self.registration.vulnerability;
            //hidden as requested
            cell.hidden = YES;
        }else if (indexPath.row == row_skip_finger) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeSwitch reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Skip Finger Image",Nil);
            //            cell.switcher.on = self.registration.skipFinger.boolValue;
            cell.onSwitcherValueChanged = ^(BOOL value){ self.skipFinger = value;
            };
            
        }
    }else if (indexPath.section == table_unhcr_data) {
        if (indexPath.row == 0) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"UNHCR Document",Nil);
            cell.labelValue.text = [self.registration.unhcrDocument length]?self.registration.unhcrDocument:NSLocalizedString(@"No Document",Nil);
        }else if (indexPath.row == 1) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"UNHCR Document Number",Nil);
            cell.textValue.placeholder = NSLocalizedString(@"e.g 186-09C02429",Nil);
            
            cell.textValue.text = self.registration.unhcrNumber;
            cell.onTextValueReturn = ^(NSString *value){
                if (!self.registration.unhcrDocument){
                    //show alert
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Input",Nil) message:NSLocalizedString(@"Please input UNHCR Document",Nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    alert.tag = IMAlertNOUNHCR_Tag;
                    [alert show];
                    self.registration.unhcrNumber = value = Nil;
                }else self.registration.unhcrNumber = [value uppercaseString]; };
            cell.characterSets = @[[NSCharacterSet characterSetWithCharactersInString:@"0123456789cC-"]];
            //case no document, then hide UNHCR document Number
            cell.hidden =[self.registration.unhcrDocument length]?NO:YES;
        }
    }else if (indexPath.section == table_interception_data) {
        if (indexPath.row == 0) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Date Of Entry",Nil);
            cell.labelValue.text = [self.registration.interceptionData.dateOfEntry mediumFormatted];
        } else if (indexPath.row == 1) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Interception Date",Nil);
            cell.labelValue.text = [self.registration.interceptionData.interceptionDate mediumFormatted];
        }else if (indexPath.row == 2) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Interception Location",Nil);
            cell.textValue.text = self.registration.interceptionData.interceptionLocation;
            cell.textValue.placeholder = NSLocalizedString(@"e.g Pelabuhan Ratu, Banten, Jawa Barat",Nil);
            cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet], [NSCharacterSet characterSetWithCharactersInString:@"-,"]];
            cell.onTextValueReturn = ^(NSString *value){ self.registration.interceptionData.interceptionLocation = value; };
            cell.maxCharCount = 50;
        }
        //TODO : add IOM assosiate Office
        else if (indexPath.row == 3){
            
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Assosiate IOM Office",Nil);
            
            if (!self.registration.associatedOffice.name) {
                self.registration.associatedOffice = [IomOffice officeWithName:[IMAuthManager sharedManager].activeUser.officeName inManagedObjectContext:self.registration.managedObjectContext];
            }
            cell.labelValue.text = self.registration.associatedOffice.name;
            
        }
        else if (indexPath.row == 4){
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeSwitch reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Self Reporting",Nil);
            cell.switcher.on = self.registration.selfReporting.boolValue;
            cell.onSwitcherValueChanged = ^(BOOL value){ self.registration.selfReporting = @(value);
                self.registration.interceptionData.selfReporting = @(value);
            };
        }
        else {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeSwitch reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Under IOM Care",Nil);
            cell.switcher.on = self.registration.underIOMCare.boolValue;
            cell.onSwitcherValueChanged = ^(BOOL value){ self.underIOMCare = value; };
        }
    }else if (indexPath.section > table_movements && [self.migrant.movements count]) {
        
        
        //get the index based on total movement, so we can add section header for every movement history
        NSUInteger index = ((indexPath.section - table_location));
        Movement *movement = [self.movementData objectAtIndex:index];
        
        
        if (indexPath.row == 0) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Movement Type",Nil);
            cell.labelValue.text = movement.type;
        } else if (indexPath.row == 1) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Movement Date",Nil);
            cell.labelValue.text = [movement.date mediumFormatted];
        }else if (indexPath.row == 2) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Document Number",Nil);
            cell.textValue.placeholder = NSLocalizedString(@"e.g LSD-09C02429",Nil);
            cell.textValue.text = movement.documentNumber;
            cell.onTextValueReturn = ^(NSString *value){ movement.documentNumber = value; };
            cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet]];
        }else if (indexPath.row == 3) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Proposed Date",Nil);
            cell.labelValue.text = [movement.proposedDate mediumFormatted];
        }else if (indexPath.row == 4) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Travel Mode",Nil);
            cell.labelValue.text = movement.travelMode;
        }else if (indexPath.row == 5) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Reference Code",Nil);
            cell.textValue.placeholder = NSLocalizedString(@"e.g travel/vehicle/flight number",Nil);
            cell.textValue.text = movement.referenceCode;
            cell.onTextValueReturn = ^(NSString *value){ movement.referenceCode = value; };
            cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet]];
        }else if (indexPath.row == 6) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Departure Port",Nil);
            cell.labelValue.text = movement.departurePort.name;
        }else if (indexPath.row == 7) {
            switch ([self numberOfRow:movement orWithMovementType:Nil]) {
                case 8:
                    cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
                    cell.labelTitle.text = NSLocalizedString(@"Destination Country",Nil);
                    cell.labelValue.text = movement.destinationCountry.name;
                    break;
                case 9:
                    cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
                    cell.labelTitle.text = NSLocalizedString(@"Origin Location",Nil);
                    cell.labelValue.text = movement.originLocation.name;
                    break;
                default:
                    break;
            }
        }else if (indexPath.row == 8) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Transfer Location",Nil);
            cell.labelValue.text = movement.transferLocation.name;
        }
        
        
    }else if (indexPath.section == table_migrant_location) {
        if (indexPath.row == 0) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Latest Location",Nil);
            if (!self.registration.transferDestination.name && self.registration.transferDate) {
                self.registration.transferDestination = [Accommodation accommodationWithName:self.registration.detentionLocationName inManagedObjectContext:self.registration.managedObjectContext];
                NSError * err;
                [self.registration.managedObjectContext save:&err];
                if (err) {
                    NSLog(@"Error while saving : %@",[err description]);
                }else [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil userInfo:nil];
            }
            cell.labelValue.text = self.registration.transferDestination.name;
        }else if (indexPath.row == 1) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = NSLocalizedString(@"Transfer Date to Latest Location",Nil);
            cell.labelValue.text = [self.registration.transferDate mediumFormatted];
        }
        //case not under IOM care, then hide cell
        //        cell.hidden = !_underIOMCare;
    }
    
    return cell;
}

- (NSInteger) tableFormula:(NSInteger)Base withPlace:(NSInteger)place
{
    return (Base - place);
}

#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
//    _useLastData = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.registration.transferDestination.name && self.registration.transferDate) {
        self.registration.transferDestination = [Accommodation accommodationWithName:self.registration.detentionLocationName inManagedObjectContext:self.registration.managedObjectContext];
        NSError * err;
        [self.registration.managedObjectContext save:&err];
        if (err) {
            NSLog(@"Error while saving : %@",[err description]);
        }else [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil userInfo:nil];
    }

}

- (void)saveData:(BOOL)flag
{
    @try {
        if (flag) {
            //deep copy all data
            //        self.registration = self.lastReg;
            NSManagedObjectContext *workingContext = self.registration.managedObjectContext;
            Registration * lastReg = [Registration registrationWithId:IMBackupKey inManagedObjectContext:workingContext];
            if (lastReg) {
                
                //personal information
                self.registration.bioData.countryOfBirth = [Country countryWithName:lastReg.bioData.countryOfBirth.name inManagedObjectContext:workingContext];
                self.registration.bioData.nationality =   [Country countryWithName:lastReg.bioData.nationality.name inManagedObjectContext:workingContext];
                
                //unhcr document
                self.registration.unhcrDocument = lastReg.unhcrDocument;
                self.registration.unhcrNumber =  lastReg.unhcrNumber;
                
                
                //interception data
                
                self.registration.associatedOffice = [IomOffice officeWithName:lastReg.associatedOffice.name inManagedObjectContext:workingContext];
                self.registration.underIOMCare = lastReg.underIOMCare;
                self.underIOMCare = self.registration.underIOMCare.boolValue;
                self.registration.selfReporting =  lastReg.selfReporting;
                self.registration.interceptionData.dateOfEntry =  lastReg.interceptionData.dateOfEntry;
                self.registration.interceptionData.interceptionDate =  lastReg.interceptionData.interceptionDate;
                self.registration.interceptionData.interceptionLocation =  lastReg.interceptionData.interceptionLocation;
                
                //location
                self.registration.transferDestination =  [Accommodation accommodationWithId:lastReg.transferDestination.accommodationId inManagedObjectContext:workingContext];
                
                self.registration.transferDate =  lastReg.transferDate;
                if (!self.registration.detentionLocationName && self.registration.transferDestination.name) {
                    self.registration.detentionLocationName = self.registration.transferDestination.name;
                    self.registration.detentionLocation = self.registration.transferDestination.accommodationId;
                }
            }
        }else {
            self.registration.bioData.countryOfBirth = self.registration.bioData.nationality = Nil;
            self.registration.unhcrDocument = self.registration.unhcrNumber = Nil;
            self.registration.associatedOffice = Nil;
            self.registration.underIOMCare = Nil;
            self.registration.selfReporting = Nil;
            self.registration.interceptionData.dateOfEntry = Nil;
            self.registration.interceptionData.interceptionDate = Nil;
            self.registration.interceptionData.interceptionLocation = Nil;
            self.registration.transferDestination = Nil;
            self.registration.transferDate = Nil;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception with flag : %@ on saveData : %@",flag?@"Yes":@"No",[exception description]);
    }
    @finally {
        [self.tableView reloadData];
    }
    
    
    
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == IMAlertNOUNHCR_Tag) {
        //reset UNHCR document number
        self.registration.unhcrNumber = Nil;
    }else if (alertView.tag == IMSkipFinger_Tag && buttonIndex == [alertView cancelButtonIndex]){
        _skipFinger = NO;
        //        self.registration.skipFinger = @(_skipFinger);
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row_skip_finger inSection:table_personal_info]]
                              withRowAnimation:UITableViewRowAnimationNone];
    }else if (alertView.tag == IMUseLastRegistrationData_Tag){
        
        if (buttonIndex == [alertView cancelButtonIndex]) {
            _useLastData = NO;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row_use_last_data inSection:table_personal_info]]
                                  withRowAnimation:UITableViewRowAnimationNone];
            //reset data
            [self saveData:NO];
        }else{
            [self saveData:YES];
        }
        
        
    }
    
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == table_personal_info) {
        if (indexPath.row == row_sex) {
            IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_GENDER delegate:self];
            vc.selectedValue = self.registration.bioData.gender;
            [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
        }else if (indexPath.row == row_status) {
            IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_MARITAL_STATUS delegate:self];
            vc.selectedValue = self.registration.bioData.maritalStatus;
            [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
        }else if (indexPath.row == row_date_of_birth) {
            IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
                self.registration.bioData.dateOfBirth = date;
                IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.labelValue.text = [self.registration.bioData.dateOfBirth mediumFormatted];
                [self updateVulnerability];
            }];
            
            datePicker.maximumDate = [NSDate date];
            datePicker.date = self.registration.bioData.dateOfBirth;
            [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
        }else if (indexPath.row == row_country_of_birth) {
            IMCountryListVC *vc = [[IMCountryListVC alloc] initWithBasePredicate:nil presentAsModal:NO popover:YES];
            vc.onSelected = ^(Country *country){
                Country *selectedCountry = [Country countryWithCode:country.code inManagedObjectContext:self.registration.managedObjectContext];
                self.registration.bioData.countryOfBirth = selectedCountry;
                if (!self.registration.bioData.nationality) self.registration.bioData.nationality = selectedCountry;
                
                [self.popover dismissPopoverAnimated:YES];
                self.popover = nil;
                [self.tableView reloadRowsAtIndexPaths:@[indexPath, [NSIndexPath indexPathForRow:row_nationality inSection:table_personal_info]] withRowAnimation:UITableViewRowAnimationAutomatic];
            };
            [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
        }else if (indexPath.row == row_nationality) {
            IMCountryListVC *vc = [[IMCountryListVC alloc] initWithBasePredicate:nil presentAsModal:NO popover:YES];
            vc.onSelected = ^(Country *country){
                self.registration.bioData.nationality = [Country countryWithCode:country.code inManagedObjectContext:self.registration.managedObjectContext];
                [self.popover dismissPopoverAnimated:YES];
                self.popover = nil;
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            };
            [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
        }else if (indexPath.row == row_vulnerability) {
            IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithOptions:[self vulnerabilityOptions] delegate:self];
            vc.selectedValue = self.registration.vulnerability;
            vc.firstRowIsSpecial = NO;
            [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
        }
    }else if (indexPath.section == table_unhcr_data){
        if (indexPath.row == 0) {
            IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_UNHCR_DOCUMENT delegate:self];
            vc.selectedValue = self.registration.unhcrDocument;
            vc.firstRowIsSpecial = NO;
            [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
        }else if (indexPath.row == 1){
            if (!self.registration.unhcrDocument) {
                //show alert
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Input",Nil) message:NSLocalizedString(@"Please input UNHCR Document",Nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                alert.tag = IMAlertNOUNHCR_Tag;
                [alert show];
                
            }
        }
        
    }else if (indexPath.section == table_interception_data) {
        if (indexPath.row == 0) {
            IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
                self.registration.interceptionData.dateOfEntry = date;
                IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.labelValue.text = [self.registration.interceptionData.dateOfEntry mediumFormatted];
            }];
            
            datePicker.maximumDate = [NSDate date];
            datePicker.date = self.registration.interceptionData.dateOfEntry;
            [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
        }else if (indexPath.row == 1) {
            IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
                self.registration.interceptionData.interceptionDate = date;
                IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.labelValue.text = [self.registration.interceptionData.interceptionDate mediumFormatted];
            }];
            
            datePicker.maximumDate = [NSDate date];
            datePicker.date = self.registration.interceptionData.interceptionDate;
            [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
        }else if (indexPath.row == 3){
            
            //get Assosiate IOM Office from database
            NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
            NSArray *offices = [IomOffice officesInManagedObjectContext:context];
            
            //add Assosiate IOM Office data
            IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithOptions:offices onOptionSelected:^(id selectedValue){
                IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.labelValue.text = [selectedValue description];
                self.registration.associatedOffice = [IomOffice officeWithName:[selectedValue description] inManagedObjectContext:self.registration.managedObjectContext];
                [self.popover dismissPopoverAnimated:YES];
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }];
            vc.title = NSLocalizedString(@"Select IOM Office",Nil);
            
            [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:YES];
            
        }
        
    }else if ((indexPath.section > table_movements) && [self.migrant.movements count]){
        
        //get the index based on total movement, so we can add section header for every movement history
        NSUInteger index = ((indexPath.section - table_location));
        Movement *movement = [self.movementData objectAtIndex:index];
        
        if (indexPath.row == 0) {
            IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_MOVEMENT_TYPE delegate:self];
            vc.selectedValue = movement.type;
            vc.firstRowIsSpecial = NO;
            vc.onOptionSelected = ^ (id selectedValue){
                movement.type = selectedValue;
                [self.popover dismissPopoverAnimated:YES];
                self.popover = nil;
                //update movement data
                [self.movementData replaceObjectAtIndex:index withObject:movement];
                //reload table
                [self.tableView reloadData];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            };
            [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
        }else if (indexPath.row == 1) {
            IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
                movement.date = date;
                IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.labelValue.text = [movement.date mediumFormatted];
            }];
            datePicker.maximumDate = [NSDate date];
            datePicker.date = movement.date;
            [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
        }else if (indexPath.row == 3){
            IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
                movement.proposedDate = date;
                IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.labelValue.text = [movement.proposedDate mediumFormatted];
            }];
            datePicker.maximumDate = [NSDate date];
            datePicker.date = movement.proposedDate;
            [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
        }else if (indexPath.row == 4){
            IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_TRAVEL_MODE delegate:self];
            vc.selectedValue = movement.travelMode;
            vc.firstRowIsSpecial = NO;
            [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
        }else if (indexPath.row == 6){
            [self showPort:indexPath];
        }else if (indexPath.row == 7) {
            
            switch ([self numberOfRow:movement orWithMovementType:Nil]) {
                case 8:{
                    IMCountryListVC *vc = [[IMCountryListVC alloc] initWithBasePredicate:nil presentAsModal:NO popover:YES];
                    vc.onSelected = ^(Country *country){
                        movement.destinationCountry = [Country countryWithCode:country.code inManagedObjectContext:self.registration.managedObjectContext];
                        [self.popover dismissPopoverAnimated:YES];
                        self.popover = nil;
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    };
                    [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
                    break;
                }
                case 9:
                    [self showAccommodation:indexPath];
                    break;
                default:
                    break;
            }
        }else if (indexPath.row == 8) {
            [self showAccommodation:indexPath];
        }
        
        //update movement data
        [self.movementData replaceObjectAtIndex:index withObject:movement];
        
    }else if (indexPath.section == table_migrant_location) {
        if (indexPath.row == 0) {
            [self showAccommodation:indexPath];
        }else if (indexPath.row == 1) {
            IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
                self.registration.transferDate = date;
                IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.labelValue.text = [self.registration.transferDate mediumFormatted];
            }];
            
            datePicker.maximumDate = [NSDate date];
            datePicker.date = self.registration.transferDate;
            [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
        }
    }
    
}

- (void)showOptionChooserWithConstantsKey:(NSString *)constantsKey indexPath:(NSIndexPath *)indexPath useNavigation:(BOOL)useNavigation
{
    IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:constantsKey delegate:self];
    vc.view.tintColor = [UIColor IMMagenta];
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:useNavigation];
}


- (void)optionChooser:(IMOptionChooserViewController *)optionChooser didSelectOptionAtIndex:(NSUInteger)selectedIndex withValue:(id)value
{
    if (optionChooser.constantsKey == CONST_UNHCR_DOCUMENT) {
        if (selectedIndex == 0) {
            self.registration.unhcrDocument = nil;
            self.registration.unhcrNumber = nil;
        }else {
            self.registration.unhcrDocument = value;
        }
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }else if (optionChooser.constantsKey == CONST_GENDER) {
        self.registration.bioData.gender = value;
        [self updateVulnerability];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row_sex inSection:table_personal_info]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }else if (optionChooser.constantsKey == CONST_MARITAL_STATUS) {
        self.registration.bioData.maritalStatus = value;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row_status inSection:table_personal_info]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }else if (optionChooser.constantsKey == CONST_TRAVEL_MODE){
        //get the index based on total movement, so we can add section header for every movement history
        NSUInteger index = (([optionChooser getSelectedIndexPath].section - table_location));
        
        Movement *movement = [self.movementData objectAtIndex:index];
        movement.travelMode = value;
        //update movement data
        [self.movementData replaceObjectAtIndex:index withObject:movement];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:4 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }else if (!optionChooser.constantsKey) {
        self.registration.vulnerability = selectedIndex == 0 ? nil : value;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row_vulnerability inSection:table_personal_info]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self.popover dismissPopoverAnimated:YES];
    self.popover = nil;
}

- (void) updateRow:(NSString *)lastMovementType and:(NSString *)currentMovementType onIndexPath:(NSIndexPath *)indexPath
{
    NSInteger lastRowTotal = lastMovementType ?[self numberOfRow:Nil orWithMovementType:lastMovementType]:2;
    NSInteger currentRowTotal = [self numberOfRow:Nil orWithMovementType:currentMovementType];
    
    NSMutableArray *arrayOfCommand = [NSMutableArray array];
    if (lastRowTotal < currentRowTotal) {
        //case need update and insert the row
        for (; lastRowTotal < currentRowTotal; lastRowTotal++) {
            [arrayOfCommand addObject:[NSIndexPath indexPathForRow:(lastRowTotal -1) inSection:indexPath.section]];
        }
        [self.tableView beginUpdates];
        [self.tableView  insertRowsAtIndexPaths:arrayOfCommand withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView endUpdates];
    }else {
        //case need update and delete the row
        for (; currentRowTotal < lastRowTotal; currentRowTotal++) {
            [arrayOfCommand addObject:[NSIndexPath indexPathForRow:(currentRowTotal -1) inSection:indexPath.section]];
        }
        [self.tableView beginUpdates];
        [self.tableView  deleteRowsAtIndexPaths:arrayOfCommand withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView endUpdates];
    }
    
}



- (void)showPopoverFromRect:(CGRect)rect withViewController:(UIViewController *)vc navigationController:(BOOL)useNavigation
{
    rect = CGRectMake(rect.size.width - 150, rect.origin.y, rect.size.width, rect.size.height);
    vc.view.tintColor = [UIColor IMMagenta];
    vc.modalInPopover = NO;
    
    if (useNavigation) {
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
        navCon.navigationBar.tintColor = [UIColor IMMagenta];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:navCon];
    }else {
        vc.view.tintColor = [UIColor IMMagenta];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    }
    
    self.popover.delegate = self;
    [self.popover presentPopoverFromRect:rect inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    self.popover = nil;
}

- (void)showAccommodation:(NSIndexPath *)indexPath
{
    IMAccommodationChooserVC *vc = [[IMAccommodationChooserVC alloc] initWithBasePredicate:nil presentAsModal:NO];
    vc.onSelected = ^(Accommodation *accommodation){
        if ((indexPath.section >= table_location) && [self.migrant.movements count]) {
            //get the index based on total movement, so we can add section header for every movement history
            
            if (indexPath.row == 7 || indexPath.row == 8) {
                NSUInteger index = ((indexPath.section - table_location));
                Movement *movement = [self.movementData objectAtIndex:index];
                movement.originLocation = [Accommodation accommodationWithId:accommodation.accommodationId inManagedObjectContext:self.registration.managedObjectContext];
                [self.movementData replaceObjectAtIndex:index withObject:movement];
            }else {
                self.registration.transferDestination = [Accommodation accommodationWithId:accommodation.accommodationId inManagedObjectContext:self.registration.managedObjectContext];
                self.registration.detentionLocationName = self.registration.transferDestination.name;
                self.registration.detentionLocation = self.registration.transferDestination.accommodationId;
            }
            
            
        }else {
            self.registration.transferDestination = [Accommodation accommodationWithId:accommodation.accommodationId inManagedObjectContext:self.registration.managedObjectContext];
            self.registration.detentionLocationName = self.registration.transferDestination.name;
            self.registration.detentionLocation = self.registration.transferDestination.accommodationId;
        }
        
        
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    vc.preferredContentSize = CGSizeMake(500, 400);
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:YES];
}

- (void)showPort:(NSIndexPath *)indexPath
{
    IMPortChooserVC *vc = [[IMPortChooserVC alloc] initWithBasePredicate:nil presentAsModal:NO];
    vc.onSelected = ^(Port *port){
        if ((indexPath.section >= table_location) && [self.migrant.movements count]) {
            
            //get the index based on total movement, so we can add section header for every movement history
            NSUInteger index = (indexPath.section - table_location);
            Movement *movement = [self.movementData objectAtIndex:index];
            
            movement.departurePort = [Port portWithName:port.name inManagedObjectContext:self.registration.managedObjectContext];
            [self.movementData replaceObjectAtIndex:index withObject:movement];
            
        }
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    vc.preferredContentSize = CGSizeMake(500, 400);
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:YES];
}


@end
/*
 
 
 
 #import "IMEditRegistrationDataVC.h"
 #import "Registration+Export.h"
 #import "IMFormCell.h"
 #import "IMDatePickerVC.h"
 #import "IMCountryListVC.h"
 #import "IMAccommodationChooserVC.h"
 #import "IMOptionChooserViewController.h"
 #import "IMDBManager.h"
 #import "IomOffice+Extended.h"
 #import "Migrant+Extended.h"
 
 #define TAG_NO_UNHCR_DOC 1
 
 @interface IMEditRegistrationDataVC ()<UIPopoverControllerDelegate, IMOptionChooserDelegate>
 
 @property (nonatomic) BOOL underIOMCare;
 @property (nonatomic, strong) UIPopoverController *popover;
 
 @end
 
 
 @implementation IMEditRegistrationDataVC
 
 #define kOptionGenderTag                1
 #define kOptionMaritalStatusTag         2
 #define kOptionDateOfBirthTag           3
 #define kNationality
 
 - (void)setRegistration:(Registration *)registration
 {
 _registration = registration;
 _underIOMCare = self.registration.underIOMCare.boolValue;
 
 [self.tableView reloadData];
 }
 
 - (void)setUnderIOMCare:(BOOL)underIOMCare
 {
 _underIOMCare = underIOMCare;
 
 self.registration.underIOMCare = @(self.underIOMCare);
 
 if (self.underIOMCare) {
 [self.tableView insertSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
 [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
 }else {
 self.registration.transferDate = nil;
 self.registration.transferDestination = nil;
 if ([self.tableView numberOfSections] == 4) {
 [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationFade];
 }
 }
 }
 
 - (NSArray *)vulnerabilityOptions
 {
 NSMutableArray *options = [[IMConstants constantsForKey:CONST_VULNERABILITY] mutableCopy];
 
 if ([self.registration.bioData.gender isEqualToString:@"Male"]) {
 [options removeObject:@"Pregnant"];
 }else if ([self.registration.bioData.dateOfBirth age] < 12) {
 [options removeObject:@"Pregnant"];
 }
 
 if ([self.registration.bioData.dateOfBirth age] >= 18) {
 [options removeObject:@"Unaccompanied Minor"];
 }
 
 if ([self.registration.bioData.dateOfBirth age] <= 60) {
 [options removeObject:@"Elderly"];
 }
 
 return options;
 }
 
 - (void)updateVulnerability
 {
 NSArray *options = [self vulnerabilityOptions];
 if (self.registration.vulnerability && ![options containsObject:self.registration.vulnerability]) {
 self.registration.vulnerability = nil;
 [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:8 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
 }
 }
 
 
 #pragma mark Table View Methods
 - (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
 {
 return self.underIOMCare ? 4 : 3;
 }
 
 - (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
 {
 switch (section) {
 case 0: return 9;
 case 1: return 2;
 case 2: return 6;
 case 3: return 2;
 }
 
 return 0;
 }
 
 - (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
 {
 return 50;
 }
 
 - (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
 {
 static NSString *headerIdentifier = @"registrationHeader";
 
 IMTableHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerIdentifier];
 if (!headerView) {
 headerView = [[IMTableHeaderView alloc] initWithTitle:@"" actionTitle:nil alignCenterY:YES reuseIdentifier:headerIdentifier];
 headerView.labelTitle.font = [UIFont thinFontWithSize:28];
 headerView.labelTitle.textAlignment = NSTextAlignmentCenter;
 headerView.labelTitle.textColor = [UIColor blackColor];
 headerView.backgroundView = [[UIView alloc] init];
 headerView.backgroundView.backgroundColor = [UIColor whiteColor];
 }
 
 switch (section) {
 case 0:
 headerView.labelTitle.text = @"Personal Information";
 break;
 case 1:
 headerView.labelTitle.text = @"UNHCR Data";
 break;
 case 2:
 headerView.labelTitle.text = @"Interception Data";
 break;
 case 3:
 headerView.labelTitle.text = @"Accommodation";
 break;
 }
 
 return headerView;
 }
 
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
 {
 static NSString *cellIdentifier = @"cellIdentifier";
 
 IMFormCell *cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
 
 if (indexPath.section == 0) {
 if (indexPath.row == 0) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"First Name";
 cell.textValue.placeholder = @"e.g Jafar";
 cell.textValue.text = self.registration.bioData.firstName;
 cell.onTextValueReturn = ^(NSString *value){ self.registration.bioData.firstName = value; };
 cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet]];
 cell.maxCharCount = 40;
 }else if (indexPath.row == 1) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Family Name";
 cell.labelTitle.textColor = [UIColor grayColor];
 cell.textValue.placeholder = @"e.g Muhammad";
 cell.textValue.text = self.registration.bioData.firstName;
 cell.onTextValueReturn = ^(NSString *value){ self.registration.bioData.familyName = value; };
 cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet]];
 cell.maxCharCount = 40;
 }else if (indexPath.row == 2) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Gender";
 cell.labelValue.text = self.registration.bioData.gender;
 }else if (indexPath.row == 3) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Marital Status";
 cell.labelValue.text = self.registration.bioData.maritalStatus;
 }else if (indexPath.row == 4) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Date of Birth";
 cell.labelValue.text = [self.registration.bioData.dateOfBirth mediumFormatted];
 }else if (indexPath.row == 5) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"City of Birth";
 cell.textValue.placeholder = @"e.g Kabul";
 cell.textValue.text = self.registration.bioData.placeOfBirth;
 cell.onTextValueReturn = ^(NSString *value){ self.registration.bioData.placeOfBirth = value; };
 cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet], [NSCharacterSet characterSetWithCharactersInString:@",-"]];
 }else if (indexPath.row == 6) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Country of Birth";
 cell.labelValue.text = self.registration.bioData.countryOfBirth.name;
 }else if (indexPath.row == 7) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Nationality";
 cell.labelValue.text = self.registration.bioData.nationality.name;
 }else if (indexPath.row == 8) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Vulnerability";
 cell.labelValue.text = self.registration.vulnerability;
 }
 }else if (indexPath.section == 1) {
 if (indexPath.row == 0) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"UNHCR Document";
 cell.labelValue.text = self.registration.unhcrDocument;
 }else if (indexPath.row == 1) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"UNHCR Document Number";
 cell.textValue.placeholder = @"e.g 186-09C02429";
 cell.textValue.text = self.registration.unhcrNumber;
 cell.onTextValueReturn = ^(NSString *value){
 if (!self.registration.unhcrDocument){
 //show alert
 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Input" message:@"Please Fill UNHCR Document First" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
 alert.tag = TAG_NO_UNHCR_DOC;
 [alert show];
 value =  self.registration.unhcrNumber = Nil;
 }else self.registration.unhcrNumber = [value uppercaseString]; };
 cell.characterSets = @[[NSCharacterSet characterSetWithCharactersInString:@"0123456789cC-"]];
 }
 }else if (indexPath.section == 2) {
 if (indexPath.row == 0) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Date Of Entry";
 cell.labelValue.text = [self.registration.interceptionData.dateOfEntry mediumFormatted];
 } else if (indexPath.row == 1) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Interception Date";
 cell.labelValue.text = [self.registration.interceptionData.interceptionDate mediumFormatted];
 }else if (indexPath.row == 2) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Interception Location";
 cell.textValue.text = self.registration.interceptionData.interceptionLocation;
 cell.textValue.placeholder = @"e.g Pelabuhan Ratu, Banten, Jawa Barat";
 cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet], [NSCharacterSet characterSetWithCharactersInString:@"-,"]];
 cell.onTextValueReturn = ^(NSString *value){ self.registration.interceptionData.interceptionLocation = value; };
 cell.maxCharCount = 50;
 }
 //TODO : add IOM assosiate Office
 else if (indexPath.row == 3){
 
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Assosiate IOM Office";
 cell.labelValue.text = self.registration.associatedOffice.name;
 
 }
 else if (indexPath.row == 4){
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeSwitch reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Self Reporting";
 cell.switcher.on = self.registration.selfReporting.boolValue;
 cell.onSwitcherValueChanged = ^(BOOL value){ self.registration.selfReporting = @(value);
 self.registration.interceptionData.selfReporting = @(value);
 };
 }
 else {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeSwitch reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Under IOM Care";
 cell.switcher.on = self.registration.underIOMCare.boolValue;
 cell.onSwitcherValueChanged = ^(BOOL value){ self.underIOMCare = value; };
 }
 }else if (indexPath.section == 3) {
 if (indexPath.row == 0) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Latest Accommodation";
 cell.labelValue.text = self.registration.transferDestination.name;
 }else if (indexPath.row == 1) {
 cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
 cell.labelTitle.text = @"Transfer Date to Latest Accommodation";
 cell.labelValue.text = [self.registration.transferDate mediumFormatted];
 }
 }
 
 return cell;
 }
 
 #pragma mark UIAlertViewDelegate
 - (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
 {
 if (alertView.tag == TAG_NO_UNHCR_DOC) {
 //reset UNHCR document number
 self.registration.unhcrNumber = Nil;
 }
 
 
 }
 
 - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (indexPath.section == 0) {
 if (indexPath.row == 2) {
 IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_GENDER delegate:self];
 vc.selectedValue = self.registration.bioData.gender;
 [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
 }else if (indexPath.row == 3) {
 IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_MARITAL_STATUS delegate:self];
 vc.selectedValue = self.registration.bioData.maritalStatus;
 [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
 }else if (indexPath.row == 4) {
 IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
 self.registration.bioData.dateOfBirth = date;
 IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
 cell.labelValue.text = [self.registration.bioData.dateOfBirth mediumFormatted];
 [self updateVulnerability];
 }];
 
 datePicker.maximumDate = [NSDate date];
 datePicker.date = self.registration.bioData.dateOfBirth;
 [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
 }else if (indexPath.row == 6) {
 IMCountryListVC *vc = [[IMCountryListVC alloc] initWithBasePredicate:nil presentAsModal:NO popover:YES];
 vc.onSelected = ^(Country *country){
 Country *selectedCountry = [Country countryWithCode:country.code inManagedObjectContext:self.registration.managedObjectContext];
 self.registration.bioData.countryOfBirth = selectedCountry;
 if (!self.registration.bioData.nationality) self.registration.bioData.nationality = selectedCountry;
 
 [self.popover dismissPopoverAnimated:YES];
 self.popover = nil;
 [self.tableView reloadRowsAtIndexPaths:@[indexPath, [NSIndexPath indexPathForRow:7 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
 };
 [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
 }else if (indexPath.row == 7) {
 IMCountryListVC *vc = [[IMCountryListVC alloc] initWithBasePredicate:nil presentAsModal:NO popover:YES];
 vc.onSelected = ^(Country *country){
 self.registration.bioData.nationality = [Country countryWithCode:country.code inManagedObjectContext:self.registration.managedObjectContext];
 [self.popover dismissPopoverAnimated:YES];
 self.popover = nil;
 [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
 };
 [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
 }else if (indexPath.row == 8) {
 IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithOptions:[self vulnerabilityOptions] delegate:self];
 vc.selectedValue = self.registration.vulnerability;
 vc.firstRowIsSpecial = YES;
 [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
 }
 }else if (indexPath.section == 1){
 if (indexPath.row == 0) {
 IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_UNHCR_DOCUMENT delegate:self];
 vc.selectedValue = self.registration.unhcrDocument;
 vc.firstRowIsSpecial = YES;
 [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
 }else if (indexPath.row == 1){
 if (!self.registration.unhcrDocument) {
 //show alert
 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Input" message:@"Please Fill UNHCR Document First" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
 alert.tag = TAG_NO_UNHCR_DOC;
 [alert show];
 
 }
 }
 
 }else if (indexPath.section == 2) {
 if (indexPath.row == 0) {
 IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
 self.registration.interceptionData.dateOfEntry = date;
 IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
 cell.labelValue.text = [self.registration.interceptionData.dateOfEntry mediumFormatted];
 }];
 
 datePicker.maximumDate = [NSDate date];
 datePicker.date = self.registration.interceptionData.dateOfEntry;
 [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
 }else if (indexPath.row == 1) {
 IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
 self.registration.interceptionData.interceptionDate = date;
 IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
 cell.labelValue.text = [self.registration.interceptionData.interceptionDate mediumFormatted];
 }];
 
 datePicker.maximumDate = [NSDate date];
 datePicker.date = self.registration.interceptionData.interceptionDate;
 [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
 }else if (indexPath.row == 3){
 
 //get Assosiate IOM Office from database
 NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
 NSArray *offices = [IomOffice officesInManagedObjectContext:context];
 
 //add Assosiate IOM Office data
 IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithOptions:offices onOptionSelected:^(id selectedValue){
 IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
 cell.labelValue.text = [selectedValue description];
 self.registration.associatedOffice = [IomOffice officeWithName:[selectedValue description] inManagedObjectContext:self.registration.managedObjectContext];
 [self.popover dismissPopoverAnimated:YES];
 [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
 }];
 vc.title = @"Select IOM Office";
 
 [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:YES];
 
 }
 
 }else if (indexPath.section == 3) {
 if (indexPath.row == 0) {
 [self showAccommodation:indexPath];
 }else if (indexPath.row == 1) {
 IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
 self.registration.transferDate = date;
 IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
 cell.labelValue.text = [self.registration.transferDate mediumFormatted];
 }];
 
 datePicker.maximumDate = [NSDate date];
 datePicker.date = self.registration.transferDate;
 [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
 }
 }
 
 }
 
 - (void)showOptionChooserWithConstantsKey:(NSString *)constantsKey indexPath:(NSIndexPath *)indexPath useNavigation:(BOOL)useNavigation
 {
 IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:constantsKey delegate:self];
 vc.view.tintColor = [UIColor IMMagenta];
 [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:useNavigation];
 }
 
 - (void)optionChooser:(IMOptionChooserViewController *)optionChooser didSelectOptionAtIndex:(NSUInteger)selectedIndex withValue:(id)value
 {
 if (optionChooser.constantsKey == CONST_UNHCR_DOCUMENT) {
 if (selectedIndex == 0) {
 self.registration.unhcrDocument = nil;
 self.registration.unhcrNumber = nil;
 }else {
 self.registration.unhcrDocument = value;
 }
 
 [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
 }else if (optionChooser.constantsKey == CONST_GENDER) {
 self.registration.bioData.gender = value;
 [self updateVulnerability];
 [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
 }else if (optionChooser.constantsKey == CONST_MARITAL_STATUS) {
 self.registration.bioData.maritalStatus = value;
 [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
 }else if (!optionChooser.constantsKey) {
 self.registration.vulnerability = selectedIndex == 0 ? nil : value;
 [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:8 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
 }
 
 [self.popover dismissPopoverAnimated:YES];
 self.popover = nil;
 }
 
 - (void)showPopoverFromRect:(CGRect)rect withViewController:(UIViewController *)vc navigationController:(BOOL)useNavigation
 {
 rect = CGRectMake(rect.size.width - 150, rect.origin.y, rect.size.width, rect.size.height);
 vc.view.tintColor = [UIColor IMMagenta];
 vc.modalInPopover = NO;
 
 if (useNavigation) {
 UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
 navCon.navigationBar.tintColor = [UIColor IMMagenta];
 self.popover = [[UIPopoverController alloc] initWithContentViewController:navCon];
 }else {
 vc.view.tintColor = [UIColor IMMagenta];
 self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
 }
 
 self.popover.delegate = self;
 [self.popover presentPopoverFromRect:rect inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
 }
 
 - (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
 {
 [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
 self.popover = nil;
 }
 
 - (void)showAccommodation:(NSIndexPath *)indexPath
 {
 IMAccommodationChooserVC *vc = [[IMAccommodationChooserVC alloc] initWithBasePredicate:nil presentAsModal:NO];
 vc.onSelected = ^(Accommodation *accommodation){
 self.registration.transferDestination = [Accommodation accommodationWithId:accommodation.accommodationId inManagedObjectContext:self.registration.managedObjectContext];
 [self.popover dismissPopoverAnimated:YES];
 self.popover = nil;
 [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
 };
 vc.preferredContentSize = CGSizeMake(500, 400);
 [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:YES];
 }
 
 
 
 @end
 */