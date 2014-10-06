//
//  IMMovementsReviewVC.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 7/30/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMMovementsReviewVC.h"
#import "IMRegistrationCollectionViewCell.h"
#import "Migrant+Extended.h"
#import "UIImage+ImageUtils.h"
#import "IMDBManager.h"
#import "Registration+Export.h"
#import "IMEditRegistrationVC.h"
#import "Movement+Extended.h"
#import "MBProgressHUD.h"
#import "IMMigrantViewController.h"


@interface IMMovementsReviewVC () <MBProgressHUDDelegate>
@property (nonatomic, strong) NSOperationQueue *thumbnailQueue;
@property (nonatomic, strong) NSMutableArray *migrants;
@property (nonatomic, strong) Movement *movement;
@property (nonatomic) int currentIndex;
@property (nonatomic,strong) MBProgressHUD *HUD;
@property (nonatomic) BOOL flag;
@property (nonatomic) BOOL next;
@property (nonatomic) BOOL upload_status;
@property (nonatomic) BOOL receive_warning;
@property (nonatomic) float progress;
@property (nonatomic) NSInteger total;
@property (nonatomic,strong) NSManagedObjectContext *context;
@property (strong,nonatomic) dispatch_queue_t movementQueue;



@end

@implementation IMMovementsReviewVC

@synthesize delegate;

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    //    // Remove HUD from screen when the HUD was hidded
    if (_HUD) {
         [_HUD removeFromSuperview];
    }
   
}

- (void)setMigrantData:(NSMutableDictionary *)migrantData{
    if (migrantData) {
        _migrantData = migrantData;
        
        //get migrant data form dictionary
        if (self.migrantData[@"Migrant"]) {
            if (!self.migrants) {
                self.migrants = [NSMutableArray array];
            }
            
            self.migrants = self.migrantData[@"Migrant"];
            NSLog(@"self.migrants = %lu",(unsigned long)[self.migrants count]);
        }
        
        if (self.migrantData[@"Movement"]) {
            //get movement from dictionary
            if (!self.movement) {
                if (!self.context) {
                    self.context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
                }
                NSManagedObjectContext *context = self.context;
                self.movement = [Movement newMovementInContext:context];
            }
            self.movement = self.migrantData[@"Movement"];
        }
        
        if ([self isViewLoaded]) {
            [self.collectionView reloadData];
        }
        
    }
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
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"IMRegistrationCollectionViewCell"
                                                    bundle:[NSBundle mainBundle]]
          forCellWithReuseIdentifier:@"IMRegistrationCollectionViewCell"];
    
    self.thumbnailQueue = [[NSOperationQueue alloc] init];
    self.thumbnailQueue.maxConcurrentOperationCount = 3;
    
    if (!self.migrants) {
        self.migrants = [NSMutableArray array];
    }
    
    self.title = @"Review and Submit";
    //add upload icon
    UIBarButtonItem *itemUploadAll= [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-upload-small"] style:UIBarButtonItemStylePlain target:self action:@selector(uploadAll)];
    
    
    self.navigationItem.rightBarButtonItems = @[itemUploadAll];
    
    
    self.receive_warning = FALSE;
    self.context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    
}

- (void)uploadAll
{
    
    
    //show confirmation
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload all Movement Data"
                                                    message:@"All your Movement Data will be uploaded and you need internet connection to do this.\nContinue upload all Movement?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Yes", nil];
    alert.tag = IMAlertUpload_Tag;
    [alert show];
}

- (void) uploading
{
    @try {
        
        //formating data
        self.total = [self.migrants count]?1:0;
        
        if (self.total > 0) {
            self.upload_status = FALSE;
            _HUD.mode = MBProgressHUDModeDeterminate;
            self.progress = 0;
            //disable Menu
            [self.sideMenuDelegate disableMenu:YES];
            //show data loading view until upload is finish
            //start blocking
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            
            
            NSLog(@"uploading == self.migrants = %lu",(unsigned long)[self.migrants count]);
            //add migrants to array
            NSMutableArray * migrantArray = [NSMutableArray array];
            NSMutableDictionary * formatted = [NSMutableDictionary dictionary];
            
            //formating migrants data
            for (Migrant * migrant in self.migrants) {
                //adding migrants
                [migrantArray addObject:migrant.registrationNumber];
            }
            
            //wrap data
            [formatted setObject:migrantArray forKey:@"migrants"];
            [formatted setObject:[self.movement format] forKey:@"movement"];
            
            NSLog(@"formatted : %@",[formatted description]);
            self.next  =FALSE;
            //send formatted data to server
            [self sendMovement:formatted];
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
            
            if (self.upload_status) {
                //case upload success and movement != transfer then deactived migrant
                
                NSError * error;
                if (![self.movement.type isEqual:@"Transfer"]) {
                    
                    for (Migrant * migrant in self.migrants) {
                        //deactivated the migrants
                        migrant.active = @(0);
                        [migrant.managedObjectContext save:&error];
                        if (error) {
                            NSLog(@"=== save Migrant database with error  === : %@", [error description]);
                        }
                    }
                }
                
                //save movement to migrant
                for (Migrant * migrant in self.migrants) {
                    //save movement
                    [migrant addMovementsObject:self.movement];
                    [migrant.managedObjectContext save:&error];
                    if (error) {
                        NSLog(@"=== save Movement database with error === : %@", [error description]);
                    }
                }
                
                
                [self.context save:&error];
                if (error) {
                    NSLog(@"=== save All database with error === : %@", [error description]);
                }
                
                // Back to indeterminate mode
                _HUD.mode = MBProgressHUDModeIndeterminate;
                
                //save database
                [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
                
                //         finish blocking
                [UIApplication sharedApplication].idleTimerDisabled = NO;
                [self.sideMenuDelegate disableMenu:NO];
                
                //synchronize data
                _HUD.labelText = @"Synchronizing...";
                [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
                sleep(5);
                
                //return to migrant list
                IMMigrantViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IMMigrantViewController"];
                
                
                
                UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
                navCon.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
                [self presentViewController:navCon animated:YES completion:nil];
                /*
                 UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
                 
                 IMEditRegistrationVC *editVC = [storyboard instantiateViewControllerWithIdentifier:@"IMEditRegistrationVC"];
                 editVC.registration = registration;
                 
                 UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:editVC];
                 [self.navigationController presentViewController:navCon animated:YES completion:Nil];
                 */
                
            }
            
        }else{
            NSLog(@"There is no data to upload");
            
            //show alert
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"There is no data to upload" message:Nil delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    
}

- (void) sendMovement:(NSDictionary *)params
{
    
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client postJSONWithPath:@"movement/save"
                  parameters:params
                     success:^(NSDictionary *jsonData, int statusCode){
//                                                 [self showAlertWithTitle:@"Upload Success" message:nil];
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Success" message:Nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                         alert.tag = IMAlertUploadSuccess_Tag;
                         [alert show];
                         
                         NSLog(@"Upload Success");
   
                         
                     }
                     failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                         if (!self.flag) {
                             [self showAlertWithTitle:@"Upload Failed" message:@"Please check your network connection and try again. If problem persist, contact administrator."];
                             self.flag = TRUE;
                             NSLog(@"Upload Fail : %@",[error description]);
                             self.upload_status = FALSE;
                             self.next = TRUE;
                         }
                     }];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == IMAlertUpload_Tag && buttonIndex != [alertView cancelButtonIndex]) {
        //start uploading
//        if (!_HUD) {
            // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
            _HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
//        }
        
        // Back to indeterminate mode
        _HUD.mode = MBProgressHUDModeDeterminate;
        
        // Add HUD to screen
        [self.navigationController.view addSubview:_HUD];
        
        
        
        // Regisete for HUD callbacks so we can remove it from the window at the right time
        _HUD.delegate = self;
        
        _HUD.labelText = @"Uploading Data";
        
        
        // Show the HUD while the provided method executes in a new thread
        [_HUD showWhileExecuting:@selector(uploading) onTarget:self withObject:nil animated:YES];
        
    }else if (alertView.tag == IMAlertUploadSuccess_Tag){
           //         finish blocking
        
        
        self.upload_status = TRUE;
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        [self.sideMenuDelegate disableMenu:NO];
        
        //reset flag
        self.next = TRUE;

    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    self.receive_warning = TRUE;
    sleep(1);
}



#pragma mark Collection View Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [collectionView.collectionViewLayout invalidateLayout];
    return self.migrants.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"IMRegistrationCollectionViewCell";
    IMRegistrationCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    id data = self.migrants[indexPath.row];
    [self _configureCell:cell forDataObject:data animated:NO];
    cell.buttonUpload.tag = indexPath.row;
    // load photo images in the background
    __weak IMMovementsReviewVC *weakSelf = self;
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        //        UIImage *image = [photo image];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // then set them via the main queue if the cell is still visible.
            if ([weakSelf.collectionView.indexPathsForVisibleItems containsObject:indexPath]) {
                IMRegistrationCollectionViewCell *cell =
                (IMRegistrationCollectionViewCell *)[weakSelf.collectionView cellForItemAtIndexPath:indexPath];
                id data = self.migrants[indexPath.row];
                [self _configureCell:cell forDataObject:data animated:NO];
                cell.buttonUpload.tag = indexPath.row;
            }
        });
    }];
    
    [self.thumbnailQueue addOperation:operation];
    
    return cell;
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
        
        if (migrant.detentionLocation) {
            NSManagedObjectContext *context = self.context;
            Accommodation * place = [Accommodation accommodationWithId:migrant.detentionLocation inManagedObjectContext:context];
            cell.labelDetail4.text = place.name;
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
                NSManagedObjectContext *workingContext = self.context;
                NSError *error;
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
    Migrant *migrant = self.migrants[indexPath.row];
    
    NSManagedObjectContext *context = self.context;
    
    //save to registration
    Registration * registration = [Registration registrationFromMigrant:migrant inManagedObjectContext:context];
    
    
    IMEditRegistrationVC *editVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IMEditRegistrationVC"];
    editVC.registration = registration;
    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:editVC];
    [self presentViewController:navCon animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self isViewLoaded]) {
        [self.collectionView reloadData];
    }
    
}


- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        if (indexPath.row < [self.migrants count] ) {
            if ([self.migrants[indexPath.row] isKindOfClass:[Migrant class]]) {
                Migrant *migrant = self.migrants[indexPath.row];
                
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
