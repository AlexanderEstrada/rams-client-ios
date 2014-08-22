//
//  IMFamilyViewController.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 7/31/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMFamilyViewController.h"
#import "IMFamilyListVC.h"
#import "IMFormCell.h"
#import "Migrant+Extended.h"
#import "Child+Extended.h"
#import <QuickLook/QuickLook.h>
#import "NSDate+Relativity.h"
#import "MBProgressHUD.h"
#import "IMDBManager.h"
#import "IMFamilyDataViewController.h"
#import "FamilyRegister.h"
#import "FamilyRegister+Extended.h"
#import "Migrant+Extended.h"
#import "DataProvider.h"

typedef enum : NSUInteger {
    section_family_information = 0,
    section_head_of_family,
    section_spouse,
    section_guadian,
    section_childs,
    section_grand_father,
    section_grand_mother,
    section_other_extended_member
    
} section_type;

#define TOTAL_SECTION 8

#define cellName @"cellFamily"

@interface IMFamilyViewController ()<UITableViewDataSource, UITableViewDelegate,QLPreviewControllerDelegate,QLPreviewControllerDataSource,UIGestureRecognizerDelegate,MBProgressHUDDelegate>

@property (nonatomic,strong) MBProgressHUD *HUD;
@property (nonatomic, strong) NSMutableArray *previewingPhotos;
@property (nonatomic, strong) NSMutableArray *childData;
@property (nonatomic, strong) NSMutableArray *migrantData;
@property (nonatomic, strong) NSArray *familyRegister;
@property (nonatomic) int tapCount;
@property (nonatomic) BOOL reloadingData;
@property (nonatomic, strong) NSOperationQueue *thumbnailQueue;
@end

@implementation IMFamilyViewController

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    [_HUD removeFromSuperview];
}

- (IBAction)addFamilyRegister:(id)sender {
   
    IMFamilyDataViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IMFamilyDataViewController"];
    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
    navCon.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
    [self presentViewController:navCon animated:YES completion:nil];
    
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
    
    //set default value
    _tapCount = 0;
    
//    UIBarButtonItem *clearButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStyleBordered target:self action:@selector(onClear)];
//    
//    self.navigationItem.rightBarButtonItems = @[self.addButton ,clearButton];
    
    //get all data from database
    
    self.thumbnailQueue = [[NSOperationQueue alloc] init];
    self.thumbnailQueue.maxConcurrentOperationCount = 3;
}

- (void)onClear
{
    //clear database
    NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"FamilyRegister"];
    
    request.returnsObjectsAsFaults = YES;
    NSError *error;
    NSArray * familyRegister = [context executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"Error : %@",[error description]);
        
    }else {
        for (FamilyRegister * famReg in familyRegister) {
            //delete all data
            [context deleteObject:famReg];
        }
        if (![context save:&error]) {
            NSLog(@"Error : %@",[error description]);
        }
    }
    
    [self reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self reloadData];
}

- (void)executing
{
    
    if(!self.reloadingData){
        self.reloadingData = YES;
        
        NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"FamilyRegister"];
        
        request.returnsObjectsAsFaults = YES;
        NSError *error;
        self.familyRegister = [context executeFetchRequest:request error:&error];
        
        if (error) {
            NSLog(@"Error : %@",[error description]);
        }
        
        
        
        [_HUD hideUsingAnimation:YES];
        [self.tableView reloadData];
        self.reloadingData = NO;
        
    }
}


- (void)reloadData
{
    // Show progress window
    if (!_HUD) {
        // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
        _HUD = [[MBProgressHUD alloc] initWithView:self.view];
    }
    
    
    
    // Add HUD to screen
    [self.view addSubview:_HUD];
    
    // Regisete for HUD callbacks so we can remove it from the window at the right time
    _HUD.delegate = self;
    
    _HUD.labelText = @"Reloading Data...";
    
    // Show the HUD while the provided method executes in a new thread
    [_HUD showUsingAnimation:YES];
    
    [self executing];
}

#pragma mark QLPreviewControllerDelegate
- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
    self.previewingPhotos = nil;
}

#pragma mark QLPreviewControllerDataSource
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return [self.previewingPhotos count];
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    controller.title = self.migrant.fullname;
    
    return [NSURL fileURLWithPath:self.previewingPhotos[index]];
}

- (void)showPhotoPreview:(NSIndexPath *)indexPath
{
    if (!self.previewingPhotos) {
        self.previewingPhotos = [NSMutableArray array];
    }
    
    if ([self.previewingPhotos count]) {
        //remove old photo before we used it
        [self.previewingPhotos removeAllObjects];
    }
    
    FamilyRegister * familyRegister = [self.familyRegister objectAtIndex:indexPath.row];
    
    if (familyRegister.photograph)[self.previewingPhotos addObject:familyRegister.photograph];
    
    QLPreviewController *previewController = [[QLPreviewController alloc] init];
    previewController.delegate = self;
    previewController.dataSource = self;
    
    [self presentViewController:previewController animated:YES completion:^{
        previewController.view.tintColor = [UIColor IMMagenta];
        previewController.view.backgroundColor = [UIColor blackColor];
    }];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.familyRegister count]?[self.familyRegister count]:1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *headerIdentifier = @"familyHeader";
    
    
    //implement header
    IMTableHeaderView * headerView = [[IMTableHeaderView alloc] initWithTitle:@"" actionTitle:nil alignCenterY:YES reuseIdentifier:headerIdentifier];
    headerView.labelTitle.font = [UIFont thinFontWithSize:28];
    headerView.labelTitle.textAlignment = NSTextAlignmentCenter;
    headerView.labelTitle.textColor = [UIColor blackColor];
    headerView.backgroundView = [[UIView alloc] init];
    headerView.backgroundView.backgroundColor = [UIColor whiteColor];
    
    
    
    if (section == section_family_information) {
        headerView.labelTitle.text = @"Family Information";
    }
    
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellName forIndexPath:indexPath];
    if (![self.familyRegister count]) {
        cell.textLabel.text = @"No Data";
        cell.imageView.image = Nil;
    }else {
        NSLog(@"There is data on database");
        
        if (indexPath.section == 0 ) {
            FamilyRegister * familyRegister = self.familyRegister[indexPath.row];
            if (familyRegister) {
                
                
                NSString * mesage = [NSString stringWithFormat:@"Family of %@ (%@)",familyRegister.headOfFamilyName,familyRegister.headOfFamilyId];
                cell.textLabel.text = mesage;
                if (familyRegister.photographThumbnail) {
                    cell.imageView.image = familyRegister.photographImageThumbnail;
                    
                    if (cell.imageView.image) {
                        cell.imageView.userInteractionEnabled = YES;
                    }
                    
                }
            }
        }
        
        
    }
    
    
    
    return cell;
    
}



- (void)singleTap:(NSIndexPath *)indexPath {
    if ([self.familyRegister count]) {
        if (indexPath.section == 0) {
            
            IMFamilyDataViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IMFamilyDataViewController"];
            //get migrant data
            FamilyRegister * familyRegister = self.familyRegister[indexPath.row];
            
            if (familyRegister) {
                vc.familyRegister = familyRegister;
            }
            
            UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
            navCon.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
            
            [self.navigationController presentViewController:navCon animated:YES completion:Nil];
            
            //reset tap count
            _tapCount =0;
            
        }
    }else NSLog(@"indexPath.row : %i -- do nothing",indexPath.row);
    
    
}
- (void)doubleTap:(NSIndexPath *)indexPath {
    
    if ([self.familyRegister count]) {
        [self performSelector:@selector(showPhotoPreview:) withObject: indexPath];
    }else{
        NSLog(@"indexPath.row : %i -- do nothing",indexPath.row);
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    @synchronized(self) {
        //increase tap counter
        _tapCount++;
        switch (_tapCount)
        {
            case 1: //single tap
                [self performSelector:@selector(singleTap:) withObject: indexPath afterDelay: 0.2];
                break;
            case 2: //double tap
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(singleTap:) object:indexPath];
                [self performSelector:@selector(doubleTap:) withObject: indexPath];
                break;
            default:
                break;
        }
        if (_tapCount>=2) _tapCount=0;
        
    }
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
