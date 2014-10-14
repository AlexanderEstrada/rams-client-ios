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
#import "DataProvider.h"
#import "IMConstants.h"

#import "MBProgressHUD.h"



@interface IMMigrantListVC () <DataProviderDelegate,MBProgressHUDDelegate>

@property (nonatomic,strong) MBProgressHUD *HUD;

@end

@implementation IMMigrantListVC

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
    if (self.reloadingData || basePredicate == _basePredicate) {
        //            /do not do anything until data complete reload
        return;
    }
    
    _basePredicate = basePredicate;
    [self reloadData];
}

- (void)executing
{
    if(!self.reloadingData){
        self.reloadingData = YES;
        
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
        self.reloadingData = NO;
        
    }

}

- (void)reloadData
{
    [self executing];
    
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    [self.collectionView reloadData];
    
}

#pragma mark Collection View Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [collectionView.collectionViewLayout invalidateLayout];
    return self.dataProvider.dataObjects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"IMRegistrationCollectionViewCell";
    IMRegistrationCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    id data = self.dataProvider.dataObjects[indexPath.row];
    [self _configureCell:cell forDataObject:data animated:NO];
    cell.buttonUpload.tag = indexPath.row;
    // load photo images in the background
    __weak IMMigrantListVC *weakSelf = self;
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        //        UIImage *image = [photo image];
        
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
        cell.labelSubtitle.text = [migrant.registrationNumber length]?[NSString stringWithFormat:@"Reg. Number %@",migrant.registrationNumber]:Nil;
        cell.labelDetail1.text = migrant.bioDataSummary;
        cell.labelDetail2.text = migrant.unhcrDocument;
        cell.labelDetail3.text = [migrant.unhcrNumber length]?[NSString stringWithFormat:@"Doc. Number %@",migrant.unhcrNumber]:Nil;
        cell.labelDetail4.text = migrant.interceptionSummary;
        
        NSManagedObjectContext *workingContext = migrant.managedObjectContext;
        NSError *error;
        
        if (migrant.detentionLocationName) {
            cell.labelDetail5.text = migrant.detentionLocationName;
        }else if (migrant.detentionLocation) {
            Accommodation * place = [Accommodation accommodationWithId:migrant.detentionLocation inManagedObjectContext:workingContext];
            cell.labelDetail5.text = place.name;
            
            //save detention location name
            migrant.detentionLocationName = place.name;
            
            //save to database
            if (![workingContext save:&error]) {
                NSLog(@"Error saving context: %@", [error description]);
            }
            
        }else {
            cell.labelDetail5.text = Nil;
        }
        
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
        
        cell.hidden = NO;
        //hide loading view
//        [self hideLoadingView];
    }else{
        //hide null class
        cell.hidden = YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Migrant *migrant = self.dataProvider.dataObjects[indexPath.row];
    
    NSManagedObjectContext *context = migrant.managedObjectContext;
    
    //save to registration
    Registration * registration = [Registration registrationFromMigrant:migrant inManagedObjectContext:context];
    
    
    IMEditRegistrationVC *editVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IMEditRegistrationVC"];
    editVC.registration = registration;
    
    editVC.registrationSave  = ^(BOOL remove)
    {
        //TODO : reload Data
        
        NSError * err;
        if (remove) {
            //save on database
            [context.parentContext save:&err];
            if (err) {
                NSLog(@"Error saving : %@",[err description]);
            }else [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil userInfo:nil];
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
            if ([self.dataProvider.dataObjects[indexPath.row] isKindOfClass:[Migrant class]]) {
                Migrant *migrant = self.dataProvider.dataObjects[indexPath.row];
                
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

- (void)showLoadingViewWithTitle:(NSString *)title
{
//    if (self.loading) return;
//    
//    self.useBackground = NO;
//    self.loadingView.alpha = 0;
//  self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
//    self.labelLoading.text = title;
//    self.labelLoading.textColor = self.view.tintColor;
//    self.loadingIndicator.color = self.view.tintColor;
//    
//    [self.view addSubview:self.loadingView];
//    self.loadingView.transform = CGAffineTransformMakeScale(0, 0);
//    
//    [UIView animateWithDuration:.25 animations:^{
//        self.loadingView.transform = CGAffineTransformMakeScale(1, 1);
//            self.loadingView.alpha = 1;
//    } completion:^(BOOL finished){
//        [self.loadingIndicator startAnimating];
//        self.view.userInteractionEnabled = NO;
//        self.loading = YES;
//    }];
    
//    if (!_HUD) {
        // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
        _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
//    }
    
    // Back to indeterminate mode
    _HUD.mode = MBProgressHUDModeIndeterminate;
    
    // Add HUD to screen
    [self.navigationController.view addSubview:_HUD];
    
    
    
    // Regisete for HUD callbacks so we can remove it from the window at the right time
    _HUD.delegate = self;
    
    _HUD.labelText = title;
    
    
    // Show the HUD while the provided method executes in a new thread
    [_HUD showUsingAnimation:YES];
    
}

- (void)hideLoadingView
{
    
//    if (!self.loading && [self.dataProvider.dataObjects count]) return;
//    
//    [UIView animateWithDuration:.25
//                     animations:Nil
//                     completion:^(BOOL finished){
//                         [self.loadingIndicator stopAnimating];
//                         [self.loadingView removeFromSuperview];
//                         self.view.userInteractionEnabled = YES;
//                         
//                         self.labelLoading = nil;
//                         self.loadingIndicator = nil;
//                         self.loadingView = nil;
//                         self.loading = NO;
//                     }];
    
     [_HUD hideUsingAnimation:YES];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    
    [super viewWillDisappear:animated];
    
    [_HUD hideUsingAnimation:animated];
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
    self.firstLaunch = TRUE;
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:IMDatabaseChangedNotification object:nil];
    
    //hide loading view
    [self hideLoadingView];
    
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
    
    //check if there is collection to be view
    if ([[self.collectionView visibleCells] count]) {
        //case exist
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    }

    
    [UIView animateWithDuration:0.125f animations:^{
        [self.collectionView setAlpha:1.0f];
    }];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    if (_HUD) {
        [_HUD removeFromSuperview];
    }
}

@end
