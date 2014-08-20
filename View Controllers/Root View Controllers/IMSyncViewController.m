//
//  IMSyncViewController.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/14/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMSyncViewController.h"
#import "IMAccommodationFetcher.h"
#import "IMInterceptionFetcher.h"
#import "IMReferencesFetcher.h"
#import "IMInterceptionLocationFetcher.h"
#import "IMPhotoFetcher.h"
#import "IMDBManager.h"
#import "Photo+Extended.h"
#import "IMMigrantFetcher.h"
#import "IMAuthManager.h"
#import "IMRegistrationFetcher.h"
#import "IMFamilyDataFetcher.h"

typedef enum : NSUInteger {
    state_start,
    state_finish,
    state_location,
    state_interception_location,
    state_interception_case,
    state_reference,
    state_migrant,
    state_photo,
    state_family,
    state_registration
} synchState;


@interface IMSyncViewController ()<UIAlertViewDelegate>
@property (nonatomic) BOOL updating;
@property (nonatomic) BOOL success;
@property (nonatomic) synchState currentState;
@property (nonatomic,strong) IMDataFetcher *currentFetcher;
@end



@implementation IMSyncViewController



- (synchState)sharedSynchState
{
    static dispatch_once_t once;
    static synchState singleton;
    
    dispatch_once(&once, ^{
        singleton = state_start;
    });
    
    return singleton;
}

- (void)startSynchronization
{
    if (self.updating) return;
  
    //start blocking
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [UIView animateWithDuration:.35 animations:^{
        self.warningContainer.alpha = 1;
        self.updating = YES;
        self.buttonStart.hidden = YES;
        self.buttonTryLater.hidden = YES;
        self.progressBar.hidden = NO;
        self.progressBar.progress = 0;
        self.labelTitle.text = @"Data Updates";
        self.labelProgress.text = @"Contacting server";
    } completion:^(BOOL finished){
        switch (self.currentState) {
            case state_location:
                [self fetchAccommodations];
                break;
            case state_interception_case:
                [self fetchInterceptionCases];
                break;
            case state_reference:
                [self fetchReferences];
                break;
            case state_interception_location:
                [self fetchInterceptionLocations];
                break;
            case state_migrant:
                [self fetchMigrants];
                break;
            case state_photo:
                [self synchronizePhotos];
                break;
            case state_registration:
                [self synchronizeRegistrations];
                break;
            case state_finish:
                [self finished];
                break;
            case state_family:
                [self fetchFamilys];
                break;
            default:
                [self fetchReferences];
                break;
        }
        
    }];
}

- (void)finishedWithError:(NSError *)error
{
    NSLog(@"Synchronization error: %@", [error description]);

    [UIView animateWithDuration:.35 animations:^{
        self.progressBar.hidden = YES;
        self.warningContainer.alpha = 0;
        [self.buttonStart setTitle:@"Try Again" forState:UIControlStateNormal];
        [self.buttonStart setHidden:NO];
        [self.buttonTryLater setHidden:NO];
//        if (++self.try_counter > 3) {
//            self.try_counter =0;
//            [[IMAuthManager sharedManager] logout];
//        }

    } completion:^(BOOL finished){
        self.updating = NO;
        self.success = NO;
        self.labelTitle.text = @"Updates Failed";
        self.labelProgress.text = @"Please check your internet connection and try again.\nIf problem persist, contact administrator.";
    }];
    
}

- (void)finished
{

    [UIApplication sharedApplication].idleTimerDisabled = NO;

    self.updating = NO;
    self.labelProgress.text = @"";
    self.success = YES;
    [self.buttonStart setTitle:@"Start App" forState:UIControlStateNormal];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate date] forKey:IMLastSyncDate];
    [defaults synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil userInfo:nil];
    [UIView animateWithDuration:.35 animations:^{
        self.buttonStart.hidden = NO;
        self.progressBar.hidden = YES;
        self.labelWarning1.hidden = YES;
        self.labelWarning2.hidden = YES;
        self.labelWarning3.hidden = YES;
        self.labelProgress.hidden = YES;
        self.buttonTryLater.hidden = YES;
        self.warningContainer.alpha = 0;
        self.labelTitle.text = @"Updates Finished";
    }];
    self.currentState = state_finish;
    //delete pointer
    self.currentFetcher = Nil;
}

- (void)execute:(IMDataFetcher *)fetcher
{
    fetcher.onFailure = ^(NSError *error){ [self finishedWithError:error]; };
    fetcher.onProgress = ^(float progress, float total){self.progressBar.progress = progress / total;};
    [fetcher fetchUpdates];
}


#pragma mark Fetcher Management
- (void)fetchReferences
{
    if (self.currentState != state_reference) {
    self.currentState = state_reference;
        _currentFetcher = [[IMReferencesFetcher alloc] init];
         __weak typeof(self) weakSelf = self;
        _currentFetcher.onFinished = ^{ [weakSelf fetchAccommodations]; };
    }
    self.labelProgress.text = @"Updating References";
    [self execute:_currentFetcher];
}

- (void)fetchAccommodations
{
    if (self.currentState != state_location) {
        self.currentState = state_location;
        _currentFetcher = [[IMAccommodationFetcher alloc] init];
         __weak typeof(self) weakSelf = self;
        _currentFetcher.onFinished = ^{ [weakSelf fetchInterceptionLocations]; };
    }
    self.labelProgress.text = @"Updating Locations";
    [self execute:_currentFetcher];
}

- (void)fetchInterceptionLocations
{
    if (self.currentState != state_interception_location) {
        self.currentState = state_interception_location;
        _currentFetcher = [[IMInterceptionLocationFetcher alloc] init];
        __weak typeof(self) weakSelf = self;
        _currentFetcher.onFinished = ^{ [weakSelf fetchInterceptionCases]; };
    }
    self.labelProgress.text = @"Updating Interception Locations";
    [self execute:_currentFetcher];
}

- (void)fetchInterceptionCases
{
    if (self.currentState != state_interception_case) {
        self.currentState = state_interception_case;
        _currentFetcher = [[IMInterceptionFetcher alloc] init];
         __weak typeof(self) weakSelf = self;
        _currentFetcher.onFinished = ^{ [weakSelf fetchMigrants]; };
    }
    self.labelProgress.text = @"Updating Interception Cases";
    [self execute:_currentFetcher];
}

- (void)fetchMigrants
{
    if (self.currentState != state_migrant) {
        self.currentState = state_migrant;
        _currentFetcher = [[IMMigrantFetcher alloc] init];
        __weak typeof(self) weakSelf = self;
        _currentFetcher.onFinished = ^{ [weakSelf synchronizePhotos]; };
    }
     self.labelProgress.text = @"Updating Migrant Data";
    [self execute:_currentFetcher];
}

- (void)synchronizePhotos
{
    if (self.currentState != state_photo) {
        self.currentState = state_photo;
       _currentFetcher = [[IMPhotoFetcher alloc] init];
         __weak typeof(self) weakSelf = self;
//        _currentFetcher.onFinished = ^{ [weakSelf fetchFamilys]; };
                _currentFetcher.onFinished = ^{ [weakSelf finished]; };
    }
    self.labelProgress.text = @"Downloading Photos...";
    [self execute:_currentFetcher];
}



- (void)fetchFamilys
{
    if (self.currentState != state_family) {
        self.currentState = state_family;
        _currentFetcher = [[IMFamilyDataFetcher alloc] init];
        __weak typeof(self) weakSelf = self;
        _currentFetcher.onFinished = ^{ [weakSelf finished]; };
    }
    self.labelProgress.text = @"Updating Family Data";
    [self execute:_currentFetcher];
}


- (void)synchronizeRegistrations
{
    if (self.currentState != state_registration) {
        self.currentState = state_registration;
        _currentFetcher = [[IMRegistrationFetcher alloc] init];
         __weak typeof(self) weakSelf = self;
        _currentFetcher.onFinished = ^{ [weakSelf finished]; };
    }
    self.labelProgress.text = @"Synchronize Registration...";
    [self execute:_currentFetcher];
}
- (void)start
{

    if (self.success) {
        [self.sideMenuDelegate showContent];
    }else {
        [self startSynchronization];
    }
}

#pragma View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.tintColor = [UIColor IMRed];
    self.buttonStart.hidden = YES;
    self.buttonTryLater.hidden = YES;
    self.buttonStart.tintColor = [UIColor IMRed];
    self.buttonTryLater.tintColor = [UIColor IMRed];
    self.labelTitle.textColor = [UIColor IMRed];
    [self.buttonStart addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
     [self.buttonTryLater addTarget:self action:@selector(tryLater) forControlEvents:UIControlEventTouchUpInside];
    self.try_counter =0;
    self.currentState = [self sharedSynchState];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.view removeGestureRecognizer:[self.sideMenuDelegate swipeRightGesture]];
    [self.view removeGestureRecognizer:[self.sideMenuDelegate swipeLeftGesture]];
    [self startSynchronization];
}

- (NSUInteger) supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
    
}

- (void)tryLater
{
    //TODO : show alert to user : they need to synch before they can use apps, if yes then showApps, if not then retry again
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Start RAMS without Sync"
                                                    message:@"There is no data on RAMS, please manually synchronize, before you use RAMS.\nContinue ?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Yes", nil];
    alert.tag = IMAlertStartWithoutSynch_Tag;
    [alert show];
    
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if (alertView.tag == IMAlertStartWithoutSynch_Tag && buttonIndex != [alertView cancelButtonIndex]) {
        //delete pointer
        self.currentFetcher = Nil;
        
     //start apps without synch
         [self.sideMenuDelegate showContent];
    }
}


@end