//
//  IMInterceptionFetcher.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/10/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMInterceptionFetcher.h"
#import "IMHTTPClient.h"
#import "NSDate+Relativity.h"
#import "IMConstants.h"
#import "IMDBManager.h"
#import "InterceptionData+Extended.h"


@implementation IMInterceptionFetcher

#define kParamSince @"since"

#pragma mark Updater Logic
- (void)fetchUpdates
{
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client getJSONWithPath:@"interception/list"
                 parameters:@{kParamSince: [[self lastFetchDate] toUTCString]}
                    success:^(NSDictionary *jsonData, int statusCode){
                        [self parseInterceptionCases:jsonData];
                    }
                    failure:self.onFailure];
}

- (void)parseInterceptionCases:(NSDictionary *)dictionary
{
    dispatch_queue_t queue = dispatch_queue_create("InterceptionCaseParser", NULL);
    dispatch_async(queue, ^{
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        context.parentContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        
        @try {
            self.total = [dictionary[@"total"] intValue];
            NSArray *results = dictionary[@"results"];
        
            for (NSDictionary *interceptionDict in results) {
                [context performBlockAndWait:^{
                    InterceptionData *data = [InterceptionData dataWithDictionary:interceptionDict inManagedObjectContext:context];
                    if (!data){
                     NSLog(@"Failed parsing interception case dictionary: %@", interceptionDict);   
                    }
                    self.progress++;
                }];
            }
            
            NSError *error;
            if ([context save:&error]) {
                
                [self postFinished];
                [self updateLastUpdatedDate];
            }else {
                /*
                 return [NSString stringWithFormat:@"Item is missing the mandatory
                 property \"%@\" (item pointer = %p)", [error.userInfo
                 objectForKey:NSValidationKeyErrorKey], [error.userInfo
                 objectForKey:NSValidationObjectErrorKey] ];
                */
                /*
                if( withDescription )
                    return [NSString stringWithFormat:@"Item is missing the mandatory
                            property \"%@\" (item = %@)", [error.userInfo
                                                           objectForKey:NSValidationKeyErrorKey], [[error.userInfo
                                                                                                    objectForKey:NSValidationObjectErrorKey] description] ];
                 */
                NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
                NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
                if(detailedErrors != nil && [detailedErrors count] > 0) {
                    for(NSError* detailedError in detailedErrors) {
                        NSLog(@"  DetailedError: %@", [detailedError userInfo]);
                        }
                }
                    [context rollback];
                [self postFailureWithError:error];
            }
             [context reset];
        }
        @catch (NSException *exception) {
            [context rollback];
            NSLog(@"Exception while fetching updates for interception cases: %@", [exception description]);
            [self postFailureWithError:[NSError errorWithDomain:@"Fetcher Exception" code:0 userInfo:@{IMSyncKeyError: [exception description]}]];
        }
    });
}

- (void)updateLastUpdatedDate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        [def setObject:[NSDate date] forKey:IMInterceptionFetcherUpdate];
        [def synchronize];
    });
}

- (BOOL)shouldFetchUpdates
{
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:IMInterceptionFetcherUpdate];
    if (date) {
        NSTimeInterval timeInterval = [date timeIntervalSinceNow];
        return timeInterval < 3600;
    }
    
    return NO;
}

#pragma mark Data Submission
- (NSDate *)lastFetchDate
{
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:IMInterceptionFetcherUpdate];
    if (!date) {
        date = [[NSDate date] dateBySubstractingDayElement:90];
    }
    return date;
}

@end
