//
//  IMAccommodationUpdater.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/11/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMAccommodationUpdater.h"
#import "IMConstants.h"
#import "Accommodation+Extended.h"
#import "Photo+Extended.h"
#import "IMHTTPClient.h"
#import "IMDBManager.h"
#import "IMPhotoFetcher.h"


@implementation IMAccommodationUpdater

- (void)sendUpdate:(NSDictionary *)params
{
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client postJSONWithPath:@"accommodation/save"
                  parameters:params
                     success:^(NSDictionary *jsonData, int statusCode){
                         [self saveAccommodationData:jsonData];
                     }
                     failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                         NSLog(@"Error updating accommodation data: %@", [error description]);
                         if (self.failureHandler) self.failureHandler(error);
                     }];
}

- (void)saveAccommodationData:(NSDictionary *)dictionary
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = [[IMDBManager sharedManager] localDatabase].managedObjectContext;
    
    NSError *error;
    Accommodation *accommodation = [Accommodation accommodationWithDictionary:dictionary inManagedObjectContext:context];
    
    if (accommodation && [context save:&error]) {
        IMPhotoFetcher *photoFetcher = [[IMPhotoFetcher alloc] init];
        photoFetcher.onFailure = self.failureHandler;
        photoFetcher.onFinished = self.successHandler;
        [photoFetcher fetchUpdates];
    }else {
        NSLog(@"Error saving accommodation data after update: %@\nError: %@", dictionary, [error description]);
        [context rollback];
    }
//     [context reset];
    
}

@end