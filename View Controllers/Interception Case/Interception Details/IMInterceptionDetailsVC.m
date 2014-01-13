//
//  IMInterceptionDetailsVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/27/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMInterceptionDetailsVC.h"
#import "IMTableHeaderView.h"
#import "IMFormCell.h"
#import "NSDate+Relativity.h"
#import "IMInterceptionMovementHistoryVC.h"
#import "IMInterceptionDataUpdater.h"
#import "IMDBManager.h"
#import "IMAuthManager.h"


@interface IMInterceptionDetailsVC ()<UIPopoverControllerDelegate>

@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic) BOOL hasIssues;

@end


@implementation IMInterceptionDetailsVC

- (void)edit
{
    [self.delegate showEditForInterceptionData:self.interceptionData];
}

- (void)showMovementHistory:(UIButton *)sender
{
    IMInterceptionMovementHistoryVC *vc = [[IMInterceptionMovementHistoryVC alloc] initWithInterceptionGroup:self.groups[sender.tag]
                                                                                                     onClose:^{ [self.popover dismissPopoverAnimated:YES]; }];
    [self showPopoverFromRect:[self.tableView rectForHeaderInSection:sender.tag + 3] withViewController:vc navigationController:YES];
}

- (void)toggleActive
{
    NSDictionary *params = @{@"id":self.interceptionData.interceptionDataId, @"active":@(!self.interceptionData.active.boolValue)};
    IMInterceptionDataUpdater *updater = [[IMInterceptionDataUpdater alloc] init];
    updater.successHandler = ^{
        [[IMDBManager sharedManager] saveDatabase:nil];
        NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        InterceptionData *updatedData = [InterceptionData dataWithId:self.interceptionData.interceptionDataId inManagedObjectContext:context];
        if (updatedData) {
            self.interceptionData = updatedData;
            [self.tableView reloadData];
            [self setupNavigationItem];
        }
        [self hideLoadingView];
    };
    
    updater.failureHandler = ^(NSError *error){
        [self hideLoadingView];
        [self showAlertWithTitle:@"Update Failed"
                         message:@"Failed updating interception data. Please check your network connection and try again."];
    };
    
    [self showLoadingView];
    [updater toggleActive:params];
}

#pragma mark View Lifecycle
- (void)showPopoverFromRect:(CGRect)rect withViewController:(UIViewController *)vc navigationController:(BOOL)useNavigation
{
    rect = CGRectMake(rect.size.width - 150, rect.origin.y, rect.size.width, rect.size.height);
    
    if (useNavigation) {
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
        navCon.navigationBar.tintColor = [UIColor IMRed];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:navCon];
    }else {
        vc.view.tintColor = [UIColor IMRed];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    }
    
    self.popover.delegate = self;
    [self.popover presentPopoverFromRect:rect inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}

- (id)initWithInterceptionData:(InterceptionData *)data delegate:(id<IMInterceptionDelegate>)delegate
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.interceptionData = data;
    self.delegate = delegate;
    self.groups = [self.interceptionData.interceptionGroups allObjects];
    self.hasIssues = self.interceptionData.issues && [self.interceptionData.issues length];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Interception Details";
    self.allowsEditing = [IMAuthManager sharedManager].activeUser.roleInterception;
    [self setupNavigationItem];
    self.tableView.allowsSelection = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadData)
                                                 name:IMDatabaseChangedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.tableView];
    [super viewWillDisappear:animated];
}

- (void)reloadData
{
    [self.tableView reloadData];
    [self setupNavigationItem];
}

- (void)setupNavigationItem
{
    if (self.interceptionData.active.boolValue && self.allowsEditing) {
        UIBarButtonItem *itemEdit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                  target:self
                                                                                  action:@selector(edit)];
        UIBarButtonItem *itemDeactivate = [[UIBarButtonItem alloc] initWithTitle:@"Close Case" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleActive)];
        self.navigationItem.rightBarButtonItems = @[itemEdit, itemDeactivate];
    }else if (!self.interceptionData.active.boolValue && self.allowsEditing) {
        UIBarButtonItem *itemActivate = [[UIBarButtonItem alloc] initWithTitle:@"Reopen Case" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleActive)];
        self.navigationItem.rightBarButtonItems = @[itemActivate];
    }
}

- (void) close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark Table View Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.hasIssues ? 4 + [self.groups count] : 3 + [self.groups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.hasIssues && section == [tableView numberOfSections] - 1) return 1;
    
    switch (section) {
        case 0: return self.interceptionData.expectedMovementDate ? 4 : 3;
        case 1:
            if (self.interceptionData.immigrationOfficer && self.interceptionData.policeOfficer) {
                return 3;
            }else if (!self.interceptionData.immigrationOfficer && !self.interceptionData.policeOfficer) {
                return 1;
            }else {
                return 2;
            }
        case 2: return 0;
        default: return (self.interceptionData.totalUAM || self.interceptionData.totalMedicalAttention) ? 6 : 4;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *titleOnlyIdentifier = @"TitleOnlyIdentifier";
    static NSString *withActionIdentifier = @"WithActionIdentifier";
    
    if (self.hasIssues && section == [tableView numberOfSections] - 1) {
        IMTableHeaderView *header = [[IMTableHeaderView alloc] initWithTitle:@"Issues" reuseIdentifier:titleOnlyIdentifier];
        header.labelTitle.font = [UIFont systemFontOfSize:22];
        header.labelTitle.textColor = [UIColor IMRed];
        return header;
    }
    
    if (section == 0) {
        return [[UIView alloc] init];
    }else if (section == 1) {
        IMTableHeaderView *header = [[IMTableHeaderView alloc] initWithTitle:@"Contact Person" reuseIdentifier:titleOnlyIdentifier];
        header.labelTitle.textAlignment = NSTextAlignmentCenter;
        header.backgroundView = [[UIView alloc] init];
        header.labelTitle.font = [UIFont systemFontOfSize:22];
        header.labelTitle.textColor = [UIColor IMRed];
        return header;
    }else if (section == 2) {
        IMTableHeaderView *header = [[IMTableHeaderView alloc] initWithTitle:@"Intercepted Migrants by Group" reuseIdentifier:titleOnlyIdentifier];
        header.labelTitle.textAlignment = NSTextAlignmentCenter;
        header.backgroundView = [[UIView alloc] init];
        header.labelTitle.font = [UIFont systemFontOfSize:22];
        header.labelTitle.textColor = [UIColor IMRed];
        return header;
    }
    
    InterceptionGroup *group = self.groups[section - 3];
    IMTableHeaderView *header = [[IMTableHeaderView alloc] initWithTitle:[group description]
                                                             actionTitle:@"Movements"
                                                            alignCenterY:YES
                                                         reuseIdentifier:withActionIdentifier];
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.backgroundColor = [UIColor IMTableHeaderColor];
    header.backgroundView = backgroundView;
    header.buttonAction.tintColor = [UIColor IMRed];
    header.labelTitle.font = [UIFont systemFontOfSize:18];
    header.buttonAction.tag = section - 3;
    [header.buttonAction setImage:[UIImage imageNamed:@"icon-next"] forState:UIControlStateNormal];
    [header.buttonAction setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -90)];
    [header.buttonAction setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 15)];
    [header.buttonAction.titleLabel setFont:[UIFont systemFontOfSize:17]];
    [header.buttonAction addTarget:self action:@selector(showMovementHistory:) forControlEvents:UIControlEventTouchUpInside];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return !section ? 10 : 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section && indexPath.section < (self.hasIssues ? [tableView numberOfSections] - 1 : [tableView numberOfSections])) {
        return 30;
    }
    
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellIdentifier";
    
    IMFormCell *cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetailCenter reuseIdentifier:cellIdentifier];
    cell.labelTitle.font = [UIFont boldSystemFontOfSize:14];
    cell.labelTitle.textColor = [UIColor blackColor];
    cell.labelValue.font = [UIFont systemFontOfSize:14];
    cell.labelValue.textColor = [UIColor blackColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                cell.labelTitle.text = @"Interception Location";
                cell.labelValue.text = [NSString stringWithFormat:@"%@, %@", self.interceptionData.interceptionLocation.name, self.interceptionData.interceptionLocation.administrativeArea];
                break;
            case 1:
                cell.labelTitle.text = @"Date / IOM Office";
                cell.labelValue.text = [NSString stringWithFormat:@"%@ / IOM %@", [self.interceptionData.interceptionDate longFormatted], self.interceptionData.iomOffice.name];
                break;
            case 2:
                cell.labelTitle.text = @"Current Population";
                cell.labelValue.text = [NSString stringWithFormat:@"%li", (long)self.interceptionData.currentPopulation];
                break;
            case 3:
                cell.labelTitle.text = @"Expected Movement";
                cell.labelValue.text = [self.interceptionData.expectedMovementDate longFormatted];
                break;
        }
    }else if (indexPath.section == 1) {        
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
    }else if (self.hasIssues && indexPath.section == [tableView numberOfSections] - 1) {
        IMFormCell *cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTitle reuseIdentifier:cellIdentifier];
        cell.labelTitle.text = self.interceptionData.issues;
        return cell;
    }else {
        InterceptionGroup *group = self.groups[indexPath.section - 3];
        
        switch (indexPath.row) {
            case 0:
                cell.labelTitle.text = @"Adult";
                cell.labelValue.text = [NSString stringWithFormat:@"Initial: %i, Current: %i", group.adult.intValue, group.currentAdult];
                break;
            case 1:
                cell.labelTitle.text = @"Children";
                cell.labelValue.text = [NSString stringWithFormat:@"Initial: %i, Current: %i", group.child.intValue, group.currentChildren];
                break;
            case 2:
                cell.labelTitle.text = @"Male";
                cell.labelValue.text = [NSString stringWithFormat:@"Initial: %i, Current: %i", group.male.intValue, group.currentMale];
                break;
            case 3:
                cell.labelTitle.text = @"Female";
                cell.labelValue.text = [NSString stringWithFormat:@"Initial: %i, Current: %i", group.female.intValue, group.currentFemale];
                break;
            case 4:
                cell.labelTitle.text = @"Unaccompanied Minor";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", group.currentUAM];
                break;
            case 5:
                cell.labelTitle.text = @"Requires Medical Attention";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", group.currentMedicalAttention];
                break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{}

@end