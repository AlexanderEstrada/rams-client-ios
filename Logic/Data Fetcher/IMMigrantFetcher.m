//
//  IMMigrantFetcher.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMMigrantFetcher.h"
#import "IMHTTPClient.h"
#import "IMConstants.h"
#import "NSDate+Relativity.h"
#import "IMDBManager.h"

@interface IMMigrantFetcher () {
    dispatch_queue_t migrantQueue;
    NSManagedObjectContext *context;
}

@property (nonatomic) NSInteger currentProgress;
@property (nonatomic) NSInteger currentTotal;
@property (nonatomic) BOOL hasNext;

@end


@implementation IMMigrantFetcher

- (void)fetchUpdates
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@(10) forKey:@"max"];
    [params setObject:@(self.progress) forKey:@"offset"];

    NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:IMLastSyncDate];
    if (lastSyncDate) [params setObject:[lastSyncDate toUTCString] forKey:@"since"];
    
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client getJSONWithPath:@"migrant/list"
                 parameters:params
                    success:^(NSDictionary *jsonData, int statusCode){ [self parseMigrants:jsonData]; }
                    failure:self.onFailure];
}

- (void)fetchMigrant:(NSString *)migrantId
{
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client getJSONWithPath:@"migrant/list"
                 parameters:@{@"id":migrantId}
                    success:^(NSDictionary *jsonData, int statusCode){ [self parseMigrants:jsonData]; }
                    failure:self.onFailure];
}

- (void)setCurrentProgress:(NSInteger)currentProgress
{
    _currentProgress = currentProgress;
    
    //when current progress equals to current total and list has next, fetch next batch
    if (self.hasNext && self.currentProgress && self.currentProgress == self.currentTotal) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self fetchUpdates]; });
    }
}


#pragma Specific Implementation
- (void)parseMigrants:(NSDictionary *)dictionary
{
    @try {
        NSArray *migrants = dictionary[@"results"];
        
        self.total = [dictionary[@"total"] integerValue];
        self.hasNext = [dictionary[@"next"] boolValue];
        
        //reset current progress and update current total to current batch count
        self.currentProgress = 0;
        self.currentTotal = [migrants count];
        
        if (!self.currentTotal) {   //finalize synchronizer when returned migrants count reached zero
            [self postFinished];
        }else {
            for (NSString *migrantId in migrants) { //otherwise, fetch migrant data
                [self fetchMigrant:migrantId];
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Error while parsing migrant list: %@\nError message: %@", dictionary, [exception description]);
        if (self.onFailure) self.onFailure([NSError errorWithDomain:@"Exception Occurred" code:0 userInfo:@{@"errorMessage":[exception description]}]);
    }
}

- (void)parseMigrant:(NSDictionary *)dictionary
{
    //define queue if it's nil
    if (!migrantQueue) {
        migrantQueue = dispatch_queue_create("MigrantQueue", NULL);
        dispatch_sync(migrantQueue, ^{
            context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            context.parentContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        });
    }
    
    dispatch_async(migrantQueue, ^{
        @autoreleasepool {
            @try {
                //TODO: Parse migrant dictionary
                
                
                NSError *error;
                if (![context save:&error]) {
                    NSLog(@"Failed saving context after parsing migrant: %@\nError message: %@", dictionary, [error description]);
                    [self postFailureWithError:error];
                }
                
                //update fetcher's progress, end it if necessary
                self.progress++;
                if (self.progress == self.total) {
                    [self postFinished];
                }else {
                    //if fetcher not finished yet, update current batch progress
                    self.currentProgress++;
                }
            }
            @catch (NSException *exception) {
                NSLog(@"Error while parsing migrant dictionary: %@\nError message: %@", dictionary, [exception description]);
                [self postFailureWithError:[NSError errorWithDomain:@"Exception Occurred" code:0 userInfo:@{@"errorMessage":[exception description]}]];
            }
        }
    });
}

@end