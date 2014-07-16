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

#import "MBProgressHUD.h"



@interface IMRegistrationListVC () <DataProviderDelegate>

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

        // Show progress window
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Reloading Data...";
        
        [self reloadData];
    };

}

- (void)reloadData
{
    
    @synchronized(self)
    {
        if(!self.reloadingData){
            self.reloadingData = YES;
            
            NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Registration"];
            if (self.basePredicate) {
                request.predicate = self.basePredicate;
            }else {
                //default
               request.predicate =  [NSPredicate predicateWithFormat:@"complete = NO"];
            }
            request.returnsObjectsAsFaults = YES;
            
            NSError *error;
            
            NSUInteger total = [context countForFetchRequest:request error:&error];
            DataProvider *dataProvider = [[DataProvider alloc] initWithPageSize:(total > Default_Page_Size)?Default_Page_Size:total initWithTotalData:total withEntity:@"Registration" andSort:@"dateCreated" basePredicate:request.predicate];
            self.dataProvider = Nil;
            [self setDataProvider:dataProvider];
    
//            // Remove progress window
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            self.reloadingData = NO;
            
        }
    };

}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self hideLoadingView];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.collectionView reloadData];
    
}

- (void)upload:(UIButton *)sender
{
    //TODO: upload individual registration here
    Registration * registration = self.dataProvider.dataObjects[sender.tag];
    //implement success and failure handler
    registration.onProgress = ^{
        [self showLoadingViewWithTitle:@"Just a moment please..."];
    };
    
    registration.successHandler = ^{
        
        //sleep for synchcronize
        sleep(5);
        [self hideLoadingView];
        [self showAlertWithTitle:@"Upload Success" message:nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
        //TODO : reload Data
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           //delete data on data source
                           [self.dataProvider.dataObjects removeObjectAtIndex:sender.tag];
                           [self.collectionView reloadData];
                           
                       });
    };
    
    registration.failureHandler = ^(NSError *error){
        [self hideLoadingView];
        [self showAlertWithTitle:@"Upload Failed" message:@"Please check your network connection and try again. If problem persist, contact administrator."];
        [self dismissViewControllerAnimated:YES completion:nil];
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
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        
        if ([self.collectionView.indexPathsForVisibleItems containsObject:indexPath]) {
            
            IMRegistrationCollectionViewCell *cell = (IMRegistrationCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [self _configureCell:cell forDataObject:dataProvider.dataObjects[index] animated:YES];
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
        cell.labelSubtitle.text = registration.registrationId;
        //        cell.labelDetail1.text = registration.bioData.nationality.name;
        cell.labelDetail1.text = registration.bioDataSummary;
        cell.labelDetail2.text = registration.unhcrSummary;
        cell.labelDetail3.text = registration.interceptionSummary;
        
        if (registration.detentionLocation) {
            NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
            
            Accommodation * place = [Accommodation accommodationWithId:registration.detentionLocation inManagedObjectContext:context];
            cell.labelDetail4.text = place.name;
        }else {
            cell.labelDetail4.text = Nil;
        }
        cell.labelDetail5.text = Nil;
        
        UIImage *image = registration.biometric.photographImage;
        if (image) {
            cell.photoView.image = [image scaledToWidthInPoint:100];
        }else {
            cell.photoView.image = [UIImage imageNamed:@"icon-avatar"];
        }
        
        cell.buttonUpload.hidden = !registration.complete.boolValue;
        [cell.buttonUpload removeTarget:self action:@selector(upload:) forControlEvents:UIControlEventTouchUpInside];
        [cell.buttonUpload addTarget:self action:@selector(upload:) forControlEvents:UIControlEventTouchUpInside];
        
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



- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Registration *registration = self.dataProvider.dataObjects[indexPath.row];
    
    IMEditRegistrationVC *editVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IMEditRegistrationVC"];
    editVC.registration = registration;

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
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.dataProvider.dataObjects && !self.reloadingData){
        [self reloadData];
    }
    
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

@end