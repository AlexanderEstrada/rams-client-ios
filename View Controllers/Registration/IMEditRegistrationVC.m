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

@interface IMEditRegistrationVC ()<UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate,QLPreviewControllerDelegate,QLPreviewControllerDataSource>

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
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Photo Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Camera" otherButtonTitles:@"Photo Library", @"Photo Preview",nil];
        CGPoint location = [gesture locationInView:self.view];
        CGRect rect = CGRectMake(location.x, location.y, self.imagePhotograph.frame.size.width, self.imagePhotograph.frame.size.height);
        [actionSheet showFromRect:rect inView:self.view animated:YES];
    }else if (library) {
        [self showPhotoLibrary];
    }else {
        [self showAlertWithTitle:@"Photo Library Not Available"
                         message:@"RAMS requires access to your Photo Library. Go to Settings > Privacy > Photos and turn on access for RAMS Manager."];
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
    
    self.previewingPhotos = [NSMutableArray array];
    //add all photo
    if (self.registration.biometric.photograph)[self.previewingPhotos addObject:self.registration.biometric.photograph];
    if (self.registration.biometric.leftIndex)[self.previewingPhotos addObject:self.registration.biometric.leftIndex];
    if (self.registration.biometric.leftThumb)[self.previewingPhotos addObject:self.registration.biometric.leftThumb];
    if (self.registration.biometric.rightIndex)[self.previewingPhotos addObject:self.registration.biometric.rightIndex];
    if (self.registration.biometric.rightThumb)[self.previewingPhotos addObject:self.registration.biometric.rightThumb];
    
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
//    if (self.registration.biometric.photograph) return [NSURL fileURLWithPath:self.registration.biometric.photograph];
    
    
    return [NSURL fileURLWithPath:self.previewingPhotos[index]];
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
    self.popover = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
    [self.popover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}


#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.popover dismissPopoverAnimated:YES];
    self.popover = nil;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (info[UIImagePickerControllerOriginalImage]) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        image = [image scaledToHeight:1800];
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        [self.registration.biometric updatePhotographData:imageData];
        self.imagePhotograph.image = [self.registration.biometric.photographImage scaledToWidthInPoint:100];
    }
    
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }else {
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
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    }
    //     [self.context reset];
    
    if (self.registrationCancel) {
        self.registrationCancel();
    }
    
}

- (void)save
{
    
    NSNumber * lastStatus = self.registration.complete;
    BOOL needRemove = NO;
    
    //checking the value
    if (!self.registration.unhcrDocument && self.registration.unhcrNumber) {
        //show alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Input" message:@"Please Fill UNHCR Document First" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    //set current date for date of entry
    if (self.registration.interceptionData.dateOfEntry == Nil) {
        self.registration.interceptionData.dateOfEntry =[NSDate date];
    }
    
    [self.registration validateCompletion];
    needRemove = (lastStatus != self.registration.complete);
    
    self.registration.dateCreated = [NSDate date];
    
    NSManagedObjectContext *workingContext = self.registration.managedObjectContext;
    NSError *error;
    
    
    //TODO : check if this is from Migrant list, if Yes then delete the migrant data
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Migrant"];
    
    request.predicate = [NSPredicate predicateWithFormat:@"registrationNumber = %@",self.registration.registrationId];
    request.returnsObjectsAsFaults = YES;
    
    NSArray *data = [workingContext executeFetchRequest:request error:&error];
    if ([data count]) {
        int i = 1;
        for (NSManagedObject *managedObject in data) {
            [workingContext deleteObject:managedObject];
            NSLog(@"%i object deleted",i);
            needRemove = YES;
        }
        
    }
    
    if (![workingContext save:&error]) {
        NSLog(@"Error saving context: %@", [error description]);
        [self showAlertWithTitle:@"Failed Saving Registration" message:@"Please try again. If problem persist, please cancel and consult with administrator."];
    }else {
        //save database
        [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
        if (self.registrationSave) {
            self.registrationSave(needRemove);
        }
    }
    
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
        self.title = @"Edit Registration";
        self.editingMode = YES;
        [self updateBiometricImages];
    }else {
        self.title = @"New Registration";
        self.editingMode = NO;
        self.registration = [Registration newRegistrationInContext:self.context];
    }
    
    //setup actions
    [self setupFingerprintGestureRecognizer:self.imageRightThumb];
    [self setupFingerprintGestureRecognizer:self.imageRightIndex];
    [self setupFingerprintGestureRecognizer:self.imageLeftThumb];
    [self setupFingerprintGestureRecognizer:self.imageLeftIndex];
    
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                          initWithTarget:self
                                                          action:@selector(showPhotoPreview)];
    [doubleTapGestureRecognizer setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:doubleTapGestureRecognizer];
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showPhotographOption:)];
    [singleTapGestureRecognizer setNumberOfTapsRequired:1];
    // Wait for failed doubleTapGestureRecognizer
    [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
    self.imagePhotograph.userInteractionEnabled = YES;
    [self.imagePhotograph addGestureRecognizer:singleTapGestureRecognizer];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    
    UIViewController *vc = [self.childViewControllers lastObject];
    if ([vc isKindOfClass:[IMEditRegistrationDataVC class]]) {
        IMEditRegistrationDataVC *regVC = (IMEditRegistrationDataVC *)vc;
        regVC.registration = self.registration;
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
        self.imageRightIndex.image = [[self.registration.biometric fingerImageForPosition:RightIndex] scaledToWidthInPoint:100];
    }else {
        self.imageRightIndex.image = defaultImage;
    }
    
    if (self.registration.biometric.rightThumb) {
        self.imageRightThumb.image = [[self.registration.biometric fingerImageForPosition:RightThumb] scaledToWidthInPoint:100];
    }else {
        self.imageRightThumb.image = defaultImage;
    }
    
    if (self.registration.biometric.leftIndex) {
        self.imageLeftIndex.image = [[self.registration.biometric fingerImageForPosition:LeftIndex] scaledToWidthInPoint:100];
    }else {
        self.imageLeftIndex.image = defaultImage;
    }
    
    if (self.registration.biometric.leftThumb) {
        self.imageLeftThumb.image = [[self.registration.biometric fingerImageForPosition:LeftThumb] scaledToWidthInPoint:100];
    }else {
        self.imageLeftThumb.image = defaultImage;
    }
    
    if (self.registration.biometric.photograph) {
        self.imagePhotograph.image = [[self.registration.biometric photographImage] scaledToWidthInPoint:100];
    }else {
        self.imagePhotograph.image = [UIImage imageNamed:@"icon-avatar-large"];
    }
}

@end