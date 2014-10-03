//
//  IMFamilyDataViewController.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 6/2/14.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMFamilyDataViewController.h"
#import "IMFamilyListVC.h"
#import "IMFormCell.h"
#import "Migrant+Extended.h"
#import "Child+Extended.h"
#import <QuickLook/QuickLook.h>
#import "NSDate+Relativity.h"
#import "MBProgressHUD.h"
#import "IMOptionChooserViewController.h"
#import "FamilyRegisterEntry+Extended.h"
#import "IMDBManager.h"
#import "IMConstants.h"
#import "UIImage+ImageUtils.h"

typedef enum : NSUInteger {
    
    function_minus =0,
    function_plus,
    function_multiple,
    function_divided,
    function_by_section,
    function_by_tag
    
} function_type;

static int section_adding = 0;
static int section_head_of_family;
static int section_spouse;
static int section_guadian;
static int section_grand_father;
static int section_grand_mother;
static int section_childs;
static int section_other_extended_member;

#define TOTAL_SECTION 8


@interface IMFamilyDataViewController ()<UITableViewDataSource, UITableViewDelegate,QLPreviewControllerDelegate,QLPreviewControllerDataSource,UIGestureRecognizerDelegate,UIPopoverControllerDelegate,MBProgressHUDDelegate,IMOptionChooserDelegate>
@property (nonatomic, strong) NSMutableArray *childData;
@property (nonatomic, strong) NSMutableArray *grandFather;
@property (nonatomic, strong) NSMutableArray *grandMother;
@property (nonatomic, strong) NSMutableArray *others;
@property (nonatomic, strong) NSMutableArray *selectedFamilyTypes;
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
@property (nonatomic) BOOL isHeadOfFamilyFemale;
@property (nonatomic) BOOL haveHeadOfFamily;
@property (nonatomic) BOOL reloading;
@property (nonatomic, strong) UIPopoverController *popover;

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
    self.isHeadOfFamilyFemale = NO;
    
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
    
    if (!self.selectedFamilyTypes) {
        self.selectedFamilyTypes = [NSMutableArray array];
    }else{
        [self.selectedFamilyTypes removeAllObjects];
    }
    
    self.navigationController.navigationBar.tintColor = [UIColor IMLightBlue];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    if (!self.context) {
        self.context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    }
    
    //set default value
    section_head_of_family = section_spouse = section_guadian = section_grand_father = section_grand_mother = section_childs = section_other_extended_member = 1000;
    
    if (self.familyRegister) {
        self.title = NSLocalizedString(@"Edit Family Data",Nil);
        self.editingMode = YES;
        
        if (self.familyRegister.headOfFamilyId) {
            //head of family is exist
            [self.selectedFamilyTypes addObject:FAMILY_TYPE_HEAD_OF_FAMILY];
            section_head_of_family = [self.selectedFamilyTypes count];
        }
        //update selected family type
        for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
            if (![self.selectedFamilyTypes containsObject:entry.type]) {
                //add entry type to array
                [self.selectedFamilyTypes addObject:entry.type];
                if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_FATHER]) {
                    section_grand_father = [self.selectedFamilyTypes count];
                }else if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_MOTHER]) {
                    section_grand_mother = [self.selectedFamilyTypes count];
                }else if ([entry.type isEqualToString:FAMILY_TYPE_GUARDIAN]) {
                    section_guadian = [self.selectedFamilyTypes count];
                }else if ([entry.type isEqualToString:FAMILY_TYPE_SPOUSE]) {
                    section_spouse = [self.selectedFamilyTypes count];
                }else if ([entry.type isEqualToString:FAMILY_TYPE_CHILD]) {
                    section_childs = [self.selectedFamilyTypes count];
                }else if ([entry.type isEqualToString:FAMILY_TYPE_OTHER_EXTENDED_MEMBER]) {
                    section_other_extended_member = [self.selectedFamilyTypes count];
                }
            }
        }
        
    }else {
        self.title = NSLocalizedString(@"New Family Data",Nil);
        self.editingMode = NO;
        //create new family register
        self.familyRegister = [FamilyRegister newFamilyRegisterInContext:self.context];
    }
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel)];
    //add upload icon
    self.itemUploadAll= [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-upload-small"] style:UIBarButtonItemStylePlain target:self action:@selector(uploadAll:)];
    self.itemUploadAll.enabled = FALSE;
    
    self.navigationItem.rightBarButtonItems = @[self.itemUploadAll];
    self.navigationItem.leftBarButtonItems = @[cancelBtn];
    
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
                        
                        if (item == section_head_of_family) {
                            
                            // HEAD_OF_FAMILY
                            tmp = [NSPredicate predicateWithFormat:@"registrationNumber != %@",entry.migrantId];
                            if (!self.predicateHeadOfFamily) {
                                self.predicateHeadOfFamily =tmp;
                            }else {
                                self.predicateHeadOfFamily =[NSCompoundPredicate andPredicateWithSubpredicates:@[self.predicateHeadOfFamily,tmp]];
                            }
                            
                        }
                        
                        else if (item == section_spouse) {
                            //SPOUSE
                            tmp = [NSPredicate predicateWithFormat:@"registrationNumber != %@",entry.migrantId];
                            if (!self.predicateSpouse) {
                                self.predicateSpouse =tmp;
                            }else {
                                self.predicateSpouse =[NSCompoundPredicate andPredicateWithSubpredicates:@[self.predicateSpouse,tmp]];
                            }
                            
                        }
                        
                        else if (item == section_childs) {
                            //CHILD
                            tmp = [NSPredicate predicateWithFormat:@"registrationNumber != %@",entry.migrantId];
                            if (!self.predicateChilds) {
                                self.predicateChilds =tmp;
                            }else {
                                self.predicateChilds =[NSCompoundPredicate andPredicateWithSubpredicates:@[self.predicateChilds,tmp]];
                            }
                            
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Upload all Family Data",Nil)
                                                    message: NSLocalizedString(@"All your Family Data will be uploaded and you need internet connection to do this.\nContinue upload all Family Data?",Nil)
                                                   delegate:self
                                          cancelButtonTitle: NSLocalizedString(@"Cancel",Nil)
                                          otherButtonTitles: NSLocalizedString(@"Yes", nil),Nil];
    alert.tag = IMAlertUpload_Tag;
    [alert show];
    
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == IMAlertUpload_Tag && buttonIndex != [alertView cancelButtonIndex]) {
        //start uploading
//        if (!_hud) {
            // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
            _hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
//        }
        
        // Back to indeterminate mode
        _hud.mode = MBProgressHUDModeDeterminate;
        
        // Add HUD to screen
        [self.navigationController.view addSubview:_hud];
        
        // Regisete for HUD callbacks so we can remove it from the window at the right time
        _hud.delegate = self;
        
        _hud.labelText =  NSLocalizedString(@"Uploading Data",Nil);
        
        
        // Show the HUD while the provided method executes in a new thread
        [_hud showWhileExecuting:@selector(uploading) onTarget:self withObject:nil animated:YES];
    }else if (alertView.tag == IMAlertUploadSuccess_Tag){
        //         finish blocking
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [self.sideMenuDelegate disableMenu:NO];
        
        //reset flag
        self.next = TRUE;
        
        //close view
        [self dismissViewControllerAnimated:YES completion:Nil];
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
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    NSString * path = [IMConstants getIMConstantKey:CONST_IMFamilySave];
    [client postJSONWithPath:path
                  parameters:params
                     success:^(NSDictionary *jsonData, int statusCode){
                         //                         [self showAlertWithTitle:@"Upload Success" message:nil];
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Upload Success",Nil) message:Nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                         alert.tag = IMAlertUploadSuccess_Tag;
                         [alert show];
                         NSLog(@"Upload Success");
                         NSLog(@"return JSON : %@",[jsonData description]);
                         self.uploadStatus = self.next = YES;
                     }
                     failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                         [self showAlertWithTitle: NSLocalizedString(@"Upload Failed",Nil) message: NSLocalizedString(@"Please check your network connection and try again. If problem persist, contact administrator.",Nil)];
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
            }else if ([entry.type isEqualToString:FAMILY_TYPE_CHILD]) {
                //add to child data
                [self.childData addObject:entry];
            }else if([entry.type isEqualToString:FAMILY_TYPE_GUARDIAN]) {
                //set flag, cause there is guardian as head of family
                self.haveHeadOfFamily = YES;
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
        
        //set head of family gender
        Migrant * migrant = [Migrant migrantWithId:self.familyRegister.headOfFamilyId inContext:self.context];
        
        //set default value
        self.isHeadOfFamilyFemale = NO;
        if (migrant) {
            if ([migrant.bioData.gender isEqualToString:@"Female"]) {
                self.isHeadOfFamilyFemale = YES;
            }
        }
        
        //reset flag
        self.haveHeadOfFamily |= self.familyRegister.headOfFamilyId != Nil;
        
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
    return ([self.selectedFamilyTypes count]?[self.selectedFamilyTypes count]+1:1);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self familyRowFormula:section];
}

- (NSInteger)familyRowFormula:(NSInteger)section{
    
    NSInteger totalSection =0;
    int counter = 0;
    
    if (section == section_spouse || section == section_head_of_family || section == section_guadian) {
        totalSection +=2;
    }else if (section == section_grand_mother){
        for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
            if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_MOTHER]) {
                counter++;
            }
        }
        totalSection +=(counter * 2);
    }else if (section == section_grand_father){
        for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
            if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_FATHER]) {
                counter++;
            }
        }
        totalSection +=(counter * 2);
    }else if (section == section_other_extended_member){
        for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
            if ([entry.type isEqualToString:FAMILY_TYPE_OTHER_EXTENDED_MEMBER]) {
                counter++;
            }
        }
        totalSection +=(counter * 2);
    }else if (section == section_childs){
        for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
            if ([entry.type isEqualToString:FAMILY_TYPE_CHILD]) {
                counter++;
            }
        }
        totalSection +=(counter * 2);
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
    if (section == section_adding){
        headerView.labelTitle.text =  NSLocalizedString(@"Type Of Family",Nil);
        //implement action button
        headerView.buttonAction = [UIButton buttonWithType:UIButtonTypeContactAdd];
        headerView.buttonAction.tag = section_adding;
        [headerView.buttonAction setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [headerView.buttonAction setTitle:Nil forState:UIControlStateNormal];
        [headerView.buttonAction setTranslatesAutoresizingMaskIntoConstraints:NO];
        [headerView.contentView addSubview:headerView.buttonAction];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAction attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:-20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
        [headerView.buttonAction addTarget:self action:@selector(addMoreType:) forControlEvents:UIControlEventTouchUpInside];
        
    }else if (section == section_head_of_family){
        headerView.labelTitle.text =  NSLocalizedString(@"Head Of Family",Nil);
        headerView.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_HEAD_OF_FAMILY];
        
    }else if (section == section_spouse){
        if (self.isHeadOfFamilyFemale) {
            return Nil;
        }
        headerView.labelTitle.text =  NSLocalizedString(@"Spouse",Nil);
        headerView.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_SPOUSE];
    }else if (section == section_guadian){
        headerView.labelTitle.text =  NSLocalizedString(@"Guardian",Nil);
        headerView.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_GUARDIAN];
    }else if (section == section_childs){
        headerView.labelTitle.text = [self.childData count]?[NSString stringWithFormat:([self.childData count] > 1)? NSLocalizedString(@"Childrens (%lu)",Nil) :  NSLocalizedString(@"Children (%lu)",Nil),(unsigned long)[self.childData count]]: NSLocalizedString(@"Children",Nil);
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
        headerView.buttonAction.tag = section_childs;
        
        if ([self.childData count]) {
            headerView.buttonAdd = [UIButton buttonWithType:UIButtonTypeCustom];
            [headerView.buttonAdd setImage:[[UIImage imageNamed:@"icon-delete"] imageMaskWithColor:[UIColor IMMagenta]] forState:UIControlStateNormal];
            [headerView.buttonAdd setTitle:Nil forState:UIControlStateNormal];
            [headerView.buttonAdd setTranslatesAutoresizingMaskIntoConstraints:NO];
            [headerView.contentView addSubview:headerView.buttonAdd];
            [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAdd attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeRight multiplier:1 constant:-40]];
            [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAdd attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
            [headerView.buttonAdd addTarget:self action:@selector(deleteItem:) forControlEvents:UIControlEventTouchUpInside];
            headerView.buttonAdd.tag = section_childs;
        }
        
        headerView.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_CHILD];
    }else if (section == section_grand_father){
        headerView.labelTitle.text = [self.grandFather count]?[NSString stringWithFormat: NSLocalizedString(@"Grand Father (%lu)",Nil),(unsigned long)[self.grandFather count]]: NSLocalizedString(@"Grand Father",Nil);
        //implement action button
        headerView.buttonAction = [UIButton buttonWithType:UIButtonTypeContactAdd];
        headerView.buttonAction.tag = section_grand_father;
        [headerView.buttonAction setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [headerView.buttonAction setTitle:Nil forState:UIControlStateNormal];
        [headerView.buttonAction setTranslatesAutoresizingMaskIntoConstraints:NO];
        [headerView.contentView addSubview:headerView.buttonAction];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAction attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:-20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
        [headerView.buttonAction addTarget:self action:@selector(addMoreChild:) forControlEvents:UIControlEventTouchUpInside];
        
        if ([self.grandFather count]) {
            headerView.buttonAdd = [UIButton buttonWithType:UIButtonTypeCustom];
            [headerView.buttonAdd setImage:[[UIImage imageNamed:@"icon-delete"] imageMaskWithColor:[UIColor IMMagenta]] forState:UIControlStateNormal];
            [headerView.buttonAdd setTitle:Nil forState:UIControlStateNormal];
            [headerView.buttonAdd setTranslatesAutoresizingMaskIntoConstraints:NO];
            [headerView.contentView addSubview:headerView.buttonAdd];
            [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAdd attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeRight multiplier:1 constant:-40]];
            [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAdd attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
            [headerView.buttonAdd addTarget:self action:@selector(deleteItem:) forControlEvents:UIControlEventTouchUpInside];
            headerView.buttonAdd.tag = section_grand_father;
        }
        headerView.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_GRAND_FATHER];
    }else if (section == section_grand_mother){
        headerView.labelTitle.text = [self.grandMother count]?[NSString stringWithFormat: NSLocalizedString(@"Grand Mother (%lu)",Nil),(unsigned long)[self.grandMother count]]: NSLocalizedString(@"Grand Mother",Nil);
        //implement action button
        headerView.buttonAction = [UIButton buttonWithType:UIButtonTypeContactAdd];
        headerView.buttonAction.tag = section_grand_mother;
        [headerView.buttonAction setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [headerView.buttonAction setTitle:Nil forState:UIControlStateNormal];
        [headerView.buttonAction setTranslatesAutoresizingMaskIntoConstraints:NO];
        [headerView.contentView addSubview:headerView.buttonAction];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAction attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:-20]];
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headerView.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
        [headerView.buttonAction addTarget:self action:@selector(addMoreChild:) forControlEvents:UIControlEventTouchUpInside];
        
        if ([self.grandMother count]) {
            headerView.buttonAdd = [UIButton buttonWithType:UIButtonTypeCustom];
            [headerView.buttonAdd setImage:[[UIImage imageNamed:@"icon-delete"] imageMaskWithColor:[UIColor IMMagenta]] forState:UIControlStateNormal];
            [headerView.buttonAdd setTitle:Nil forState:UIControlStateNormal];
            [headerView.buttonAdd setTranslatesAutoresizingMaskIntoConstraints:NO];
            [headerView.contentView addSubview:headerView.buttonAdd];
            [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAdd attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeRight multiplier:1 constant:-40]];
            [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAdd attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
            [headerView.buttonAdd addTarget:self action:@selector(deleteItem:) forControlEvents:UIControlEventTouchUpInside];
            headerView.buttonAdd.tag = section_grand_mother;
        }
        headerView.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_GRAND_MOTHER];
    }else if (section == section_other_extended_member){
        headerView.labelTitle.text = [self.others count]?[NSString stringWithFormat: NSLocalizedString(@"Other Extended Member (%lu)",Nil),(unsigned long)[self.others count]]: NSLocalizedString(@"Other Extended Member",Nil);
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
        headerView.buttonAction.tag = section_other_extended_member;
        
        if ([self.others count]) {
            headerView.buttonAdd = [UIButton buttonWithType:UIButtonTypeCustom];
            [headerView.buttonAdd setImage:[[UIImage imageNamed:@"icon-delete"] imageMaskWithColor:[UIColor IMMagenta]] forState:UIControlStateNormal];
            [headerView.buttonAdd setTitle:Nil forState:UIControlStateNormal];
            [headerView.buttonAdd setTranslatesAutoresizingMaskIntoConstraints:NO];
            [headerView.contentView addSubview:headerView.buttonAdd];
            [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.buttonAdd attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAction attribute:NSLayoutAttributeRight multiplier:1 constant:-40]];
            [headerView.contentView addConstraint:[NSLayoutConstraint constraintWithItem:headerView.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:headerView.buttonAdd attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
            [headerView.buttonAdd addTarget:self action:@selector(deleteItem:) forControlEvents:UIControlEventTouchUpInside];
            headerView.buttonAdd.tag = section_other_extended_member;
        }
        headerView.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_OTHER_EXTENDED_MEMBER];
    }
    
    return headerView;
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
    }else return; // do nothing
    UIImage * image = Nil;
    //update photo path
    if (tmp) {
        image = tmp.biometric.photographImage;
    }
    
    if (indexPath.section == section_head_of_family) {
        if (self.familyRegister && self.familyRegister.photograph) {
            //add all photo
            
            //check if the path has change
            if (![[NSFileManager defaultManager] fileExistsAtPath:self.familyRegister.photograph] && self.familyRegister.photograph) {
                //case has change then update the path before show
                tmp = Nil;
                tmp = [Migrant migrantWithId:self.familyRegister.headOfFamilyId inContext:self.context];
                if (tmp && tmp.biometric.photograph) {
                    image = tmp.biometric.photographImage;
                    //add all photo
                    self.familyRegister.photograph = tmp.biometric.photograph;
                }
            }
            [self.previewingPhotos addObject:self.familyRegister.photograph];
        }
        
    }
    
    else if (indexPath.section == section_spouse) {
        //get section_spouse
        tmp = Nil;
        for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
            if ([entry.type isEqualToString:FAMILY_TYPE_SPOUSE]) {
                tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                if (tmp && tmp.biometric.photograph) {
                    image = tmp.biometric.photographImage;
                    //add all photo
                    [self.previewingPhotos addObject:tmp.biometric.photograph];
                    break;
                }
            }
        }
        
        
    }
    
    else if (indexPath.section == section_guadian) {
        //get section_guadian
        tmp = Nil;
        for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
            if ([entry.type isEqualToString:FAMILY_TYPE_GUARDIAN]) {
                tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                if (tmp && tmp.biometric.photograph) {
                    image = tmp.biometric.photographImage;
                    //add all photo
                    [self.previewingPhotos addObject:tmp.biometric.photograph];
                    break;
                }
            }
        }
        
        
    }
    else {
        
        //get section_grand_mother
        if (tmp && tmp.biometric.photograph) {
            //add all photo
            [self.previewingPhotos addObject:tmp.biometric.photograph];
        }
        
    }
    
    
    if (![self.previewingPhotos count]) {
        //there is no photo to show
        //release memory
        if (tmp) {
            tmp = Nil;
        }
        if (entry) {
            entry = Nil;
        }
        return;
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
    
    
    
    if (indexPath.section == section_head_of_family) {
        
        if (indexPath.row == 0) {
            cell.textLabel.text =  NSLocalizedString(@"Registration Number",Nil);
            cell.detailTextLabel.text = self.familyRegister.headOfFamilyId;
        }else if (indexPath.row ==1){
            cell.textLabel.text =  NSLocalizedString(@"Name",Nil);
            cell.detailTextLabel.text = self.familyRegister.headOfFamilyName;
            if (self.familyRegister.photographThumbnail) {
                cell.imageView.image = self.familyRegister.photographImageThumbnail;
                
                if (cell.imageView.image) {
                    cell.imageView.userInteractionEnabled = YES;
                }
                
            }
            
        }
        
        cell.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_HEAD_OF_FAMILY];
        
        
    }
    
    else if (indexPath.section == section_spouse) {
        tmp = Nil;
        if (self.isHeadOfFamilyFemale) {
            cell.userInteractionEnabled = NO;
        }else{
            cell.userInteractionEnabled = YES;
            for (FamilyRegisterEntry * entry in self.familyRegister.familyEntryID) {
                if ([entry.type isEqualToString:FAMILY_TYPE_SPOUSE]) {
                    tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                    if (tmp) {
                        break;
                    }
                }
            }
            if (indexPath.row == 0) {
                cell.textLabel.text =  NSLocalizedString(@"Registration Number",Nil);
                cell.detailTextLabel.text = tmp.registrationNumber;
                
            }else if (indexPath.row ==1){
                
                cell.textLabel.text =  NSLocalizedString(@"Name",Nil);
                cell.detailTextLabel.text = [tmp fullname];
                if (tmp.biometric.photographImageThumbnail) {
                    cell.imageView.image = tmp.biometric.photographImageThumbnail;
                    
                    if (cell.imageView.image) {
                        cell.imageView.userInteractionEnabled = YES;
                    }
                    
                }
            }
            cell.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_SPOUSE];
            
        }
    }
    
    else if (indexPath.section == section_guadian) {
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
            cell.textLabel.text =  NSLocalizedString(@"Registration Number",Nil);
            cell.detailTextLabel.text = tmp.registrationNumber;
            
        }else if (indexPath.row ==1){
            
            cell.textLabel.text =  NSLocalizedString(@"Name",Nil);
            cell.detailTextLabel.text = [tmp fullname];
            if (tmp.biometric.photographImageThumbnail) {
                cell.imageView.image = tmp.biometric.photographImageThumbnail;
                
                if (cell.imageView.image) {
                    cell.imageView.userInteractionEnabled = YES;
                }
                
            }
        }
        cell.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_GUARDIAN];
        
    }
    
    else {
        if (indexPath.row == 0 || ((indexPath.row %2) == 0)) {
            cell.textLabel.text =  NSLocalizedString(@"Registration Number",Nil);
            cell.detailTextLabel.text = tmp.registrationNumber;
            
        }else {
            
            cell.textLabel.text =  NSLocalizedString(@"Name",Nil);
            cell.detailTextLabel.text = [tmp fullname];
            if (tmp.biometric.photographImageThumbnail) {
                cell.imageView.image = tmp.biometric.photographImageThumbnail;
                
                if (cell.imageView.image) {
                    cell.imageView.userInteractionEnabled = YES;
                }
                
            }
        }
        
    }
    
    if (indexPath.section == section_grand_mother) {
        cell.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_GRAND_MOTHER];
        
    }
    
    else if (indexPath.section == section_grand_father) {
        cell.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_GRAND_FATHER];
        
    }
    
    else if (indexPath.section == section_other_extended_member) {
        cell.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_OTHER_EXTENDED_MEMBER];
        
    }
    
    else if (indexPath.section == section_childs) {
        cell.hidden = ![self.selectedFamilyTypes containsObject:FAMILY_TYPE_CHILD];
        
    }
    
    
    
    return cell;
}

- (void)showOptionChooserWithConstantsKey:(NSString *)constantsKey indexPath:(NSIndexPath *)indexPath useNavigation:(BOOL)useNavigation
{
    IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:constantsKey delegate:self];
    vc.view.tintColor = [UIColor IMMagenta];
    NSMutableArray * tmp = [NSMutableArray array];
    if ([self.selectedFamilyTypes count]) {
        
        
        //only show non selected family types
        
        for (NSString * type in vc.options) {
            
            if (![self.selectedFamilyTypes containsObject:type]) {
                
                if(self.isHeadOfFamilyFemale && [type isEqualToString:FAMILY_TYPE_SPOUSE]) continue;
                
                [tmp addObject:type];
            }
        }
        
    }else {
        //only show head of family and guardian
        [tmp addObject:FAMILY_TYPE_HEAD_OF_FAMILY];
        [tmp addObject:FAMILY_TYPE_GUARDIAN];
    }
    
    //show it as option
    vc.options = tmp;
    [self showPopoverFromRect:[self.tableView rectForHeaderInSection:indexPath.section] withViewController:vc navigationController:useNavigation];
}

- (void)optionChooser:(IMOptionChooserViewController *)optionChooser didSelectOptionAtIndex:(NSUInteger)selectedIndex withValue:(id)value
{
    if (optionChooser.constantsKey == CONST_FAMILY_TYPE) {
        //        self.movement.type = value;
        NSString * type = value;
        [self.selectedFamilyTypes addObject:type];
        if ([type isEqualToString:FAMILY_TYPE_HEAD_OF_FAMILY]) {
            section_head_of_family = [self.selectedFamilyTypes count];
        }else if ([type isEqualToString:FAMILY_TYPE_GRAND_FATHER]) {
            section_grand_father = [self.selectedFamilyTypes count];
        }else if ([type isEqualToString:FAMILY_TYPE_GRAND_MOTHER]) {
            section_grand_mother = [self.selectedFamilyTypes count];
        }else if ([type isEqualToString:FAMILY_TYPE_GUARDIAN]) {
            section_guadian = [self.selectedFamilyTypes count];
        }else if ([type isEqualToString:FAMILY_TYPE_SPOUSE]) {
            section_spouse = [self.selectedFamilyTypes count];
        }else if ([type isEqualToString:FAMILY_TYPE_CHILD]) {
            section_childs = [self.selectedFamilyTypes count];
        }else if ([type isEqualToString:FAMILY_TYPE_OTHER_EXTENDED_MEMBER]) {
            section_other_extended_member = [self.selectedFamilyTypes count];
        }
        
        [self reloadData];
    }
    [self.popover dismissPopoverAnimated:YES];
    self.popover = nil;
}

- (void)showPopoverFromRect:(CGRect)rect withViewController:(UIViewController *)vc navigationController:(BOOL)useNavigation
{
    rect = CGRectMake(rect.size.width - 150, rect.origin.y, rect.size.width, rect.size.height);
    vc.view.tintColor = [UIColor IMMagenta];
    vc.modalInPopover = NO;
    
    if (useNavigation) {
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
        navCon.navigationBar.tintColor = [UIColor IMMagenta];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:navCon];
    }else {
        vc.view.tintColor = [UIColor IMMagenta];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    }
    
    self.popover.delegate = self;
    [self.popover presentPopoverFromRect:rect inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    self.popover = nil;
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
        
        //get predicate
        [list setBasePredicate:[self getPredicate:indexPath.section]];
        
        list.onSelect = ^(Migrant *migrant)
        {
            BOOL found = NO;
            NSInteger index = indexPath.row/2;
            FamilyRegisterEntry *tmp = Nil;
            
            if (indexPath.section == section_head_of_family) {
                
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
                        break;
                    }else if ([entry.migrantId isEqualToString:migrant.registrationNumber]){
                        //do not insert same value on different section
                        found = YES;
                        break;
                    }
                }
                if (!found) {
                    FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                    entry.migrantId = migrant.registrationNumber;
                    entry.type = FAMILY_TYPE_HEAD_OF_FAMILY;
                    
                    //Add to family register
                    [self.familyRegister addFamilyEntryIDObject:entry];
                }
                
                
            }
            
            else if (indexPath.section == section_grand_mother) {
                tmp = [ self.grandMother objectAtIndex:index];
                //check is this an update or new
                for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                    if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_MOTHER] && [entry.migrantId isEqualToString:tmp.migrantId]) {
                        //update
                        entry.migrantId = migrant.registrationNumber;
                        found = YES;
                        break;
                    }else if ([entry.migrantId isEqualToString:migrant.registrationNumber]){
                        //do not insert same value on different section
                        found = YES;
                        break;
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
            
            else if (indexPath.section == section_grand_father) {
                //check is this an update or new
                tmp = [ self.grandFather objectAtIndex:index];
                for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                    if ([entry.type isEqualToString:FAMILY_TYPE_GRAND_FATHER] && [entry.migrantId isEqualToString:tmp.migrantId]) {
                        //update
                        entry.migrantId = migrant.registrationNumber;
                        found = YES;
                        break;
                    }else if ([entry.migrantId isEqualToString:migrant.registrationNumber]){
                        //do not insert same value on different section
                        found = YES;
                        break;
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
            
            else if (indexPath.section == section_spouse) {
                //check is this an update or new
                for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                    if ([entry.type isEqualToString:FAMILY_TYPE_SPOUSE]) {
                        //update
                        entry.migrantId = migrant.registrationNumber;
                        found = YES;
                        break;
                    }else if ([entry.migrantId isEqualToString:migrant.registrationNumber]){
                        //do not insert same value on different section
                        found = YES;
                        break;
                    }
                }
                if (!found) {
                    FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                    entry.migrantId = migrant.registrationNumber;
                    entry.type = FAMILY_TYPE_SPOUSE;
                    
                    //Add to family register
                    [self.familyRegister addFamilyEntryIDObject:entry];
                }
                
                
            }
            
            else if (indexPath.section == section_guadian) {
                //check is this an update or new
                for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                    if ([entry.type isEqualToString:FAMILY_TYPE_GUARDIAN]) {
                        //update
                        entry.migrantId = migrant.registrationNumber;
                        found = YES;
                        break;
                    }else if ([entry.migrantId isEqualToString:migrant.registrationNumber]){
                        //do not insert same value on different section
                        found = YES;
                        break;
                    }
                }
                if (!found) {
                    FamilyRegisterEntry *entry = [FamilyRegisterEntry newFamilyRegisterEntryInContext:self.context];
                    entry.migrantId = migrant.registrationNumber;
                    entry.type = FAMILY_TYPE_GUARDIAN;
                    
                    //Add to family register
                    [self.familyRegister addFamilyEntryIDObject:entry];
                }
                
                
            }
            
            else if (indexPath.section == section_other_extended_member)
            {
                tmp = [ self.others objectAtIndex:index];
                //check is this an update or new
                for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                    if ([entry.migrantId isEqualToString:tmp.migrantId] && [entry.type isEqualToString:FAMILY_TYPE_OTHER_EXTENDED_MEMBER]) {
                        //update
                        entry.migrantId = migrant.registrationNumber;
                        found = YES;
                        break;
                    }else if ([entry.migrantId isEqualToString:migrant.registrationNumber]){
                        //do not insert same value on different section
                        found = YES;
                        break;
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
            
            else if (indexPath.section == section_childs)
            {
                tmp = [ self.childData objectAtIndex:index];
                //check is this an update or new
                for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                    if ([entry.migrantId isEqualToString:tmp.migrantId] && [entry.type isEqualToString:FAMILY_TYPE_CHILD]) {
                        //update
                        entry.migrantId = migrant.registrationNumber;
                        found = YES;
                        break;
                    }else if ([entry.migrantId isEqualToString:migrant.registrationNumber]){
                        //do not insert same value on different section
                        found = YES;
                        break;
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
        [self showAlertWithTitle: NSLocalizedString(@"Failed Saving Family Data",Nil) message: NSLocalizedString(@"Please try again. If problem persist, please cancel and consult with administrator.",Nil)];
    }else {
        //save database
        [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
        
        // sleep for synch
        sleep(5);
        
        //set upload button enable
        self.itemUploadAll.enabled = TRUE;
    }
    
    [self dismissViewControllerAnimated:YES completion:Nil];
    
}

- (void)onCancel
{
    @try {
        if (self.editingMode) {
            [self.familyRegister.managedObjectContext rollback];
        }else {
            [self.context deleteObject:self.familyRegister];
        }
        
        NSError *error;
        if (![self.context save:&error]) {
            NSLog(@"Error deleting family data: %@", [error description]);
            [self showAlertWithTitle: NSLocalizedString(@"Failed Saving Family Data",Nil) message: NSLocalizedString(@"Please try again. If problem persist, please cancel and consult with administrator.",Nil)];
            
        }else {
            [[IMDBManager sharedManager] saveDatabase:^(BOOL success){
            }];
        }
        
        [self.navigationController dismissViewControllerAnimated:YES completion:Nil];
    }
    @catch (NSException *exception) {
        NSLog(@"exception onCancel : %@",[exception description]);
    }
    
    
}

- (void)onSave
{
    
    // Add HUD to screen
    [self.view addSubview:_hud];
    
    // Regisete for HUD callbacks so we can remove it from the window at the right time
    _hud.delegate = self;
    
    _hud.labelText =  NSLocalizedString(@"Saving...",Nil);
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

- (NSPredicate *)getPredicate:(NSInteger) section{
    NSPredicate *tmp = Nil;
    @try {
        
        Migrant * migrant = [Migrant migrantWithId:self.familyRegister.headOfFamilyId inContext:self.context];
        if (migrant) {
            if (section == section_head_of_family) {
                tmp = [NSPredicate predicateWithFormat:@"bioData.dateOfBirth <= %@ ",[self calculateAge:[NSDate date] compareAge:18 typeOfFuction:function_minus]];
                if (self.predicateHeadOfFamily) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.predicateHeadOfFamily]];
                if (self.predicateExclude) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self. self.predicateExclude]];
                
            }
            
            else if (section == section_other_extended_member) {
                //do not show head of family and child and spouse and grand mother and grand father and guardian
                tmp = self.predicateExclude?self.predicateExclude:Nil;
                
            }
            
            else if (section == section_grand_mother) {
                tmp = [NSPredicate predicateWithFormat:@"bioData.dateOfBirth <= %@ && bioData.gender = %@",[self calculateAge:migrant.bioData.dateOfBirth compareAge:15 typeOfFuction:function_minus],@"Female"];
                if (self.predicateExclude) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self. self.predicateExclude]];
                
            }
            
            else if (section == section_grand_father) {
                tmp = [NSPredicate predicateWithFormat:@"bioData.dateOfBirth <= %@ && bioData.gender = %@",[self calculateAge:migrant.bioData.dateOfBirth compareAge:15 typeOfFuction:function_minus],@"Male"];
                if (self.predicateExclude) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self. self.predicateExclude]];
                
            }
            
            else if (section == section_guadian) {
                
                tmp = [NSPredicate predicateWithFormat:@"bioData.dateOfBirth < %@",migrant.bioData.dateOfBirth];
                if (self.predicateExclude) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self. self.predicateExclude]];
                
            }
            
            else if (section == section_spouse) {
                //do not show head of family and child
                tmp = [NSPredicate predicateWithFormat:@"bioData.gender != %@ AND bioData.dateOfBirth <= %@ ",migrant.bioData.gender,[self calculateAge:[NSDate date] compareAge:18 typeOfFuction:function_minus]];
                if (self.predicateSpouse) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.predicateSpouse]];
                if (self.predicateExclude) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self. self.predicateExclude]];
                
            }
            
            else if (section == section_childs) {
                //do not show head of family and spouse
                tmp = [NSPredicate predicateWithFormat:@"bioData.dateOfBirth >= %@",[self calculateAge:migrant.bioData.dateOfBirth compareAge:15 typeOfFuction:function_plus]];
                if (self.predicateChilds) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.predicateChilds]];
                if (self.predicateExclude) tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self. self.predicateExclude]];
            }
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"Error on getPredicate : %@",[exception description]);
    }
    
    return tmp;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    return ((indexPath.section == section_head_of_family) || (indexPath.section == section_spouse) || (indexPath.section == section_guadian))?UITableViewCellEditingStyleNone:UITableViewCellEditingStyleDelete;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        FamilyRegisterEntry *entry = Nil;
        NSInteger index = indexPath.row/2;
        
        if (indexPath.section == section_other_extended_member) {
            
            if ([self.others count]) {
                entry = [ self.others objectAtIndex:index];
            }
            
        }
        
        else if (indexPath.section == section_childs) {
            if ([self.childData count]) {
                entry = [ self.childData objectAtIndex:index];
            }
            
        }
        
        else if (indexPath.section == section_grand_father) {
            if ([self.grandFather count]) {
                entry = [ self.grandFather objectAtIndex:index];
            }
            
        }
        
        else if (indexPath.section == section_grand_mother) {
            if ([self.grandMother count]) {
                entry = [ self.grandMother objectAtIndex:index];
            }
            
        }
        NSLog(@"Deleting");
        if (entry) {
            //delete from data
            [self.familyRegister removeFamilyEntryIDObject:entry];
            [self reloadData];
        }
    }
}


- (void)deleteItem:(UIButton *)sender
{
    
    @try {
        
        NSInteger maxSelection = [self getMaxSelection:sender.tag];
        
        //show migrant list
        UICollectionViewFlowLayout *aFlowLayout = [[UICollectionViewFlowLayout alloc] init];
        Migrant * tmp = Nil;
        [aFlowLayout setItemSize:CGSizeMake(320, 150)];
        [aFlowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
        IMFamilyListVC *list = [[IMFamilyListVC alloc] initWithCollectionViewLayout:aFlowLayout];
        list.maxSelection = maxSelection;
        
        if (!list.migrants) {
            list.migrants = [NSMutableArray array];
        }
        
        //set static data
        
        if (sender.tag == section_childs) {
            //get all migrant data, then copy it
            for (FamilyRegisterEntry *entry in self.childData) {
                tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                [list.migrants addObject:tmp];
            }
            
        }
        
        else if (sender.tag == section_other_extended_member) {
            //get all migrant data, then copy it
            for (FamilyRegisterEntry *entry in self.others) {
                tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                [list.migrants addObject:tmp];
            }
            
        }
        
        else if (sender.tag == section_grand_father) {
            //get all migrant data, then copy it
            for (FamilyRegisterEntry *entry in self.grandFather) {
                tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                [list.migrants addObject:tmp];
            }
            
        }
        
        else if (sender.tag == section_grand_mother) {
            //get all migrant data, then copy it
            for (FamilyRegisterEntry *entry in self.grandMother) {
                tmp = [Migrant migrantWithId:entry.migrantId inContext:self.context];
                [list.migrants addObject:tmp];
            }
            
        }
        
        list.onMultiSelect = ^(NSMutableArray *migrants)
        {
            NSMutableArray *tobeDelete = Nil;
            if ([migrants count]) {
                tobeDelete = [NSMutableArray array];
            }
            //update familyRegister data
            for (Migrant * migrant in migrants) {
                for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                    if ([entry.migrantId isEqualToString:migrant.registrationNumber]) {
                        //add to array to be remove later
                        [tobeDelete addObject:entry];
                    }
                }
            }
            
            if ([tobeDelete count]) {
                
                for (FamilyRegisterEntry *entry in tobeDelete) {
                    //delete from data
                    [self.familyRegister removeFamilyEntryIDObject:entry];
                }
                [self reloadData];
            }
            
            
        };
        
        list.useStaticData = YES;
        
        //show it
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:list];
        [self presentViewController:navCon animated:YES completion:nil];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception on deleteItem : %@",[exception description]);
    }
}

- (NSInteger)getMaxSelection:(NSInteger)section
{
    NSInteger maxSelection = 2;
    
    
    if (section == section_other_extended_member || section == section_childs) {
        maxSelection = 100;
        
    }
    
    else if (section == section_grand_father || section == section_grand_mother) {
        maxSelection = 2;
        
    }
    
    else {
        maxSelection = 2;
        
    }
    
    return maxSelection;
}

- (void)addMoreType:(UIButton *)sender
{
    //show movement type that available
    IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_FAMILY_TYPE delegate:self];
    vc.firstRowIsSpecial = NO;
    [self showOptionChooserWithConstantsKey:CONST_FAMILY_TYPE indexPath:[NSIndexPath indexPathForRow:0 inSection:sender.tag] useNavigation:NO];
    
}
- (void)addMoreChild:(UIButton *)sender
{
    //add special predicate for child, origin migrant age must be greater than child , at minimum 15 years
    NSInteger maxSelection = [self getMaxSelection:sender.tag];
    BOOL validation = YES;
    
    
    if (sender.tag == section_childs) {
        if (!self.haveHeadOfFamily) {
            
            [self showAlertWithTitle: NSLocalizedString(@"Failed Add Children",Nil) message: NSLocalizedString(@"Please input Head Of Family or Guardian before adding Children.",Nil)];
            
            return;
        }
        if ([self.childData count] >= maxSelection) {
            //validate input
            validation = NO;
            return;
        }
        
    }
    
    else if (sender.tag == section_other_extended_member) {
        if (!self.familyRegister.headOfFamilyId) {
            [self showAlertWithTitle: NSLocalizedString(@"Failed Add Other Extended Member",Nil) message: NSLocalizedString(@"Please input Head Of Family before adding Other Extended Member.",Nil)];
            
            return;
        }
        if ([self.others count] >= maxSelection) {
            validation = NO;
        }
        
    }
    
    else if (sender.tag == section_grand_father) {
        if ([self.grandFather count] >= maxSelection) {
            validation = NO;
        }
        
    }
    
    else if (sender.tag == section_grand_mother) {
        if ([self.grandMother count] >= maxSelection) {
            validation = NO;
        }
        
    }
    //validate data
    if (!validation) {
        [self showAlertWithTitle: NSLocalizedString(@"Maximum Selection",Nil) message:[NSString stringWithFormat: NSLocalizedString(@"You only can select %i for this section",Nil),maxSelection]];
        return;
    }
    //show migrant list
    UICollectionViewFlowLayout *aFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [aFlowLayout setItemSize:CGSizeMake(320, 150)];
    [aFlowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    IMFamilyListVC *list = [[IMFamilyListVC alloc] initWithCollectionViewLayout:aFlowLayout];
    list.maxSelection = maxSelection;
    
    //get predicate
    [list setBasePredicate:[self getPredicate:sender.tag]];
    
    list.onMultiSelect = ^(NSMutableArray *migrants)
    {
        BOOL found = NO;
        
        if (sender.tag == section_childs) {
            for (Migrant * migrant in migrants) {
                for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                    if ([entry.migrantId isEqualToString:migrant.registrationNumber] && [entry.type isEqualToString:FAMILY_TYPE_CHILD]) {
                        //update
                        entry.migrantId = migrant.registrationNumber;
                        found = YES;
                        break;
                    }else if ([entry.migrantId isEqualToString:migrant.registrationNumber]){
                        //do not insert same value on different section
                        found = YES;
                        break;
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
            
        }
        
        else if (sender.tag == section_other_extended_member) {
            for (Migrant * migrant in migrants) {
                
                for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                    if ([entry.migrantId isEqualToString:migrant.registrationNumber] && [entry.type isEqualToString:FAMILY_TYPE_OTHER_EXTENDED_MEMBER]) {
                        //update
                        entry.migrantId = migrant.registrationNumber;
                        found = YES;
                        break;
                    }else if ([entry.migrantId isEqualToString:migrant.registrationNumber]){
                        //do not insert same value on different section
                        found = YES;
                        break;
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
            
        }
        
        else if (sender.tag == section_grand_father) {
            
            for (Migrant * migrant in migrants) {
                
                for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                    if ([entry.migrantId isEqualToString:migrant.registrationNumber] && [entry.type isEqualToString:FAMILY_TYPE_GRAND_FATHER]) {
                        //update
                        entry.migrantId = migrant.registrationNumber;
                        found = YES;
                        break;
                    }else if ([entry.migrantId isEqualToString:migrant.registrationNumber]){
                        //do not insert same value on different section
                        found = YES;
                        break;
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
            //                break;
        }
        
        else if (sender.tag == section_grand_mother) {
            for (Migrant * migrant in migrants) {
                
                for (FamilyRegisterEntry *entry in self.familyRegister.familyEntryID) {
                    if ([entry.migrantId isEqualToString:migrant.registrationNumber] && [entry.type isEqualToString:FAMILY_TYPE_GRAND_MOTHER]) {
                        //update
                        entry.migrantId = migrant.registrationNumber;
                        found = YES;
                        break;
                    }else if ([entry.migrantId isEqualToString:migrant.registrationNumber]){
                        //do not insert same value on different section
                        found = YES;
                        break;
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
            
        }
        
        
        [self reloadData];
        
    };
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:list];
    [self presentViewController:navCon animated:YES completion:nil];
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
