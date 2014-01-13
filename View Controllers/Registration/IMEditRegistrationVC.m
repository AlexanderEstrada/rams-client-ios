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


@interface IMEditRegistrationVC ()<UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate>

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


@implementation IMEditRegistrationVC

- (void)showFingerprintScanner:(UITapGestureRecognizer *)gesture
{
    IMScanFingerprintViewController *scanner = [self.storyboard instantiateViewControllerWithIdentifier:@"IMScanFingerprintViewController"];
    scanner.modalPresentationStyle = UIModalPresentationFormSheet;
    scanner.currentFingerPosition = gesture.view.tag;
    
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
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Photo Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Camera" otherButtonTitles:@"Photo Library", nil];
        CGPoint location = [gesture locationInView:self.view];
        CGRect rect = CGRectMake(location.x, location.y, self.imagePhotograph.frame.size.width, self.imagePhotograph.frame.size.height);
        [actionSheet showFromRect:rect inView:self.view animated:YES];
    }else if (library) {
        [self showPhotoLibrary];
    }else {
        [self showAlertWithTitle:@"Photo Library Not Available"
                         message:@"IMMS requires access to your Photo Library. Go to Settings > Privacy > Photos and turn on access for IMMS Manager."];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [actionSheet destructiveButtonIndex]) {
        [self showCamera];
    }else if (buttonIndex != [actionSheet cancelButtonIndex]) {
        [self showPhotoLibrary];
    }
}

- (void)showCamera
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = NO;
    
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    [self presentViewController:imagePickerController animated:YES completion:nil];
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
}

- (void)save
{
    [self.registration validateCompletion];
    NSManagedObjectContext *workingContext = self.registration.managedObjectContext;
    NSError *error;
    
    if (![workingContext save:&error]) {
        NSLog(@"Error saving context: %@", [error description]);
        [self showAlertWithTitle:@"Failed Saving Registration" message:@"Please try again. If problem persist, please cancel and consult with administrator."];
    }else {
        [self dismissViewControllerAnimated:YES completion:nil];
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
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showPhotographOption:)];
    self.imagePhotograph.userInteractionEnabled = YES;
    [self.imagePhotograph addGestureRecognizer:gesture];
    
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