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

@interface IMAccommodationViewController ()<UIPopoverControllerDelegate, UITabBarControllerDelegate>

//View Controllers
@property (nonatomic, strong) IMAccommodationFilterVC *cityChooser;
@property (nonatomic, strong) UIPopoverController *popover;

//Programmatic Data
@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

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
        self.cityChooser = [[IMAccommodationFilterVC alloc] initWithAction:^(NSPredicate *basePredicate){
            [self.popover dismissPopoverAnimated:YES];
            self.popover = nil;
            self.basePredicate = basePredicate;
        }];
        
        self.cityChooser.view.tintColor = [UIColor IMLightBlue];
    }
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.cityChooser];
    
    if (!self.popover) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:navController];
        self.popover.delegate = self;
    }
    
    [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)showCreateAccommodation
{
    IMEditAccommodationVC *vc = [[IMEditAccommodationVC alloc] initWithAccommodation:nil];
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
    navCon.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
    [self presentViewController:navCon animated:YES completion:nil];
}


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.delegate = self;
    self.tabBar.tintColor = [UIColor IMLightBlue];
    self.navigationController.navigationBar.tintColor = [UIColor IMLightBlue];
    self.title = NSLocalizedString(@"Accommodations", @"Accommodations");
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
