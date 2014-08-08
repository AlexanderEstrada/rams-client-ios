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

typedef enum : NSUInteger {
    section_personal = 0,
    section_father,
    section_mother,
    section_spouse,
    section_childs
} section_type;

#define TOTAL_SECTION 5

@interface IMFamilyViewController ()<UITableViewDataSource, UITableViewDelegate,QLPreviewControllerDelegate,QLPreviewControllerDataSource,UIGestureRecognizerDelegate,MBProgressHUDDelegate>
@property (nonatomic, strong) NSMutableArray *childData;
@property (nonatomic, strong) NSMutableArray *previewingPhotos;
@property (nonatomic) int tapCount;
@property (nonatomic,strong) MBProgressHUD *hud;
@property (nonatomic,strong) UIBarButtonItem *itemUploadAll;
@property (nonatomic) BOOL next;

@end

@implementation IMFamilyViewController


- (void)setMigrant:(Migrant *)migrant
{
    _migrant = migrant;
     self.save.enabled = YES;
    
    [self.tableView reloadData];
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
    
    self.childData = [[self.migrant.familyData.childs allObjects] mutableCopy];
    
    
    
    self.navigationController.navigationBar.tintColor = [UIColor IMLightBlue];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.save =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(onSave)];
    
//    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel)];
    //add upload icon
    self.itemUploadAll= [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-upload-small"] style:UIBarButtonItemStylePlain target:self action:@selector(uploadAll:)];
    self.itemUploadAll.enabled = FALSE;
    
    self.navigationItem.rightBarButtonItems = @[self.itemUploadAll,self.save];
//    self.navigationItem.leftBarButtonItems = @[cancelBtn];
    
    //set to no until user add migrant
    self.save.enabled = NO;
    
    //set default value
    _tapCount = 0;
    
    if (!_hud) {
        // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
        _hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    }
    
    
}

- (void) uploadAll:(UIBarButtonItem *)sender
{
    //show confirmation
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload all Family Data"
                                                    message:@"All your Family Data will be uploaded and you need internet connection to do this.\nContinue upload all Family Data?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Yes", nil];
    alert.tag = IMAlertUpload_Tag;
    [alert show];
    
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == IMAlertUpload_Tag && buttonIndex != [alertView cancelButtonIndex]) {
        //start uploading
        if (!_hud) {
            // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
            _hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        }
        
        // Back to indeterminate mode
        _hud.mode = MBProgressHUDModeIndeterminate;
        
        // Add HUD to screen
        [self.navigationController.view addSubview:_hud];
        
        
        
        // Regisete for HUD callbacks so we can remove it from the window at the right time
        _hud.delegate = self;
        
        _hud.labelText = @"Uploading Data";
        
        
        // Show the HUD while the provided method executes in a new thread
        [_hud showWhileExecuting:@selector(uploading) onTarget:self withObject:nil animated:YES];
    }
    
    //         finish blocking
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.sideMenuDelegate disableMenu:NO];
    
    //reset flag
    self.next = TRUE;
    
}

- (void) uploading
{
    NSLog(@"Uploading Family Data");
    
     @try {
         self.next = FALSE;
         //disable Menu
         [self.sideMenuDelegate disableMenu:YES];
         //show data loading view until upload is finish
         //start blocking
         [UIApplication sharedApplication].idleTimerDisabled = YES;
    //formating data
    NSDictionary * dict = [self.migrant format];
         
         //send formatted data to server
         [self sendFamilyData:dict];
         while(self.next ==FALSE){
             usleep(5000);
         }

     }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }

}


- (void) sendFamilyData:(NSDictionary *)params
{
    
    NSLog(@"params : %@",[params description]);
    
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client postJSONWithPath:@"family/save"
                  parameters:params
                     success:^(NSDictionary *jsonData, int statusCode){
                         [self showAlertWithTitle:@"Upload Success" message:nil];
                         NSLog(@"Upload Success");
                     }
                     failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                         [self showAlertWithTitle:@"Upload Failed" message:@"Please check your network connection and try again. If problem persist, contact administrator."];
                         NSLog(@"Upload Fail : %@",[error description]);
                     }];
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if (self.childData) {
        self.childData = [[self.migrant.familyData.childs allObjects] mutableCopy];
    }
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (self.migrant?TOTAL_SECTION:1);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self familyRowFormula:section];
}

- (NSInteger)familyRowFormula:(NSInteger)section{
    
    NSInteger totalSection =0;
    switch (section) {
        case section_personal:
        case section_father:
        case section_mother:
        case section_spouse:
            totalSection +=2;
            break;
        case section_childs :
            totalSection +=([self.migrant.familyData.childs count] * 2);
            break;
        default:
            //only show defined section
            break;
    }
    
    return totalSection;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 40;
}

- (void) headerTap:(NSInteger)section
{
    NSLog(@"section : %i",section);
    
    //forward function
    [self singleTap:[NSIndexPath indexPathForRow:0 inSection:section]];
    
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
    
    
    
    if (section == section_personal) {
    
        headerView.labelTitle.text = @"Personal Information";
//        [headerView.buttonAction addTarget:self action:@selector(headerTap:) forControlEvents:UIControlEventApplicationReserved];
    }else if (section == section_father){
        headerView.labelTitle.text = @"Father";
//        [headerView.buttonAction addTarget:self action:@selector(headerTap:) forControlEvents:UIControlEventApplicationReserved];
    }else if (section == section_mother){
// [headerView.buttonAction addTarget:self action:@selector(headerTap:) forControlEvents:UIControlEventApplicationReserved];
        headerView.labelTitle.text = @"Mother";
    }else if (section == section_spouse){
// [headerView.buttonAction addTarget:self action:@selector(headerTap:) forControlEvents:UIControlEventApplicationReserved];
        headerView.labelTitle.text = @"Spouse";
    }else if (section == section_childs){
        headerView.labelTitle.text = @"Childs";
        //implement action button
        headerView.buttonAction = [UIButton buttonWithType:UIButtonTypeContactAdd];
        [headerView.buttonAction setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        headerView.buttonAction.tag = section;
        [headerView.buttonAction setTitle:Nil forState:UIControlStateNormal];
        [headerView.buttonAction setTranslatesAutoresizingMaskIntoConstraints:NO];
        [headerView.contentView addSubview:headerView.buttonAction];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAction attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:-20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
        [headerView.buttonAction addTarget:self action:@selector(addMoreChild:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return headerView;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    label.textAlignment = NSTextAlignmentCenter;
    
    
    switch (section) {
        case section_personal:
        case section_father:
        case section_mother:
        case section_spouse:
        case section_childs :
            label.text = [NSString stringWithFormat:@"This is Footer"];
            break;
        default:
            //only show defined section
            label.text = [NSString stringWithFormat:@"This is Default Footer"];
            break;
    }
    
    label.textColor = [UIColor darkGrayColor];
    
    return label;
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
    
    Migrant * tmp = Nil;
    Child *child = Nil;
    if (indexPath.section == section_childs) {
        
        NSInteger index = indexPath.row/2;
        child = [ self.childData objectAtIndex:index];
        tmp = [Migrant migrantWithId:child.registrationNumber inContext:self.migrant.managedObjectContext];
    }
    
    switch (indexPath.section) {
        case section_personal:
            //add all photo
            if (self.migrant.biometric.photograph)[self.previewingPhotos addObject:self.migrant.biometric.photograph];
            break;
        case section_father:
            //get father
            tmp = Nil;
            tmp = [Migrant migrantWithId:self.migrant.familyData.father inContext:self.migrant.managedObjectContext];
            if (tmp && tmp.biometric.photograph) {
                //add all photo
                [self.previewingPhotos addObject:tmp.biometric.photograph];
            }
            break;
        case section_mother:
            //get mother
            tmp = Nil;
            tmp = [Migrant migrantWithId:self.migrant.familyData.mother inContext:self.migrant.managedObjectContext];
            if (tmp && tmp.biometric.photograph) {
                //add all photo
                [self.previewingPhotos addObject:tmp.biometric.photograph];
            }
            break;
            
        case section_spouse:
            //get spouse
            tmp = Nil;
            tmp = [Migrant migrantWithId:self.migrant.familyData.spouse inContext:self.migrant.managedObjectContext];
            if (tmp && tmp.biometric.photograph) {
                //add all photo
                [self.previewingPhotos addObject:tmp.biometric.photograph];
            }
            break;
            
        case section_childs :
        default:
            //get childs
            if (tmp && tmp.biometric.photograph) {
                //add all photo
                [self.previewingPhotos addObject:tmp.biometric.photograph];
            }
            //only show defined section
            break;
    }
    
    
    
    QLPreviewController *previewController = [[QLPreviewController alloc] init];
    previewController.delegate = self;
    previewController.dataSource = self;
    
    [self presentViewController:previewController animated:YES completion:^{
        previewController.view.tintColor = [UIColor IMMagenta];
        previewController.view.backgroundColor = [UIColor blackColor];
    }];
    
    
    //release memory
    if (tmp) {
        tmp = Nil;
    }
    if (child) {
        child = Nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"familyCellIdentifier";
    
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    cell.backgroundColor = [UIColor clearColor];
    cell.tintColor = [UIColor IMLightBlue];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.textColor = [UIColor IMRed];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    Migrant * tmp = Nil;
    Child *child = Nil;
    if (indexPath.section == section_childs) {

       //reset data
        self.childData = [[self.migrant.familyData.childs allObjects] mutableCopy];
        
        NSInteger index = indexPath.row/2;
        //TODO : need to check
        child = [ self.childData objectAtIndex:index];
        tmp = [Migrant migrantWithId:child.registrationNumber inContext:self.migrant.managedObjectContext];
    }
    
    switch (indexPath.section) {
        case section_personal:{
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Registration Number";
                cell.detailTextLabel.text = self.migrant.registrationNumber;
                
                
            }else if (indexPath.row ==1){
                cell.textLabel.text = @"Name";
                cell.detailTextLabel.text = [self.migrant fullname];
                if (self.migrant.biometric.photographImageThumbnail) {
                    cell.imageView.image = self.migrant.biometric.photographImageThumbnail;
                    
                    if (cell.imageView.image) {
                        cell.imageView.userInteractionEnabled = YES;
                    }
                    
                }
                
            }
            break;
        }
        case section_father:{
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Registration Number";
                cell.detailTextLabel.text = self.migrant.familyData.father;
            }else if (indexPath.row ==1){
                cell.textLabel.text = @"Name";
                //get father
                tmp = Nil;
                tmp = [Migrant migrantWithId:self.migrant.familyData.father inContext:self.migrant.managedObjectContext];
                cell.detailTextLabel.text = [tmp fullname];
                if (tmp.biometric.photographImageThumbnail) {
                    cell.imageView.image = tmp.biometric.photographImageThumbnail;
                    
                    if (cell.imageView.image) {
                        cell.imageView.userInteractionEnabled = YES;
                    }
                    
                }
                
            }
            
            break;
        }
        case section_mother:{
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Registration Number";
                cell.detailTextLabel.text = self.migrant.familyData.mother;
                
            }else if (indexPath.row ==1){
                
                cell.textLabel.text = @"Name";
                tmp = Nil;
                tmp = [Migrant migrantWithId:self.migrant.familyData.mother inContext:self.migrant.managedObjectContext];
                cell.detailTextLabel.text = [tmp fullname];
                if (tmp.biometric.photographImageThumbnail) {
                    cell.imageView.image = tmp.biometric.photographImageThumbnail;
                    
                    if (cell.imageView.image) {
                        cell.imageView.userInteractionEnabled = YES;
                    }
                    
                }
            }
            
            break;
        }
        case section_spouse:{
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Registration Number";
                cell.detailTextLabel.text = self.migrant.familyData.spouse;
                
            }else if (indexPath.row ==1){
                
                cell.textLabel.text = @"Name";
                tmp = Nil;
                tmp = [Migrant migrantWithId:self.migrant.familyData.spouse inContext:self.migrant.managedObjectContext];
                cell.detailTextLabel.text = [tmp fullname];
                if (tmp.biometric.photographImageThumbnail) {
                    cell.imageView.image = tmp.biometric.photographImageThumbnail;
                    
                    if (cell.imageView.image) {
                        cell.imageView.userInteractionEnabled = YES;
                    }
                    
                }
            }
            
            break;
        }
        case section_childs :
        default:
        {
            if (indexPath.row == 0 || ((indexPath.row %2) == 0)) {
                cell.textLabel.text = @"Registration Number";
                cell.detailTextLabel.text = tmp.registrationNumber;
                
            }else {
                
                cell.textLabel.text = @"Name";
                cell.detailTextLabel.text = [tmp fullname];
                if (tmp.biometric.photographImageThumbnail) {
                    cell.imageView.image = tmp.biometric.photographImageThumbnail;
                    
                    if (cell.imageView.image) {
                        cell.imageView.userInteractionEnabled = YES;
                    }
                    
                }
            }
            break;
        }
    }
    
    return cell;
}

- (void)singleTap:(NSIndexPath *)indexPath {
    
    @try {
        //show migrant list
        UICollectionViewFlowLayout *aFlowLayout = [[UICollectionViewFlowLayout alloc] init];
        [aFlowLayout setItemSize:CGSizeMake(320, 150)];
        [aFlowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
        
           IMFamilyListVC *list = [[IMFamilyListVC alloc] initWithCollectionViewLayout:aFlowLayout];
//        IMFamilyListVC *list = [self.storyboard instantiateViewControllerWithIdentifier:@"IMFamilyListVC"];
        

        
        
        if (!self.migrant && indexPath.section != 0) {
            [list setBasePredicate:Nil];
            //        list.basePredicate = Nil;
        }else{
            
            switch (indexPath.section) {
                case section_personal:
                    
                    //                list.basePredicate = Nil;
                    [list setBasePredicate:Nil];
                    break;
                case section_father:
                    //                list.basePredicate =[NSPredicate predicateWithFormat:@"bioData.dateOfBirth < %@  && bioData.gender = %@",self.migrant.bioData.dateOfBirth,@"Male"];
                    [list setBasePredicate:[NSPredicate predicateWithFormat:@"bioData.dateOfBirth < %@  && bioData.gender = %@",self.migrant.bioData.dateOfBirth,@"Male"]];
                    break;
                case section_mother:
                    //                list.basePredicate = [NSPredicate predicateWithFormat:@"bioData.dateOfBirth < %@ && bioData.gender = %@",self.migrant.bioData.dateOfBirth,@"Female"];
                    [list setBasePredicate:[NSPredicate predicateWithFormat:@"bioData.dateOfBirth < %@ && bioData.gender = %@",self.migrant.bioData.dateOfBirth,@"Female"]];
                    break;
                case section_spouse:
                    //                list.basePredicate = [NSPredicate predicateWithFormat:@"bioData.gender != %@",self.migrant.bioData.gender];
                    [list setBasePredicate:[NSPredicate predicateWithFormat:@"bioData.gender != %@",self.migrant.bioData.gender]];
                    break;
                case section_childs :
                default:
                    //                list.basePredicate = [NSPredicate predicateWithFormat:@"bioData.dateOfBirth < %@",self.migrant.bioData.dateOfBirth];
                    [list setBasePredicate:[NSPredicate predicateWithFormat:@"bioData.dateOfBirth < %@",self.migrant.bioData.dateOfBirth]];
                    break;
            }
        }
        
        list.onSelect = ^(Migrant *migrant)
        {
            switch (indexPath.section) {
                case section_personal:
                    //save migrant and reload data
                    self.migrant = migrant;
                    break;
                case section_father:
                    if (!self.migrant.familyData) {
                        self.migrant.familyData = [NSEntityDescription insertNewObjectForEntityForName:@"FamilyData" inManagedObjectContext:self.migrant.managedObjectContext];
                    }
                    self.migrant.familyData.father = migrant.registrationNumber;
                    break;
                case section_mother:
                    if (!self.migrant.familyData) {
                        self.migrant.familyData = [NSEntityDescription insertNewObjectForEntityForName:@"FamilyData" inManagedObjectContext:self.migrant.managedObjectContext];
                    }
                    self.migrant.familyData.mother = migrant.registrationNumber;
                    break;
                case section_spouse:
                    if (!self.migrant.familyData) {
                        self.migrant.familyData = [NSEntityDescription insertNewObjectForEntityForName:@"FamilyData" inManagedObjectContext:self.migrant.managedObjectContext];
                    }
                    self.migrant.familyData.spouse = migrant.registrationNumber;
                    break;
                case section_childs :
                default:
                {
                    Child *data = [Child childWithId:migrant.registrationNumber inContext:self.migrant.managedObjectContext];
                    if (!data) {
                        data = [NSEntityDescription insertNewObjectForEntityForName:@"Child" inManagedObjectContext:self.migrant.managedObjectContext];
                        data.registrationNumber = migrant.registrationNumber;
                    }
                    if (!self.migrant.familyData) {
                        self.migrant.familyData = [NSEntityDescription insertNewObjectForEntityForName:@"FamilyData" inManagedObjectContext:self.migrant.managedObjectContext];
                    }
                    //add child to family
                    [self.migrant.familyData addChildsObject:data];
                    //only show defined section
                    break;
                }
            }
            
            [self.tableView reloadData];
            
        };
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:list];
        [self presentViewController:navCon animated:YES completion:Nil];
        
        
        //    [self presentViewController:navCon animated:YES completion:nil];
        //    [self.parentViewController.navigationController pushViewController:list animated:YES];
        //     [self.parentViewController.navigationController pushViewController:list animated:YES];
        //reset tap count
        _tapCount =0;
    }
    @catch (NSException *exception) {
        NSLog(@"error on singleTap : %@",[exception description]);
    }
    
    
}

- (void)doubleTap:(NSIndexPath *)indexPath {
    NSLog(@"indexPath.row : %i",indexPath.row);
    
//    if (indexPath.row ==1){
        [self performSelector:@selector(showPhotoPreview:) withObject: indexPath];
//    }else {
//        [self singleTap:indexPath];
//    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    @synchronized(self) {
    //increase tap counter
    _tapCount++;
        NSLog(@"tapCount : %i",_tapCount);
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

- (void)saving
{
    NSError *error;
    //save to database
    if (![self.migrant.managedObjectContext save:&error]) {
        NSLog(@"Error saving context: %@", [error description]);
        [self showAlertWithTitle:@"Failed Saving Family Data" message:@"Please try again. If problem persist, please cancel and consult with administrator."];
    }else {
        //save database
        [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
        
        // sleep for synch
        sleep(5);
        
        //set upload button enable
        self.itemUploadAll.enabled = TRUE;
    }
    
}

- (void)onCancel
{
    [self.migrant.managedObjectContext rollback];
    NSError *error;
    //save to database
    if (![self.migrant.managedObjectContext save:&error]) {
        NSLog(@"Error saving context: %@", [error description]);
        [self showAlertWithTitle:@"Failed Saving Family Data" message:@"Please try again. If problem persist, please cancel and consult with administrator."];
    }
}

- (void)onSave
{
    
    // Add HUD to screen
    [self.view addSubview:_hud];
    
    // Regisete for HUD callbacks so we can remove it from the window at the right time
    _hud.delegate = self;
    
    _hud.labelText = @"Saving...";
    //    Show progress window
    [_hud showWhileExecuting:@selector(saving) onTarget:self withObject:nil animated:YES];
    
}
- (void)addMoreChild:(UIButton *)sender
{
    if (!self.migrant) {
        [self showAlertWithTitle:@"Failed Add Childs" message:@"Please fill Personal Information before adding child."];
        
        return;
    }
    //add special predicate for child, origin migrant age must be greater than child , at minimum 15 years
    //show migrant list
    UICollectionViewFlowLayout *aFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [aFlowLayout setItemSize:CGSizeMake(320, 150)];
    [aFlowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    IMFamilyListVC *list = [[IMFamilyListVC alloc] initWithCollectionViewLayout:aFlowLayout];
    list.basePredicate = [NSPredicate predicateWithFormat:@"bioData.dateOfBirth > %@",self.migrant.bioData.dateOfBirth];
    list.multiSelect = YES;
    
    list.onMultiSelect = ^(NSMutableArray *migrants)
    {
        for (Migrant * migrant in migrants) {
        
        Child *data = [Child childWithId:migrant.registrationNumber inContext:self.migrant.managedObjectContext];
        if (!data) {
            data = [NSEntityDescription insertNewObjectForEntityForName:@"Child" inManagedObjectContext:self.migrant.managedObjectContext];
            data.registrationNumber = migrant.registrationNumber;
        }
        if (!self.migrant.familyData) {
            self.migrant.familyData = [NSEntityDescription insertNewObjectForEntityForName:@"FamilyData" inManagedObjectContext:self.migrant.managedObjectContext];
        }
        //add child to family
        [self.migrant.familyData addChildsObject:data];
     
    }
          [self.tableView reloadData];
        
    };
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:list];
    [self presentViewController:navCon animated:YES completion:nil];
    
    
    //    [self showPopoverFromRect:[self.tableView rectForHeaderInSection:3] withViewController:vc navigationController:YES];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    [_hud removeFromSuperview];
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
