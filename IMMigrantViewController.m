//
//  IMMigrantViewController.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 4/15/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMMigrantViewController.h"
#import "IMMigrantListVC.h"
#import "IMMigrantFilterDataVC.h"
#import "Migrant.h"
#import "IMEditRegistrationVC.h"
#import "IMDBManager.h"
#import "IMAuthManager.h"

#import "DataReceiver.h"
#import "DataProvider.h"

@interface IMMigrantViewController ()<UIPopoverControllerDelegate, UITabBarControllerDelegate,UIAlertViewDelegate>

//View Controllers
@property (nonatomic, strong) IMMigrantFilterDataVC * filterChooser;
@property (nonatomic, strong) UIPopoverController *popover;

//Programmatic Data
@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end

@implementation IMMigrantViewController


- (void)updateBasePredicateForSelectedIndex
{
    if ([self.selectedViewController isKindOfClass:[IMMigrantListVC class]]) {
        IMMigrantListVC *vc = (IMMigrantListVC *)self.selectedViewController;
        
        if (self.selectedIndex == 0) {
            self.basePredicate = vc.basePredicate =  [NSPredicate predicateWithFormat:@"active = YES AND complete = YES"];
        }else if (self.selectedIndex ==1) {
            self.basePredicate = vc.basePredicate =  [NSPredicate predicateWithFormat:@"active = YES AND lastUploader = %@",[IMAuthManager sharedManager].activeUser.email];
        }
        
        if (self.filterChooser) {
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
        if ([self.selectedViewController isKindOfClass:[IMMigrantListVC class]]) {
            IMMigrantListVC *vc = (IMMigrantListVC *)self.selectedViewController;
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
        //remove active predicate, we use active predicate from filter chooser
        self.basePredicate = [NSPredicate predicateWithFormat:@"complete = YES"];
        self.filterChooser = [[IMMigrantFilterDataVC alloc] initWithAction:^(NSPredicate *basePredicate)
                              {
                                  [self.popover dismissPopoverAnimated:YES];
                                  self.popover = nil;
                                  if (basePredicate) {
                                      if (self.selectedIndex == 0) {
                                          self.basePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[basePredicate]];
                                      }
                                  }else {
                                      //reset base predicate
                                      [self updateBasePredicateForSelectedIndex];
                                  }
                                  
                              } andBasePredicate:self.basePredicate
                              ];
        
        self.filterChooser.view.tintColor = [UIColor IMMagenta];
        //set predicate
        self.filterChooser.basePredicate = self.basePredicate;
    }else{
        //set predicate
        self.filterChooser.basePredicate = self.basePredicate;
    }
    // Establish the weak self reference
    __weak typeof(self) weakSelf = self;
    self.filterChooser.doneCompletionBlock = ^(NSMutableDictionary * value)
    {
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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
    vc.registrationSave = ^(BOOL remove)
    {
        //TODO : reload Data
        [self updateBasePredicateForSelectedIndex];
    };

    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
    navCon.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
    [self presentViewController:navCon animated:YES completion:nil];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == IMAlertNeedSynch_Tag && buttonIndex != [alertView cancelButtonIndex]) {
        
        [self.sideMenuDelegate openSynchronizationDialog:nil];
        
    }
    
}

#pragma mark UITabBarControllerDelegate
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    [self updateBasePredicateForSelectedIndex];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    
    if (index == 0) {
        self.title = @"Migrant List";
    }else if (index == 1) {
        self.title = @"My Upload";
    }else {
        self.title = @"tab 3";
    }
    
    
    return YES;
}




#pragma mark UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Migrant List";
    self.navigationController.navigationBar.tintColor = [UIColor IMMagenta];
    self.view.tintColor = [UIColor IMMagenta];
    self.tabBar.tintColor = [UIColor IMMagenta];
    self.delegate = self;
    
    //setup navigation bar items
    UIBarButtonItem *itemCreate = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                target:self action:@selector(showCreateRegistration)];
    
    UIBarButtonItem *itemFilter = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                target:self action:@selector(showFilterOptions:)];
    
    self.navigationItem.rightBarButtonItems = @[itemCreate,itemFilter];
    //reset top layout
    self.edgesForExtendedLayout=UIRectEdgeNone;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
