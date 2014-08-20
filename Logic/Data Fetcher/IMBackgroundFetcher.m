//
//  IMBackgroundUpdater.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/26/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMBackgroundFetcher.h"
#import "IMDataFetcher.h"
#import "IMAccommodationFetcher.h"
#import "IMInterceptionFetcher.h"
#import "IMReferencesFetcher.h"
#import "IMPhotoFetcher.h"
#import "IMInterceptionLocationFetcher.h"
#import "IMConstants.h"
#import "IMDBManager.h"
#import "IMMigrantFetcher.h"
#import "IMFamilyDataFetcher.h"


@interface IMBackgroundFetcher()

@property (nonatomic, copy) void (^completionHandler)(BOOL success);

@end


@implementation IMBackgroundFetcher

- (void)startBackgroundUpdatesWithCompletionHandler:(void (^)(BOOL success))completionHandler
{
    NSLog(@"Starting background updates... ");
    self.completionHandler = completionHandler;
    [self fetchReferences];
}

- (void)execute:(IMDataFetcher *)fetcher
{
    fetcher.onFailure = ^(NSError *error){ [self finishedWithError:error]; };
    [fetcher fetchUpdates];
}

- (void)finished
{
    if (self.completionHandler) self.completionHandler(YES);
    NSLog(@"Background Updates Finished");
}

- (void)finishedWithError:(NSError *)error
{
    if (self.completionHandler) self.completionHandler(NO);
    NSLog(@"Background updates error: %@", [error description]);
}


#pragma mark Fetcher Management
- (void)fetchReferences
{
    NSLog(@"Updating References");
    IMDataFetcher *fetcher = [[IMReferencesFetcher alloc] init];
    fetcher.onFinished = ^{ [self fetchAccommodations]; };
    [self execute:fetcher];
}

- (void)fetchAccommodations
{
//    NSLog(@"Updating Accommodations");
        NSLog(@"Updating Locations");
    IMDataFetcher *fetcher = [[IMAccommodationFetcher alloc] init];
    fetcher.onFinished = ^{ [self fetchInterceptionLocations]; };
    [self execute:fetcher];
}

- (void)fetchInterceptionLocations
{
    NSLog(@"Updating Interception Locations");
    IMDataFetcher *fetcher = [[IMInterceptionLocationFetcher alloc] init];
    fetcher.onFinished = ^{ [self fetchInterceptionCases]; };
    [self execute:fetcher];
}

- (void)fetchInterceptionCases
{
    NSLog(@"Updating Interception Cases");
    IMDataFetcher *fetcher = [[IMInterceptionFetcher alloc] init];
    fetcher.onFinished = ^{ [self fetchMigrants]; };
    [self execute:fetcher];
}

- (void)fetchMigrants
{
    NSLog(@"Updating Migrant Data");
    
    IMDataFetcher *fetcher = [[IMMigrantFetcher alloc] init];
    fetcher.onFinished = ^{ [self synchronizePhotos]; };
    [self execute:fetcher];
//    [self synchronizePhotos] ;
}

- (void)synchronizePhotos
{
    NSLog(@"Downloading Photos...");
    IMDataFetcher *fetcher = [[IMPhotoFetcher alloc] init];
//    fetcher.onFinished = ^{ [self fetchFamilys]; };
        fetcher.onFinished = ^{ [self finished]; };
    [self execute:fetcher];
}

- (void)fetchFamilys
{
    NSLog(@"Updating Family Data");
    IMDataFetcher *fetcher = [[IMFamilyDataFetcher alloc] init];
    fetcher.onFinished = ^{ [self finished]; };
    [self execute:fetcher];
}

@end