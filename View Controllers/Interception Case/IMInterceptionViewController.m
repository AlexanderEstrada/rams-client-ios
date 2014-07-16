//
//  IMInterceptionViewController.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/10/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMInterceptionViewController.h"
#import "IMInterceptionMapVC.h"
#import "IMInterceptionListVC.h"
#import "IMInterceptionFetcher.h"
#import "NSDate+Relativity.h"
#import "IMDBManager.h"
#import "InterceptionData+Extended.h"
#import "IMInterceptionDataSource.h"
#import "IMEditInterceptionVC.h"
#import "IMDatePickerVC.h"
#import "IMInterceptionDetailsVC.h"
#import "UIImage+ImageEffects.h"
#import "UIImage+ImageUtils.h"
#import "IMAuthManager.h"


@interface IMInterceptionViewController ()<IMInterceptionDataSource, IMInterceptionDelegate, UIPopoverControllerDelegate,UIAlertViewDelegate>

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) BOOL listViewHidden;

@property (nonatomic, strong) IMInterceptionMapVC *mapVC;
@property (nonatomic, strong) IMInterceptionListVC *listVC;

@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic, strong) NSDate *selectedDate;

@property (nonatomic, strong) UISegmentedControl *segmentFilter;
@property (nonatomic, strong) UIPopoverController *popover;

@property (nonatomic, strong) UIBarButtonItem *itemSwitchView;

@property (nonatomic) int selectedSegmentIndex;
@property (nonatomic, strong) UIBarButtonItem *itemSegment;

@property (nonatomic, strong) NSArray *data;

@end


@implementation IMInterceptionViewController

- (void)databaseChanged:(NSNotification *)notification
{
    self.data = nil;
    [self.mapVC reloadData];
    if (!self.listViewHidden){
        [self.listVC reloadData];
    }else self.listViewContainer.frame = [self listViewContainerFrame:self.listViewHidden];
    
}

- (void)showNewInterceptionCase
{
    //TODO : check if apps already competely synch, case not, then show alert to synch the apps
    if (![[NSUserDefaults standardUserDefaults] objectForKey:IMLastSyncDate]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm Data Updates" message:@"You are about to start data updates. Internet connection is required and may take some time to finish.\nContinue updating application data?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
        alert.tag = IMAlertNeedSynch_Tag;
        [alert show];
        return;
    };
    
    [self showInterceptionVCWithData:nil];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == IMAlertNeedSynch_Tag && buttonIndex != [alertView cancelButtonIndex]) {
        
        [self.sideMenuDelegate openSynchronizationDialog:nil];
        
    }
    
}

- (void)showInterceptionVCWithData:(InterceptionData *)interceptionData
{
    IMEditInterceptionVC *vc = [[IMEditInterceptionVC alloc] initWithStyle:UITableViewStyleGrouped];
    vc.interceptionData = interceptionData;
    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
    navCon.navigationBar.tintColor = [UIColor IMRed];
    
    [self presentViewController:navCon animated:YES completion:nil];
}

- (NSDate *)fetchInterceptionDate:(BOOL)maxDate
{
    NSManagedObjectContext *context = [[IMDBManager sharedManager] localDatabase].managedObjectContext;
    NSExpression *dateKeyPath = [NSExpression expressionForKeyPath:@"interceptionDate"];
    NSExpression *dateExpression = [NSExpression expressionForFunction:(maxDate ? @"max:" : @"min:") arguments:@[dateKeyPath]];

    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
    [expressionDescription setExpression:dateExpression];
    [expressionDescription setExpressionResultType:NSDateAttributeType];
    [expressionDescription setName:@"interceptionDate"];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"InterceptionData"];
    [request setPropertiesToFetch:@[expressionDescription]];
    [request setResultType:NSDictionaryResultType];
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    NSDate *date = [[results lastObject] objectForKey:@"interceptionDate"];
    
    if (!date) {
        date = maxDate ? [NSDate date] : [[NSDate date] dateBySubstractingAgeElement:1];
    }
    
    return date;
}

- (void)showDateFilter
{
    if (self.popover) return;
    
    IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithDoneHandler:^(NSDate *selectedDate){        
        self.basePredicate = [NSPredicate predicateWithFormat:@"interceptionDate >= %@", selectedDate];
        [self.segmentFilter setSelectedSegmentIndex:-1];
        self.data = nil;
        [self.mapVC reloadData];
        if (!self.listViewHidden) [self.listVC reloadData];
        
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
        self.selectedSegmentIndex = self.segmentFilter.selectedSegmentIndex;
    } onCancel:^{
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
        self.segmentFilter.selectedSegmentIndex = self.selectedSegmentIndex;
    }];
    
    datePicker.title = @"Select Starting Date";
    datePicker.maximumDate = [self fetchInterceptionDate:YES];
    datePicker.minimumDate = [self fetchInterceptionDate:NO];
    datePicker.modalInPopover = YES;
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:datePicker];
    navCon.navigationBar.tintColor = [UIColor IMRed];
    self.popover = [[UIPopoverController alloc] initWithContentViewController:navCon];
    self.popover.delegate = self;
    [self.popover presentPopoverFromBarButtonItem:self.itemSegment permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)toggleListView
{
    self.listViewHidden = !self.listViewHidden;
}

- (void)updateData:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.basePredicate = [NSPredicate predicateWithFormat:@"active = YES"];
            break;
        case 1:
            self.basePredicate = [NSPredicate predicateWithFormat:@"interceptionDate >= %@", [[NSDate date] dateBySubstractingDayElement:30]];
            break;
        case 2:
            self.basePredicate = [NSPredicate predicateWithFormat:@"interceptionDate >= %@", [[NSDate date] dateBySubstractingDayElement:90]];
            break;
    }
    
    if (self.selectedSegmentIndex != sender.selectedSegmentIndex && sender.selectedSegmentIndex < 3) {
        self.selectedSegmentIndex = sender.selectedSegmentIndex;
        self.data = nil;
        [self.mapVC reloadData];
        if (!self.listViewHidden) [self.listVC reloadData];
    }else if (sender.selectedSegmentIndex == 3) {
        [self showDateFilter];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}


#pragma mark IMInterceptionDataSource
- (NSArray *)interceptionDataByLocation
{
    if (!self.data) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"InterceptionData"];
        if (self.basePredicate) request.predicate = self.basePredicate;
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"interceptionDate" ascending:YES]];
        
        NSError *error;
        NSArray *results = [[IMDBManager sharedManager].localDatabase.managedObjectContext executeFetchRequest:request error:&error];
        NSMutableArray *finalResults = [NSMutableArray array];
        
        if (!self.basePredicate) {
            for (InterceptionData *data in results) {
                if (data.active) {
                    [finalResults addObject:data];
                }
            }
        }else {
            finalResults = [results mutableCopy];
        }
        
        NSMutableArray *groupedResults = [NSMutableArray array];
        NSArray *locations = [finalResults valueForKeyPath:@"@distinctUnionOfObjects.interceptionLocation"];
        
        for (InterceptionLocation *location in locations) {
            NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"interceptionLocation = %@", location];
            NSArray *dataPerLocation = [finalResults filteredArrayUsingPredicate:filterPredicate];
            NSDictionary *dict = @{kLocationGroupTitle: location.name,
                                   kLocationGroupLatitude: location.latitude,
                                   kLocationGroupLongitude: location.longitude,
                                   kLocationGroupData: dataPerLocation};
            [groupedResults addObject:dict];
        }
        
        self.data = [groupedResults sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:kLocationGroupTitle ascending:YES]]];
    }
    
    return self.data;
}


#pragma mark IMInterceptionDelegate
- (void)showDetailsForInterceptionData:(InterceptionData *)data
{
    [self.mapVC hidePopover];
    
    IMInterceptionDetailsVC *vc = [[IMInterceptionDetailsVC alloc] initWithInterceptionData:data delegate:self];
    vc.allowsEditing = YES;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showEditForInterceptionData:(InterceptionData *)data
{
    [self showInterceptionVCWithData:data];
}

- (void)willShowPopoverOnMap
{
    if (!self.listViewHidden) self.listViewHidden = YES;
}


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.tintColor = [UIColor IMRed];
    self.navigationController.toolbar.tintColor = [UIColor IMRed];
    self.view.tintColor = [UIColor IMRed];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.hidesWhenStopped = YES;
    
    if ([IMAuthManager sharedManager].activeUser.roleInterception) {
        UIBarButtonItem *itemNew = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                 target:self
                                                                                 action:@selector(showNewInterceptionCase)];
        self.navigationItem.rightBarButtonItem = itemNew;
    }
    
    self.segmentFilter = [[UISegmentedControl alloc] initWithItems:@[@"All Active", @"Last 30 Days", @"Last 90 Days", @"Custom"]];
    self.segmentFilter.selectedSegmentIndex = 0;
    [self.segmentFilter addTarget:self action:@selector(updateData:) forControlEvents:UIControlEventValueChanged];
    self.itemSegment = [[UIBarButtonItem alloc] initWithCustomView:self.segmentFilter];
    
    self.itemSwitchView = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-list"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleListView)];
    UIBarButtonItem *itemLoading = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    self.toolbarItems = @[itemLoading, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], self.itemSegment, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], self.itemSwitchView];
    self.selectedSegmentIndex = 0;
    
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.toolbar.barTintColor = [UIColor whiteColor];
    
    self.basePredicate = [NSPredicate predicateWithFormat:@"active = YES"];
    self.listViewContainer.backgroundColor = [UIColor clearColor];
    [self setupChildViewControllers];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseChanged:) name:IMDatabaseChangedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO];
    
  }

- (void)setupChildViewControllers
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //setup map
        self.mapVC = [[IMInterceptionMapVC alloc] init];
        self.mapVC.delegate = self;
        self.mapVC.dataSource = self;
        
        [self addChildViewController:self.mapVC];
        self.mapVC.view.frame = self.mapViewContainer.bounds;
        [self.mapViewContainer addSubview:self.mapVC.view];
        [self.mapVC didMoveToParentViewController:self];
        
        //setup list
        self.listVC = [[IMInterceptionListVC alloc] initWithStyle:UITableViewStylePlain];
        self.listVC.dataSource = self;
        self.listVC.delegate = self;
        
        [self addChildViewController:self.listVC];
        self.listVC.view.frame = self.listViewContainer.bounds;
        [self.listViewContainer addSubview:self.listVC.view];
        [self.listVC didMoveToParentViewController:self];
        
        self.listViewContainer.hidden = YES;
        
        self.listViewHidden = YES;
    });
}

- (void)setListViewHidden:(BOOL)listViewHidden
{
   self.listViewContainer.hidden = _listViewHidden = listViewHidden;

    if (!self.listViewHidden) [self.mapVC hidePopover];
      self.listViewContainer.frame = [self listViewContainerFrame:self.listViewHidden];
    
    [UIView animateWithDuration:IMRootViewAnimationDuration animations:^{
        self.listViewContainer.frame = [self listViewContainerFrame:self.listViewHidden];
        self.listViewContainer.alpha = 1;
    } completion:^(BOOL finished){
        if (!listViewHidden) {
            self.itemSwitchView.image = [UIImage imageNamed:@"icon-list-selected"];
            [self.listVC reloadData];
        }else {
            self.itemSwitchView.image = [UIImage imageNamed:@"icon-list"];
            [self.listVC viewDidDisappear:YES];
        }
    }];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.listViewHidden = self.listViewHidden;
}

- (CGRect)listViewContainerFrame:(BOOL)hidden
{
    if (hidden) {
        return CGRectMake(self.view.frame.size.width + self.listViewContainer.frame.size.width, 0, self.listViewContainer.frame.size.width, self.listViewContainer.frame.size.height);
    }
    
    return CGRectMake(self.view.frame.size.width - self.listViewContainer.frame.size.width, 0, self.listViewContainer.frame.size.width, self.listViewContainer.frame.size.height);
}

@end