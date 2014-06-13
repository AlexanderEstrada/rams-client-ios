//
//  IMInterceptionMapDetailVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/1/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMinterceptionInfoVC.h"
#import "InterceptionData+Extended.h"
#import "NSDate+Relativity.h"


@interface IMinterceptionInfoVC ()

@property (nonatomic, strong) NSArray *data;

@end


@implementation IMinterceptionInfoVC

#pragma mark Logic
- (void)setData:(NSArray *)data forTitle:(NSString *)title
{
    self.data = data;
    self.title = title;
    
    if ([data count] == 1) {
        self.preferredContentSize = CGSizeMake(320, 210);
        [self.tableView setScrollEnabled:NO];
    }else {
        self.preferredContentSize = CGSizeMake(320, 350);
        [self.tableView setScrollEnabled:YES];
    }
    
    [self.tableView reloadData];
}

- (void)showDetails:(UIButton *)sender
{
    [self.delegate showDetailsForInterceptionData:self.data[sender.tag]];
}


#pragma mark View Lifecycle
- (id)initWithData:(NSArray *)data title:(NSString *)title delegate:(id<IMInterceptionDelegate>)delegate
{
    self = [super initWithStyle:UITableViewStylePlain];
    
    self.delegate = delegate;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self setData:data forTitle:title];
    
    return self;
}


#pragma mark Table View Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.data count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    InterceptionData *data = self.data[section];
    if (data.active) return (data.totalUAM || data.totalMedicalAttention) ? 4 : 2;
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
        cell.detailTextLabel.textColor = [UIColor blackColor];
    }
    
    InterceptionData *data = self.data[indexPath.section];
    if (data.active) {
        switch (indexPath.row) {
            case 0:
                cell.detailTextLabel.text = @"Remaining Adult";
                cell.textLabel.text = [NSString stringWithFormat:@"%i / %i", [data currentAdult], [data totalAdult]];
                break;
            case 1:
                cell.detailTextLabel.text = @"Remaining Children";
                cell.textLabel.text = [NSString stringWithFormat:@"%i / %i", [data currentChildren], [data totalChildren]];
                break;
            case 2:
                cell.detailTextLabel.text = @"Unaccompanied Minor";
                cell.textLabel.text = [NSString stringWithFormat:@"%i / %i", [data currentUAM], [data totalUAM]];
                break;
            case 3:
                cell.detailTextLabel.text = @"Requires Medical Attention";
                cell.textLabel.text = [NSString stringWithFormat:@"%i / %i", [data currentMedicalAttention], [data totalMedicalAttention]];
                break;
        }
    }else {
        switch (indexPath.row) {
            case 0:
                cell.detailTextLabel.text = @"Deported";
                cell.textLabel.text = [NSString stringWithFormat:@"%i", [data totalDeported]];
                break;
            case 1:
                cell.detailTextLabel.text = @"Escaped";
                cell.textLabel.text = [NSString stringWithFormat:@"%i", [data totalEscaped]];
                break;
            case 2:
                cell.detailTextLabel.text = @"Transferred";
                cell.textLabel.text = [NSString stringWithFormat:@"%i", [data totalTransferred]];
                break;
        }
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    InterceptionData *data = self.data[section];
    BOOL active = data.active.boolValue;
    
    NSString *headerTitle = active ? [data.interceptionDate mediumFormatted] : [NSString stringWithFormat:@"[CLOSED] %@", [data.interceptionDate mediumFormatted]];
    
    static NSString *identifier = @"InterceptionMapDetailHeader";
    IMTableHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
    if (!headerView) {
        headerView = [[IMTableHeaderView alloc] initWithInfoButtonAndTitle:headerTitle reuseIdentifier:identifier];
        headerView.buttonAction.tintColor = [UIColor IMRed];
        [headerView.buttonAction addTarget:self action:@selector(showDetails:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    headerView.buttonAction.tag = section;
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

@end