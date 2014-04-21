//
//  IMScanFingerprintViewController.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMScanFingerprintViewController.h"
#import "FbFAccessoryController.h"
#import "UIImage+ImageUtils.h"
#import "IMBiometricEngine.h"
#import "Biometric+Storage.h"


@interface IMScanFingerprintViewController ()<FbFmobileOneDelegate>

@property (weak, nonatomic) IBOutlet UIButton *buttonRescan;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UIButton *buttonNext;
@property (weak, nonatomic) IBOutlet UIButton *buttonBack;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *scanningView;

@property (strong, nonatomic) NSMutableDictionary *data;
@property (strong, nonatomic) UIBarButtonItem *itemDone;

@property (strong, nonatomic) FbFAccessoryController *scanner;
@property (strong, nonatomic) IMBiometricEngine *engine;
//@property (strong, nonatomic) Biometric * biometric;
@property (nonatomic) BOOL scanCompleted;

@end



@implementation IMScanFingerprintViewController

#pragma mark FbF
#pragma mark FbFmobileOneDelegate Methods
- (void)mobileOneAccessoryController:(FbFAccessoryController *)mobileOne didChangeConnectionStatus:(BOOL)connected
{
    NSLog(@"Fingerprint connection changed: %@", connected ? @"connected" : @"disconnected");
    [self updateUIForFingerprintScannerStatusChanged];
}

- (void)mobileOneAccessoryController:(FbFAccessoryController *)mobileOne didReceiveData:(NSData *)data
{
    //TODO : set image
    if (self.scanCompleted) return;
    
    self.scanCompleted = NO;
    UIImage *grayscaleImage = [[UIImage imageWithData:data] grayscaleImage];
    self.scanningView.image = grayscaleImage;
    [self showLoadingViewWithTitle:@"Just a moment please ..."];
    [self.engine validateFingerprintImage:grayscaleImage onComplete:^(BOOL valid){

        [self hideLoadingView];
    
        if (valid) {
            [self.data setObject:grayscaleImage forKey:@(self.currentFingerPosition)];
            self.containerView.backgroundColor = [UIColor greenColor];
            self.scanCompleted = YES;
                self.itemDone.enabled = TRUE;

            //TODO : save data
            
        }else {
            self.containerView.backgroundColor = [UIColor redColor];
            self.scanCompleted = NO;
            self.buttonRescan.hidden = FALSE;
            self.itemDone.enabled = FALSE;
        }
    }];

}

- (void)mobileOneAccessoryController:(FbFAccessoryController *)mobileOne didReceiveError:(NSError *)error
{
    [self showAlertWithTitle:@"Scanner Error"
                     message:@"Error occurred while communicating with fingerprint scanner. Please cancel this process and start again."];
}

- (void)mobileOneAccessoryController:(FbFAccessoryController *)mobileOne didReceiveDataSpin:(BOOL)started
{
    //TODO : add spin
    if (self.scanCompleted) return;
    self.containerView.backgroundColor = [UIColor blueColor];
    
}

//NOT IMPLEMENTED, ScannerStarted property always return NO anyway, BUG from vendor
- (void)mobileOneAccessoryController:(FbFAccessoryController *)mobileOne didReceiveScannerStartStop:(BOOL)started{}

- (void)updateUIForFingerprintScannerStatusChanged
{
    if (self.scanner.mobileOneConnected) {
        [self.scanner startScanner];
        [self hideLoadingView];
    }else if (!self.scanner.mobileOneConnected) {
        [self showLoadingViewWithTitle:@"Please connect fingerprint scanner to your device"];
    }
}


#pragma mark UI Workflow
- (IBAction)clear:(UIButton *)sender
{
    self.scanningView.image = nil;
    self.containerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.buttonRescan.hidden = YES;
    self.scanCompleted = NO;
    [self.data removeObjectForKey:@(self.currentFingerPosition)];
}

- (IBAction)nextFinger:(UIButton *)sender
{
    self.currentFingerPosition++;
}

- (IBAction)previousFinger:(UIButton *)sender
{
    self.currentFingerPosition--;
}

- (void)updateUIForFingerPositionChanged
{
    //data already put on dictionary
//    BOOL hasData =[self.data objectForKey:@(self.currentFingerPosition)] != nil;
    self.buttonBack.enabled = self.currentFingerPosition > 1;
    self.buttonNext.enabled = self.currentFingerPosition < 4;
    
    //TODO : reset background
    self.scanningView.image = [self.data objectForKey:@(self.currentFingerPosition)];
    
    if (self.scanningView.image != nil) {
        self.containerView.backgroundColor = [UIColor greenColor];
            self.buttonRescan.hidden = FALSE;
        self.scanCompleted = TRUE;
         self.itemDone.enabled = TRUE;
    }else {
       
        self.containerView.backgroundColor = [UIColor grayColor];
        self.buttonRescan.hidden = TRUE;
        self.scanCompleted = FALSE;
         self.itemDone.enabled = FALSE;
    }
    
    switch (self.currentFingerPosition) {
        case RightThumb:
            self.labelTitle.text = @"Scan Right Thumb";
            break;
        case RightIndex:
            self.labelTitle.text = @"Scan Right Index";
            break;
        case LeftThumb:
            self.labelTitle.text = @"Scan Left Thumb";
            break;
        case LeftIndex:
            self.labelTitle.text = @"Scan Left Index";
            break;
    }
}


#pragma mark Common Actions
- (void)setCurrentFingerPosition:(FingerPosition)currentFingerPosition
{
    _currentFingerPosition = currentFingerPosition;
    [self updateUIForFingerPositionChanged];
}

- (void)done
{
    if (self.doneCompletionBlock) self.doneCompletionBlock(self.data);
    [self cancel];
}

- (void)cancel
{
    if (self.scanner.ScannerStarted) [self.scanner stopScanner];
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.tintColor = [UIColor IMRed];
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor IMRed];
    
    self.itemDone = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(done)];
    
    //reset Done button
    self.itemDone.enabled = FALSE;
    self.navigationItem.rightBarButtonItem = self.itemDone;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    
    self.buttonBack.tintColor = [UIColor IMRed];
    self.buttonNext.tintColor = [UIColor IMRed];
    self.buttonRescan.tintColor = [UIColor IMRed];
    
    self.engine = [[IMBiometricEngine alloc] init];
    self.scanner = [FbFAccessoryController sharedController];
    self.data = [[NSMutableDictionary alloc] init];
    [self updateUIForFingerPositionChanged];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.scanner setDelegate:self];
    [self updateUIForFingerPositionChanged];
    [self updateUIForFingerprintScannerStatusChanged];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.scanner setDelegate:nil];
    [super viewWillDisappear:animated];
}

@end