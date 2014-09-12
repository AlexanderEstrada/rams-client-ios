//
//  IMInterceptionGroupVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/20/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMInterceptionGroupVC.h"
#import "IMFormCell.h"
#import "Country+Extended.h"
#import "IMTableHeaderView.h"
#import "IMCountryListVC.h"
#import "IMDBManager.h"


@interface IMInterceptionGroupVC ()

@property (nonatomic) BOOL creating;

@end


@implementation IMInterceptionGroupVC

- (void)save
{
    if (![self validateInput]) {
        [self showAlertWithTitle:@"Invalid Input" message:@"Please evaluate your inputs before saving."];
        return;
    }
    
    if (self.onSave) self.onSave(self.group, !self.creating);
}

- (void)cancel
{
    if (self.creating) {
        NSManagedObjectContext *context = [self.group managedObjectContext];
        [context deleteObject:self.group];
    }
    
    if (self.onSave) self.onSave(nil, !self.creating);
}

- (BOOL)validateInput
{
    int gender = self.group.male.intValue + self.group.female.intValue;
    int age = self.group.adult.intValue + self.group.child.intValue;
    BOOL stat = gender == age;
    stat &= self.group.ethnicName && self.group.originCountry;
    return stat;
}


#pragma mark Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IMFormCell *cell;
    
    if (indexPath.section == 0) {
        cell = [[IMFormCell alloc] initWithFormType:(indexPath.row ? IMFormCellTypeDetail : IMFormCellTypeTextInput) reuseIdentifier:@"FormText"];
        cell.labelTitle.text = indexPath.row ? @"Origin Country" : @"Ethnic Name";
        cell.textValue.placeholder = @"e.g Rohinga";
        cell.textValue.text = self.group.ethnicName;
        cell.labelValue.text = [self.group.originCountry description];
        cell.onTextValueReturn = ^(NSString *value){ self.group.ethnicName = value; };
    }else if (indexPath.section == 1) {
        cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeStepper reuseIdentifier:@"FormStepper"];
        cell.labelTitle.text = indexPath.row ? @"Children (<18)" : @"Adult (18+)";
        cell.labelValue.text = [NSString stringWithFormat:@"%i", indexPath.row ? self.group.child.intValue : self.group.adult.intValue];
        cell.stepper.value = indexPath.row ? self.group.child.intValue : self.group.adult.intValue;
        
        if (indexPath.row) {
            cell.onStepperValueChanged = ^(int newValue){ self.group.child = @(newValue); };
        }else {
            cell.onStepperValueChanged = ^(int newValue){ self.group.adult = @(newValue); };
        }
    }else if (indexPath.section == 2) {
        cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeStepper reuseIdentifier:@"FormStepper"];
        cell.labelTitle.text = indexPath.row ? @"Female (<18)" : @"Male (18+)";
        cell.labelValue.text = [NSString stringWithFormat:@"%i", indexPath.row ? self.group.female.intValue : self.group.male.intValue];
        cell.stepper.value = indexPath.row ? self.group.child.intValue : self.group.adult.intValue;
        
        if (indexPath.row) {
            cell.onStepperValueChanged = ^(int newValue){ self.group.female = @(newValue); };
        }else {
            cell.onStepperValueChanged = ^(int newValue){ self.group.male = @(newValue); };
        }
    }else {
        cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeStepper reuseIdentifier:@"FormStepper"];
        cell.labelTitle.text = indexPath.row ? @"Requires Medical Attention" : @"Unaccompanied Minor (UAM)";
        cell.labelValue.text = [NSString stringWithFormat:@"%i", indexPath.row ? self.group.medicalAttention.intValue : self.group.unaccompaniedMinor.intValue];
        cell.stepper.value =  indexPath.row ? self.group.medicalAttention.intValue : self.group.unaccompaniedMinor.intValue;
        
        if (indexPath.row) {
            cell.onStepperValueChanged = ^(int newValue){ self.group.medicalAttention = @(newValue); };
        }else {
            cell.onStepperValueChanged = ^(int newValue){ self.group.unaccompaniedMinor = @(newValue); };
        }
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    
    switch (section) {
        case 0: title = @"Group Details"; break;
        case 1: title = @"Migrants by Age Group"; break;
        case 2: title = @"Migrants by Sex"; break;
        case 3: title = @"Vulnerable Migrants"; break;
    }
    
    static NSString *identifier = @"HeaderIdentifier";
    IMTableHeaderView *header = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!header) {
        header = [[IMTableHeaderView alloc] initWithTitle:title actionTitle:nil reuseIdentifier:@"TableViewHeader"];
        header.labelTitle.font = [UIFont boldFontWithSize:16];
    }
    
    header.labelTitle.text = title;
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath.section && indexPath.row) {
        IMCountryListVC *vc = [[IMCountryListVC alloc] initWithBasePredicate:nil presentAsModal:NO popover:YES];
        vc.preferredContentSize = self.preferredContentSize;
        vc.onSelected = ^(Country *country){
            self.group.originCountry = country;
            [self.navigationController popViewControllerAnimated:YES];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        };
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}


#pragma mark View Lifecycle
- (id)initWithInterceptionGroup:(InterceptionGroup *)group action:(void (^)(InterceptionGroup *group, BOOL editing))onSave
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    self.title = @"Intercepted Group";
    self.onSave = onSave;
    self.group = group;
    self.modalInPopover = YES;
    self.preferredContentSize = CGSizeMake(500, 550);
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.group) {
        NSManagedObjectContext *context = [[IMDBManager sharedManager] localDatabase].managedObjectContext;
        self.group = [NSEntityDescription insertNewObjectForEntityForName:@"InterceptionGroup" inManagedObjectContext:context];
        self.creating = YES;
    }
}

@end