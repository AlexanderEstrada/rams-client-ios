//
//  IMIOMOfficerVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/20/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMNewIOMOfficerVC.h"
#import "IMDBManager.h"
#import "IMFormCell.h"


@interface IMNewIOMOfficerVC ()<UIAlertViewDelegate>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *email;

@end


@implementation IMNewIOMOfficerVC

- (void)save
{
    if ( ![self validateInput] ) {
        [self showAlertWithTitle:@"Invalid Input" message:@"Officer's name and phone number has to be valid. Please check your input."];
        return;
    }

    NSManagedObjectContext *context = [[IMDBManager sharedManager] localDatabase].managedObjectContext;
    IomOfficer *officer = [IomOfficer officerWithEmail:self.email inManagedObjectContext:context];
    
    if (officer) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Duplicate Data" message:[NSString stringWithFormat:@"IOM Officer with email \n%@\nalready exists. Do you want to replace existing information with your inputs?", self.email] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Replace", nil];
        [alert show];
    }else {
        [self saveToDatabase];
    }
}

- (void)saveToDatabase
{
    NSManagedObjectContext *context = [[IMDBManager sharedManager] localDatabase].managedObjectContext;
    IomOfficer *officer = [NSEntityDescription insertNewObjectForEntityForName:@"IomOfficer" inManagedObjectContext:context];
    officer.name = self.name;
    officer.phone = self.phone;
    officer.email = self.email;
    
    if (self.onSelected) self.onSelected(officer);
}

- (BOOL)validateInput
{
    BOOL stat = [self.name length] >= 3;
    stat &= [self.email length] >= 10;
    stat &= [self.phone length] >= 7;
    return stat;
}


#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [alertView cancelButtonIndex]) {
        [self saveToDatabase];
    }
}


#pragma mark View Lifecycle
- (id)initWithAction:(void (^)(IomOfficer *officer))onSelected
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.onSelected = onSelected;
    self.preferredContentSize = CGSizeMake(450, 500);
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"IOM Officer";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
}


#pragma mark Table View
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IMFormCell *cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:@"ImmigrationOfficerCell"];
    
    if (indexPath.row == 0) {
        cell.labelTitle.text = @"Name";
        cell.textValue.placeholder = @"Officer's name";
        cell.textValue.text = self.name;
        cell.onTextValueReturn = ^(NSString *textValue){ self.name = textValue; };
        cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet]];
        cell.maxCharCount = 50;
        
    }else if (indexPath.row == 1) {
        cell.labelTitle.text = @"Email";
        cell.textValue.placeholder = @"name@iom.int";
        cell.textValue.text = self.email;
        cell.onTextValueReturn = ^(NSString *textValue){ self.email = textValue; };
        cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet characterSetWithCharactersInString:@"@._-"]];
        cell.textValue.autocapitalizationType = UITextAutocapitalizationTypeNone;
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