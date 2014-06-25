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



@interface IMEditRegistrationDataVC ()<UIPopoverControllerDelegate, IMOptionChooserDelegate>

@property (nonatomic) BOOL underIOMCare;
@property (nonatomic, strong) UIPopoverController *popover;

@end


@implementation IMEditRegistrationDataVC


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
        case 2: return 5;
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
//            headerView.labelTitle.text = @"Accommodation";
            headerView.labelTitle.text = @"Location";
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
            cell.textValue.text = self.registration.bioData.familyName;
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
                    alert.tag = IMAlertNOUNHCR_Tag;
                        [alert show];
                    self.registration.unhcrNumber = value = Nil;
                }else self.registration.unhcrNumber = [value uppercaseString]; };
            cell.characterSets = @[[NSCharacterSet characterSetWithCharactersInString:@"0123456789cC-"]];
        }
    }else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Interception Date";
            cell.labelValue.text = [self.registration.interceptionData.interceptionDate mediumFormatted];
        }else if (indexPath.row == 1) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Interception Location";
            cell.textValue.text = self.registration.interceptionData.interceptionLocation;
            cell.textValue.placeholder = @"e.g Pelabuhan Ratu, Banten, Jawa Barat";
            cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet], [NSCharacterSet characterSetWithCharactersInString:@"-,"]];
            cell.onTextValueReturn = ^(NSString *value){ self.registration.interceptionData.interceptionLocation = value; };
            cell.maxCharCount = 50;
        }
        //TODO : add IOM assosiate Office
        else if (indexPath.row == 2){
            
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Assosiate IOM Office";
            cell.labelValue.text = self.registration.associatedOffice.name;

        }
        else if (indexPath.row == 3){
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
//            cell.labelTitle.text = @"Latest Accommodation";
            cell.labelTitle.text = @"Latest Location";
            cell.labelValue.text = self.registration.transferDestination.name;
        }else if (indexPath.row == 1) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
//            cell.labelTitle.text = @"Transfer Date to Latest Accommodation";
            cell.labelTitle.text = @"Transfer Date";
            cell.labelValue.text = [self.registration.transferDate mediumFormatted];
        }
    }
    
    return cell;
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == IMAlertNOUNHCR_Tag) {
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
                alert.tag = IMAlertNOUNHCR_Tag;
                [alert show];
                
            }
        }
        
    }else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
                self.registration.interceptionData.interceptionDate = date;
                IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.labelValue.text = [self.registration.interceptionData.interceptionDate mediumFormatted];
            }];
            
            datePicker.maximumDate = [NSDate date];
            datePicker.date = self.registration.interceptionData.interceptionDate;
            [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
        }else if (indexPath.row == 2){
            
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