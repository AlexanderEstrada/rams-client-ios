//
//  IMRegistrationListVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMRegistrationListVC.h"
#import "IMRegistrationCollectionViewCell.h"
#import "IMDBManager.h"
#import "Registration+Export.h"
#import "UIImage+ImageUtils.h"
#import "IMEditRegistrationVC.h"
#import "Accommodation+Extended.h"
#import "Migrant+Extended.h"
#import "DataProvider.h"
#import "IMConstants.h"
#import "Registration.h"
#import "MBProgressHUD.h"
#import "IMSSCheckMark.h"


typedef enum : NSUInteger {
    option_delete = 0,
    option_edit
    
} recognizer_option;

@interface IMRegistrationListVC () <DataProviderDelegate,MBProgressHUDDelegate,UIGestureRecognizerDelegate,UIActionSheetDelegate>

@property (nonatomic,strong) MBProgressHUD *HUD;
@property (nonatomic,strong) NSIndexPath * selectedIndexPath;
@property (nonatomic) NSInteger currentTag;
@property (nonatomic, strong) Registration *lastReg;
@end

@implementation IMRegistrationListVC

@synthesize dataProvider = _dataProvider;

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


- (void)setBasePredicate:(NSPredicate *)basePredicate
{
    @synchronized(self)
    {
        if (self.reloadingData || basePredicate == _basePredicate) {
            //            /do not do anything until data complete reload
            return;
        }
        
        _basePredicate = basePredicate;
        
        [self reloadData];
    };
    
}

- (void)executing
{
//    @synchronized(self)
//    {
        if(!self.reloadingData){
            self.reloadingData = YES;
            

            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Registration"];
            if (self.basePredicate) {
                request.predicate = self.basePredicate;
            }else {
                //default
                request.predicate =  [NSPredicate predicateWithFormat:@"complete = NO"];
            }
            request.returnsObjectsAsFaults = YES;
            
            NSError *error;
             NSManagedObjectContext * context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
            NSUInteger total = [context countForFetchRequest:request error:&error];
            DataProvider *dataProvider = [[DataProvider alloc] initWithPageSize:(total > Default_Page_Size)?Default_Page_Size:total initWithTotalData:total withEntity:@"Registration" andSort:@"dateCreated" basePredicate:request.predicate];
            self.dataProvider = Nil;
            [self setDataProvider:dataProvider];
            
            [_HUD hideUsingAnimation:YES];
            //            [self hideLoadingView];
            
            self.reloadingData = NO;
        }
//    };
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

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == IMAlertUpload_Tag && buttonIndex != [alertView cancelButtonIndex]) {
//        if (!_HUD) {
//            // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
//            _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
//            
//        }
//        
//        // Back to indeterminate mode
//        _HUD.mode = MBProgressHUDModeIndeterminate;
//        
//        // Regisete for HUD callbacks so we can remove it from the window at the right time
//        _HUD.delegate = self;
//        
//        _HUD.labelText = @"Just a moment please...";
//        
//        // Add HUD to screen
//        [self.navigationController.view addSubview:_HUD];
//        
//        // Show the HUD while the provided method executes in a new thread
////        [_HUD showWhileExecuting:@selector(uploading:) onTarget:self withObject:nil animated:YES];
//        [_HUD show:YES];
        [self showLoadingViewWithTitle:@"Just a moment please..."];
        [self uploading:Nil];
        
    }else {
        //    [self hideLoadingView];
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.collectionView reloadData];
    }
    
}

- (void)uploading:(UIButton *)sender
{
    
    Registration * registration = self.dataProvider.dataObjects[self.currentTag];
    
    //implement success and failure handler
    __weak typeof(self) weakSelf = self;
    registration.successHandler = ^{
        
        [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        //TODO : reload Data
        
        //delete data on data source
        [self.dataProvider.dataObjects removeObjectAtIndex:weakSelf.currentTag];
        [self.collectionView reloadData];
        
        //sleep for synchcronize
        sleep(5);
                [self hideLoadingView];
//        [_HUD hide:YES];
        [self showAlertWithTitle:@"Upload Success" message:nil];
        
    };
    
    registration.failureHandler = ^(NSError *error){
        [self dismissViewControllerAnimated:YES completion:nil];
                [self hideLoadingView];
//        [_HUD hide:YES];
        NSLog(@"error : %@",[error description]);
        [self showAlertWithTitle:@"Upload Failed" message:@"Please check your network connection and try again. If problem persist, contact administrator."];
        
    };
    
    //TODO : package data to json and send to server
    /*
     1. encode biometric data (fingers print and photo from jpg to Base64
     2. save registration data to local database
     3. create json format data from Registration
     4. Create connection to server
     5. Upload Registration Data to server
     */
    
    NSMutableDictionary * params = [[registration format] mutableCopy];
    
    //send the json data to server
    [registration sendRegistration:params];
    
}
- (void)upload:(UIButton *)sender
{
    //TODO: upload individual registration here
    //show confirmation
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Registration data"
                                                    message:@"Registration data will be uploaded and you need internet connection to do this.\nContinue upload Registration data?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Yes", nil];
    alert.tag = IMAlertUpload_Tag;
    //save current Tag
    self.currentTag = sender.tag;
    [alert show];
    
}


#pragma mark Collection View Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [collectionView.collectionViewLayout invalidateLayout];
    
    return [self.dataProvider.dataObjects count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"IMRegistrationCollectionViewCell";
    IMRegistrationCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    id data = self.dataProvider.dataObjects[indexPath.row];
    [self _configureCell:cell forDataObject:data animated:NO];
    cell.buttonUpload.tag = indexPath.row;
    // load photo images in the background
    __weak IMRegistrationListVC *weakSelf = self;
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // then set them via the main queue if the cell is still visible.
            if ([weakSelf.collectionView.indexPathsForVisibleItems containsObject:indexPath]) {
                IMRegistrationCollectionViewCell *cell =
                (IMRegistrationCollectionViewCell *)[weakSelf.collectionView cellForItemAtIndexPath:indexPath];
                id data = self.dataProvider.dataObjects[indexPath.row];
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
    
    //    [self hideLoadingView];
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
    
    if ([dataObject isKindOfClass:[Registration class]]) {
        Registration *registration = (Registration *) dataObject;
        if (!registration) {
            //do not show empty cell
            return;
        }
        cell.labelTitle.text = registration.fullname;
        cell.labelSubtitle.text = [registration.registrationId length]?[NSString stringWithFormat:@"Reg. Number %@",registration.registrationId]:Nil;
        //        cell.labelDetail1.text = registration.bioData.nationality.name;
        cell.labelDetail1.text = registration.bioDataSummary;
        cell.labelDetail2.text = registration.unhcrDocument;
        cell.labelDetail3.text = [registration.unhcrNumber length]?[NSString stringWithFormat:@"Doc. Number %@",registration.unhcrNumber]:Nil;
        cell.labelDetail4.text = registration.interceptionSummary;
        NSManagedObjectContext *workingContext = registration.managedObjectContext;
        NSError *error;
        
        if (registration.detentionLocationName) {
            cell.labelDetail5.text = registration.detentionLocationName;
        }else if (registration.detentionLocation) {
            Accommodation * place = [Accommodation accommodationWithId:registration.detentionLocation inManagedObjectContext:workingContext];
            cell.labelDetail5.text = place.name;
            //save detention location name
            registration.detentionLocationName = place.name;
            
            //save to database
            if (![workingContext save:&error]) {
                NSLog(@"Error saving context: %@", [error description]);
            }
            
        }else {
            registration.detentionLocationName = cell.labelDetail5.text = [registration.transferDestination.name length]?registration.transferDestination.name:Nil;
            registration.detentionLocation = [registration.detentionLocationName length]?registration.transferDestination.accommodationId:Nil;
        }
        
        UIImage *image = registration.biometric.photographImageThumbnail;
        if (image) {
            
            cell.photoView.image = image;
            
        }else {
            //check if there is photo, case exist then create thumbnail and show it
            image = registration.biometric.photographImage;
            if (image) {
                //create thumbnail
                cell.photoView.image = [image scaledToWidthInPoint:125];
                NSData *imgData= UIImagePNGRepresentation(cell.photoView.image);
                
                [registration.biometric updatePhotographThumbnail:imgData];
                
                //save to database
                if (![workingContext save:&error]) {
                    NSLog(@"Error saving context: %@", [error description]);
                }
                
            }else cell.photoView.image = [UIImage imageNamed:@"icon-avatar"];
        }
        
        cell.buttonUpload.hidden = !registration.complete.boolValue;
        [cell.buttonUpload removeTarget:self action:@selector(upload:) forControlEvents:UIControlEventTouchUpInside];
        [cell.buttonUpload addTarget:self action:@selector(upload:) forControlEvents:UIControlEventTouchUpInside];
        
        if (self.tabBarController.selectedIndex != 2){
            //implement long press gesture recognizer
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
            longPress.minimumPressDuration = .5; //seconds
            longPress.delegate = self;
            longPress.delaysTouchesBegan = YES;
            
            [cell addGestureRecognizer:longPress];
        }
        
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
            }];
        }
    }
}

- (void)longPress:(UILongPressGestureRecognizer*)gesture
{
    if ( gesture.state == UIGestureRecognizerStateEnded ) {
        
        CGPoint location = [gesture locationInView:self.collectionView];
        
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
        if (indexPath == nil){
            NSLog(@"couldn't find index path");
        } else {
            //set selected index
            self.selectedIndexPath = indexPath;
            
            //check if there is image to preview
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Action",Nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",Nil) destructiveButtonTitle:NSLocalizedString(@"Delete",Nil) otherButtonTitles:NSLocalizedString(@"Edit",Nil),nil];
            
            CGRect rect = CGRectMake(location.x, location.y,30, 30);
            [actionSheet showFromRect:rect inView:self.view animated:YES];
            
            
        }
        
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    @try {
        if (buttonIndex == option_delete) {
            // get the cell at indexPath (the one you long pressed)
            // do stuff with the cell
            Registration *registration = self.dataProvider.dataObjects[self.selectedIndexPath.row];
            
            //delete on data base and datasource
            NSManagedObjectContext * context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
            [context deleteObject:registration];
            NSError * err;
            [context save:&err];
            if (err) {
                NSLog(@"error : %@",[err description]);
            }else {
                [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil userInfo:nil];
                [self.dataProvider.dataObjects removeObjectAtIndex:self.selectedIndexPath.row];
                [self.collectionView reloadData];
//                registration= Nil;
            }
        }else if (buttonIndex == option_edit) {
            //show edit
            [self collectionView:self.collectionView didSelectItemAtIndexPath:self.selectedIndexPath];
        }else {
            NSLog(@"Not implement yet");
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exeption : %@",[exception description]);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    Registration *registration = self.dataProvider.dataObjects[indexPath.row];
    IMEditRegistrationVC *editVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IMEditRegistrationVC"];
    
    if (registration.registrationId) {
        //get the latest data from database
        NSManagedObjectContext * context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        registration = [Registration registrationWithId:registration.registrationId inManagedObjectContext:context];
    }
    
    editVC.registration = registration;
    //set last registration
    editVC.LastReg = self.lastReg;
    
    editVC.registrationSave = ^(BOOL remove)
    {
        //TODO : reload Data
        if (remove) {
            //delete data on data source
            [self.dataProvider.dataObjects removeObjectAtIndex:indexPath.row];
            [self.collectionView reloadData];
        }else {
            //reload Data
            [self reloadData];
        }
    };
    
    editVC.registrationLast = ^(Registration *reg)
    {
        if (reg) {
            //save last registration
            self.lastReg = reg;
        }
    };
    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:editVC];
    [self.tabBarController presentViewController:navCon animated:YES completion:nil];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        if (indexPath.row < [self.dataProvider.dataObjects count] ) {
            if ([self.dataProvider.dataObjects[indexPath.row] isKindOfClass:[Registration class]]) {
                Registration *reg = self.dataProvider.dataObjects[indexPath.row];
                
                if (reg) {
                    [reg didTurnIntoFault];
                }
            }
        }
        
        
    }
    @catch (NSException *exception) {
        NSLog(@"Error faulting registration data: %@", [exception description]);
    }
}


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"IMRegistrationCollectionViewCell"
                                                    bundle:[NSBundle mainBundle]]
          forCellWithReuseIdentifier:@"IMRegistrationCollectionViewCell"];
    
    self.thumbnailQueue = [[NSOperationQueue alloc] init];
    self.thumbnailQueue.maxConcurrentOperationCount = 3;
    self.firstLaunch = YES;
    
    if (!_HUD) {
        // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
        _HUD = [[MBProgressHUD alloc] initWithView:self.view];
    }
    
    
    //hide loading view
    //     [self hideLoadingView];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.dataProvider.dataObjects && !self.reloadingData){
        [self reloadData];
    }
    //    else {
    //        [self hideLoadingView];
    //    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    self.dataProvider = Nil;
    [self.collectionView reloadData];
}

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


@end