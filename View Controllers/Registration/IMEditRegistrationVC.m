//
//  IMEditRegistrationVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 29/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMEditRegistrationVC.h"
#import "Registration+Export.h"
#import "IMDBManager.h"
#import "IMTableHeaderView.h"
#import "IMFormCell.h"
#import "UIImage+ImageUtils.h"
#import "RegistrationBiometric+Storage.h"
#import "IMEditRegistrationDataVC.h"
#import "IMScanFingerprintViewController.h"
#import "Migrant.h"
#import <QuickLook/QuickLook.h>
#import "Migrant+Extended.h"
#import "IMConstants.h"
#import "IMCollectionViewController.h"

#import "MBProgressHUD.h"

@interface IMEditRegistrationVC ()<UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate,QLPreviewControllerDelegate,QLPreviewControllerDataSource,MBProgressHUDDelegate>

@property (weak, nonatomic) IBOutlet UIView *headerContainer;
@property (weak, nonatomic) IBOutlet UILabel *labelHeader;
@property (weak, nonatomic) IBOutlet UIView *photographContainer;

@property (weak, nonatomic) IBOutlet UIImageView *imagePhotograph;
@property (weak, nonatomic) IBOutlet UIImageView *imageRightThumb;
@property (weak, nonatomic) IBOutlet UIImageView *imageRightIndex;
@property (weak, nonatomic) IBOutlet UIImageView *imageLeftThumb;
@property (weak, nonatomic) IBOutlet UIImageView *imageLeftIndex;

//programmatic data
@property (nonatomic) BOOL firstLaunch;
@property (nonatomic) BOOL editingMode;
@property (nonatomic, strong) NSMutableDictionary *data;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic) BOOL underIOMCare;
@property (nonatomic,strong) MBProgressHUD *hud;

@end

typedef enum : NSUInteger {
    option_camera,
    option_photo_library,
    option_photo_preview,
} photo_option;

@implementation IMEditRegistrationVC

- (void)showFingerprintScanner:(UITapGestureRecognizer *)gesture
{
    IMScanFingerprintViewController *scanner = [self.storyboard instantiateViewControllerWithIdentifier:@"IMScanFingerprintViewController"];
    scanner.modalPresentationStyle = UIModalPresentationFormSheet;
    scanner.currentFingerPosition = (FingerPosition) gesture.view.tag;
    //TODO set delegate implemetation
    self.data =[[NSMutableDictionary alloc] init];
    scanner.doneCompletionBlock = ^(NSMutableDictionary * value)
    { self.data = value;
        //TODO : save image on file
        NSData *imageData = Nil;
        //                    case RightThumb:
        if ([self.data objectForKey:@(RightThumb)] != Nil) {
            if (self.registration.biometric.rightThumb){
                //delete the image
                [self.registration.biometric deleteBiometricData:RightThumb];
            }
            self.imageRightThumb.image = [self.data objectForKey:@(RightThumb)];
            imageData = UIImageJPEGRepresentation(self.imageRightThumb.image, 1);
            [self.registration.biometric updateFingerImageWithData:imageData forFingerPosition:RightThumb];
        }
        //                    case RightIndex:
        if ([self.data objectForKey:@(RightIndex)] != Nil) {
            //if there is data to edit, then delete the image first
            
            if (self.registration.biometric.rightIndex){
                //delete the image
                [self.registration.biometric deleteBiometricData:RightIndex];
            }
            self.imageRightIndex.image = [self.data objectForKey:@(RightIndex)];
            imageData = UIImageJPEGRepresentation(self.imageRightIndex.image, 1);
            [self.registration.biometric updateFingerImageWithData:imageData forFingerPosition:RightIndex];
        }
        //        case LeftThumb:
        if ([self.data objectForKey:@(LeftThumb)] != Nil) {
            if (self.registration.biometric.leftThumb){
                //delete the image
                [self.registration.biometric deleteBiometricData:LeftThumb];
            }
            
            self.imageLeftThumb.image = [self.data objectForKey:@(LeftThumb)];
            imageData = UIImageJPEGRepresentation(self.imageLeftThumb.image, 1);
            [self.registration.biometric updateFingerImageWithData:imageData forFingerPosition:LeftThumb];
        }
        
        //                case LeftIndex:
        if ([self.data objectForKey:@(LeftIndex)] != Nil) {
            if (self.registration.biometric.leftIndex){
                //delete the image
                [self.registration.biometric deleteBiometricData:LeftIndex];
                
            }
            self.imageLeftIndex.image = [self.data objectForKey:@(LeftIndex)];
            imageData = UIImageJPEGRepresentation(self.imageLeftIndex.image, 1);
            [self.registration.biometric updateFingerImageWithData:imageData forFingerPosition:LeftIndex];
            
        }
        
        //TODO : update image
        [self updateBiometricImages];
    };
    
    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:scanner];
    navCon.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navCon animated:YES completion:nil];
    
}

- (void)showPhotographOption:(UITapGestureRecognizer *)gesture
{
    BOOL camera = NO;
    BOOL library = NO;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        camera = YES;
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        library = YES;
    }
    
    if (camera && library) {
        //check if there is image to preview
        UIActionSheet *actionSheet = Nil;
        
        //check if there is image to preview
        if (self.registration.biometric.photograph || self.registration.biometric.rightIndex || self.registration.biometric.rightThumb || self.registration.biometric.leftIndex || self.registration.biometric.leftThumb) {
            
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Photo Source",Nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",Nil) destructiveButtonTitle:NSLocalizedString(@"Camera",Nil) otherButtonTitles:NSLocalizedString(@"Photo Library",Nil), NSLocalizedString(@"Photo Preview",Nil),nil];
            
        }else actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Photo Source",Nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",Nil) destructiveButtonTitle:NSLocalizedString(@"Camera",Nil) otherButtonTitles:NSLocalizedString(@"Photo Library",Nil),nil];
        
        CGPoint location = [gesture locationInView:self.view];
        CGRect rect = CGRectMake(location.x, location.y, self.imagePhotograph.frame.size.width, self.imagePhotograph.frame.size.height);
        [actionSheet showFromRect:rect inView:self.view animated:YES];
    }else if (library) {
        [self showPhotoLibrary];
    }else {
        [self showAlertWithTitle:NSLocalizedString(@"Photo Library Not Available",Nil)
                         message:NSLocalizedString(@"RAMS requires access to your Photo Library. Go to Settings > Privacy > Photos and turn on access for RAMS Manager.",Nil)];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if (buttonIndex == option_camera) {
        [self showCamera];
    }else if (buttonIndex == option_photo_library) {
        [self showPhotoLibrary];
    }else if (buttonIndex == option_photo_preview){
        [self showPhotoPreview];
    }
}

- (void)showCamera
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)showPhotoPreview
{
    if(!self.previewingPhotos){
        self.previewingPhotos = [NSMutableArray array];
    }
    
    //add all photo
    if (self.registration.biometric.photograph)[self.previewingPhotos addObject:self.registration.biometric.photograph];
    if (self.registration.biometric.leftIndex)[self.previewingPhotos addObject:self.registration.biometric.leftIndex];
    if (self.registration.biometric.leftThumb)[self.previewingPhotos addObject:self.registration.biometric.leftThumb];
    if (self.registration.biometric.rightIndex)[self.previewingPhotos addObject:self.registration.biometric.rightIndex];
    if (self.registration.biometric.rightThumb)[self.previewingPhotos addObject:self.registration.biometric.rightThumb];
    
    if (![self.previewingPhotos count]) {
        //there is no data
        return;
    }
    
    QLPreviewController *previewController = [[QLPreviewController alloc] init];
    previewController.delegate = self;
    previewController.dataSource = self;
    previewController.title = self.registration.fullname;
    [self presentViewController:previewController animated:YES completion:^{
        previewController.view.tintColor = [UIColor IMMagenta];
        previewController.view.backgroundColor = [UIColor blackColor];
        previewController.title = self.registration.fullname;
    }];
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
    controller.title = self.registration.fullname;
    
    return [NSURL fileURLWithPath:self.previewingPhotos[index] isDirectory:YES];
    
    
}

- (void)showPhotoLibrary
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.preferredContentSize = CGSizeMake(400, 400);
    
    CGPoint center = self.imagePhotograph.center;
    CGRect bounds = self.imagePhotograph.bounds;
    CGRect rect = CGRectMake(center.x - 50, center.y - 50, bounds.size.width, bounds.size.height);
    rect = [self.view convertRect:rect fromView:self.imagePhotograph];
    
    if (self.popover) {
        //close to avoid memory leaks
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
    
    self.popover = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
    [self.popover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
}


#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
    
    
    if (picker) {
        [picker dismissViewControllerAnimated:YES completion:Nil];
        picker = Nil;
    }
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (info[UIImagePickerControllerOriginalImage]) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        image = [image scaledToHeight:1800];
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        [self.registration.biometric updatePhotographData:imageData];
        //        self.imagePhotograph.image = [self.registration.biometric.photographImage scaledToWidthInPoint:100];
        self.imagePhotograph.image = self.registration.biometric.photographImageThumbnail;
        
    }
    
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    navigationController.navigationBar.tintColor = [UIColor IMMagenta];
}


#pragma mark UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}


#pragma mark Actions
- (void)cancel
{
    if (self.editingMode) {
        [self.registration.managedObjectContext rollback];
    }else {
        [self.registration.biometric deleteBiometricData];
        [self.context deleteObject:self.registration];
    }
    
    NSError *error;
    if (![self.context save:&error]) {
        NSLog(@"Error deleting registration: %@", [error description]);
        
    }else {
        [[IMDBManager sharedManager] saveDatabase:^(BOOL success){
            //            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    }
    //    [self.context reset];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (self.registrationCancel) {
        self.registrationCancel();
    }
    
}

- (void)saving
{
      BOOL showAlert =FALSE;
    
    @try {
        BOOL needRemove =FALSE;
        NSNumber * lastStatus = self.registration.complete;
      
        
        //checking the value
        if (!self.registration.unhcrDocument && self.registration.unhcrNumber) {
            //show alert
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Input",Nil) message:NSLocalizedString(@"Please input UNHCR Document",Nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",Nil) otherButtonTitles:nil];
            
            [alert show];
            [_hud hideUsingAnimation:YES];
            showAlert = YES;
            return;
        }
        
        //check interception date and date of entry
        if ([self.registration.interceptionData.dateOfEntry compare:self.registration.interceptionData.interceptionDate] == NSOrderedDescending) {
            //show alert
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Input on Interception Data",Nil) message:NSLocalizedString(@"Date Of Entry can not be more than interception date",Nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",Nil) otherButtonTitles:nil];
            
            [alert show];
            [_hud hideUsingAnimation:YES];
             showAlert = YES;
            return;
            
        }
        
        //check location and transfer date
        if ((self.registration.transferDate && !self.registration.transferDestination.name) || (self.registration.transferDestination.name && !self.registration.transferDate)) {
            //show alert
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Input on Location Data",Nil) message:NSLocalizedString(@"Please check your input on Location",Nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",Nil) otherButtonTitles:nil];
            
            [alert show];
            [_hud hideUsingAnimation:YES];
             showAlert = YES;
            return;
            
        }
        
        //        //validate Biodata value
        //        if (!self.registration.bioData.firstName || !self.registration.bioData.familyName || !self.registration.bioData.gender || !self.registration.bioData.maritalStatus || !self.registration.bioData.placeOfBirth || !self.registration.bioData.dateOfBirth || !self.registration.bioData.nationality || !self.registration.bioData.countryOfBirth) {
        //validate Biodata value
        if (!self.registration.bioData.firstName) {
            //show alert
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Input on Personal Information",Nil) message:NSLocalizedString(@"Please input First Name",Nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",Nil) otherButtonTitles:nil];
            
            [alert show];
            [_hud hideUsingAnimation:YES];
             showAlert = YES;
            return;
        }
        
        [self.registration validateCompletion];
        needRemove = (lastStatus != self.registration.complete);
        
        if (!self.registration.dateCreated) {
            self.registration.dateCreated = [NSDate date];
        }
        
        
        NSManagedObjectContext *workingContext = self.registration.managedObjectContext;
        NSError *error;
        
        
        //TODO : check if this is from Migrant list, if Yes then delete the migrant data
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Migrant"];
        
        request.predicate = [NSPredicate predicateWithFormat:@"registrationNumber = %@",self.registration.registrationId];
        request.returnsObjectsAsFaults = YES;
        
        NSArray *data = [workingContext executeFetchRequest:request error:&error];
        if ([data count]) {
            int i = 1;
            for (Migrant * migrant in data) {
                migrant.complete = @(FALSE);
                NSLog(@"%i object deleted",i);
                needRemove = TRUE;
                
                
            }
            //deep copy new registration data to migrant
            [Migrant saveMigrantInContext:workingContext withId:self.registration.registrationId andRegistrationData:self.registration];
        }
        
        if (![workingContext save:&error]) {
            NSLog(@"Error saving context: %@", [error description]);
            [self showAlertWithTitle:NSLocalizedString(@"Failed Saving Registration",Nil) message:NSLocalizedString(@"Please try again. If problem persist, please cancel and consult with administrator.",Nil)];
        }else {
            //save database
            [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
            
            //        if(self.editingMode && [data count]){
            //            // sleep for synch
            //            sleep(2);
            //        }
            
            if (!self.editingMode) {
                //new registration
                needRemove = TRUE;
            }
            
            if (self.registrationSave) {
                self.registrationSave(needRemove);
            }
            
           
            
//            if (self.registrationLast) {
                //                self.registrationLast(self.registration);
             //save to backup for template next data
            if ([[NSUserDefaults standardUserDefaults] boolForKey:IMTemplateForm]) {
                //get last registration data on backup
                if (![Registration createBackupReg:self.registration inManagedObjectContext:self.registration.managedObjectContext]) {
                    NSLog(@"Fail to create backup");
                }
                
                sleep(1);
            }
            
//            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception on saving : %@",[exception description]);
    }
    @finally {
        //flag for alert view, do not dissmiss before user touch alert button
        if (!showAlert) {
            [self dismissViewControllerAnimated:YES completion:nil];
            [_hud hideUsingAnimation:YES];
        }
        
    }
    
    
}

- (void)save
{
    //    // Add HUD to screen
    //    [self.view addSubview:_hud];
    //
    //    // Regisete for HUD callbacks so we can remove it from the window at the right time
    //    _hud.delegate = self;
    //
    //    _hud.labelText = @"Saving...";
    //    //    Show progress window
    //    [_hud showWhileExecuting:@selector(saving) onTarget:self withObject:nil animated:YES];
    
    // Show progress window
    if (!_hud) {
        // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
        _hud = [[MBProgressHUD alloc] initWithView:self.view];
    }
    
    
    
    // Add HUD to screen
    [self.view addSubview:_hud];
    
    // Regisete for HUD callbacks so we can remove it from the window at the right time
    _hud.delegate = self;
    
    _hud.labelText = NSLocalizedString(@"Saving...",Nil);
    
    // Show the HUD while the provided method executes in a new thread
    [_hud showUsingAnimation:YES];
    
    [self saving];
}


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.tintColor = [UIColor IMMagenta];
    self.navigationController.navigationBar.translucent = NO;
    self.view.tintColor = [UIColor IMMagenta];
    
    [self circleImageView:self.imagePhotograph];
    [self circleImageView:self.imageLeftIndex];
    [self circleImageView:self.imageLeftThumb];
    [self circleImageView:self.imageRightIndex];
    [self circleImageView:self.imageRightThumb];
    
    self.context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.context.parentContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    
    if (self.registration) {
        self.title = NSLocalizedString(@"Edit Registration",Nil);
        self.editingMode = YES;
        [self updateBiometricImages];
    }else {
        self.title = NSLocalizedString(@"New Registration",Nil);
        self.editingMode = NO;
        self.registration = [Registration newRegistrationInContext:self.context];
    }
    
    //setup actions
    [self setupFingerprintGestureRecognizer:self.imageRightThumb];
    [self setupFingerprintGestureRecognizer:self.imageRightIndex];
    [self setupFingerprintGestureRecognizer:self.imageLeftThumb];
    [self setupFingerprintGestureRecognizer:self.imageLeftIndex];
    
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showPhotographOption:)];
    [singleTapGestureRecognizer setNumberOfTapsRequired:1];
    
    //check if there is image to preview
    if (self.registration.biometric.photograph || self.registration.biometric.rightIndex || self.registration.biometric.rightThumb || self.registration.biometric.leftIndex || self.registration.biometric.leftThumb) {
        UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                              initWithTarget:self
                                                              action:@selector(showPhotoPreview)];
        [doubleTapGestureRecognizer setNumberOfTapsRequired:2];
        // Wait for failed doubleTapGestureRecognizer
        [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
        [self.imagePhotograph addGestureRecognizer:doubleTapGestureRecognizer];
    }
    
    self.imagePhotograph.userInteractionEnabled = YES;
    [self.imagePhotograph addGestureRecognizer:singleTapGestureRecognizer];
    
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    
    UIViewController *vc = [self.childViewControllers lastObject];
    if ([vc isKindOfClass:[IMEditRegistrationDataVC class]]) {
        IMEditRegistrationDataVC *regVC = (IMEditRegistrationDataVC *)vc;
        regVC.registration = self.registration;
        if (!self.editingMode && [[NSUserDefaults standardUserDefaults] boolForKey:IMTemplateForm]) {
            regVC.useLastData = YES;
        }
//        regVC.lastReg = self.LastReg;
    }
    
    if (!_hud) {
        // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
        _hud = [[MBProgressHUD alloc] initWithView:self.presentingViewController.view];
    }
    
}

- (void)setupFingerprintGestureRecognizer:(UIImageView *)imageView
{
    imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFingerprintScanner:)];
    [imageView addGestureRecognizer:gesture];
}

- (void)circleImageView:(UIImageView *)imageView
{
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
}


- (void)updateBiometricImages
{
    UIImage *defaultImage = [UIImage imageNamed:@"icon-fingerprint-empty"];
    
    if (self.registration.biometric.rightIndex) {
        [self.registration.biometric fingerImageForPosition:RightIndex] ;
        self.imageRightIndex.image = [[self.registration.biometric fingerImageForPosition:RightIndex] scaledToWidthInPoint:100];
        
    }else {
        self.imageRightIndex.image = defaultImage;
    }
    
    if (self.registration.biometric.rightThumb) {
        [self.registration.biometric fingerImageForPosition:RightThumb];
        self.imageRightThumb.image = [[self.registration.biometric fingerImageForPosition:RightThumb] scaledToWidthInPoint:100];
    }else {
        self.imageRightThumb.image = defaultImage;
    }
    
    if (self.registration.biometric.leftIndex) {
        [self.registration.biometric fingerImageForPosition:LeftIndex];
        self.imageLeftIndex.image = [[self.registration.biometric fingerImageForPosition:LeftIndex] scaledToWidthInPoint:100];
    }else {
        self.imageLeftIndex.image = defaultImage;
    }
    
    if (self.registration.biometric.leftThumb) {
        [self.registration.biometric fingerImageForPosition:LeftThumb];
        self.imageLeftThumb.image = [[self.registration.biometric fingerImageForPosition:LeftThumb] scaledToWidthInPoint:100];
    }else {
        self.imageLeftThumb.image = defaultImage;
    }
    
    if (self.registration.biometric.photograph) {
        
        [self.registration.biometric photographImage];
        
        //show thumbnail
        if (!self.registration.biometric.photographThumbnail) {
            //save as thumbnail
            self.imagePhotograph.image = [[self.registration.biometric photographImage] scaledToWidthInPoint:125];
            
            
            NSData *imgData= UIImagePNGRepresentation(self.imagePhotograph.image);
            
            [self.registration.biometric updatePhotographThumbnail:imgData];
            
            //save to database
            NSManagedObjectContext *workingContext = self.registration.managedObjectContext;
            NSError *error;
            if (![workingContext save:&error]) {
                NSLog(@"Error saving context: %@", [error description]);
                [self showAlertWithTitle:NSLocalizedString(@"Failed Saving Registration",Nil) message:NSLocalizedString(@"Please try again. If problem persist, please cancel and consult with administrator.",Nil)];
            }
        }
        
        self.imagePhotograph.image = [self.registration.biometric photographImageThumbnail];
    }else {
        self.imagePhotograph.image = [UIImage imageNamed:@"icon-avatar-large"];
    }
    
    NSError *error;
    if (![self.registration.managedObjectContext save:&error]) {
        NSLog(@"Error saving registration: %@", [error description]);
        
    }
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden {
    // Remove HUD from screen when the HUD was hidded
    [_hud removeFromSuperview];
}

@end