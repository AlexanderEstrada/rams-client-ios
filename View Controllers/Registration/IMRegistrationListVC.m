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


@implementation IMRegistrationListVC

- (void)setBasePredicate:(NSPredicate *)basePredicate
{
    _basePredicate = basePredicate;
    [self reloadData];
}

- (void)reloadData
{
    self.reloadingData = YES;
//        [self hideLoadingView];
    
    NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Registration"];
    request.predicate = self.basePredicate;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO]];
    request.returnsObjectsAsFaults = YES;
    // Set the batch size to a suitable number.
    [request setFetchBatchSize:15];
    
    NSError *error;
    self.data = [context executeFetchRequest:request error:&error];
    [self.collectionView reloadData];
    self.reloadingData = NO;
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self hideLoadingView];
    [self reloadData];
    
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
        [self reloadData];
        
        
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
    
    //reload data
    [self reloadData];
    
}


#pragma mark Collection View Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.data count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"IMRegistrationCollectionViewCell";
    IMRegistrationCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    Registration *registration = self.data[indexPath.row];
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
        cell.photoView.image = [image scaledToWidthInPoint:70];
    }else {
        cell.photoView.image = [UIImage imageNamed:@"icon-avatar"];
    }
    
    cell.buttonUpload.hidden = !registration.complete.boolValue;
    cell.buttonUpload.tag = indexPath.row;
    [cell.buttonUpload removeTarget:self action:@selector(upload:) forControlEvents:UIControlEventTouchUpInside];
    [cell.buttonUpload addTarget:self action:@selector(upload:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Registration *registration = self.data[indexPath.row];
    
    IMEditRegistrationVC *editVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IMEditRegistrationVC"];
    editVC.registration = registration;
    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:editVC];
    [self.tabBarController presentViewController:navCon animated:YES completion:nil];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        Registration *reg = self.data[indexPath.row];
        [reg didTurnIntoFault];
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
    
//    [self showLoadingView];
//    sleep(2);
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    //    self.data = nil;
    [super viewWillDisappear:animated];
    [self reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.data && !self.reloadingData) self.basePredicate = [NSPredicate predicateWithFormat:@"complete = NO"];

    [self reloadData];
//    [self hideLoadingView];
//    [self showAlertWithTitle:@"Reload Success" message:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    self.data = nil;
    [self.collectionView reloadData];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self reloadData];
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

@end