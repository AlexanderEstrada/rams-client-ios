//
//  IMInterceptionMovementVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/28/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMInterceptionMovementHistoryVC.h"
#import "InterceptionMovement+Extended.h"
#import "InterceptionData+Extended.h"
#import "IMFormCell.h"
#import "IMTableHeaderView.h"
#import "Accommodation+Extended.h"
#import "NSDate+Relativity.h"
#import "IMEditInterceptionMovementVC.h"
#import "IMAuthManager.h"


@interface IMInterceptionMovementHistoryVC ()

@property (nonatomic, strong) NSArray *movements;

@end


@implementation IMInterceptionMovementHistoryVC

- (void)editMovementData:(UIButton *)sender
{
    IMEditInterceptionMovementVC *vc = [[IMEditInterceptionMovementVC alloc] initWithMovement:self.movements[sender.tag] forGroup:self.group];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openNewMovement
{
    IMEditInterceptionMovementVC *vc = [[IMEditInterceptionMovementVC alloc] initWithMovement:nil forGroup:self.group];
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark Table View Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.movements count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    InterceptionMovement *movement = self.movements[section];
    return movement.transferLocation ? 7 : 6;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    InterceptionMovement *movement = self.movements[section];
    NSString *sectionTitle = [NSString stringWithFormat:@"%@, %@", movement.type, [movement.date longFormatted]];
    
    IMTableHeaderView *header = [[IMTableHeaderView alloc] initWithTitle:sectionTitle
                                                             actionTitle:@"Edit"
                                                            alignCenterY:YES reuseIdentifier:@"TableViewHeader"];
    header.labelTitle.font = [UIFont systemFontOfSize:18];
    header.backgroundColor = [UIColor IMBorderColor];
    header.buttonAction.tag = section;
    header.buttonAction.titleLabel.font = [UIFont systemFontOfSize:17];
    [header.buttonAction addTarget:self action:@selector(editMovementData:) forControlEvents:UIControlEventTouchUpInside];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellIdentifier";
    
    IMFormCell *cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetailCenter reuseIdentifier:cellIdentifier];
    cell.labelTitle.font = [UIFont boldSystemFontOfSize:14];
    cell.labelTitle.textColor = [UIColor blackColor];
    cell.labelValue.font = [UIFont boldSystemFontOfSize:14];
    cell.labelValue.textColor = [UIColor blackColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    InterceptionMovement *movement = self.movements[indexPath.section];
    
    if (movement.transferLocation) {
        switch (indexPath.row) {
            case 0:
                cell.labelTitle.text = @"Destination";
                cell.labelValue.text = [movement.transferLocation description];
                break;
            case 1:
                cell.labelTitle.text = @"Adult";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", movement.adult.intValue];
                break;
            case 2:
                cell.labelTitle.text = @"Children";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", movement.child.intValue];
                break;
            case 3:
                cell.labelTitle.text = @"Male";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", movement.male.intValue];
                break;
            case 4:
                cell.labelTitle.text = @"Female";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", movement.female.intValue];
                break;
            case 5:
                cell.labelTitle.text = @"Unaccompanied Minor";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", movement.unaccompaniedMinor.intValue];
                break;
            case 6:
                cell.labelTitle.text = @"Requires Medical Attention";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", movement.medicalAttention.intValue];
                break;
        }
    }else {
        switch (indexPath.row) {
            case 0:
                cell.labelTitle.text = @"Adult";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", movement.adult.intValue];
                break;
            case 1:
                cell.labelTitle.text = @"Children";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", movement.child.intValue];
                break;
            case 2:
                cell.labelTitle.text = @"Male";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", movement.male.intValue];
                break;
            case 3:
                cell.labelTitle.text = @"Female";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", movement.female.intValue];
                break;
            case 4:
                cell.labelTitle.text = @"Unaccompanied Minor";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", movement.unaccompaniedMinor.intValue];
                break;
            case 5:
                cell.labelTitle.text = @"Requires Medical Attention";
                cell.labelValue.text = [NSString stringWithFormat:@"%i", movement.medicalAttention.intValue];
                break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{}


#pragma mark View Lifecycle
- (id)initWithInterceptionGroup:(InterceptionGroup *)group onClose:(void (^)(void))onClose
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    self.group = group;
    self.onClose = onClose;
    self.title = @"Movements History";
    [self setupNavigationItem];
    self.modalInPopover = YES;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)];
    self.preferredContentSize = CGSizeMake(500, 420);
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 20, 0, 0);
    
    return self;
}

- (void)setGroup:(InterceptionGroup *)group
{
    _group = group;
    self.movements = [[self.group.interceptionMovements allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
}

- (void)setupNavigationItem
{
    if (self.group.currentPopulationByAgeGroup > 0 && [self.group.interceptionData.active boolValue] && [IMAuthManager sharedManager].activeUser.roleInterception) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(openNewMovement)];
    }else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)close
{
    if (self.onClose) self.onClose();
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.group = self.group;
    [self.tableView reloadData];
}

@end