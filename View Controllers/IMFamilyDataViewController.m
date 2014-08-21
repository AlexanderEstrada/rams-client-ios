//
//  IMFamilyDataViewController.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 8/18/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMFamilyDataViewController.h"
#import "IMFamilyListVC.h"
#import "IMFormCell.h"
#import "Migrant+Extended.h"
#import "Child+Extended.h"
#import <QuickLook/QuickLook.h>
#import "NSDate+Relativity.h"
#import "MBProgressHUD.h"

#import "FamilyRegisterEntry+Extended.h"
#import "IMDBManager.h"
#import "IMConstants.h"


typedef enum : NSUInteger {
    
    section_head_of_family = 0,
    section_spouse,
    section_guadian,
    section_grand_father,
    section_grand_mother,
    section_childs,
    section_other_extended_member
    
} section_type;

typedef enum : NSUInteger {
    
    function_minus =0,
    function_plus,
    function_multiple,
    function_divided
    
} function_type;


typedef enum : NSUInteger {
    
    tag_child = 0,
    tag_other_extended_member,
    tag_grand_father,
    tag_grand_mother
} action_tag;

#define TOTAL_SECTION 8

@interface IMFamilyDataViewController ()<UITableViewDataSource, UITableViewDelegate,QLPreviewControllerDelegate,QLPreviewControllerDataSource,UIGestureRecognizerDelegate,MBProgressHUDDelegate>
@property (nonatomic, strong) NSMutableArray *childData;
@property (nonatomic, strong) NSMutableArray *grandFather;
@property (nonatomic, strong) NSMutableArray *grandMother;
@property (nonatomic, strong) NSMutableArray *others;
@property (nonatomic, strong) NSMutableArray *previewingPhotos;
@property (nonatomic) int tapCount;
@property (nonatomic,strong) MBProgressHUD *hud;
@property (nonatomic,strong) UIBarButtonItem *itemUploadAll;
@property (nonatomic,strong) NSManagedObjectContext *context;
@property (nonatomic,strong) NSPredicate *predicateHeadOfFamily;
@property (nonatomic,strong) NSPredicate *predicateSpouse;
@property (nonatomic,strong) NSPredicate *predicateChilds;
@property (nonatomic,strong) NSPredicate *predicateExclude;
@property (nonatomic) BOOL next;
@property (nonatomic) BOOL editingMode;
@property (nonatomic) BOOL uploadStatus;
@property (nonatomic) BOOL reloading;
@end

@implementation IMFamilyDataViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setFamilyRegister:(FamilyRegister *)familyRegister{
    if (familyRegister) {
        _familyRegister = familyRegister;
        
        [self reloadData];
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (!self.childData) {
        self.childData = [NSMutableArray array];
    }
    
    if (!self.grandFather) {
        self.grandFather = [NSMutableArray array];
    }
    
    if (!self.grandMother) {
        self.grandMother = [NSMutableArray array];
    }
    
    if (!self.others) {
        self.others = [NSMutableArray array];
    }
    
    self.navigationController.navigationBar.tintColor = [UIColor IMLightBlue];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    if (!self.context) {
        self.context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    }
    
    if (self.familyRegister) {
        self.title = @"Edit Family Data";
        self.editingMode = YES;
    }else {
        self.title = @"New Family Data";
        self.editingMode = NO;
        //create new family register
        self.familyRegister = [FamilyRegister newFamilyRegisterInContext:self.context];
    }
    
    
    
    //    self.save =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(onSave)];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel)];
    //add upload icon
    self.itemUploadAll= [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-upload-small"] style:UIBarButtonItemStylePlain target:self action:@selector(uploadAll:)];
    self.itemUploadAll.enabled = FALSE;
    
    //    self.navigationItem.rightBarButtonItems = @[self.itemUploadAll,self.save];
    self.navigationItem.rightBarButtonItems = @[self.itemUploadAll];
    self.navigationItem.leftBarButtonItems = @[cancelBtn];
    
    //set to no until user add migrant
    //    self.save.enabled = NO;
    
    //set default value
    _tapCount = 0;
    
    if (!_hud) {
        // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
        _hud = [[MBProgressHUD alloc] initWithView:self.view];
    }
    self.reloading = NO;
    //reset predicate
    self.predicateHeadOfFamily = Nil;
    self.predicateSpouse= Nil;
    self.predicateChilds= Nil;
    //add predicate
    [self addPredicate];
    
    
}

- (void)addPredicate{
    //add predicate
    @try {
        
        NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"FamilyRegister"];
        
        request.returnsObjectsAsFaults = YES;
        NSError *error;
        NSArray *familyRegister = [context executeFetchRequest:request error:&error];
        
        if (error) {
            NSLog(@"Error : %@",[error description]);
        }else {
            if ([familyRegister count]) {
                for (FamilyRegister * registered in familyRegister) {
                    for (FamilyRegisterEntry *entry in registered.familyEntryID) {
                        
                        //predicate algorithm
                        NSArray *items = [IMConstants constantsForKey:CONST_FAMILY_TYPE];
                        NSUInteger item = [items indexOfObject:entry.type];
                        NSPredicate * tmp = Nil;
                        switch (item) {
                            case 0:{
                                // HEAD_OF_FAMILY
                                tmp = [NSPredicate predicateWithFormat:@"registrationNumber != %@",entry.migrantId];
                                if (!self.predicateHeadOfFamily) {
                                    self.predicateHeadOfFamily =tmp;
                                }else {
                                    self.predicateHeadOfFamily =[NSCompoundPredicate andPredicateWithSubpredicates:@[self.predicateHeadOfFamily,tmp]];
                                }
                                break;
                            }
                            case 4 :{
                                //SPOUSE
                                tmp = [NSPredicate predicateWithFormat:@"registrationNumber != %@",entry.migrantId];
                                if (!self.predicateSpouse) {
                                    self.predicateSpouse =tmp;
                                }else {
                                    self.predicateSpouse =[NSCompoundPredicate andPredicateWithSubpredicates:@[self.predicateSpouse,tmp]];
                                }
                                break;
                            }
                            case 5:{
                                //CHILD
                                tmp = [NSPredicate predicateWithFormat:@"registrationNumber != %@",entry.migrantId];
                                if (!self.predicateChilds) {
                                    self.predicateChilds =tmp;
                                }else {
                                    self.predicateChilds =[NSCompoundPredicate andPredicateWithSubpredicates:@[self.predicateChilds,tmp]];
                                }
                                break;
                            }
                            case 1:// GRAND_FATHER
                            case 2:// GRAND_MOTHER
                            case 3://GUARDIAN
                            case 6://OTHER_EXTENDED_MEMBER
                            default:
                                //only show registered entry type
                                break;
                        }
                        
                    }
                }
            }
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"Exeption on addPredicate : %@",[exception description]);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)validate
{
    int counter = 0;
    if ([self.familyRegister.familyEntryID count]) {
        //check minimum family member
        
        for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
            
            if(self.familyRegister.headOfFamilyId || [entry.type isEqualToString:FAMILY_TYPE_SPOUSE] || [entry.type isEqualToString:FAMILY_TYPE_CHILD] || [entry.type isEqualToString:FAMILY_TYPE_GUARDIAN]){
                counter++;
            }
        }
    }
    return counter > 2;
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
        NSMutableArray * data = [NSMutableArray array];
        for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
            //add entry to array
            NSDictionary * formatted = [entry format];
            if (formatted) {
                [data addObject:formatted];
            }else {
                NSLog(@"something wrong while creating formatted data");
            }
            
        }
        NSDictionary * dict = [NSDictionary dictionaryWithObject:data forKey:@"members"];
        self.uploadStatus = NO;
        //send formatted data to server
        [self sendFamilyData:dict];
        //3 minutes before force close
        NSNumber * defaultValue = [IMConstants getIMConstantKeyNumber:CONST_IMSleepDefault];
        
        if (defaultValue.intValue < 0) {
            defaultValue = @(36000);
        }
        int counter = 0;
        while(self.next ==FALSE){
            usleep(5000);
            if (counter == defaultValue.intValue) {
                break;
            }
            counter++;
        }
        if (self.uploadStatus) {
            //save to local database and close family data view controller
            [self onSave];
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
    NSString * path = [IMConstants getIMConstantKey:CONST_IMFamilySave];
    NSLog(@"path : %@",path);
    //    [client postJSONWithPath:@"family/save"
    [client postJSONWithPath:path
                  parameters:params
                     success:^(NSDictionary *jsonData, int statusCode){
                         [self showAlertWithTitle:@"Upload Success" message:nil];
                         NSLog(@"Upload Success");
                         NSLog(@"return JSON : %@",[jsonData description]);
                         self.uploadStatus = self.next = YES;
                     }
                     failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                         [self showAlertWithTitle:@"Upload Failed" message:@"Please check your network connection and try again. If problem persist, contact administrator."];
                         NSLog(@"Upload Fail : %@",[error description]);
                         NSLog(@"return JSON : %@",[jsonData description]);
                         self.next = YES;
                     }];
}

- (void)reloadData
{
    if (!self.reloading) {
        
        self.reloading = YES;
        
        if (!self.familyRegister) {
            //create new family register
            self.familyRegister = [FamilyRegister newFamilyRegisterInContext:self.context];
        }
        
        if ([self.childData count]) {
            //clear before use
            [self.childData removeAllObjects];
        }
        
        if ([self.grandFather count]) {
            //clear before use
            [self.grandFather removeAllObjects];
        }
        
        if ([self.grandMother count]) {
            //clear before use
            [self.grandMother removeAllObjects];
        }
        
        if ([self.others count]) {
            //clear before use
            [self.others removeAllObjects];
        }
        
          NSPredicate * tmp = Nil;
        self.predicateExclude = Nil;
        for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
            if ([entry.type isEqualToString:FAMILY_TYPE_OTHER_EXTENDED_MEMBER]) {
                //add to child data
                [self.others addObject:entry];
            }else if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_MOTHER]) {
                //add to child data
                [self.grandMother addObject:entry];
            }else if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_FATHER]) {
                //add to child data
                [self.grandFather addObject:entry];
            }else        if ([entry.type isEqualToString:FAMILY_TYPE_CHILD]) {
                //add to child data
                [self.childData addObject:entry];
            }
            //add exclude predicate to avoid more than one choice for ever section
            tmp = [NSPredicate predicateWithFormat:@"registrationNumber != %@",entry.migrantId];
              //get all member that already select
            if (!self.predicateExclude) {
                self.predicateExclude =tmp;
            }else {
                self.predicateExclude =[NSCompoundPredicate andPredicateWithSubpredicates:@[self.predicateExclude,tmp]];
            }
        }
        
        if ([self validate]) {
            //enabling save and upload
            //set upload button enable
            self.itemUploadAll.enabled = self.save.enabled = YES;
        }
 
        [self.tableView reloadData];
        self.reloading = NO;
    }
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    if (!self.familyRegister || !self.reloading) {
        [self reloadData];
    }
    
}

#pragma mark Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ([self.familyRegister.familyEntryID count]?TOTAL_SECTION:1);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self familyRowFormula:section];
}

- (NSInteger)familyRowFormula:(NSInteger)section{
    
    NSInteger totalSection =0;
    int counter = 0;
    switch (section) {
            //        case section_family_information:
        case section_head_of_family:
        case section_spouse:
        case section_guadian:
            totalSection +=2;
            break;
        case section_grand_mother:{
            for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
                if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_MOTHER]) {
                    counter++;
                }
            }
            totalSection +=(counter * 2);
            break;
            
        }
            
        case section_grand_father:{
            for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
                if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_FATHER]) {
                    counter++;
                }
            }
            totalSection +=(counter * 2);
            break;
            
        }
            
        case section_other_extended_member:{
            for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
                if ([entry.type isEqualToString:FAMILY_TYPE_OTHER_EXTENDED_MEMBER]) {
                    counter++;
                }
            }
            totalSection +=(counter * 2);
            break;
            
        }
        case section_childs :{
            for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
                if ([entry.type isEqualToString:FAMILY_TYPE_CHILD]) {
                    counter++;
                }
            }
            totalSection +=(counter * 2);
            break;
        }
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
    
    if (section == section_head_of_family){
        headerView.labelTitle.text = @"Head Of Family";
    }else if (section == section_spouse){
        headerView.labelTitle.text = @"Spouse";
    }else if (section == section_guadian){
        headerView.labelTitle.text = @"Guardian";
    }else if (section == section_childs){
        headerView.labelTitle.text = [self.childData count]?[NSString stringWithFormat:@"Childs (%i)",[self.childData count]]:@"Childs";
        //implement action button
        headerView.buttonAction = [UIButton buttonWithType:UIButtonTypeContactAdd];
        
        [headerView.buttonAction setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [headerView.buttonAction setTitle:Nil forState:UIControlStateNormal];
        [headerView.buttonAction setTranslatesAutoresizingMaskIntoConstraints:NO];
        [headerView.contentView addSubview:headerView.buttonAction];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAction attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:-20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
        
        [headerView.buttonAction addTarget:self action:@selector(addMoreChild:) forControlEvents:UIControlEventTouchUpInside];
        headerView.buttonAction.tag = tag_child;
    }else if (section == section_grand_father){
        headerView.labelTitle.text = [self.grandFather count]?[NSString stringWithFormat:@"Grand Father (%i)",[self.grandFather count]]:@"Grand Father";
        //implement action button
        headerView.buttonAction = [UIButton buttonWithType:UIButtonTypeContactAdd];
        headerView.buttonAction.tag = tag_grand_father;
        [headerView.buttonAction setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [headerView.buttonAction setTitle:Nil forState:UIControlStateNormal];
        [headerView.buttonAction setTranslatesAutoresizingMaskIntoConstraints:NO];
        [headerView.contentView addSubview:headerView.buttonAction];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAction attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:-20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
        [headerView.buttonAction addTarget:self action:@selector(addMoreChild:) forControlEvents:UIControlEventTouchUpInside];
    }else if (section == section_grand_mother){
         headerView.labelTitle.text = [self.grandMother count]?[NSString stringWithFormat:@"Grand Mother (%i)",[self.grandMother count]]:@"Grand Mother";
        //implement action button
        headerView.buttonAction = [UIButton buttonWithType:UIButtonTypeContactAdd];
        headerView.buttonAction.tag = tag_grand_mother;
        [headerView.buttonAction setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [headerView.buttonAction setTitle:Nil forState:UIControlStateNormal];
        [headerView.buttonAction setTranslatesAutoresizingMaskIntoConstraints:NO];
        [headerView.contentView addSubview:headerView.buttonAction];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAction attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:-20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
        [headerView.buttonAction addTarget:self action:@selector(addMoreChild:) forControlEvents:UIControlEventTouchUpInside];
    }else if (section == section_other_extended_member){
         headerView.labelTitle.text = [self.others count]?[NSString stringWithFormat:@"Other Extended Member (%i)",[self.others count]]:@"Other Extended Member";
        //implement action button
        headerView.buttonAction = [UIButton buttonWithType:UIButtonTypeContactAdd];
        
        [headerView.buttonAction setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [headerView.buttonAction setTitle:Nil forState:UIControlStateNormal];
        [headerView.buttonAction setTranslatesAutoresizingMaskIntoConstraints:NO];
        [headerView.contentView addSubview:headerView.buttonAction];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAction attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:-20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
        [headerView.buttonAction addTarget:self action:@selector(addMoreChild:) forControlEvents:UIControlEventTouchUpInside];
        headerView.buttonAction.tag = tag_other_extended_member;
    }
    
    return headerView;
}


//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
//{
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
//    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
//    label.textAlignment = NSTextAlignmentCenter;
//    
//    switch (section) {
//        case section_head_of_family:
//        case section_grand_mother:
//        case section_grand_father:
//        case section_spouse:
//        case section_childs :
//        case section_other_extended_member:
//        case section_guadian:
//            label.text = [NSString stringWithFormat:@"This is Footer"];
//            break;
//        default:
//            //only show defined section
//            label.text = [NSString stringWithFormat:@"This is Default Footer"];
//            break;
//    }
//    
//    label.textColor = [UIColor darkGrayColor];
//    
//    return label;
//}

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
    FamilyRegisterEntry *entry = Nil;
    if (indexPath.section == section_childs && [self.childData count]) {
        
        NSInteger index = indexPath.row/2;
        entry = [ self.childData objectAtIndex:index];
        tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
    }else if (indexPath.section == section_grand_father && [self.grandFather count]){
        NSInteger index = indexPath.row/2;
        entry = [ self.grandFather objectAtIndex:index];
        tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
    }else if (indexPath.section == section_grand_mother && [self.grandMother count]){
        NSInteger index = indexPath.row/2;
        entry = [ self.grandMother objectAtIndex:index];
        tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
        
    }else if (indexPath.section == section_other_extended_member && [self.others count]){
        NSInteger index = indexPath.row/2;
        entry = [ self.others objectAtIndex:index];
        tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
    }
    
    switch (indexPath.section) {
        case section_head_of_family:{
            
            if (self.familyRegister && self.familyRegister.photograph) {
                //add all photo
                [self.previewingPhotos addObject:self.familyRegister.photograph];
            }
            break;
        }
        case section_spouse:{
            //get section_spouse
            tmp = Nil;
            for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
                if ([entry.type isEqualToString:FAMILY_TYPE_SPOUSE]) {
                    tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                    if (tmp && tmp.biometric.photograph) {
                        //add all photo
                        [self.previewingPhotos addObject:tmp.biometric.photograph];
                    }
                }
            }
            
            break;
        }
        case section_guadian:{
            //get section_guadian
            tmp = Nil;
            for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
                if ([entry.type isEqualToString:FAMILY_TYPE_GUARDIAN]) {
                    tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                    if (tmp && tmp.biometric.photograph) {
                        //add all photo
                        [self.previewingPhotos addObject:tmp.biometric.photograph];
                    }
                }
            }
            
            break;
        }
        case section_grand_mother:{
            //get section_grand_mother
            tmp = Nil;
            for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
                if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_MOTHER]) {
                    tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                    if (tmp && tmp.biometric.photograph) {
                        //add all photo
                        [self.previewingPhotos addObject:tmp.biometric.photograph];
                    }
                }
            }
            
            break;
        }
        case section_grand_father:{
            //get section_grand_father
            tmp = Nil;
            for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
                if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_FATHER]) {
                    tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                    if (tmp && tmp.biometric.photograph) {
                        //add all photo
                        [self.previewingPhotos addObject:tmp.biometric.photograph];
                    }
                }
            }
            
            break;
        }
        case section_other_extended_member:{
            //get section_other_extended_member
            tmp = Nil;
            for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
                if ([entry.type isEqualToString:FAMILY_TYPE_OTHER_EXTENDED_MEMBER]) {
                    tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                    if (tmp && tmp.biometric.photograph) {
                        //add all photo
                        [self.previewingPhotos addObject:tmp.biometric.photograph];
                    }
                }
            }
            
            break;
        }
        case section_childs :
        default:{
            //get childs
            if (tmp && tmp.biometric.photograph) {
                //add all photo
                [self.previewingPhotos addObject:tmp.biometric.photograph];
            }
            //only show defined section
            break;
        }
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
    if (entry) {
        entry = Nil;
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
    FamilyRegisterEntry *entry = Nil;
    NSInteger index = 0;
    if (indexPath.section == section_childs && [self.childData count]) {
        index = indexPath.row/2;
        //TODO : need to check
        entry = [ self.childData objectAtIndex:index];
        tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
        
    }else if (indexPath.section == section_grand_father && [self.grandFather count]){
        index = indexPath.row/2;
        //TODO : need to check
        entry = [ self.grandFather objectAtIndex:index];
        tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
    }else if (indexPath.section == section_grand_mother && [self.grandMother count]){
        index = indexPath.row/2;
        //TODO : need to check
        entry = [ self.grandMother objectAtIndex:index];
        tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
    }else if (indexPath.section == section_other_extended_member && [self.others count]){
        index = indexPath.row/2;
        //TODO : need to check
        entry = [ self.others objectAtIndex:index];
        tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
    }
    
    
    switch (indexPath.section) {
            
        case section_head_of_family:{
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Registration Number";
                cell.detailTextLabel.text = self.familyRegister.headOfFamilyId;
            }else if (indexPath.row ==1){
                cell.textLabel.text = @"Name";
                cell.detailTextLabel.text = self.familyRegister.headOfFamilyName;
                if (self.familyRegister.photographThumbnail) {
                    cell.imageView.image = self.familyRegister.photographImageThumbnail;
                    
                    if (cell.imageView.image) {
                        cell.imageView.userInteractionEnabled = YES;
                    }
                    
                }
                
            }
            
            break;
        }
        case section_spouse:{
            tmp = Nil;
            for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
                if ([entry.type isEqualToString:FAMILY_TYPE_SPOUSE]) {
                    tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                    if (tmp) {
                        break;
                    }
                }
            }
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Registration Number";
                cell.detailTextLabel.text = tmp.registrationNumber;
                
            }else if (indexPath.row ==1){
                
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
        case section_guadian:{
            tmp = Nil;
            for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
                if ([entry.type isEqualToString:FAMILY_TYPE_GUARDIAN]) {
                    tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                    if (tmp) {
                        break;
                    }
                }
            }
            if (indexPath.row == 0) {
                cell.textLabel.text = @"Registration Number";
                cell.detailTextLabel.text = tmp.registrationNumber;
                
            }else if (indexPath.row ==1){
                
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
        case section_grand_mother:
        case section_grand_father:
        case section_other_extended_member:
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
        
        Migrant * migrant = Nil;
        if (indexPath.section != section_head_of_family) {
            //get head of family as migrant
            migrant = [Migrant migrantWithId:self.familyRegister.headOfFamilyId inContext:self.context];
        }
        
        NSPredicate *tmp = Nil;
        switch (indexPath.section) {
            case section_head_of_family:{
                tmp = [NSPredicate predicateWithFormat:@"bioData.dateOfBirth <= %@ ",[self calculateAge:[NSDate date] compareAge:18 typeOfFuction:function_minus]];
                if (self.predicateHeadOfFamily) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.predicateHeadOfFamily]];
                if (self.predicateExclude) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self. self.predicateExclude]];
                break;
            }
            case section_other_extended_member:{
                //do not show head of family and child and spouse and grand mother and grand father and guardian
                tmp = self.predicateExclude?self.predicateExclude:Nil;
                break;
            }
            case section_grand_mother:{
                tmp = [NSPredicate predicateWithFormat:@"bioData.dateOfBirth <= %@ && bioData.gender = %@",[self calculateAge:migrant.bioData.dateOfBirth compareAge:15 typeOfFuction:function_minus],@"Female"];
                 if (self.predicateExclude) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self. self.predicateExclude]];
                break;
            }
            case section_grand_father:{
                tmp = [NSPredicate predicateWithFormat:@"bioData.dateOfBirth <= %@ && bioData.gender = %@",[self calculateAge:migrant.bioData.dateOfBirth compareAge:15 typeOfFuction:function_minus],@"Male"];
                if (self.predicateExclude) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self. self.predicateExclude]];
                break;
            }
            case section_guadian:{
                tmp = [NSPredicate predicateWithFormat:@"bioData.dateOfBirth < %@",migrant.bioData.dateOfBirth];
                if (self.predicateExclude) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self. self.predicateExclude]];
                break;
            }
            case section_spouse:{
                //do not show head of family and child
                tmp = [NSPredicate predicateWithFormat:@"bioData.gender != %@ AND bioData.dateOfBirth <= %@ ",migrant.bioData.gender,[self calculateAge:[NSDate date] compareAge:18 typeOfFuction:function_minus]];
                if (self.predicateSpouse) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.predicateSpouse]];
                 if (self.predicateExclude) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self. self.predicateExclude]];
                break;
            }
            case section_childs :
            default:
            {
                //do not show head of family and spouse
                tmp = [NSPredicate predicateWithFormat:@"bioData.dateOfBirth >= %@",[self calculateAge:migrant.bioData.dateOfBirth compareAge:15 typeOfFuction:function_plus]];
                if (self.predicateChilds) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.predicateChilds]];
                 if (self.predicateExclude) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self. self.predicateExclude]];
               
                break;
            }
        }
        //set predicate for list
         [list setBasePredicate:tmp];
        
        list.onSelect = ^(Migrant *migrant)
        {
            BOOL found = NO;
            NSInteger index = indexPath.row/2;
            FamilyRegisterEntry *tmp = Nil;
            switch (indexPath.section) {
                case section_head_of_family:{
                    //save to family register
                    self.familyRegister.headOfFamilyId = migrant.registrationNumber;
                    self.familyRegister.headOfFamilyName = [migrant fullname];
                    self.familyRegister.photographThumbnail = migrant.biometric.photographThumbnail;
                    self.familyRegister.photograph = migrant.biometric.photograph;
                    
                    //check is this an update or new
                    for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                        if ([entry.type isEqualToString:FAMILY_TYPE_HEAD_OF_FAMILY]) {
                            //update
                            entry.migrantId = migrant.registrationNumber;
                            found = YES;
                        }
                    }
                    if (!found) {
                        FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                        entry.migrantId = migrant.registrationNumber;
                        entry.type = FAMILY_TYPE_HEAD_OF_FAMILY;
                        
                        //Add to family register
                        [self.familyRegister addFamilyEntryIDObject:entry];
                    }
                    
                    break;
                }
                case section_grand_mother:{
                    tmp = [ self.grandMother objectAtIndex:index];
                    //check is this an update or new
                    for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                        if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_MOTHER] && [entry.migrantId isEqualToString:tmp.migrantId]) {
                            //update
                            entry.migrantId = migrant.registrationNumber;
                            found = YES;
                        }
                    }
                    if (!found) {
                        FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                        entry.migrantId = migrant.registrationNumber;
                        entry.type = FAMILY_TYPE_GRAND_MOTHER;
                        
                        //Add to family register
                        [self.familyRegister addFamilyEntryIDObject:entry];
                    }
                    break;
                }
                case section_grand_father:{
                    //check is this an update or new
                    tmp = [ self.grandFather objectAtIndex:index];
                    for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                        if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_FATHER] && [entry.migrantId isEqualToString:tmp.migrantId]) {
                            //update
                            entry.migrantId = migrant.registrationNumber;
                            found = YES;
                        }
                    }
                    if (!found) {
                        FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                        entry.migrantId = migrant.registrationNumber;
                        entry.type = FAMILY_TYPE_GRAND_FATHER;
                        
                        //Add to family register
                        [self.familyRegister addFamilyEntryIDObject:entry];
                    }
                    break;
                }
                case section_spouse:{
                    //check is this an update or new
                    for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                        if ([entry.type isEqualToString:FAMILY_TYPE_SPOUSE]) {
                            //update
                            entry.migrantId = migrant.registrationNumber;
                            found = YES;
                        }
                    }
                    if (!found) {
                        FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                        entry.migrantId = migrant.registrationNumber;
                        entry.type = FAMILY_TYPE_SPOUSE;
                        
                        //Add to family register
                        [self.familyRegister addFamilyEntryIDObject:entry];
                    }
                    
                    break;
                }
                case section_guadian:{
                    //check is this an update or new
                    for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                        if ([entry.type isEqualToString:FAMILY_TYPE_GUARDIAN]) {
                            //update
                            entry.migrantId = migrant.registrationNumber;
                            found = YES;
                        }
                    }
                    if (!found) {
                        FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                        entry.migrantId = migrant.registrationNumber;
                        entry.type = FAMILY_TYPE_GUARDIAN;
                        
                        //Add to family register
                        [self.familyRegister addFamilyEntryIDObject:entry];
                    }
                    
                    break;
                }
                case section_other_extended_member :
                {
                    tmp = [ self.others objectAtIndex:index];
                    //check is this an update or new
                    for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                        if ([entry.migrantId isEqualToString:tmp.migrantId] && [entry.type isEqualToString:FAMILY_TYPE_OTHER_EXTENDED_MEMBER]) {
                            //update
                            entry.migrantId = migrant.registrationNumber;
                            found = YES;
                        }
                    }
                    if (!found) {
                        FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                        entry.migrantId = migrant.registrationNumber;
                        entry.type = FAMILY_TYPE_OTHER_EXTENDED_MEMBER;
                        
                        //Add to family register
                        [self.familyRegister addFamilyEntryIDObject:entry];
                    }
                    
                    break;
                }
                case section_childs :
                default:
                {
                    tmp = [ self.childData objectAtIndex:index];
                    //check is this an update or new
                    for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                        if ([entry.migrantId isEqualToString:tmp.migrantId] && [entry.type isEqualToString:FAMILY_TYPE_CHILD]) {
                            //update
                            entry.migrantId = migrant.registrationNumber;
                            found = YES;
                        }
                    }
                    if (!found) {
                        FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                        entry.migrantId = migrant.registrationNumber;
                        entry.type = FAMILY_TYPE_CHILD;
                        
                        //Add to family register
                        [self.familyRegister addFamilyEntryIDObject:entry];
                    }
                    
                    break;
                }
            }
            
            [self reloadData];
            
        };
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:list];
        [self presentViewController:navCon animated:YES completion:Nil];
        
        //reset tap count
        _tapCount =0;
    }
    @catch (NSException *exception) {
        NSLog(@"error on singleTap : %@",[exception description]);
    }
    
    
}

- (void)doubleTap:(NSIndexPath *)indexPath {
    NSLog(@"indexPath.row : %i",indexPath.row);
    
    [self performSelector:@selector(showPhotoPreview:) withObject: indexPath];
    
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

- (void)saving
{
    NSError *error;
    //save to database
    if (![self.familyRegister.managedObjectContext save:&error]) {
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
    
    [self dismissViewControllerAnimated:YES completion:Nil];
    //save to family register and family entry
    //    self.familyRegister.headOfFamilyId =
    
}

- (void)onCancel
{
    if (self.editingMode) {
        [self.familyRegister.managedObjectContext rollback];
    }else {
        [self.context deleteObject:self.familyRegister];
    }
    
    NSError *error;
    if (![self.context save:&error]) {
        NSLog(@"Error deleting family data: %@", [error description]);
        [self showAlertWithTitle:@"Failed Saving Family Data" message:@"Please try again. If problem persist, please cancel and consult with administrator."];
        
    }else {
        [[IMDBManager sharedManager] saveDatabase:^(BOOL success){
            //            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:Nil];
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

- (NSDate *)calculateAge:(NSDate*)baseDate compareAge:(int)ageValue typeOfFuction:(function_type)type
{
    if (ageValue > 0) {
        
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDate *today = baseDate;
        
        switch (type) {
            case function_minus:{
                // components for "min Years ago"
                NSDateComponents *dateOffset = [[NSDateComponents alloc] init];
                [dateOffset setYear:0-ageValue];
                
                // date on "today minus age_min years"
                NSDate *minYearsAgo = [calendar dateByAddingComponents:dateOffset toDate:today options:0];
                
                // only use month and year component to create a date at the beginning of the month
                NSDateComponents *minYearsAgoComponents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:minYearsAgo];
                
                return minYearsAgo = [calendar dateFromComponents:minYearsAgoComponents];
                break;
            }
            case function_plus:{
                // components for "min Years ago"
                NSDateComponents *dateOffset = [[NSDateComponents alloc] init];
                [dateOffset setYear:0+ageValue];
                
                // date on "today minus age_min years"
                NSDate *minYearsAgo = [calendar dateByAddingComponents:dateOffset toDate:today options:0];
                
                // only use month and year component to create a date at the beginning of the month
                NSDateComponents *minYearsAgoComponents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:minYearsAgo];
                
                return minYearsAgo = [calendar dateFromComponents:minYearsAgoComponents];
                break;
            }
            default:
                break;
        }
        
    }
    
    return Nil;
    
}


- (void)addMoreChild:(UIButton *)sender
{
    //add special predicate for child, origin migrant age must be greater than child , at minimum 15 years
    //show migrant list
    UICollectionViewFlowLayout *aFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [aFlowLayout setItemSize:CGSizeMake(320, 150)];
    [aFlowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    IMFamilyListVC *list = [[IMFamilyListVC alloc] initWithCollectionViewLayout:aFlowLayout];
    list.basePredicate = Nil;
    Migrant * migrant = [Migrant migrantWithId:self.familyRegister.headOfFamilyId inContext:self.context];
    
    switch (sender.tag) {
        case tag_child:{
            if (!self.familyRegister.headOfFamilyId) {
                [self showAlertWithTitle:@"Failed Add Childs" message:@"Please input Head Of Family before adding child."];
                
                return;
            }
            [list setBasePredicate:[NSPredicate predicateWithFormat:@"bioData.dateOfBirth >= %@",[self calculateAge:migrant.bioData.dateOfBirth compareAge:15 typeOfFuction:function_plus]]];
            list.maxSelection = 100;
            break;
        }
        case tag_other_extended_member:{
            if (!self.familyRegister.headOfFamilyId) {
                [self showAlertWithTitle:@"Failed Add Other Extended Member" message:@"Please input Head Of Family before adding Other Extended Member."];
                
                return;
            }
            list.maxSelection = 100;
            list.basePredicate = Nil;
            break;
        }
        case tag_grand_father:{
            [list setBasePredicate:[NSPredicate predicateWithFormat:@"bioData.dateOfBirth <= %@ && bioData.gender = %@",[self calculateAge:migrant.bioData.dateOfBirth compareAge:15 typeOfFuction:function_minus],@"Male"]];
            list.maxSelection = 2;
            break;
        }
        case tag_grand_mother:{
            [list setBasePredicate:[NSPredicate predicateWithFormat:@"bioData.dateOfBirth <= %@ && bioData.gender = %@",[self calculateAge:migrant.bioData.dateOfBirth compareAge:15 typeOfFuction:function_minus],@"Female"]];
            list.maxSelection = 2;
            break;
        }
        default:
            list.maxSelection = 2;
            list.basePredicate = Nil;
            break;
    }
    
    
    list.multiSelect = YES;
    
    list.onMultiSelect = ^(NSMutableArray *migrants)
    {
        BOOL found = NO;
        switch (sender.tag) {
            case tag_child:{
                for (Migrant * migrant in migrants) {
                    for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                        if ([entry.migrantId isEqualToString:migrant.registrationNumber] && [entry.type isEqualToString:FAMILY_TYPE_CHILD]) {
                            //update
                            entry.migrantId = migrant.registrationNumber;
                            found = YES;
                        }
                    }
                    if (!found) {
                        FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                        entry.migrantId = migrant.registrationNumber;
                        entry.type = FAMILY_TYPE_CHILD;
                        
                        //Add to family register
                        [self.familyRegister addFamilyEntryIDObject:entry];
                    }
                    
                    
                }
                break;
            }
            case tag_other_extended_member:{
                for (Migrant * migrant in migrants) {
                    
                    for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                        if ([entry.migrantId isEqualToString:migrant.registrationNumber] && [entry.type isEqualToString:FAMILY_TYPE_OTHER_EXTENDED_MEMBER]) {
                            //update
                            entry.migrantId = migrant.registrationNumber;
                            found = YES;
                        }
                    }
                    if (!found) {
                        FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                        entry.migrantId = migrant.registrationNumber;
                        entry.type = FAMILY_TYPE_OTHER_EXTENDED_MEMBER;
                        
                        //Add to family register
                        [self.familyRegister addFamilyEntryIDObject:entry];
                    }
                    
                    
                }
                break;
            }
            case tag_grand_father:{
                for (Migrant * migrant in migrants) {
                    
                    for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                        if ([entry.migrantId isEqualToString:migrant.registrationNumber] && [entry.type isEqualToString:FAMILY_TYPE_GRAND_FATHER]) {
                            //update
                            entry.migrantId = migrant.registrationNumber;
                            found = YES;
                        }
                    }
                    if (!found) {
                        FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                        entry.migrantId = migrant.registrationNumber;
                        entry.type = FAMILY_TYPE_GRAND_FATHER;
                        
                        //Add to family register
                        [self.familyRegister addFamilyEntryIDObject:entry];
                    }
                    
                    
                }
                //todo : only get 2 migrants
                break;
            }
            case tag_grand_mother:
            default:{
                for (Migrant * migrant in migrants) {
                    
                    for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                        if ([entry.migrantId isEqualToString:migrant.registrationNumber] && [entry.type isEqualToString:FAMILY_TYPE_GRAND_MOTHER]) {
                            //update
                            entry.migrantId = migrant.registrationNumber;
                            found = YES;
                        }
                    }
                    if (!found) {
                        FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                        entry.migrantId = migrant.registrationNumber;
                        entry.type = FAMILY_TYPE_GRAND_MOTHER;
                        
                        //Add to family register
                        [self.familyRegister addFamilyEntryIDObject:entry];
                    }
                    
                    
                }
                //todo : only get 2 migrants
                break;
            }
                
                
        }
        
        
        
        [self reloadData];
        
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
