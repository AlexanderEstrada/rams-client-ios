//
//  IMPoliceOfficerVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/26/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMPoliceOfficerVC.h"
#import "IMDBManager.h"
#import "IMFormCell.h"


@interface IMPoliceOfficerVC ()

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *phone;

@end


@implementation IMPoliceOfficerVC

- (void)save
{
    if ( ![self validateInput] ) {
        [self showAlertWithTitle:@"Invalid Input" message:@"Officer's name and phone number has to be valid. Please check your input."];
        return;
    }
    
    if (!self.policeOfficer) {
        NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        _policeOfficer = [NSEntityDescription insertNewObjectForEntityForName:@"PoliceOfficer" inManagedObjectContext:context];
    }
    
    self.policeOfficer.name = self.name;
    self.policeOfficer.phone = self.phone;
    
    if (self.onSave) self.onSave(self.policeOfficer);
}

- (void)cancel
{
    if (self.onCancel) self.onCancel();
}

- (BOOL)validateInput
{
    BOOL stat = [self.name length] >= 3;
    stat &= [self.phone length] > 7;
    return stat;
}


#pragma mark View Lifecycle
- (void)setPoliceOfficer:(PoliceOfficer *)policeOfficer
{
    _policeOfficer = policeOfficer;
    self.name = self.policeOfficer.name;
    self.phone = self.policeOfficer.phone;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Police Officer";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.modalInPopover = YES;
    self.preferredContentSize = CGSizeMake(320, 150);
}


#pragma mark Table View
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IMFormCell *cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:@"PoliceOfficerCell"];
    
    if (indexPath.row == 0) {
        cell.labelTitle.text = @"Name";
        cell.textValue.placeholder = @"Officer's name";
        cell.textValue.text = self.name;
        cell.onTextValueReturn = ^(NSString *textValue){ self.name = textValue; };
        cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet]];
        cell.maxCharCount = 50;
        
    }else {
        cell.labelTitle.text = @"Phone";
        cell.textValue.text = self.phone;
        cell.textValue.placeholder = @"e.g +628112223456";
        cell.onTextValueReturn = ^(NSString *textValue){ self.phone = textValue; };
        cell.characterSets = @[[NSCharacterSet characterSetWithCharactersInString:@"+0123456789"]];
        cell.maxCharCount = 20;
    }
    
    return cell;
}

@end