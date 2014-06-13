//
//  IMMigrantListVC.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 6/2/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMMigrantListVC.h"
#import "IMDBManager.h"
#import "Registration+Export.h"
#import "UIImage+ImageUtils.h"
#import "IMEditRegistrationVC.h"
#import "Accommodation+Extended.h"
#import "Migrant+Extended.h"
#import "Migrant.h"
#import "IMRegistrationCollectionViewCell.h"

#import "MBProgressHUD.h"


@interface IMMigrantListVC () <MBProgressHUDDelegate> {
	MBProgressHUD *HUD;
}

@end


@implementation IMMigrantListVC

- (void)setBasePredicate:(NSPredicate *)basePredicate
{
    
    _basePredicate = basePredicate;
    
    if (!HUD) {
        // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
        HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    }
    // Add HUD to screen
    [self.navigationController.view addSubview:HUD];
    
    // Regisete for HUD callbacks so we can remove it from the window at the right time
    HUD.delegate = self;
    
    
    
    HUD.labelText = @"Reloading Data";
    
    // Show the HUD while the provided method executes in a new thread
    [HUD showWhileExecuting:@selector(reloadData) onTarget:self withObject:nil animated:YES];
    
}

- (void)reloadData
{
    
    if(!self.reloadingData){
        self.reloadingData = YES;
        
        NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Migrant"];
        if (self.basePredicate) {
            request.predicate = self.basePredicate;
        }
        
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO]];
        request.returnsObjectsAsFaults = YES;
        NSError *error;
        self.data = [[context executeFetchRequest:request error:&error] mutableCopy];
        self.reloadingData = NO;
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           [self.collectionView reloadData];
                           
                       });
        if ([self.data count] > 100) {
            sleep(2);
        }
        self.reloadingData = NO;
    }
    
    
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    [self.collectionView reloadData];
    
}

- (void)upload:(UIButton *)sender
{
    //TODO: upload individual registration here
    Registration *registration = self.data[sender.tag];
    //implement success and failure handler
    registration.onProgress = ^{
        [self showLoadingViewWithTitle:@"Just a moment please..."];
    };
    
    registration.successHandler = ^{
        
        [self hideLoadingView];
        [self showAlertWithTitle:@"Upload Success" message:nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        //TODO : reload Data
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           //delete data on data source
                           [self.data removeObjectAtIndex:sender.tag];
                           [self.collectionView reloadData];
                           
                       });
        
        
    };
    
    registration.failureHandler = ^(NSError *error){
        [self hideLoadingView];
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


#pragma mark Collection View Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [collectionView.collectionViewLayout invalidateLayout];
    return [self.data count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"IMRegistrationCollectionViewCell";
    IMRegistrationCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    Migrant *migrant = self.data[indexPath.row];
    cell.labelTitle.text = migrant.fullname;
    cell.labelSubtitle.text = migrant.registrationNumber;
    cell.labelDetail1.text = migrant.bioDataSummary;
    cell.labelDetail2.text = migrant.unhcrSummary;
    cell.labelDetail3.text = migrant.interceptionSummary;
    if (migrant.detentionLocation) {
        NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        Accommodation * place = [Accommodation accommodationWithId:migrant.detentionLocation inManagedObjectContext:context];
        cell.labelDetail4.text = place.name;
    }else {
        cell.labelDetail4.text = Nil;
    }
    cell.labelDetail5.text = Nil;
    
    
    
    UIImage *image = migrant.biometric.photographImage;
    if (image) {
        cell.photoView.image = [image scaledToWidthInPoint:140];
    }else {
        cell.photoView.image = [UIImage imageNamed:@"icon-avatar"];
    }
    cell.buttonUpload.hidden = TRUE;
    cell.buttonUpload.tag = indexPath.row;
    [cell.buttonUpload removeTarget:self action:@selector(upload:) forControlEvents:UIControlEventTouchUpInside];
    [cell.buttonUpload addTarget:self action:@selector(upload:) forControlEvents:UIControlEventTouchUpInside];
    
    
    // load photo images in the background
    __weak IMMigrantListVC *weakSelf = self;
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        //        UIImage *image = [photo image];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // then set them via the main queue if the cell is still visible.
            if ([weakSelf.collectionView.indexPathsForVisibleItems containsObject:indexPath]) {
                IMRegistrationCollectionViewCell *cell =
                (IMRegistrationCollectionViewCell *)[weakSelf.collectionView cellForItemAtIndexPath:indexPath];
                Migrant *migrant = self.data[indexPath.row];
                cell.labelTitle.text = migrant.fullname;
                cell.labelSubtitle.text = migrant.registrationNumber;
                cell.labelDetail1.text = migrant.bioDataSummary;
                cell.labelDetail2.text = migrant.unhcrSummary;
                cell.labelDetail3.text =  migrant.interceptionSummary;
                if (migrant.detentionLocation) {
                    NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
                    Accommodation * place = [Accommodation accommodationWithId:migrant.detentionLocation inManagedObjectContext:context];
                    cell.labelDetail4.text = place.name;
                }else {
                    cell.labelDetail4.text = Nil;
                }
                cell.labelDetail5.text = Nil;
                
                UIImage *image = migrant.biometric.photographImage;
                if (image) {
                    cell.photoView.image = [image scaledToWidthInPoint:140];
                }else {
                    cell.photoView.image = [UIImage imageNamed:@"icon-avatar"];
                }
                cell.buttonUpload.hidden = TRUE;
                cell.buttonUpload.tag = indexPath.row;
                [cell.buttonUpload removeTarget:self action:@selector(upload:) forControlEvents:UIControlEventTouchUpInside];
                [cell.buttonUpload addTarget:self action:@selector(upload:) forControlEvents:UIControlEventTouchUpInside];
                
            }
        });
    }];
    
    [self.thumbnailQueue addOperation:operation];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Migrant *migrant = self.data[indexPath.row];
    NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    
    //save to registration
    Registration * registration = [Registration registrationFromMigrant:migrant inManagedObjectContext:context];
    
    
    IMEditRegistrationVC *editVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IMEditRegistrationVC"];
    editVC.registration = registration;
    
    editVC.registrationSave  = ^(void)
    {
        //TODO : reload Data
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           //delete data on data source
                           [self.data removeObjectAtIndex:indexPath.row];
                           [self.collectionView reloadData];
                           
                       });
    };
    
    
    
    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:editVC];
    [self.tabBarController presentViewController:navCon animated:YES completion:nil];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        if (indexPath.row < [self.data count] ) {
            Migrant *migrant = self.data[indexPath.row];
            
            if (migrant) {
                [migrant didTurnIntoFault];
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Error faulting migrant data: %@", [exception description]);
    }
}


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.basePredicate = [NSPredicate predicateWithFormat:@"active = YES"];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"IMRegistrationCollectionViewCell"
                                                    bundle:[NSBundle mainBundle]]
          forCellWithReuseIdentifier:@"IMRegistrationCollectionViewCell"];
    self.collectionView.delegate=self;
    [self.collectionView setDataSource:self];
    
    self.thumbnailQueue = [[NSOperationQueue alloc] init];
    self.thumbnailQueue.maxConcurrentOperationCount = 3;
    self.firstLaunch = TRUE;
    
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.data && !self.reloadingData){
        
        [self reloadData];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    self.data = nil;
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

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
    //    [HUD release];
}


@end
