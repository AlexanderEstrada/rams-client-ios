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

@interface IMSyncViewController ()<UIAlertViewDelegate>
@property (nonatomic) BOOL updating;
@property (nonatomic) BOOL success;
@end


@implementation IMSyncViewController


- (void)startSynchronization
{
    if (self.updating) return;
    
    [UIView animateWithDuration:.35 animations:^{
        self.warningContainer.alpha = 1;
        self.updating = YES;
        self.buttonStart.hidden = YES;
        self.progressBar.hidden = NO;
        self.progressBar.progress = 0;
        self.labelTitle.text = @"Data Updates";
        self.labelProgress.text = @"Contacting server";
    } completion:^(BOOL finished){
        [self fetchReferences];
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
    } completion:^(BOOL finished){
        self.updating = NO;
        self.success = NO;
        self.labelTitle.text = @"Updates Failed";
        self.labelProgress.text = @"Please check your internet connection and try again.\nIf problem persist, contact administrator.";
    }];
}

- (void)finished
{
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
        self.warningContainer.alpha = 0;
        self.labelTitle.text = @"Updates Finished";
    }];
}

- (void)execute:(IMDataFetcher *)fetcher
{
    fetcher.onFailure = ^(NSError *error){ [self finishedWithError:error]; };
    fetcher.onProgress = ^(float progress, float total){ self.progressBar.progress = progress / total; };
    [fetcher fetchUpdates];
}


#pragma mark Fetcher Management
- (void)fetchReferences
{
    self.labelProgress.text = @"Updating References";
    IMDataFetcher *fetcher = [[IMReferencesFetcher alloc] init];
    fetcher.onFinished = ^{ [self fetchAccommodations]; };
    [self execute:fetcher];
}

- (void)fetchAccommodations
{
    self.labelProgress.text = @"Updating Accommodations";
    IMDataFetcher *fetcher = [[IMAccommodationFetcher alloc] init];
    fetcher.onFinished = ^{ [self fetchInterceptionLocations]; };
    [self execute:fetcher];
}

- (void)fetchInterceptionLocations
{
    self.labelProgress.text = @"Updating Interception Locations";
    IMDataFetcher *fetcher = [[IMInterceptionLocationFetcher alloc] init];
    fetcher.onFinished = ^{ [self fetchInterceptionCases]; };
    [self execute:fetcher];
}

- (void)fetchInterceptionCases
{
    self.labelProgress.text = @"Updating Interception Cases";
    IMDataFetcher *fetcher = [[IMInterceptionFetcher alloc] init];
    fetcher.onFinished = ^{ [self synchronizePhotos]; };
    [self execute:fetcher];
}

- (void)fetchMigrants
{
    self.labelProgress.text = @"Updating Irregular Migrant Data";
}

- (void)synchronizePhotos
{
    self.labelProgress.text = @"Downloading Photos...";
    IMDataFetcher *fetcher = [[IMPhotoFetcher alloc] init];
    fetcher.onFinished = ^{ [self finished]; };
    [self execute:fetcher];
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
    self.buttonStart.tintColor = [UIColor IMRed];
    self.labelTitle.textColor = [UIColor IMRed];
    [self.buttonStart addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.view removeGestureRecognizer:[self.sideMenuDelegate swipeRightGesture]];
    [self.view removeGestureRecognizer:[self.sideMenuDelegate swipeLeftGesture]];
    [self startSynchronization];
}

@end