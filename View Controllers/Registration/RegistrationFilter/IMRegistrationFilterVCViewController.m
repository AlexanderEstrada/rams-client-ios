//
//  IMRegistrationFilterVCViewController.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 4/10/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMRegistrationFilterVCViewController.h"
#import "IMDBMAnager.h"
#import "IMFormCell.h"
#import "IMTableHeaderView.h"
#import "IMOptionChooserViewController.h"
#import "IMRegistrationFilterDataVC.h"


#define Const_Country @"Country = ";
#define Const_Location @"Location = ";
#define Const_Name @"name = ";
#define Const_UNHCR @"unhcr = ";

@interface IMRegistrationFilterVCViewController ()<UIPopoverControllerDelegate, UITabBarControllerDelegate>

//View Controllers
@property (nonatomic, strong) IMRegistrationFilterDataVC *filterChooser;
@property (nonatomic, strong) UIPopoverController *popover;

//Programmatic Data
@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end


@implementation IMRegistrationFilterVCViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark UITabBarControllerDelegate
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    [self forwardBasePredicate:viewController];
    return YES;
}

- (void)forwardBasePredicate:(UIViewController *)viewController
{
    if (!viewController) viewController = [self selectedViewController];
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
            self.basePredicate = basePredicate;
        }];
        
        self.filterChooser.view.tintColor = [UIColor IMLightBlue];
    }
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.filterChooser];
    
    if (!self.popover) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:navController];
        self.popover.delegate = self;
    }
    
    [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(search)];
    
    UIViewController *vc = [self.childViewControllers lastObject];
    if ([vc isKindOfClass:[IMRegistrationFilterDataVC class]]) {
        IMRegistrationFilterDataVC *filVC = (IMRegistrationFilterDataVC *)vc;
        filVC.country = self.country;
        filVC.detentionLocation = self.detentionLocation;
        filVC.name = self.name;
        filVC.gender = self.gender;
    }
    
}

- (void) search
{

    NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Registration"];
    
    /* search
     1. Country
     2. Location
     3. Name/ UNCHR Document
     
     
     */
    NSString * name;
//    self.activePredicate = [NSPredicate predicateWithFormat:@"complete = 2"];
    
    //check if has number in string
    NSString * query;
    if ([self isNumeric:name]) {
        //todo this is UNHCR Document
        
    }
    //string request

    if (self.country) {
       request.predicate =  [NSPredicate predicateWithFormat:@"country = %@",self.country];
        query = @"Country = %@";
    }
    
    if (self.detentionLocation) {
         request.predicate =  [NSPredicate predicateWithFormat:@"country = %@ && detentionLocation = %@",@(REG_STATUS_LOCAL)];
    }
    
    if (self.name) {
         request.predicate =  [NSPredicate predicateWithFormat:@"complete = %@",@(REG_STATUS_LOCAL)];
    }
    
    if (self.gender) {
         request.predicate =  [NSPredicate predicateWithFormat:@"complete = %@",@(REG_STATUS_LOCAL)];
    }
    
    
   
    
    
    
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO]];
    request.returnsObjectsAsFaults = YES;
    
    NSError *error;
    NSDictionary *data = [[context executeFetchRequest:request error:&error] mutableCopy];
    self.result = data;
}

- (void) cancel
{
    //reset all value
    self.country = Nil;
    self.detentionLocation = Nil;
    self.name = self.gender = Nil;
    self.result = Nil;
    
}

-(BOOL)isNumeric:(NSString*)inputString{
    BOOL isValid = NO;
    NSCharacterSet *alphaNumbersSet = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *stringSet = [NSCharacterSet characterSetWithCharactersInString:inputString];
    isValid = [alphaNumbersSet isSupersetOfSet:stringSet];
    return isValid;
}

#pragma mark UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
