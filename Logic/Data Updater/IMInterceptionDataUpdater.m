//
//  IMInterceptionDataUpdater.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/27/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMInterceptionDataUpdater.h"
#import "IMHTTPClient.h"
#import "IMDBManager.h"
#import "InterceptionData+Extended.h"


@implementation IMInterceptionDataUpdater

- (void)submitInterceptionData:(NSDictionary *)params
{
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client postJSONWithPath:@"interception/save"
                  parameters:params
                     success:^(NSDictionary *jsonData, int statusCode){
                         if ([self saveInterceptionData:jsonData] && self.successHandler) {
                             self.successHandler();
                         }else if (self.failureHandler){
                             self.failureHandler([NSError errorWithDomain:@"Failed Saving Database" code:0 userInfo:nil]);
                         }
                     }
                     failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                         if (self.failureHandler) self.failureHandler(error);
                     }];
}

- (BOOL)saveInterceptionData:(NSDictionary *)dictionary
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = [[IMDBManager sharedManager] localDatabase].managedObjectContext;
    
    InterceptionData *data = [InterceptionData dataWithDictionary:dictionary inManagedObjectContext:context];
    if (data) {
        NSError *error;
        BOOL result = [context save:&error];
        if (!result) {
            NSLog(@"Result : %hhd for saveInterceptionData - with error : %@ and dictionary : \n %@ ",result,[error description],dictionary);
            
        }
        return result;
    }
    
    return NO;
}

- (void)submitMovement:(NSDictionary *)params
{
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client postJSONWithPath:@"interception/updateMovement"
                  parameters:params success:^(NSDictionary *jsonData, int statusCode){
                      if ([self saveMovement:jsonData] && self.successHandler) {
                          self.successHandler();
                      }else if (self.failureHandler) {
                          self.failureHandler([NSError errorWithDomain:@"Failed Saving Database" code:0 userInfo:nil]);
                      }
                  }
                     failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                         if (self.failureHandler) self.failureHandler(error);
                     }];
}

- (BOOL)saveMovement:(NSDictionary *)dictionary
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = [[IMDBManager sharedManager] localDatabase].managedObjectContext;
    
    InterceptionGroup *group = [InterceptionGroup groupWithDictionary:dictionary inManagedObjectContext:context];
    if (group) {
        NSError *error;
        BOOL stat = [context save:&error];
        if (!stat) NSLog(@"Error saving context after creating new movement: %@\nError: %@", dictionary, [error description]);
        return stat;
    }
    
    return NO;
}

- (void)toggleActive:(NSDictionary *)params
{
    if (self.onProgress) {
        self.onProgress();
    }
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client postJSONWithPath:@"interception/toggleActive"
                  parameters:params success:^(NSDictionary *jsonData, int statusCode){
                      if ([self saveInterceptionData:jsonData] && self.successHandler) {
                          self.successHandler();
                      }else if (self.failureHandler){
                          self.failureHandler([NSError errorWithDomain:@"Failed Saving Database" code:0 userInfo:nil]);
                      }
                  }
                     failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                         NSLog(@"Error toggling active: %@", [error description]);
                         if (self.failureHandler) self.failureHandler(error);
                     }];
}

@end