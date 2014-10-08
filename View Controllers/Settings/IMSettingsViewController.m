
//  IMSettingsViewController.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/3/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMSettingsViewController.h"
#import "IMAuthManager.h"
#import "NSDate+Relativity.h"
#import "IMDBManager.h"
#import "IMTableHeaderView.h"
#import "IMFormCell.h"
#import "Biometric+Storage.h"
#import "Photo+Storage.h"
#import "IMConstants.h"
#import "ServerSettingViewController.h"
#import "Registration+Export.h"

#import "MBProgressHUD.h"

@interface IMSettingsViewController ()<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate,MBProgressHUDDelegate>

@property (nonatomic,strong) MBProgressHUD *HUD;

@end


@implementation IMSettingsViewController

#define kResetDatabaseAlertTag  1
#define kSyncAlertTag           2
#define kConfirmSyncAlertTag    3
#define kConfirmRetoreAlertTag    4


#pragma mark Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 2;
    else if (section == 1) return 1;
    return 6;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *identifier = @"SettingsHeader";
    
    IMTableHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
    if (!headerView) {
        headerView = [[IMTableHeaderView alloc] initWithTitle:@"" reuseIdentifier:identifier];
        headerView.backgroundView = [[UIView alloc] init];
    }
    
    headerView.labelTitle.textColor = [UIColor IMLightBlue];
    
    switch (section) {
        case 0: headerView.labelTitle.text =   @"Your Account"  ; break;
        case 1: headerView.labelTitle.text =   @"Troubleshooting"  ; break;
        case 2: headerView.labelTitle.text =   @"Updates"  ; break;
    }
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 60;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    label.textAlignment = NSTextAlignmentCenter;
    
    if (section == 0) {
        NSString *text = [NSString stringWithFormat:  @"Your session on %@ will expired in %@"  ,[IMHTTPClient sharedClient].baseURL,[[IMAuthManager sharedManager].activeUser.accessExpiryDate relativeTimeToFuture]];
        label.text = text;
    }else if (section == 1) {
        NSDate *lastSync = [[NSUserDefaults standardUserDefaults] objectForKey:IMLastSyncDate];
        NSString *text = [NSString stringWithFormat:  @"Latest synchronization was %@"  , lastSync ? [lastSync relativeTimeLongFormat] :   @"never"  ];
        label.text = text;
    }else {
        BOOL stat = [[NSUserDefaults standardUserDefaults] boolForKey:IMBackgroundUpdates];
        label.text = stat ?   @"When updates available, data will be synchronize automatically in the background."   :   @"App will ask for confirmation when updates available."  ;
    }
    
    label.textColor = [UIColor darkGrayColor];
    
    return label;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SettingsCell"];
    cell.backgroundColor = [UIColor clearColor];
    cell.tintColor = [UIColor IMLightBlue];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.textColor = [UIColor IMRed];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = [IMAuthManager sharedManager].activeUser.name;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.imageView.image = [[UIImage imageNamed:@"User"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            UIButton *buttonSignOut = [UIButton buttonWithTitle:@"Sign Out" titleColor:[UIColor IMRed] fontSize:cell.textLabel.font.pointSize];
            [buttonSignOut addTarget:self action:@selector(signout) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = buttonSignOut;
            
        }else if(indexPath.row == 1){
            //IMServerSettingViewController
            cell.textLabel.text =   @"Setting"  ;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [[UIImage imageNamed:@"Settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            
//            UIButton *buttonSetting = [UIButton buttonWithTitle:@"Setting" titleColor:[UIColor IMRed] fontSize:cell.textLabel.font.pointSize];
//            [buttonSetting addTarget:self action:@selector(setting) forControlEvents:UIControlEventTouchUpInside];
//            cell.accessoryView = buttonSetting;
        }
        
        
    }else if (indexPath.section == 1) {
        cell.textLabel.text =   @"Reset Application Data"  ;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = [[UIImage imageNamed:@"Database"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
    }else {
        if (indexPath.row == 0) {
            cell.textLabel.text =   @"Start Data Updates"  ;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [[UIImage imageNamed:@"Sync"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }else if (indexPath.row == 1) {
            cell.textLabel.text =   @"Check for App Updates"  ;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [[UIImage imageNamed:@"App"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }else if (indexPath.row == 2){
            cell.textLabel.text =   @"Background Updates"  ;
            cell.imageView.image = [[UIImage imageNamed:@"BackgroundUpdates"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:IMBackgroundUpdates];
            sw.tag = indexPath.row;
            sw.onTintColor = [UIColor IMLightBlue];
            cell.accessoryView = sw;
            [sw addTarget:self action:@selector(toggleBackgroundUpdates:) forControlEvents:UIControlEventValueChanged];
        }else if (indexPath.row == 3){
            cell.textLabel.text =   @"Remember Form History"  ;
           cell.imageView.image = [[UIImage imageNamed:@"Settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:IMTemplateForm];
            sw.tag = indexPath.row;
            sw.onTintColor = [UIColor IMLightBlue];
            cell.accessoryView = sw;
            [sw addTarget:self action:@selector(toggleTemplateForm:) forControlEvents:UIControlEventValueChanged];
        }else if (indexPath.row == 4){
            cell.textLabel.text =   @"Restore Backup"  ;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [[UIImage imageNamed:@"Sync"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }else {
            cell.textLabel.text =   [NSString stringWithFormat:@"RAMS version %@.%@",[NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],[NSBundle mainBundle].infoDictionary[@"CFBundleVersion"]];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            if (indexPath.row == 1) {
                [self setting];
            }
            break;
        }
        case 1:
        {
            [self confirmResetDatabase];
            break;
        }
        case 2:{
            switch (indexPath.row) {
                case 0: [self checkDataUpdates]; break;
                case 1: [self checkAppUpdate]; break;
                case 4:  [self restore]; break;
                default: break;

            }
            break;
        }
        default: break;
    }
}


#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if (alertView.tag == kResetDatabaseAlertTag && buttonIndex != [alertView cancelButtonIndex]) {
//        [self resetDatabase];
        // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
        _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        
        // Add HUD to screen
        [self.navigationController.view addSubview:_HUD];
        
        // Regisete for HUD callbacks so we can remove it from the window at the right time
        _HUD.delegate = self;
        
        _HUD.labelText =   @"Resetting Data"  ;
        _HUD.detailsLabelText =   @"Please wait a moment ..."  ;
        
        // Show the HUD while the provided method executes in a new thread
        [_HUD showWhileExecuting:@selector(resetDatabase) onTarget:self withObject:nil animated:YES];
        
    }else if (alertView.tag == kSyncAlertTag && buttonIndex != [alertView cancelButtonIndex]) {
        [self.sideMenuDelegate openSynchronizationDialog:nil];
    }else if (alertView.tag == kConfirmSyncAlertTag && buttonIndex != [alertView cancelButtonIndex]) {
        [self.sideMenuDelegate openSynchronizationDialog:nil];
    }else if (alertView.tag == kConfirmRetoreAlertTag && buttonIndex != [alertView cancelButtonIndex]){
       
        
        _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        
        // Add HUD to screen
        [self.navigationController.view addSubview:_HUD];
        
        // Regisete for HUD callbacks so we can remove it from the window at the right time
        _HUD.delegate = self;
        
        _HUD.labelText =   @"Restoring Data"  ;
        _HUD.detailsLabelText =   @"Please wait a moment ..."  ;
        
        // Show the HUD while the provided method executes in a new thread
        [_HUD showWhileExecuting:@selector(restoring) onTarget:self withObject:nil animated:YES];
      
    }
//    [self hideLoadingView];
}

- (void)restoring
{
    NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
      [Registration restore:context];
    [self showAlertWithTitle:@"Restore complete" message:Nil];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    if (_HUD) {
          [_HUD removeFromSuperview];
    }
  
    //    [HUD release];
}

#pragma mark Logic
- (void)signout
{
    [[IMAuthManager sharedManager] logout];
}

- (void)setting
{
    IMServerSettingViewController *serverSettingVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IMServerSettingViewController"];
    serverSettingVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
    serverSettingVC.title = @"Server Setting";
    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:serverSettingVC];
    
    navCon.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navCon animated:YES completion:nil];
    
}

- (void)confirmResetDatabase
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:  @"Reset Application Data"  
                                                    message:  @"All your unsaved works will be deleted and you need internet connection to update application data before continue using the app.\nContinue reset application data?"  
                                                   delegate:self
                                          cancelButtonTitle:  @"Cancel"  
                                          otherButtonTitles:  @"Yes"  , nil];
    alert.tag = kResetDatabaseAlertTag;
    [alert show];
}

- (void)resetDatabase
{
    [[IMDBManager sharedManager] removeDatabase:^(BOOL success){
        if (success) {
            [[NSFileManager defaultManager] removeItemAtPath:[Photo photosDir] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[Biometric photograpDir] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[Biometric leftIndexImageDir] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[Biometric leftIndexTemplateDir] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[Biometric leftThumbImageDir] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[Biometric leftThumbTemplateDir] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[Biometric rightIndexImageDir] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[Biometric rightIndexTemplateDir] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[Biometric rightThumbImageDir] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[Biometric rightThumbTemplateDir] error:nil];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:  @"Reset Complete"  
                                                            message:  @"Continue with updating application data?"  
                                                           delegate:self
                                                  cancelButtonTitle:  @"Later"  
                                                  otherButtonTitles:  @"Yes"  , nil];
            alert.tag = kSyncAlertTag;
            [alert show];
            
        }else {
            [self showAlertWithTitle:  @"Reset Failed"  
                             message:  @"Please try again or relaunch the application. If problem persist, please contact administrator."  ];
        }
    }];
    
}

- (void)checkDataUpdates
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:  @"Confirm Data Updates"   message:  @"You are about to start data updates. Internet connection is required and may take some time to finish.\nContinue updating application data?"   delegate:self cancelButtonTitle:  @"Cancel"   otherButtonTitles:  @"Continue"  , nil];
    alert.tag = kConfirmSyncAlertTag;
    [alert show];
}

- (void)restore{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:  @"Confirm Data Restore"   message:  @"You are about to start data restore.\nContinue restoring application data?"   delegate:self cancelButtonTitle:  @"Cancel"   otherButtonTitles:  @"Continue"  , nil];
    alert.tag = kConfirmRetoreAlertTag;
    [alert show];
}

- (void)checkAppUpdate
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSNumber *version    = infoDictionary[@"CFBundleShortVersionString"];
    NSString *bundleName = infoDictionary[(NSString *)kCFBundleNameKey];
    
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client getJSONWithPath:@"update/app"
                 parameters:@{@"appVersion": version, @"appName": bundleName}
                    success:^(NSDictionary *jsonData, int statusCode){
                        NSString *stringUrl = jsonData[@"payloadUrl"];
                        if (stringUrl) {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:stringUrl]];
                        }else {
                            [self showAlertWithTitle:  @"No Update Available"   message:  @"You have the latest version of IMMS Manager"  ];
                        }
                    }
                    failure:^(NSError *error){
                        [self showAlertWithTitle:  @"Network Error"   message:  @"Failed contacting updates server. Please check your network connection and try again."  ];
                    }];
}

- (void)toggleBackgroundUpdates:(UISwitch *)sender
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setBool:sender.on forKey:IMBackgroundUpdates];
    [def synchronize];
    [self.tableView reloadData];
}

- (void)toggleTemplateForm:(UISwitch *)sender
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setBool:sender.on forKey:IMTemplateForm];
    [def synchronize];
    [self.tableView reloadData];
}



#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.tintColor = [UIColor IMLightBlue];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    
//    [IMDBManager sharedManager].onProgress = ^{
//        [self showLoadingViewWithTitle:@"Just a moment please..."];
//    };
}

@end