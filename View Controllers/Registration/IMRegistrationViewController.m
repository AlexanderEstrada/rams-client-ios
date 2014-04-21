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
#import "IMRegistrationFilterVCViewController.h"


//@interface IMRegistrationViewController ()<UITabBarControllerDelegate>
//
//@end

@interface IMRegistrationViewController ()<UIPopoverControllerDelegate, UITabBarControllerDelegate>

//View Controllers
@property (nonatomic, strong) IMRegistrationFilterDataVC * filterChooser;
@property (nonatomic, strong) UIPopoverController *popover;

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
        }else if(self.selectedIndex == 1){
            self.basePredicate = vc.basePredicate =  [NSPredicate predicateWithFormat:@"complete = YES"];
        }else {
            self.basePredicate = vc.basePredicate = [NSPredicate predicateWithFormat:@"complete = %@",@(REG_STATUS_LOCAL)];
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
        } andBasePredicate:[NSPredicate predicateWithFormat:@"complete = NO"]];
   
        self.filterChooser.view.tintColor = [UIColor IMMagenta];
    }
    
    self.filterChooser.doneCompletionBlock  = ^(NSMutableDictionary * value)
    {
        //get all filter data
        
        //TODO : reload Data
        [self updateBasePredicateForSelectedIndex];
        
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
    IMEditRegistrationVC *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IMEditRegistrationVC"];
    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
    navCon.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
    [self presentViewController:navCon animated:YES completion:nil];
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
        self.title = @"Incomplete Registration";
    }else if (index == 1) {
        self.title = @"Pending Registration";
    }else {
        self.title = @"Local Migrant Data";
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
    
    self.navigationItem.rightBarButtonItems = @[itemCreate,itemFilter];
    
}

@end