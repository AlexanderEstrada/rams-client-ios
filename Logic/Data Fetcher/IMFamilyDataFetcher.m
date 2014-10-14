//
//  IMFamilyDataFetcher.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 8/18/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMFamilyDataFetcher.h"
#import "IMHTTPClient.h"
#import "IMConstants.h"
#import "NSDate+Relativity.h"
#import "IMDBManager.h"
#import "FamilyRegisterEntry+Extended.h"
#import "FamilyRegister+Extended.h"


@interface IMFamilyDataFetcher () {
    dispatch_queue_t familyQueue;
    NSManagedObjectContext *context;
}

@property (nonatomic) NSInteger currentProgress;
@property (nonatomic) NSInteger currentTotal;
@property (nonatomic) float lastProgress;
@property (nonatomic) int lastTotal;
@property (nonatomic) BOOL hasNext;

@end

@implementation IMFamilyDataFetcher

- (void)fetchUpdates
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@(100) forKey:@"max"];
    
    [params setObject:@(self.progress) forKey:@"offset"];
    
    NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:IMLastSyncDate];
    if (lastSyncDate) [params setObject:[lastSyncDate toUTCStringWithTime] forKey:@"since"];
    
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client getJSONWithPath:@"family/list"
                 parameters:params
                    success:^(NSDictionary *jsonData, int statusCode){ [self parseFamilys:jsonData]; }
                    failure:self.onFailure];
}

- (void)fetchMigrant:(NSString *)migrantId
{
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client getJSONWithPath:@"family/get"
                 parameters:@{@"id":migrantId}
                    success:^(NSDictionary *jsonData, int statusCode){ [self parseFamily:jsonData]; }
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
- (void)parseFamilys:(NSDictionary *)dictionary
{
    @try {
        NSArray *migrants = dictionary[@"results"];
        
        self.total = [dictionary[@"total"] integerValue];
        self.hasNext = [dictionary[@"next"] boolValue];
        
        //reset current progress and update current total to current batch count
        self.currentProgress = 0;
        self.currentTotal = [migrants count];
        NSLog(@"self.currentTotal : %ld",(long)self.currentTotal);
        
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

- (void)parseFamily:(NSDictionary *)dictionary
{
    //define queue if it's nil
    if (!familyQueue) {
        familyQueue = dispatch_queue_create("FamilyQueue", NULL);
        dispatch_sync(familyQueue, ^{
            context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            context.parentContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        });
    }
    
    dispatch_async(familyQueue, ^{
        @autoreleasepool {
            @try {
                //TODO: Parse family dictionary
                FamilyRegister * data = [FamilyRegister familyRegisterWithDictionary:dictionary inContext:context];
                NSError *error;
                if (!data) {
                    NSLog(@"Failed saving context after parsing family - JSON : \n %@", dictionary);
                    [context rollback];
                    [self postFailureWithError:error];
                }
                else{
                    //save to registration
                    BOOL result = [context save:&error];
                    
                    if (!result) {
                        [context rollback];
                        NSLog(@"Failed saving context Error : %@\n after parsing migrant - JSON : \n %@",[error description], data);
                        [self postFailureWithError:error];
                    }
                    //commit database
                    [context reset];
                    
                }
                NSLog(@"Process Migrant %ld from %ld ",(long)self.progress+1,(long)self.total);
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
                [context rollback];
                [self postFailureWithError:[NSError errorWithDomain:@"Exception Occurred" code:0 userInfo:@{@"errorMessage":[exception description]}]];
            }
        }
    });
}

@end