//
//  IMDetentionLocationFetcher.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/14/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMAccommodationFetcher.h"
#import "IMDBManager.h"
#import "IMConstants.h"
#import "IMHTTPClient.h"
#import "Accommodation+Extended.h"
#import "IMPhotoFetcher.h"


@implementation IMAccommodationFetcher

- (void)fetchUpdates
{
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client getJSONWithPath:@"accommodation/list"
                 parameters:nil
                    success:^(NSDictionary *jsonData, int statusCode){ [self parseAccommodations:jsonData]; }
                    failure:self.onFailure];
}

- (void)parseAccommodations:(NSDictionary *)dictionary
{
    dispatch_queue_t queue = dispatch_queue_create("AccommodationParser", NULL);
    dispatch_async(queue, ^{
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        context.parentContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        
        @try {
            self.total = [dictionary[@"total"] intValue];
            NSArray *results = dictionary[@"results"];
            
            for (NSDictionary *accommodationDict in results) {
                [context performBlockAndWait:^{
                    Accommodation *accommodation = [Accommodation accommodationWithDictionary:accommodationDict inManagedObjectContext:context];
                    if (!accommodation) NSLog(@"Failed parsing accommodation dictionary: %@", accommodationDict);
                    self.progress++;
                }];
            }
            
            NSError *error;
            if ([context save:&error]) {
                [self postFinished];
            }else {
                [context rollback];
                [self postFailureWithError:error];
            }
        }
        @catch (NSException *exception) {
            [context rollback];
            NSLog(@"Exception while fetching updates for accommodation: %@", [exception description]);
            [self postFailureWithError:[NSError errorWithDomain:@"Fetcher Exception" code:0 userInfo:@{IMSyncKeyError: [exception description]}]];
        }
    });
}

@end
