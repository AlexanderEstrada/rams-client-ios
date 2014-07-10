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



@interface IMMigrantListVC () <MBProgressHUDDelegate,DataProviderDelegate>

@property (nonatomic,strong) MBProgressHUD *HUD;
@property (nonatomic) pthread_mutex_t mutex;
@property (nonatomic,strong) NSLock *theLock;

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
        [self.collectionView reloadData];
    }
}

- (void)setBasePredicate:(NSPredicate *)basePredicate
{
    @synchronized(self)
    {
        if ( self.reloadingData || [_basePredicate isEqual:basePredicate]) {
            //            /do not do anything until data complete reload
            return;
        }
        _basePredicate = basePredicate;
        
        if (!_HUD) {
            // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
            _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
            // Regisete for HUD callbacks so we can remove it from the window at the right time
            _HUD.delegate = self;
        }
        // Back to indeterminate mode
        _HUD.mode = MBProgressHUDModeIndeterminate;
        
        // Add HUD to screen
        [self.navigationController.view addSubview:_HUD];
        
        _HUD.labelText = @"Reloading Data";
        
        // Show the HUD while the provided method executes in a new thread
        [_HUD showWhileExecuting:@selector(reloadData) onTarget:self withObject:nil animated:YES];
        
    };
}

- (void)reloadData
{
    
    
    @synchronized(self)
    {
        if(!self.reloadingData){
            self.reloadingData = YES;
            
            NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Migrant"];
            if (self.basePredicate) {
                //check if complete = YES flag already set, if not we must set it
                NSPredicate *localPredicate =  [NSPredicate predicateWithFormat:@"complete = YES"];
                self.basePredicate =[NSCompoundPredicate andPredicateWithSubpredicates:@[self.basePredicate,localPredicate]];
                request.predicate = self.basePredicate;
            }else {
                //default
                self.basePredicate = request.predicate =  [NSPredicate predicateWithFormat:@"active = YES AND complete = YES"];
            }
            request.returnsObjectsAsFaults = YES;
            NSError *error;
            NSUInteger total = [context countForFetchRequest:request error:&error];
            DataProvider *dataProvider = [[DataProvider alloc] initWithPageSize:(total > Default_Page_Size)?Default_Page_Size:total initWithTotalData:total withEntity:@"Migrant" andSort:@"dateCreated" basePredicate:self.basePredicate ? self.basePredicate:Nil];
            
            self.dataProvider = Nil;
            [self setDataProvider:dataProvider];
            self.reloadingData = NO;
            
        }
    };
    
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
    
    if ([dataObject isKindOfClass:[Migrant class]]) {
        Migrant *migrant = (Migrant *) dataObject;
        
        
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
            cell.photoView.image = [image scaledToWidthInPoint:100];
        }else {
            cell.photoView.image = [UIImage imageNamed:@"icon-avatar"];
        }
        
        //add double gesture to photoview cell
        UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                              initWithTarget:self
                                                              action:@selector(handleTapFrom:)];
        [doubleTapGestureRecognizer setNumberOfTapsRequired:2];
        [cell.photoView addGestureRecognizer:doubleTapGestureRecognizer];
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
            //            [UIView animateWithDuration:IMRootViewAnimationDuration animations:^{
            
            [UIView animateWithDuration:IMRootViewAnimationDuration
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                             animations:^{
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

- (void) handleTapFrom: (UITapGestureRecognizer *)recognizer
{
    //Code to handle the gesture
    NSLog(@"recognizer.numberOfTouches : %i",recognizer.numberOfTouches);
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Migrant *migrant = self.dataProvider.dataObjects[indexPath.row];
    NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    
    //save to registration
    Registration * registration = [Registration registrationFromMigrant:migrant inManagedObjectContext:context];
    
    
    IMEditRegistrationVC *editVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IMEditRegistrationVC"];
    editVC.registration = registration;
    
    editVC.registrationSave  = ^(BOOL remove)
    {
        //TODO : reload Data
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           if (remove) {
                               //delete data on data source
                               [self.dataProvider.dataObjects removeObjectAtIndex:indexPath.row];
                               [self.collectionView reloadData];
                           }else {
                               //reload Data
                               [self reloadData];
                           }
                           
                       });
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


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    _theLock = [[NSLock alloc] init];
    
    
    if (!_HUD) {
        // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
        _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    }
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"IMRegistrationCollectionViewCell"
                                                    bundle:[NSBundle mainBundle]]
          forCellWithReuseIdentifier:@"IMRegistrationCollectionViewCell"];
    //    self.collectionView.delegate=self;
    //    [self.collectionView setDataSource:self];
    
    self.thumbnailQueue = [[NSOperationQueue alloc] init];
    self.thumbnailQueue.maxConcurrentOperationCount = 3;
    self.firstLaunch = TRUE;
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    
    [super viewWillDisappear:animated];
    //    self.dataProvider = Nil;
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

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    
    @try {
        // Remove HUD from screen when the HUD was hidded
        if (_HUD) {
            [_HUD removeFromSuperview];
        }
    }@catch (NSException *exception) {
        NSLog(@"Error on hudWasHidden with message: %@",[exception description]);
    }
}


@end
