//
//  IMFamilyListVCViewController.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 7/31/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMFamilyListVC.h"
#import "IMSSCheckMark.h"
#import "FamilyData+Extended.h"
#import "IMRegistrationCollectionViewCell.h"
#import "DataProvider.h"
#import "IMConstants.h"
#import "MBProgressHUD.h"
#import "IMMigrantFilterDataVC.h"
#import "IMEditRegistrationVC.h"
#import "IMDBManager.h"
#import "Migrant+Extended.h"
#import "UIImage+ImageUtils.h"
#import "Registration+Export.h"
#import "IMConstants.h"


@interface IMFamilyListVC () <DataProviderDelegate,MBProgressHUDDelegate,UIPopoverControllerDelegate>

@property (nonatomic,strong) MBProgressHUD *HUD;
@property (nonatomic,strong) FamilyData *familyData;
@property (nonatomic, strong) IMMigrantFilterDataVC * filterChooser;
@property (nonatomic, strong) UIPopoverController *popover;
//@property (nonatomic,strong)  UIBarButtonItem *itemSelected;
@property (nonatomic,strong) NSMutableArray *deletedMigrants;



@end

@implementation IMFamilyListVC

@synthesize delegate;
@synthesize dataProvider = _dataProvider;


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
    //default value
    // Do any additional setup after loading the view.
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"IMRegistrationCollectionViewCell"
                                                    bundle:[NSBundle mainBundle]]
          forCellWithReuseIdentifier:@"IMRegistrationCollectionViewCell"];
    
    self.thumbnailQueue = [[NSOperationQueue alloc] init];
    self.thumbnailQueue.maxConcurrentOperationCount = 3;
    
    //set multiple selection as default
     self.collectionView.allowsMultipleSelection = YES;
    
    UIBarButtonItem *itemFilter = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                target:self action:@selector(showFilterOptions:)];
//    self.itemSelected = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStyleBordered target:self action:@selector(setMultipleSelection)];
    self.save =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onSave)];
    
//    self.navigationItem.rightBarButtonItems = @[self.save,itemFilter,self.itemSelected];
       self.navigationItem.rightBarButtonItems = @[self.save,itemFilter];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    
    if (!self.migrants) {
        self.migrants = [NSMutableArray array];
    }
        
    //set to no until user add migrant
    self.save.enabled = NO;
    self.maxSelection = 1;
//    self.useStaticData = NO;
}

- (void)setUseStaticData:(BOOL)useStaticData
{
    if (_useStaticData != useStaticData) {
        _useStaticData = useStaticData;
         [self reloadData];
    }
}
- (void)setMaxSelection:(int)maxSelection{
    if (maxSelection > _maxSelection) {
        _maxSelection = maxSelection;
        [self reloadData];
    }
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == IMDeleteItems_Tag && buttonIndex != [alertView cancelButtonIndex]) {
        //start deleting
        //send data to caller
        if (self.self.onMultiSelect) {
            self.onMultiSelect(self.deletedMigrants);
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    
    
}

-(void)onSave
{
    if (self.useStaticData) {
        //show warning alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Data"
                                                        message:@"Are you sure to delete this items?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Yes", nil];
        alert.tag = IMDeleteItems_Tag;
        [alert show];
        
        return;
    }
    //send data to caller
    if (self.self.onMultiSelect) {
        self.onMultiSelect(self.migrants);
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)cancel
{
   [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    self.dataProvider = Nil;
    [self.collectionView reloadData];
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    
    if (!self.dataProvider.dataObjects && !self.reloadingData){
        
        [self reloadData];
    }
    
    if ([self.dataProvider.dataObjects count]) {
        [self showLoadingViewWithTitle:@"Loading ..."];
    }
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //hide loading view
    [self hideLoadingView];
}

#pragma mark - Accessors
- (void)setDataProvider:(DataProvider *)dataProvider {
    
    if (dataProvider != _dataProvider) {
        _dataProvider = dataProvider;
        _dataProvider.delegate = self;
        _dataProvider.shouldLoadAutomatically = YES;
        _dataProvider.automaticPreloadMargin = FluentPagingCollectionViewPreloadMargin;
        if ([self isViewLoaded]) {
            [self.collectionView reloadData];
        }
    }
}

- (id)initWithPredicate:(NSPredicate *)basepredicate
{
    [self setBasePredicate:basepredicate];
    
    return self;
}

- (void)setBasePredicate:(NSPredicate *)basePredicate
{
    if (self.reloadingData || basePredicate == _basePredicate) {
        //            /do not do anything until data complete reload
        return;
    }
    
    _basePredicate = basePredicate;
    
    [self reloadData];
}

- (void)setFamilyData:(FamilyData *)familyData
{
    @try {
        if (familyData) {
            _familyData = familyData;
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    
    
}

- (void)executing
{
    if(!self.reloadingData){

        self.reloadingData = YES;
        
        if (!self.useStaticData) {
            //case use data from database
            NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Migrant"];
            if (self.basePredicate) {
                request.predicate = self.basePredicate;
            }else {
                //default
                request.predicate =  [NSPredicate predicateWithFormat:@"active = YES AND complete = YES"];
            }
            request.returnsObjectsAsFaults = YES;
            NSError *error;
            NSUInteger total = [context countForFetchRequest:request error:&error];
            DataProvider *dataProvider = [[DataProvider alloc] initWithPageSize:(total > Default_Page_Size)?Default_Page_Size:total initWithTotalData:total withEntity:@"Migrant" andSort:@"dateCreated" basePredicate:request.predicate];
            
            self.dataProvider = Nil;
            [self setDataProvider:dataProvider];
            
            //        [_HUD hideUsingAnimation:YES];
        }else {
//            if ([self isViewLoaded]) {
                [self.collectionView reloadData];
//            }

        }
    
       
        self.reloadingData = NO;
        
    }
}

- (void)reloadData
{
//    // Show progress window
//    if (!_HUD) {
//        // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
//        _HUD = [[MBProgressHUD alloc] initWithView:self.view];
//    }
//    
//    
//    
//    // Add HUD to screen
//    [self.view addSubview:_HUD];
//    
//    // Regisete for HUD callbacks so we can remove it from the window at the right time
//    _HUD.delegate = self;
//    
//    _HUD.labelText = @"Reloading Data...";
//    
//    // Show the HUD while the provided method executes in a new thread
//    [_HUD showUsingAnimation:YES];
    
    [self executing];
    
}

#pragma mark Collection View Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [collectionView.collectionViewLayout invalidateLayout];
    return self.useStaticData?self.migrants.count:self.dataProvider.dataObjects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"IMRegistrationCollectionViewCell";
    IMRegistrationCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    id data = self.useStaticData?self.migrants[indexPath.row]:self.dataProvider.dataObjects[indexPath.row];
    
    if ([collectionView.indexPathsForSelectedItems containsObject:indexPath]) {
        [collectionView selectItemAtIndexPath:indexPath animated:FALSE scrollPosition:UICollectionViewScrollPositionNone];
        // Select Cell
    }
    
    [self _configureCell:cell forDataObject:data animated:NO];
    cell.buttonUpload.tag = indexPath.row;
    // load photo images in the background
    __weak IMFamilyListVC *weakSelf = self;
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        //        UIImage *image = [photo image];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // then set them via the main queue if the cell is still visible.
            if ([weakSelf.collectionView.indexPathsForVisibleItems containsObject:indexPath]) {
                IMRegistrationCollectionViewCell *cell =
                (IMRegistrationCollectionViewCell *)[weakSelf.collectionView cellForItemAtIndexPath:indexPath];
                id data = self.useStaticData?self.migrants[indexPath.row]:self.dataProvider.dataObjects[indexPath.row];
                [self _configureCell:cell forDataObject:data animated:NO];
                cell.buttonUpload.tag = indexPath.row;
            }
        });
    }];
    
    [self.thumbnailQueue addOperation:operation];
    
    return cell;
}

#pragma mark - Data controller delegate
- (void)dataProvider:(DataProvider *)dataProvider willLoadDataAtIndexes:(NSIndexSet *)indexes {
    
}

- (void)dataProvider:(DataProvider *)dataProvider didLoadDataAtIndexes:(NSIndexSet *)indexes {
    
    //hide loading view
    [self hideLoadingView];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        
        if ([self.collectionView.indexPathsForVisibleItems containsObject:indexPath]) {
            
            IMRegistrationCollectionViewCell *cell = (IMRegistrationCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [self _configureCell:cell forDataObject:dataProvider.dataObjects[index] animated:NO];
        }
    }];
}

#pragma mark - Private methods
- (void)_configureCell:(IMRegistrationCollectionViewCell *)cell forDataObject:(id)dataObject animated:(BOOL)animated {
    
    if ([dataObject isKindOfClass:[Migrant class]]) {
        Migrant *migrant = (Migrant *) dataObject;
        
        if (!migrant || !migrant.fullname || !migrant.registrationNumber || !migrant.bioDataSummary) {
            //do not show empty cell
            return;
        }
        cell.labelTitle.text = migrant.fullname;
        cell.labelSubtitle.text = migrant.registrationNumber;
        cell.labelDetail1.text = migrant.bioDataSummary;
        cell.labelDetail2.text = migrant.unhcrSummary;
        cell.labelDetail3.text = migrant.interceptionSummary;
        
        
        
        if (self.collectionView.allowsMultipleSelection && [self.migrants count]) {
            //case multiple selection, then mark all data that already selected
            for (Migrant * tmp in self.migrants) {
                if ([tmp.registrationNumber isEqualToString:migrant.registrationNumber]) {
                    
                    CGRect rect = CGRectMake(290, 120, 30, 30);
                    IMSSCheckMark * checkmark = [[IMSSCheckMark alloc] initWithFrame:rect];
                    checkmark.checked = TRUE;
                    checkmark.checkMarkStyle = SSCheckMarkStyleOpenCircle;
                    cell.selectedBackgroundView = checkmark;
                    cell.selectedBackgroundView.frame = rect;
                    cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
                    [self.collectionView setNeedsDisplay];
                }
            }
            
            
        }
        
        NSManagedObjectContext *workingContext = migrant.managedObjectContext;
        NSError *error;
        
        if (migrant.detentionLocationName) {
            cell.labelDetail4.text = migrant.detentionLocationName;
        }else if (migrant.detentionLocation) {
            Accommodation * place = [Accommodation accommodationWithId:migrant.detentionLocation inManagedObjectContext:workingContext];
            cell.labelDetail4.text = place.name;
            
            //save detention location name
            migrant.detentionLocationName = place.name;
            
            //save to database
            if (![workingContext save:&error]) {
                NSLog(@"Error saving context: %@", [error description]);
            }
            
        }else {
            cell.labelDetail4.text = Nil;
        }
        cell.labelDetail5.text = Nil;
        
        UIImage *image = migrant.biometric.photographImageThumbnail;
        if (image) {
            
            cell.photoView.image = image;
            
        }else {
            //check if there is photo, case exist then create thumbnail and show it
            image = migrant.biometric.photographImage;
            if (image) {
                //create thumbnail
                cell.photoView.image = [image scaledToWidthInPoint:125];
                NSData *imgData= UIImagePNGRepresentation(cell.photoView.image);
                
                [migrant.biometric updatePhotographThumbnailData:imgData];
                
                //save to database
                if (![workingContext save:&error]) {
                    NSLog(@"Error saving context: %@", [error description]);
                }
                
            }else cell.photoView.image = [UIImage imageNamed:@"icon-avatar"];
        }
        
        cell.buttonUpload.hidden = TRUE;
        
        if (animated) {
            cell.photoView.alpha = 0;
            cell.labelTitle.alpha = 0;
            cell.labelSubtitle.alpha = 0;
            cell.labelDetail1.alpha = 0;
            cell.labelDetail2.alpha = 0;
            cell.labelDetail3.alpha = 0;
            cell.labelDetail4.alpha = 0;
            cell.labelDetail5.alpha = 0;
            cell.buttonUpload.alpha = 0;
            [UIView animateWithDuration:IMRootViewAnimationDuration animations:^{
                cell.photoView.alpha = 1;
                cell.labelTitle.alpha = 1;
                cell.labelSubtitle.alpha = 1;
                cell.labelDetail1.alpha = 1;
                cell.labelDetail2.alpha = 1;;
                cell.labelDetail3.alpha = 1;
                cell.labelDetail4.alpha = 1;
                cell.labelDetail5.alpha = 1;
                cell.buttonUpload.alpha = 1;
            }completion:Nil];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.collectionView.allowsMultipleSelection) {
        
        static NSString *cellIdentifier = @"IMRegistrationCollectionViewCell";
        IMRegistrationCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        CGRect rect = CGRectMake(290, 120, 30, 30);
        IMSSCheckMark * checkmark = [[IMSSCheckMark alloc] initWithFrame:rect];
        checkmark.checked = TRUE;
        checkmark.checkMarkStyle = SSCheckMarkStyleOpenCircle;
        cell.selectedBackgroundView = checkmark;
        cell.selectedBackgroundView.frame = rect;
        cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
        
        cell.backgroundView = checkmark;
        cell.backgroundView.frame = rect;
        cell.backgroundView.backgroundColor = [UIColor clearColor];
        
        
        [collectionView setNeedsDisplay];
        // Determine the selected items by using the indexPath
        Migrant *migrant = self.useStaticData?self.migrants[indexPath.row]:self.dataProvider.dataObjects[indexPath.row];
        // implement multiple selection for collection view

        //set Yes, cause user already add the migrant data
        if (!self.save.enabled) {
            self.save.enabled = YES;
        }
        
        if (self.onSelect) {
            self.onSelect(migrant);
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        
        if (self.useStaticData) {
            //remove data
            //remove migrants from array
//            [self.migrants removeObject:migrant];
            if (!self.deletedMigrants) {
                self.deletedMigrants = [NSMutableArray array];
            }
            //add migrants to array
            [self.deletedMigrants addObject:migrant];
        }else{
        
        //set check for multi selection
        if ([self.migrants count] < self.maxSelection) {
       
        //add migrants to array
        [self.migrants addObject:migrant];
        
        }else{
            [self showAlertWithTitle:@"Maximum Selection" message:[NSString stringWithFormat:@"You only can select %i for this section",self.maxSelection]];
            [collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
        
        }
        
    }else {
        @try {
            Migrant *migrant = self.dataProvider.dataObjects[indexPath.row];
            
            NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
            
            //save to registration
            Registration * registration = [Registration registrationFromMigrant:migrant inManagedObjectContext:context];
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
            
            IMEditRegistrationVC *editVC = [storyboard instantiateViewControllerWithIdentifier:@"IMEditRegistrationVC"];
            editVC.registration = registration;
            
            UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:editVC];
            [self.navigationController presentViewController:navCon animated:YES completion:Nil];
        }
        @catch (NSException *exception) {
            NSLog(@"Error : %@",[exception description]);
        }
        
        
    }
    
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    // Determine the selected items by using the indexPath
    Migrant *migrant = self.useStaticData?self.migrants[indexPath.row]:self.dataProvider.dataObjects[indexPath.row];
    // implement multiple selection for collection view

    //set check
    //remove migrants from array
        self.useStaticData?[self.deletedMigrants removeObject:migrant]:[self.migrants removeObject:migrant];
    
    static NSString *cellIdentifier = @"IMRegistrationCollectionViewCell";
    IMRegistrationCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    //set background view
    cell.backgroundView = Nil;
    
    // user can not move to next page if the migrant data is empty
    if (self.useStaticData?![self.deletedMigrants count]:![self.migrants count] && self.save.enabled) {
        self.save.enabled = NO;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        if (indexPath.row < self.useStaticData?[self.migrants count]:[self.dataProvider.dataObjects count] ) {
            if (self.useStaticData?[self.migrants[indexPath.row] isKindOfClass:[Migrant class]]:[self.dataProvider.dataObjects[indexPath.row] isKindOfClass:[Migrant class]]) {
                Migrant *migrant = self.useStaticData?self.migrants[indexPath.row] :self.dataProvider.dataObjects[indexPath.row];
                
                if (migrant) {
                    [migrant didTurnIntoFault];
                }
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Error faulting migrant data: %@", [exception description]);
    }
}

- (void)showFilterOptions:(UIBarButtonItem *)sender
{
    
    if (!self.filterChooser) {
        //remove active predicate, we use active predicate from filter chooser
        self.basePredicate = [NSPredicate predicateWithFormat:@"complete = YES"];
        self.filterChooser = [[IMMigrantFilterDataVC alloc] initWithAction:^(NSPredicate *basePredicate)
                              {
                                  [self.popover dismissPopoverAnimated:YES];
                                  self.popover = nil;
                                  if (basePredicate) {
                                      
                                      self.basePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[basePredicate]];
                                  }else self.basePredicate = Nil;
                              } andBasePredicate:self.basePredicate
                              ];
        
        self.filterChooser.view.tintColor = [UIColor IMMagenta];
        //set predicate
        self.filterChooser.basePredicate = self.basePredicate;
    }else{
        //set predicate
        self.filterChooser.basePredicate = self.basePredicate;
    }
//    // Establish the weak self reference
//    __weak typeof(self) weakSelf = self;
//    self.filterChooser.doneCompletionBlock = ^(NSMutableDictionary * value)
//    {
//        //TODO : reload Data
//        weakSelf.basePredicate = Nil;
//    };
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.filterChooser];
    
    if (!self.popover) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:navController];
        self.popover.delegate = self;
    }
    
    [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
}


//- (void)setMultipleSelection
//{
//    if ([self.itemSelected.title isEqualToString:@"Select"]) {
//        self.collectionView.allowsMultipleSelection = YES;
//        //change title to Cancel
//        self.itemSelected.title = @"Cancel";
//        
//        
//    }else {
//        //change title to Select
//        self.itemSelected.title = @"Select";
//        self.collectionView.allowsMultipleSelection = NO;
//        
//        //clear all selected item
//        self.migrants = Nil;
//        
//        //set Yes, cause user already add the migrant data
//        if (self.save.enabled) {
//            self.save.enabled = NO;
//        }
//
//    }
//    
//    //reload data
//    if ([self isViewLoaded]) {
//        [self.collectionView reloadData];
//    }
//
//}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.collectionView reloadData];
}


#pragma mark Collection View Layout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    return CGSizeMake(320, 150);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    CGFloat padding = [self padding];
    return UIEdgeInsetsMake(20, padding, 20, padding);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return [self padding];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return [self padding];
}

- (CGFloat)padding
{
    CGFloat padding = 0;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        padding = (self.view.bounds.size.width - (320 * 2)) / 3;
    }else {
        padding = (self.view.bounds.size.width - (320 * 3)) / 4;
    }
    
    return padding;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.collectionView setAlpha:0.0f];
    [self.collectionView.collectionViewLayout invalidateLayout];
    CGPoint currentOffset = [self.collectionView contentOffset];
    self.currentIndex = currentOffset.x / self.collectionView.frame.size.width;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    // Force realignment of cell being displayed
    CGSize currentSize = self.collectionView.bounds.size;
    float offset = self.currentIndex * currentSize.width;
    [self.collectionView setContentOffset:CGPointMake(offset, 0)];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.currentIndex inSection:0];
    
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    
    [UIView animateWithDuration:0.125f animations:^{
        [self.collectionView setAlpha:1.0f];
    }];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    [_HUD removeFromSuperview];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"SubmitData"]) {
        [[segue destinationViewController] setDelegate:self];
//        NSMutableDictionary * dict = [NSMutableDictionary dictionary];
//        //only set if there is data
//        if (self.movement) {
//            [dict setObject:self.movement forKey:@"Movement"];
//        }
//        if ([self.migrants count]) {
//            [dict setObject:self.migrants forKey:@"Migrant"];
//        }
//        
//        
//        //prepare data and set it
//        [[segue destinationViewController] setMigrantData:dict];
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
