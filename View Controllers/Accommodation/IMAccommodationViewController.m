//
//  IMAccommodationViewController.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/22/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMAccommodationViewController.h"
#import "IMAccommodationFilterVC.h"
#import "IMEditAccommodationVC.h"
#import "IMAuthManager.h"
#import "IMDBManager.h"
#import "Photo+Extended.h"
#import "IMAccommodationListVC.h"

@interface IMAccommodationViewController ()<UIPopoverControllerDelegate, UITabBarControllerDelegate,UIAlertViewDelegate>

//View Controllers
@property (nonatomic, strong) IMAccommodationFilterVC *cityChooser;
@property (nonatomic, strong) UIPopoverController *popover;

//Programmatic Data
@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic) BOOL active;
@property (nonatomic) NSString * city;

@end


@implementation IMAccommodationViewController

#pragma mark UITabBarControllerDelegate
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    [self forwardBasePredicate:viewController];
    return YES;
}


#pragma mark UI Workflow
- (void)setBasePredicate:(NSPredicate *)basePredicate
{
    _basePredicate = basePredicate;
    [self forwardBasePredicate:nil];
}

- (void)setCity:(NSString *)city
{
    _city = city;
    [self forwardCity:nil];
}

- (void)setActive:(BOOL)active{
    _active = active;
    [self forwardActive:nil];
}

- (void)forwardCity:(UIViewController *)viewController
{
    if (!viewController) viewController = [self selectedViewController];
    if ([viewController respondsToSelector:@selector(setCity:)]) {
        [viewController performSelector:@selector(setCity:) withObject:self.city];
    }
}

- (void)forwardType:(UIViewController *)viewController withType :(filter_type) type
{
    if (!viewController) viewController = [self selectedViewController];
    switch (type) {
        case type_predicate:{
            if ([viewController respondsToSelector:@selector(reloadDataAll)]) {
                [viewController performSelector:@selector(reloadDataAll) withObject:Nil];
            }
            break;
        }
        case type_value:{
            if ([viewController respondsToSelector:@selector(reloadData)]) {
                [viewController performSelector:@selector(reloadData) withObject:Nil];
            }
            break;
        }
        default:
            break;
    }
}


- (void)forwardActive:(UIViewController *)viewController
{
    if (!viewController) viewController = [self selectedViewController];
    if ([viewController respondsToSelector:@selector(setActive:)]) {
        [viewController performSelector:@selector(setActive:) withObject:[NSNumber numberWithBool:self.active] afterDelay:0.5];
    }
}

- (void)forwardBasePredicate:(UIViewController *)viewController
{
    if (!viewController) viewController = [self selectedViewController];
    if ([viewController respondsToSelector:@selector(setBasePredicate:)]) {
        [viewController performSelector:@selector(setBasePredicate:) withObject:self.basePredicate];
    }
}

- (void)showCityOptions:(UIBarButtonItem *)sender
{
    if (!self.cityChooser) {
        self.cityChooser = [[IMAccommodationFilterVC alloc] initWithValues:^(BOOL active,NSString *city,NSPredicate *basePredicate){
            [self.popover dismissPopoverAnimated:YES];
            self.popover = nil;
            
            if (self.active != active) self.active = active;
            if (![self.city isEqualToString:city]) self.city = city;
            if (basePredicate != self.basePredicate) self.basePredicate = basePredicate;
        }];
        self.cityChooser.view.tintColor = [UIColor IMLightBlue];
    }else {
        self.cityChooser.basePredicate = self.basePredicate;
        self.cityChooser.active = self.active;
        self.cityChooser.city = self.city;
    }
    __weak typeof(self) weakSelf = self;
    self.cityChooser.onUpdateView = ^(filter_type type){
        
        [weakSelf forwardType:Nil withType:type];
    };
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.cityChooser];
    
    if (!self.popover) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:navController];
        self.popover.delegate = self;
    }
    
    [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)showCreateAccommodation
{
    //TODO : check if apps already competely synch, case not, then show alert to synch the apps
    if (![[NSUserDefaults standardUserDefaults] objectForKey:IMLastSyncDate]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm Data Updates" message:@"You are about to start data updates. Internet connection is required and may take some time to finish.\nContinue updating application data?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
        alert.tag = IMAlertNeedSynch_Tag;
        [alert show];
        return;
    };
        
    IMEditAccommodationVC *vc = [[IMEditAccommodationVC alloc] initWithAccommodation:nil];
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


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.delegate = self;
    self.tabBar.tintColor = [UIColor IMLightBlue];
    self.navigationController.navigationBar.tintColor = [UIColor IMLightBlue];
    self.title =  @"Locations";
    //    self.title = NSLocalizedString(@"Accommodations", @"Accommodations");
    self.basePredicate = [NSPredicate predicateWithFormat:@"active = YES"];
    
    //setup navigation bar items
    UIBarButtonItem *itemCreate = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                target:self action:@selector(showCreateAccommodation)];
    UIBarButtonItem *itemFilter = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                target:self action:@selector(showCityOptions:)];
    
    if ([IMAuthManager sharedManager].activeUser.roleOperation) {
        self.navigationItem.rightBarButtonItems = @[itemCreate, itemFilter];
    }else {
        self.navigationItem.rightBarButtonItem = itemFilter;
    }
}


#pragma mark UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}

@end
