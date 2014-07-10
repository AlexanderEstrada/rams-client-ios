//
//  IMInterceptionLocationFetcher.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/14/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMInterceptionLocationFetcher.h"
#import "InterceptionLocation+Extended.h"
#import "IMDBManager.h"
#import "IMConstants.h"
#import "IMHTTPClient.h"


@interface IMInterceptionLocationFetcher()

@property (nonatomic, copy) void (^onFinished)(void);
@property (nonatomic, copy) void (^onFailure)(NSError *error);
@property (nonatomic, copy) void (^onProgress)(float progress, float total);

@property (nonatomic) int total;
@property (nonatomic) int progress;

@end


@implementation IMInterceptionLocationFetcher

- (void)fetchUpdates
{
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client getJSONWithPath:@"interceptionLocation/list"
                 parameters:nil
                    success:^(NSDictionary *jsonData, int statusCode){ [self parseInterceptionLocation:jsonData]; }
                    failure:self.onFailure];
}

- (void)parseInterceptionLocation:(NSDictionary *)dictionary
{
    dispatch_queue_t queue = dispatch_queue_create("InterceptionLocationParser", NULL);
    dispatch_async(queue, ^{
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        context.parentContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        
        @try {
            self.total = [dictionary[@"total"] intValue];
            NSArray *results = dictionary[@"results"];
            
            for (NSDictionary *locationDict in results) {
                [context performBlockAndWait:^{
                    InterceptionLocation *location = [InterceptionLocation locationWithDictionary:locationDict inManagedObjectContext:context];
                    if (!location) NSLog(@"Failed parsing interception location dictionary: %@", locationDict);
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
             [context reset];
        }
        @catch (NSException *exception) {
            [context rollback];
            NSLog(@"Exception while fetching updates for interception location: %@", [exception description]);
            [self postFailureWithError:[NSError errorWithDomain:@"Fetcher Exception" code:0 userInfo:@{IMSyncKeyError: [exception description]}]];
        }
    });
}

@end
