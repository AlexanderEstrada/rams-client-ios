//
//  IMMigrantViewController.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 4/15/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMMigrantViewController.h"
#import "IMRegistrationListVC.h"
#import "IMRegistrationFilterDataVC.h"
#import "Migrant.h"
#import "IMEditRegistrationVC.h"
#import "IMRegistrationFilterVCViewController.h"

@interface IMMigrantViewController ()<UIPopoverControllerDelegate, UITabBarControllerDelegate>

//View Controllers
@property (nonatomic, strong) IMRegistrationFilterDataVC * filterChooser;
@property (nonatomic, strong) UIPopoverController *popover;

//Programmatic Data
@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end

@implementation IMMigrantViewController

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
        self.filterChooser = [[IMRegistrationFilterDataVC alloc] initWithAction:^(NSPredicate *basePredicate){
            [self.popover dismissPopoverAnimated:YES];
            self.popover = nil;
            if (basePredicate) {
                
                //                self.basePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[self.basePredicate,basePredicate]];
                if (self.selectedIndex == 0) {
                    self.basePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"complete = NO"],basePredicate]];
                }else if(self.selectedIndex == 1){
                    self.basePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"complete = YES"],basePredicate]];
                }else {
                    self.basePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"complete = %@",@(REG_STATUS_LOCAL)],basePredicate]];
                }
                
            }
            
        }];
        
        self.filterChooser.view.tintColor = [UIColor IMMagenta];
    }
    
    self.filterChooser.doneCompletionBlock = ^(NSMutableDictionary * value)
    {
        //get all filter data
        
        //TODO : reload Data
        
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
