//
//  IMInterceptionListVC.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/11/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMInterceptionListVC.h"
#import "InterceptionData+Extended.h"
#import "IMConstants.h"
#import "NSDate+Relativity.h"


@interface IMInterceptionListVC ()

@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic) BOOL firstLaunch;
@property (nonatomic, strong) NSArray *interceptions;
@property (nonatomic, strong) NSArray *sectionIndexes;

@end


@implementation IMInterceptionListVC

#pragma mark Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.interceptions count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *data = [[self.interceptions objectAtIndex:section] objectForKey:kLocationGroupData];
    return [data count] * 3;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.sectionIndexes;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.sectionIndexes indexOfObject:title];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *identifier = @"headerIdentifier";
    
    IMTableHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
    if (!headerView) {
        headerView = [[IMTableHeaderView alloc] initWithTitle:@"" actionTitle:nil alignCenterY:YES reuseIdentifier:identifier];
//        UIView *backgroundView = [[UIView alloc] init];
//        backgroundView.backgroundColor = [UIColor whiteColor];
        headerView.backgroundView = [[UIToolbar alloc] init];
        headerView.labelTitle.textColor = [UIColor IMRed];
        headerView.labelTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        headerView.labelTitle.textAlignment = NSTextAlignmentCenter;
    }
    
    NSString *headerTitle = [[self.interceptions objectAtIndex:section] objectForKey:kLocationGroupTitle];
    headerView.labelTitle.text = headerTitle;
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *titleIdentifier = @"cellTitleIdentifier";
    static NSString *contentIdentifier = @"cellContentIdentifier";
    
    NSArray *interceptions = [[self.interceptions objectAtIndex:indexPath.section] objectForKey:kLocationGroupData];
    NSInteger dataIndex = indexPath.row / 3;
    NSInteger rowIndex = (indexPath.row + 1) % 3;
    InterceptionData *data = [interceptions objectAtIndex:dataIndex];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(rowIndex == 1 ? titleIdentifier : contentIdentifier)];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(rowIndex == 1 ? UITableViewCellStyleDefault : UITableViewCellStyleValue2)
                                      reuseIdentifier:(rowIndex == 1 ? titleIdentifier : contentIdentifier)];
        cell.tintColor = [UIColor IMRed];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = rowIndex == 1 ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryNone;
        
        cell.textLabel.font = rowIndex == 1 ? [UIFont boldSystemFontOfSize:14] : [UIFont systemFontOfSize:14];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
        cell.detailTextLabel.textColor = [UIColor blackColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundColor = [UIColor clearColor];
    }
    
    switch (rowIndex) {
        case 1:
            cell.textLabel.text = [data.interceptionDate mediumFormatted];
            break;
        case 2:
            cell.detailTextLabel.text = @"Remaining Children";
            cell.textLabel.text = [NSString stringWithFormat:@"%i / %i", [data currentChildren], [data totalChildren]];
            break;
        case 0:
            cell.detailTextLabel.text = @"Remaining Adult";
            cell.textLabel.text = [NSString stringWithFormat:@"%i / %i", [data currentAdult], [data totalAdult]];
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSArray *interceptions = [[self.interceptions objectAtIndex:indexPath.section] objectForKey:kLocationGroupData];
    NSInteger dataIndex = indexPath.row / 3;

    InterceptionData *data = [interceptions objectAtIndex:dataIndex];
    [self.delegate showDetailsForInterceptionData:data];
}


#pragma mark Actions
- (void)reloadData
{
    self.interceptions = [[self.dataSource interceptionDataByLocation] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:kLocationGroupTitle
                                                                                                                                   ascending:YES]]];
    NSArray *titles = [self.interceptions valueForKeyPath:@"@distinctUnionOfObjects.kLocationGroupTitle"];
    
    NSMutableArray *sectionIndexes = [NSMutableArray array];
    for (NSString *title in titles) [sectionIndexes addObject:[title substringToIndex:1]];
    [sectionIndexes sortUsingSelector:@selector(caseInsensitiveCompare:)];
    self.sectionIndexes = sectionIndexes;
    
    [self.tableView reloadData];
}


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:IMDatabaseChangedNotification object:nil];
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.view.bounds];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundView = toolbar;
    
    [self.tableView setContentInset:UIEdgeInsetsMake(64, 0, 44, 0)];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.interceptions = nil;
    self.sectionIndexes = nil;
    [self.tableView reloadData];
}

@end