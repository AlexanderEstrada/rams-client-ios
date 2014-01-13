//
//  IMRegistrationViewController.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMRegistrationViewController.h"
#import "IMRegistrationListVC.h"


@interface IMRegistrationViewController ()<UITabBarControllerDelegate>

@end


@implementation IMRegistrationViewController

- (void)updateBasePredicateForSelectedIndex
{
    if ([self.selectedViewController isKindOfClass:[IMRegistrationListVC class]]) {
        IMRegistrationListVC *vc = (IMRegistrationListVC *)self.selectedViewController;
        
        if (self.selectedIndex == 0) {
            vc.basePredicate = [NSPredicate predicateWithFormat:@"complete = NO"];
        }else {
            vc.basePredicate = [NSPredicate predicateWithFormat:@"complete = YES"];
        }
    }
}


#pragma mark UITabBarControllerDelegate
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    [self updateBasePredicateForSelectedIndex];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    int index = [self.viewControllers indexOfObject:viewController];
    
    if (index == 0) {
        self.title = @"Incomplete Registration";
    }else if (index == 1) {
        self.title = @"Pending Registration";
    }else {
        self.title = @"Upload Registration Data";
    }
    
    return YES;
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
}

@end