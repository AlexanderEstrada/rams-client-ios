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

@interface IMMigrantViewController ()<UIPopoverControllerDelegate, UITabBarControllerDelegate>

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
            self.basePredicate = vc.basePredicate =  [NSPredicate predicateWithFormat:@"active = YES"];
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
        self.filterChooser = [[IMMigrantFilterDataVC alloc] initWithAction:^(NSPredicate *basePredicate){
            [self.popover dismissPopoverAnimated:YES];
            self.popover = nil;
            if (basePredicate) {
                if (self.selectedIndex == 0) {
                    self.basePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[basePredicate]];
                }
            }
            
        }];
        
        self.filterChooser.view.tintColor = [UIColor IMMagenta];
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
        self.title = @"Migrant List";
    }else if (index == 1) {
        self.title = @"tab 2";
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
