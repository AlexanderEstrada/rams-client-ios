//
//  IMNewInterceptionVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 7/19/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMEditInterceptionVC.h"
#import "IMAddPhotoTableViewCell.h"
#import "IMFormCell.h"
#import "NSDate+Relativity.h"
#import "IMTableHeaderView.h"
#import "IMDatePickerVC.h"
#import "IMOptionChooserViewController.h"
#import "IMDBManager.h"
#import "IMInterceptionLocationVC.h"
#import "IMImmigrationOfficerVC.h"
#import "IMIOMOfficerVC.h"
#import "IMInterceptionGroupVC.h"
#import "IMPoliceOfficerVC.h"
#import "IMInterceptionDataUpdater.h"


@interface IMEditInterceptionVC ()<UIPopoverControllerDelegate>

@property (nonatomic, strong) NSMutableArray *photoDictionaries;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) IMOptionChooserViewController *iomOfficeChooser;
@property (nonatomic) BOOL creationMode;

@end


@implementation IMEditInterceptionVC


#pragma mark Logic
- (void)save
{
    if (![self.interceptionData validateForSubmission]) {
        [self showAlertWithTitle:@"Incomplete Data"
                         message:@"Please evaluate your inputs and make sure all mandatory fields are filled correctly."];
        return;
    }
    
    NSDictionary *params = [self.interceptionData prepareForSubmissionWithPhotos:self.photoDictionaries];
    IMInterceptionDataUpdater *updater = [[IMInterceptionDataUpdater alloc] init];
    updater.successHandler = ^{
        [self hideLoadingView];
        [self showAlertWithTitle:@"Upload Success" message:nil];
        if (self.creationMode) {
            NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
            [context deleteObject:self.interceptionData];
        }
        
        [[IMDBManager sharedManager] saveDatabase:^(BOOL success){
            if (!success) NSLog(@"Failed saving database after deleting temporary interception data.");
            else [self dismissViewControllerAnimated:YES completion:nil];
        }];
    };
    
    updater.failureHandler = ^(NSError *error){
        [self hideLoadingView];
        [self showAlertWithTitle:@"Failed Submitting Data" message:@"Error occurred while saving interception data. Please check your network connection. If problem persist, contact administrator."];
    };
    
    [self showLoadingView];
    [updater submitInterceptionData:params];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self hideLoadingView];
   [self.tableView reloadData];
    
}

- (void)cancel
{
    NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    
    if (self.creationMode) {
        [context deleteObject:self.interceptionData];
        [[IMDBManager sharedManager] saveDatabase:^(BOOL success){
            if (!success) {
                NSLog(@"Failed saving database after deleting temporary interception data.");
            }
        }];
    }else {
        [context rollback];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark UI Interactions
- (void)showPopoverFromRect:(CGRect)rect withViewController:(UIViewController *)vc navigationController:(BOOL)useNavigation
{
    rect = CGRectMake(rect.size.width - 150, rect.origin.y, rect.size.width, rect.size.height);
    vc.view.tintColor = [UIColor IMRed];
    
    if (useNavigation) {
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
        navCon.navigationBar.tintColor = [UIColor IMRed];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:navCon];
    }else {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    }
    
    self.popover.delegate = self;
    [self.popover presentPopoverFromRect:rect inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)addInterceptedGroup:(UIButton *)sender
{
    IMInterceptionGroupVC *vc = [[IMInterceptionGroupVC alloc] initWithInterceptionGroup:nil
                                                                                  action:^(InterceptionGroup *group, BOOL editing){
                                                                                      [self.popover dismissPopoverAnimated:YES];
                                                                                      self.popover = nil;
                                                                                      
                                                                                      if (group && !editing) {
                                                                                          [self.interceptionData addInterceptionGroupsObject:group];
                                                                                      }
                                                                                      
                                                                                      [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                                  }];
    [self showPopoverFromRect:[self.tableView rectForHeaderInSection:2] withViewController:vc navigationController:YES];
}

- (void)editInterceptionDate:(NSIndexPath *)indexPath
{
    IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *selectedDate){
        IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.labelValue.text = [selectedDate mediumFormatted];
        self.interceptionData.interceptionDate = selectedDate;
    }];
    
    datePicker.maximumDate = [NSDate date];
    datePicker.minimumDate = [[NSDate date] dateBySubstractingDayElement:365];
    datePicker.date = self.interceptionData.interceptionDate ? self.interceptionData.interceptionDate : [NSDate date];
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
}

- (void)editExpectedMovementDate:(NSIndexPath *)indexPath
{
    IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *selectedDate){
        IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.labelValue.text = [selectedDate mediumFormatted];
        self.interceptionData.expectedMovementDate = selectedDate;
    }];
    
    datePicker.maximumDate = [[NSDate date] dateByAddingDayElement:365];
    datePicker.minimumDate = [[NSDate date] dateBySubstractingDayElement:100];
    datePicker.date = self.interceptionData.expectedMovementDate ? self.interceptionData.expectedMovementDate : [NSDate date];
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
}

- (void)editInterceptionLocation:(NSIndexPath *)indexPath
{
    IMInterceptionLocationVC *locationVC = [[IMInterceptionLocationVC alloc] initWithAction:^(InterceptionLocation *location){
        if (location) {
            IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.labelValue.text = [location description];
            self.interceptionData.interceptionLocation = location;
        }
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }];

    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:locationVC navigationController:YES];
}

- (void)editIomOffice:(NSIndexPath *)indexPath
{
    if (!self.iomOfficeChooser) {
        NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        NSArray *offices = [IomOffice officesInManagedObjectContext:context];
        self.iomOfficeChooser = [[IMOptionChooserViewController alloc] initWithOptions:offices onOptionSelected:^(id selectedValue){
            IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            cell.labelValue.text = [selectedValue description];
            self.interceptionData.iomOffice = selectedValue;
            [self.popover dismissPopoverAnimated:YES];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }];
        self.iomOfficeChooser.title = @"Select IOM Office";
    }
    
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:self.iomOfficeChooser navigationController:YES];
}

- (void)editIomOfficer:(NSIndexPath *)indexPath
{
    IMIOMOfficerVC *vc = [[IMIOMOfficerVC alloc] initWithAction:^(IomOfficer *iomOfficer){
        self.interceptionData.iomOfficer = iomOfficer;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }];
    
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:YES];
}

- (void)editImmigrationOfficer:(NSIndexPath *)indexPath
{
    IMImmigrationOfficerVC *vc = [[IMImmigrationOfficerVC alloc] initWithStyle:UITableViewStyleGrouped];
    vc.immigrationOfficer = self.interceptionData.immigrationOfficer;
    vc.onCancel = ^{
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    };
    
    vc.onSave = ^(ImmigrationOfficer *immigrationOfficer){
        self.interceptionData.immigrationOfficer = immigrationOfficer;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    };

    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:YES];
}

- (void)editPoliceOfficer:(NSIndexPath *)indexPath
{
    IMPoliceOfficerVC *vc = [[IMPoliceOfficerVC alloc] initWithStyle:UITableViewStyleGrouped];
    vc.policeOfficer = self.interceptionData.policeOfficer;
    vc.onCancel = ^{
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    };
    
    vc.onSave = ^(PoliceOfficer *policeOfficer){
        self.interceptionData.policeOfficer = policeOfficer;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    };
    
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:YES];
}

- (void)editInterceptedGroup:(NSInteger)index indexPath:(NSIndexPath *)indexPath
{
    IMInterceptionGroupVC *vc = [[IMInterceptionGroupVC alloc] initWithInterceptionGroup:nil
                                                                                  action:^(InterceptionGroup *group, BOOL editing){
                                                                                      [self.popover dismissPopoverAnimated:YES];
                                                                                      self.popover = nil;
                                                                                      [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
                                                                                  }];
    vc.group = [self.interceptionData.interceptionGroups allObjects][index];
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:YES];
}


#pragma mark View Lifecycle
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
    NSIndexPath *indexPath = [[self.tableView indexPathsForSelectedRows] lastObject];
    if (indexPath) [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSArray *)photoDictionaries
{
    if (!_photoDictionaries) {
        _photoDictionaries = [NSMutableArray array];
        for (Photo *photo in self.interceptionData.photos) {
            [_photoDictionaries addObject:@{kPhotoImage: photo.photoImage, kPhotoId: photo.photoId}];
        }
    }
    
    return _photoDictionaries;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"New Interception Case";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    
    if (!self.interceptionData) {
        NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        self.interceptionData = [NSEntityDescription insertNewObjectForEntityForName:@"InterceptionData" inManagedObjectContext:context];
        self.creationMode = YES;
    }
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 20, 0, 0);
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorColor = [UIColor IMBorderColor];
    self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
}


#pragma mark Table View Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: return 5;
        case 1: return 3;
        default: return [self.interceptionData.interceptionGroups count];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *titleOnlyIdentifier = @"titleOnlyIdentifier";
    static NSString *withActionIdentifier = @"withActionIdentifier";
    
    IMTableHeaderView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:(section == 2 ? withActionIdentifier : titleOnlyIdentifier)];
    if (!header) {
        if (section == 2) {
            header = [[IMTableHeaderView alloc] initWithTitle:@"Intercepted Groups" actionTitle:@"Add Intercepted Group" reuseIdentifier:withActionIdentifier];
            [header.buttonAction setTitle:@"Add Intercepted Group" forState:UIControlStateNormal];
            [header.buttonAction addTarget:self action:@selector(addInterceptedGroup:) forControlEvents:UIControlEventTouchUpInside];
            header.buttonAction.tintColor = [UIColor IMRed];
        }else {
            header = [[IMTableHeaderView alloc] initWithTitle:@"" reuseIdentifier:titleOnlyIdentifier];
        }
        
        header.labelTitle.textColor = [UIColor IMRed];
    }

    switch (section) {
        case 0:
            header.labelTitle.text = @"Interception Details";
            break;
        case 1:
            header.labelTitle.text = @"Officer In Charge";
            break;
    }

    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IMFormCell *cell = nil;
    static NSString *cellIdentifier = @"CellIdentifier";
    
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
                    cell.labelTitle.text = @"Interception Date";
                    cell.labelValue.text = [self.interceptionData.interceptionDate mediumFormatted];
                    break;
                case 1:
                    cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
                    cell.labelTitle.text = @"Interception Location";
                    cell.labelValue.text = [self.interceptionData.interceptionLocation description];
                    break;
                case 2:
                    cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
                    cell.labelTitle.text = @"Responsible IOM Office";
                    cell.labelValue.text = self.interceptionData.iomOffice.name;
                    break;
                case 3:
                    cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
                    cell.labelTitle.text = @"Expected Movement Date";
                    cell.labelValue.text = [self.interceptionData.expectedMovementDate mediumFormatted];
                    break;
                case 4:
                    cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
                    cell.labelTitle.text = @"Issues";
                    cell.labelValue.text = self.interceptionData.issues;
                    cell.textValue.placeholder = @"Type any issue about the interception";
                    cell.onTextValueReturn = ^(NSString *text){ self.interceptionData.issues = text; };
                    break;
            }
            break;
        case 1:
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            
            switch (indexPath.row) {
                case 0:
                    cell.labelTitle.text = @"IOM";
                    cell.labelValue.text = [self.interceptionData.iomOfficer description];
                    break;
                case 1:
                    cell.labelTitle.text = @"Immigration Office";
                    cell.labelValue.text = [self.interceptionData.immigrationOfficer description];
                    break;
                default:
                    cell.labelTitle.text = @"Local Police Enforcement";
                    cell.labelValue.text = [self.interceptionData.policeOfficer description];
                    break;
            }
            
            break;
        case 2:
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            
            InterceptionGroup *group = [[self.interceptionData.interceptionGroups allObjects] objectAtIndex:indexPath.row];
            cell.labelTitle.text = [NSString stringWithFormat:@"%@ (%@)", [group description], [group stringGroupPopulation]];
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: [self editInterceptionDate:indexPath]; break;
                case 1: [self editInterceptionLocation:indexPath]; break;
                case 2: [self editIomOffice:indexPath]; break;
                case 3: [self editExpectedMovementDate:indexPath]; break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0: [self editIomOfficer:indexPath]; break;
                case 1: [self editImmigrationOfficer:indexPath]; break;
                case 2: [self editPoliceOfficer:indexPath]; break;
            }
            break;
        case 2:
            [self editInterceptedGroup:indexPath.row indexPath:indexPath];
            break;
    }
}

@end