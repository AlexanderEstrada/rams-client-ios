//
//  IMMovementReviewTableVC.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 8/19/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMMovementReviewTableVC.h"
#import "NSDate+Relativity.h"
#import "Movement+Extended.h"
#import "Port+Extended.h"
#import "Country+Extended.h"
#import "IMAuthManager.h"
#import "MBProgressHUD.h"
#import "IMConstants.h"
#import "IMDBManager.h"
#import "Migrant+Extended.h"
#import "IMMigrantViewController.h"
#import "IMFamilyViewController.h"
#import "IMFormCell.h"
#import "IMDatePickerVC.h"


#define cellName @"cellReview"

@interface IMMovementReviewTableVC ()<MBProgressHUDDelegate,UIPopoverControllerDelegate>
@property (nonatomic,strong) MBProgressHUD *HUD;
@property (nonatomic,strong) NSManagedObjectContext *context;
@property (nonatomic,strong) NSDate *deptDate;
@property (nonatomic) BOOL flag;
@property (nonatomic) BOOL next;
@property (nonatomic) BOOL upload_status;
@property (nonatomic) BOOL editingMode;
@property (nonatomic) BOOL receive_warning;
@property (nonatomic) BOOL show_migrant_list;
@property (nonatomic) float progress;
@property (nonatomic) NSInteger total;
@property (nonatomic, strong) UIPopoverController *popover;
@end

typedef enum : NSUInteger {
    
    section_date_of_submission = 0,
    section_proposed_date,
    section_departure_date,
    section_submitter,
    section_iom_office_of_user,
    section_movement_type,
    section_destination,
    section_number_of_migrant,
    section_travel_mode,
    section_departure_port,
    section_document_number,
    section_reference_code
    
} section_type;

@implementation IMMovementReviewTableVC

@synthesize delegate;

- (void)hudWasHidden {
    //    // Remove HUD from screen when the HUD was hidded
    [_HUD removeFromSuperview];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setShow_migrant_list:(BOOL)show_migrant_list{
    if (_show_migrant_list != show_migrant_list) {
        _show_migrant_list = show_migrant_list;
        if ([self.delegate respondsToSelector:@selector(showMigrantList:shouldShowMigrantList:)]) {
            // tell our delegate of our ending state
            [self.delegate showMigrantList:self shouldShowMigrantList:self.show_migrant_list];
        }
    }
}

- (void)setMovement:(Movement *)movement
{
    if (movement) {
        if (!_movement) {
            if (!_context) {
                _context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
            }
            _movement = [Movement newMovementInContext:_context];
        }
        
        _movement = movement;
        
        //deep copy
        if (movement.date) {
            _movement.date = movement.date;
        }else{
            _movement.date = [NSDate date];
        }
        if (movement.documentNumber) {
            _movement.documentNumber = movement.documentNumber;
        }
        if (movement.movementId) {
            _movement.movementId = movement.movementId;
        }
        if (movement.proposedDate) {
            _movement.proposedDate = movement.proposedDate;
        }
        if (movement.travelMode) {
            _movement.travelMode = movement.travelMode;
        }
        if (movement.referenceCode) {
            _movement.referenceCode = movement.referenceCode;
        }
        if (movement.type) {
            _movement.type = movement.type;
        }
        if (movement.departurePort) {
            _movement.departurePort = [Port portWithName:movement.departurePort.name inManagedObjectContext:_context];
        }
        if (movement.destinationCountry) {
            _movement.destinationCountry = [Country countryWithCode:movement.destinationCountry.code inManagedObjectContext:_context];
        }
        if (movement.originLocation) {
            _movement.originLocation = [Accommodation accommodationWithId:movement.originLocation.accommodationId inManagedObjectContext:_context];
        }
        if (movement.transferLocation) {
            _movement.transferLocation = [Accommodation accommodationWithId:movement.transferLocation.accommodationId inManagedObjectContext:_context];
        }
        
        
    }
}

- (void)setMigrants:(NSMutableArray *)migrants
{
    if ([migrants count]) {
        if (_migrants) {
            _migrants = [NSMutableArray array];
        }
        _migrants = [migrants mutableCopy];
    }
}

- (void)setMigrantData:(NSMutableDictionary *)migrantData{
    if (migrantData) {
        _migrantData = migrantData;
        
        //get migrant data form dictionary
        if (self.migrantData[@"Migrant"]) {
            if (!self.migrants) {
                self.migrants = [NSMutableArray array];
            }
            
            self.migrants = self.migrantData[@"Migrant"];
            NSLog(@"self.migrants = %lu",(unsigned long)[self.migrants count]);
        }
        
        if (self.migrantData[@"Movement"]) {
            //get movement from dictionary
            if (!self.movement) {
                if (!self.context) {
                    self.context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
                }
                self.movement = [Movement newMovementInContext:self.context];
            }
            self.movement = self.migrantData[@"Movement"];
        }
        
        if ([self isViewLoaded]) {
            [self.tableView reloadData];
        }
        
    }
}

- (IBAction)upload:(id)sender {
    
    NSLog(@"Uploading");
    //show confirmation
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload all Movement Data"
                                                    message:@"All your Movement Data will be uploaded and you need internet connection to do this.\nContinue upload all Movement?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Yes", nil];
    alert.tag = IMAlertUpload_Tag;
    [alert show];
}

- (void) uploading
{
    @try {
        
        //formating data
        self.total = [self.migrants count]?1:0;
        
        if (self.total > 0) {
            self.upload_status = FALSE;
            _HUD.mode = MBProgressHUDModeDeterminate;
            self.progress = 0;
            //disable Menu
            [self.sideMenuDelegate disableMenu:YES];
            //show data loading view until upload is finish
            //start blocking
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            
            
            NSLog(@"uploading == self.migrants = %lu",(unsigned long)[self.migrants count]);
            //add migrants to array
            NSMutableArray * migrantArray = [NSMutableArray array];
            NSMutableDictionary * formatted = [NSMutableDictionary dictionary];
            
            //formating migrants data
            for (Migrant * migrant in self.migrants) {
                //adding migrants
                [migrantArray addObject:migrant.registrationNumber];
            }
            
            //wrap data
            [formatted setObject:migrantArray forKey:@"migrants"];
            [formatted setObject:[self.movement format] forKey:@"movement"];
            
            NSLog(@"formatted : %@",[formatted description]);
            self.next  =FALSE;
            //send formatted data to server
            [self sendMovement:formatted];
            //3 minutes before force close
            NSNumber * defaultValue = [IMConstants getIMConstantKeyNumber:CONST_IMSleepDefault];
            
            if (defaultValue.intValue < 0) {
                defaultValue = @(36000);
            }
            int counter = 0;
            while(self.next ==FALSE){
                usleep(5000);
                if (counter == defaultValue.intValue) {
                    break;
                }
                counter++;
            }
            
            if (self.upload_status) {
                //case upload success and movement != transfer then deactived migrant
                
                NSError * error;
                
                for (Migrant * migrant in self.migrants) {
                    if (![self.movement.type isEqual:@"Transfer"]) {
                        //deactivated the migrants
                        migrant.active = @(0);
                    }else if ([self.movement.type isEqualToString:@"Transfer"]){
//                        update current detention location to destination
                        migrant.detentionLocation = self.movement.transferLocation.accommodationId;
                        migrant.detentionLocationName = self.movement.transferLocation.name;
                    }
                    
                    //save movement
                    [migrant addMovementsObject:self.movement];
                }
                
               
                
                //save movement to migrant database
                [self.movement.managedObjectContext save:&error];
                if (error) {
                    NSLog(@"=== save All database with error === : %@", [error description]);
                }
                
                // Back to indeterminate mode
                _HUD.mode = MBProgressHUDModeIndeterminate;
                
                //         finish blocking
                [UIApplication sharedApplication].idleTimerDisabled = NO;
                [self.sideMenuDelegate disableMenu:NO];
                
                //synchronize data
                _HUD.labelText = @"Synchronizing...";
                [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
                sleep(2);
                self.show_migrant_list = YES;
                [self showMigrantListOnParent];
                
            }
            
        }else{
            NSLog(@"There is no data to upload");
            
            //show alert
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"There is no data to upload" message:Nil delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    
}


- (void)showMigrantListOnParent
{
    @try {
        
        [self.navigationController popToRootViewControllerAnimated:NO];
        if (self.show_migrant_list) {
            [[NSNotificationCenter defaultCenter] postNotificationName:IMShowMigrantListNotification object:nil];
        }else {
            [[NSNotificationCenter defaultCenter] postNotificationName:IMCancelNotification object:nil];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Error : %@",[exception description]);
    }
    
}
- (void) sendMovement:(NSDictionary *)params
{
    
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client postJSONWithPath:@"movement/save"
                  parameters:params
                     success:^(NSDictionary *jsonData, int statusCode){
                         //                                                 [self showAlertWithTitle:@"Upload Success" message:nil];
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Success" message:Nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                         alert.tag = IMAlertUploadSuccess_Tag;
                         [alert show];
                         
                         NSLog(@"Upload Success");
                         
                         
                     }
                     failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                         if (!self.flag) {
                             [self showAlertWithTitle:@"Upload Failed" message:@"Please check your network connection and try again. If problem persist, contact administrator."];
                             self.flag = TRUE;
                             NSLog(@"Upload Fail : %@",[error description]);
                             self.upload_status = FALSE;
                             self.next = TRUE;
                         }
                     }];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == IMAlertUpload_Tag && buttonIndex != [alertView cancelButtonIndex]) {
        //start uploading
//        if (!_HUD) {
            // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
            _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
//        }
        
        // Back to indeterminate mode
        _HUD.mode = MBProgressHUDModeDeterminate;
        
        // Add HUD to screen
        [self.navigationController.view addSubview:_HUD];
        
        
        
        // Regisete for HUD callbacks so we can remove it from the window at the right time
        _HUD.delegate = self;
        
        _HUD.labelText = @"Uploading Data";
        
        
        // Show the HUD while the provided method executes in a new thread
        [_HUD showWhileExecuting:@selector(uploading) onTarget:self withObject:nil animated:YES];
        
    }else if (alertView.tag == IMAlertUploadSuccess_Tag){
        //         finish blocking
        
        
        self.upload_status = TRUE;
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [self.sideMenuDelegate disableMenu:NO];
        
        //reset flag
        self.next = TRUE;
        
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self isViewLoaded]) {
        [self.tableView reloadData];
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self action:@selector(onCancel)];
    
    self.navigationItem.rightBarButtonItems = @[self.uploadButton,cancelButton];
    if (self.movement) {
        self.title = @"Edit Movement";
        self.editingMode = YES;
    }else {
        self.title = @"New Movement";
        self.editingMode = NO;
        if (!self.context) {
            self.context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        }
        self.movement = [Movement newMovementInContext:self.context];
    }
    self.show_migrant_list = NO;
    self.deptDate = Nil;
}

- (void)onCancel{
    
    @try {
        
        if (self.editingMode) {
            [self.movement.managedObjectContext rollback];
        }else {
            [self.context deleteObject:self.movement];
        }
        
        NSError *error;
        if (![self.context save:&error]) {
            NSLog(@"Error deleting movement: %@", [error description]);
            [self showAlertWithTitle:@"Failed Saving Family Data" message:@"Please try again. If problem persist, please cancel and consult with administrator."];
            
        }else {
            [[IMDBManager sharedManager] saveDatabase:^(BOOL success){
                //            [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }
        
        if (self.show_migrant_list) {
            self.show_migrant_list = NO;
        }
        [self showMigrantListOnParent];
        
    }
    @catch (NSException *exception) {
        NSLog(@"Error : %@",[exception description]);
    }
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    self.receive_warning = TRUE;
    sleep(1);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 12;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
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

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (indexPath.row == section_departure_date) {
//        IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
//            self.deptDate = date;
//            UITableViewCell *cell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
//            cell.detailTextLabel.text = [self.deptDate mediumFormatted];
//        }];
//        
//        datePicker.maximumDate = [NSDate date];
//        datePicker.date = self.deptDate;
//        [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
//    }
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellName forIndexPath:indexPath];

    
    switch (indexPath.row) {
        case section_date_of_submission:{
            cell.textLabel.text = @"Date of Submission";
            cell.detailTextLabel.text = [[NSDate date] mediumFormatted];
            break;
        }
        case section_proposed_date:{
            cell.textLabel.text = @"Proposed date";
            cell.detailTextLabel.text = [self.movement.proposedDate mediumFormatted];
            
            break;
        }
        case section_departure_date:{
            cell.textLabel.text = @"Movement date";
            cell.detailTextLabel.text = [self.movement.date mediumFormatted];
            break;
        }
        case section_submitter:{
            cell.textLabel.text = @"Submitter";
            cell.detailTextLabel.text = [IMAuthManager sharedManager].activeUser.name;
            
            break;
        }
        case section_iom_office_of_user:{
            cell.textLabel.text = @"IOM Office of user";
            cell.detailTextLabel.text = [IMAuthManager sharedManager].activeUser.officeName;
            
            break;
        }
        case section_movement_type:{
            cell.textLabel.text = @"Movement Type";
            cell.detailTextLabel.text = self.movement.type;
            
            break;
        }
        case section_destination:{
            cell.textLabel.text = @"Destination";
            cell.detailTextLabel.text = self.movement.destinationCountry.name;
            
            break;
        }
        case section_number_of_migrant:{
            cell.textLabel.text = @"Number of Migrants";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%i",[self.migrants count]];
            
            break;
        }
        case section_travel_mode:{
            cell.textLabel.text = @"Travel mode";
            cell.detailTextLabel.text = self.movement.travelMode;
            
            break;
        }
        case section_departure_port:{
            cell.textLabel.text = @"Departure port";
            cell.detailTextLabel.text = self.movement.departurePort.name;
            
            break;
        }
        case section_document_number:{
            cell.textLabel.text = @"Document number";
            cell.detailTextLabel.text = self.movement.documentNumber;
            
            break;
        }
        case section_reference_code:{
            cell.textLabel.text = @"Reference code";
            cell.detailTextLabel.text = self.movement.referenceCode;
            
            break;
        }
        default:
            break;
    }
    
    
    return cell;
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */
//
//- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
//{
//    if ([identifier isEqualToString:@"goToMigrantList"]) {
//
//        [self upload:Nil];
//        //        while(self.next ==FALSE){
//        //            usleep(5000);
//        //        }
//        //        if (!self.upload_status) {
//        //            return NO;
//        //        }
//    }
//
//
//    return YES;
//}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self.delegate respondsToSelector:@selector(showMigrantList:shouldShowMigrantList:)]) {
        // tell our delegate of our ending state
        [self.delegate showMigrantList:self shouldShowMigrantList:self.show_migrant_list];
    }
}

//
//#pragma mark - Navigation
//
//// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    // Get the new view controller using [segue destinationViewController].
//    // Pass the selected object to the new view controller.
//
//    if ([[segue identifier] isEqualToString:@"goToMigrantList"]) {
//        NSLog(@"Do something");
//    }
//
//}


@end
