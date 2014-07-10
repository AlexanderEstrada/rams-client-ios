//
//  IMRegistrationViewController.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMRegistrationViewController.h"
#import "IMRegistrationListVC.h"
#import "IMRegistrationFilterDataVC.h"
#import "Registration.h"
#import "IMEditRegistrationVC.h"
#import "IMDBManager.h"
#import "IMViewController.h"
#import "Registration+Export.h"
#import "MBProgressHUD.h"
#import "DataProvider.h"


@interface IMRegistrationViewController ()<UIPopoverControllerDelegate, UITabBarControllerDelegate,MBProgressHUDDelegate>

//View Controllers
@property (nonatomic, strong) IMRegistrationFilterDataVC * filterChooser;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic,strong) UIBarButtonItem *itemUploadAll;
@property (nonatomic) BOOL flag;
@property (nonatomic) BOOL next;
@property (nonatomic) BOOL upload_finish;
@property (nonatomic) BOOL receive_warning;
@property (nonatomic) float progress;
@property (nonatomic) NSInteger total;
@property (nonatomic,strong) MBProgressHUD *HUD;


//Programmatic Data
@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end


@implementation IMRegistrationViewController

- (void)updateBasePredicateForSelectedIndex
{
    if ([self.selectedViewController isKindOfClass:[IMRegistrationListVC class]]) {
        IMRegistrationListVC *vc = (IMRegistrationListVC *)self.selectedViewController;
        
        if (self.selectedIndex == 0) {
            self.basePredicate = vc.basePredicate =  [NSPredicate predicateWithFormat:@"complete = NO"];
            self.itemUploadAll.enabled = FALSE;
        }else if(self.selectedIndex == 1){
            self.basePredicate = vc.basePredicate =  [NSPredicate predicateWithFormat:@"complete = YES"];
            self.itemUploadAll.enabled = TRUE;
        }else if(self.selectedIndex == 2){
            self.basePredicate = vc.basePredicate = [NSPredicate predicateWithFormat:@"complete = %@",@(REG_STATUS_LOCAL)];
            self.itemUploadAll.enabled = FALSE;
        }else {
            //default is indext 0
            self.basePredicate = vc.basePredicate =  [NSPredicate predicateWithFormat:@"complete = NO"];
            self.itemUploadAll.enabled = FALSE;

        }
        
        if (self.filterChooser) {
            self.filterChooser.basePredicate = self.basePredicate;
            //reset values
            [self.filterChooser resetValue];
        }
        
    }
    
    
}

#pragma mark UI Workflow
- (void)setBasePredicate:(NSPredicate *)basePredicate
{
    _basePredicate = basePredicate;
    [self forwardBasePredicate:nil];
}

- (void)forwardBasePredicate:(UIViewController *)viewController
{
    if (!viewController){
        if ([self.selectedViewController isKindOfClass:[IMRegistrationListVC class]]) {
            IMRegistrationListVC *vc = (IMRegistrationListVC *)self.selectedViewController;
            vc.basePredicate = self.basePredicate;
            
        }
    }
    if ([viewController respondsToSelector:@selector(setBasePredicate:)]) {
        [viewController performSelector:@selector(setBasePredicate:) withObject:self.basePredicate];
    }
    
}


- (void)showFilterOptions:(UIBarButtonItem *)sender
{
    if (!self.filterChooser) {
        self.filterChooser = [[IMRegistrationFilterDataVC alloc] initWithAction:^(NSPredicate *basePredicate) {
            [self.popover dismissPopoverAnimated:YES];
            self.popover = nil;
            if (basePredicate) {
                if (self.selectedIndex == 0) {
                    self.basePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"complete = NO"],basePredicate]];
                }else if(self.selectedIndex == 1){
                    self.basePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"complete = YES"],basePredicate]];
                }else {
                    self.basePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"complete = %@",@(REG_STATUS_LOCAL)],basePredicate]];
                }
                
            }
        } andBasePredicate:self.basePredicate];
        
        self.filterChooser.view.tintColor = [UIColor IMMagenta];
        //set predicate
        self.filterChooser.basePredicate = self.basePredicate;
    }else{
        //set predicate
        self.filterChooser.basePredicate = self.basePredicate;
    }
    __weak typeof(self) weakSelf = self;
    self.filterChooser.doneCompletionBlock  = ^(NSMutableDictionary * value)
    {
        //get all filter data
        
        //TODO : reload Data
        [weakSelf updateBasePredicateForSelectedIndex];
        
    };
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.filterChooser];
    
    if (!self.popover) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:navController];
        self.popover.delegate = self;
    }
    
    [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
}

- (void)showCreateRegistration
{
    //TODO : check if apps already competely synch, case not, then show alert to synch the apps
    if (![[NSUserDefaults standardUserDefaults] objectForKey:IMLastSyncDate]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm Data Updates" message:@"You are about to start data updates. Internet connection is required and may take some time to finish.\nContinue updating application data?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
        alert.tag = IMAlertNeedSynch_Tag;
        [alert show];
        return;
    };
    
    IMEditRegistrationVC *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IMEditRegistrationVC"];
    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
    navCon.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
    [self presentViewController:navCon animated:YES completion:nil];
}


#pragma mark UITabBarControllerDelegate
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self updateBasePredicateForSelectedIndex];
//        usleep(500);
//    });

    
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    switch ([self.viewControllers indexOfObject:viewController]) {
        case 0:
            self.title = @"Incomplete Registration";
            break;
        case 1:
            self.title = @"Pending Registration";
            break;
        case 2:
            self.title = @"Local Migrant Data";
            break;
        default:
             self.title = @"Incomplete Registration";
            break;
    }
    
    return YES;
}

#pragma mark UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.title = @"Incomplete Registration";
    self.navigationController.navigationBar.tintColor = [UIColor IMMagenta];
    self.view.tintColor = [UIColor IMMagenta];
    self.tabBar.tintColor = [UIColor IMMagenta];
    self.delegate = self;
    
    //setup navigation bar items
    UIBarButtonItem *itemCreate = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                target:self action:@selector(showCreateRegistration)];
    
    UIBarButtonItem *itemFilter = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                target:self action:@selector(showFilterOptions:)];
    //add upload icon
    self.itemUploadAll= [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-upload-small"] style:UIBarButtonItemStylePlain target:self action:@selector(uploadAll:)];
    self.itemUploadAll.enabled = FALSE;
    
    self.navigationItem.rightBarButtonItems = @[itemCreate,itemFilter,self.itemUploadAll];
    self.receive_warning = FALSE;
    //reset top layout
    self.edgesForExtendedLayout=UIRectEdgeNone;
    //TODO : reload Data
//    self.basePredicate =  [NSPredicate predicateWithFormat:@"complete = NO"];
    
    
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    
    if (alertView.tag == IMAlertUpload_Tag && buttonIndex != [alertView cancelButtonIndex]) {
        //start uploading
        if (!_HUD) {
            // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
            _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        }
        
        // Back to indeterminate mode
        _HUD.mode = MBProgressHUDModeIndeterminate;
        
        // Add HUD to screen
        [self.navigationController.view addSubview:_HUD];
        
        
        
        // Regisete for HUD callbacks so we can remove it from the window at the right time
        _HUD.delegate = self;
        
        _HUD.labelText = @"Uploading Data";
        
        
        // Show the HUD while the provided method executes in a new thread
        [_HUD showWhileExecuting:@selector(uploading) onTarget:self withObject:nil animated:YES];
        
        
    } else if (alertView.tag == IMAlertNeedSynch_Tag && buttonIndex != [alertView cancelButtonIndex]) {
        
        [self.sideMenuDelegate openSynchronizationDialog:nil];
        
    }
    
}

- (void) uploading
{
    //get all data to upload
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Registration"];
    request.predicate = [NSPredicate predicateWithFormat:@"complete = YES"];
    
    self.flag = FALSE;
    self.next  =FALSE;
    self.upload_finish = FALSE;
    
    NSManagedObjectContext *moc = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    
    self.total = [results count];
    
    if (self.total > 0) {
        _HUD.mode = MBProgressHUDModeDeterminate;
        self.progress = 0;
        //disable Menu
        [self.sideMenuDelegate disableMenu:YES];
        //show data loading view until upload is finish
        //start blocking
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        
        for (Registration * registration in results) {
            
            self.next  =FALSE;
            
            if (self.flag) {
                //there is something wrong with connection
                break;
            }
            
            if (self.receive_warning) {
                //sleep for a while
                sleep(5);
                
                self.receive_warning = FALSE;
                
            }
            
            registration.successHandler = ^{
                
                //do something if success
                NSLog(@"Upload Success");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
                [self dismissViewControllerAnimated:YES completion:nil];
                [self updateBasePredicateForSelectedIndex];
                if(self.progress < self.total ){
                    self.progress += 1;
                    _HUD.progress = self.progress/self.total;
                    _HUD.labelText = [NSString stringWithFormat:@"Uploaded %i of %lu",(int)self.progress,(unsigned long)[results count]];
                    NSLog(@"Upload : %f from %lu",self.progress,(unsigned long)[results count]);
                    
                }else self.upload_finish = TRUE;
                
                self.next = TRUE;
            };
            
            registration.failureHandler = ^(NSError *error){
                if (!self.flag) {
                    
                    [self showAlertWithTitle:@"Upload Failed" message:@"Please check your network connection and try again. If problem persist, contact administrator."];
                    self.flag = TRUE;
                    NSLog(@"Upload Fail : %@",[error description]);
                    self.upload_finish = TRUE;
                    self.next = TRUE;
                }
                
            };
            
            
            //define queue if it's nil
            if (!_registrationQueue) {
                _registrationQueue = dispatch_queue_create("RegistrationQueue", NULL);
                //        migrantQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
                dispatch_sync(_registrationQueue, ^{
                    _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                    _context.parentContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
                });
            }
            
            dispatch_async(_registrationQueue, ^{
                @autoreleasepool {
                    @try {
                        
                        //TODO: upload individual registration here
                        
                        //prepare data
                        NSMutableDictionary * params = [[registration format] mutableCopy];
                        
                        //send the json data to server
                        [registration sendRegistration:params];
                        usleep(500);
                        
                    }
                    @catch (NSException *exception) {
                        //                        NSLog(@"Error while uploading all pending Registration - Error message: %@", [exception description]);
                        [_context rollback];
                    }
                }
                
            });
            
            while(self.next ==FALSE){
                usleep(5000);
            }
            NSError * error;
            [_context save:&error];
            if (error) {
                NSLog(@"save database with error : %@", [error description]);
            }
            
        }
        // Back to indeterminate mode
        _HUD.mode = MBProgressHUDModeIndeterminate;
        
        //save database
        [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        //         finish blocking
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [self.sideMenuDelegate disableMenu:NO];
        //TODO : reload Data
        [self updateBasePredicateForSelectedIndex];
        
    }else{
        NSLog(@"There is no data to upload");
        
        //show alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"There is no data to upload" message:Nil delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
}


- (void) uploadAll:(UIBarButtonItem *)sender
{
    //show confirmation
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload all pending Registration"
                                                    message:@"All your pending Registration will be uploaded and you need internet connection to do this.\nContinue upload all pending Registration?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Yes", nil];
    alert.tag = IMAlertUpload_Tag;
    [alert show];
    
}

#pragma mark Specific Custom Implementation
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}



#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    //    // Remove HUD from screen when the HUD was hidded
    [_HUD removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    //give time to memory to release
    self.receive_warning = TRUE;
    sleep(1);
}

@end