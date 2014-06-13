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
#import "Migrant+Extended.h"
#import "Registration+Export.h"

@interface IMMigrantFetcher () {
    dispatch_queue_t migrantQueue;
    dispatch_queue_t registrationQueue;
    NSManagedObjectContext *context;
    NSManagedObjectContext *reg_context;
}

@property (nonatomic) NSInteger currentProgress;
@property (nonatomic) NSInteger currentTotal;
@property (nonatomic) float lastProgress;
@property (nonatomic) int lastTotal;
@property (nonatomic) BOOL hasNext;

@end


@implementation IMMigrantFetcher

- (void)fetchUpdates
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:@(100) forKey:@"max"];
    
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
    [client getJSONWithPath:@"migrant/show"
                 parameters:@{@"id":migrantId}
                    success:^(NSDictionary *jsonData, int statusCode){ [self parseMigrant:jsonData]; }
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

- (void) saveToRegistration :(Migrant *)data
{

    
    //define queue if it's nil
    if (!registrationQueue) {
        registrationQueue = dispatch_queue_create("RegistrationQueue", NULL);
        //        migrantQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_sync(registrationQueue, ^{
            reg_context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            reg_context.parentContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        });
    }
    
    dispatch_async(registrationQueue, ^{
        @autoreleasepool {
            @try {
       
                //save to registration
                Registration * reg = [Registration registrationFromMigrant:data inManagedObjectContext:reg_context];
                
                //save to array
                //                    NSError *error;
                NSError *error;
                BOOL result = [reg_context save:&error];
                if (!result || !reg) {
                    [reg_context rollback];
                    NSLog(@"Failed saving context Error : %@\n after parsing migrant - JSON : \n %@",[error description], data);
                    [self postFailureWithError:error];
                }
//                 [reg_context reset];
                
                NSLog(@"Procced Registration %ld from %ld ",(long)self.progress,(long)self.total);
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
                NSLog(@"Error while parsing registrationFromMigrant - Error message: %@", [exception description]);
                [reg_context rollback];
                [self postFailureWithError:[NSError errorWithDomain:@"Exception Occurred" code:0 userInfo:@{@"errorMessage":[exception description]}]];
            }
        }
    });
    
    
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
                Migrant * data = [Migrant migrantWithDictionary:dictionary inContext:context];
                NSError *error;
                if (!data) {
                    NSLog(@"Failed saving context after parsing migrant - JSON : \n %@", dictionary);
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
//                     [context reset];
                    
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