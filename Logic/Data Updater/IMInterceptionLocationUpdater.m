//
//  IMInterceptionLocationUpdater.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/12/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMInterceptionLocationUpdater.h"
#import "IMHTTPClient.h"
#import "InterceptionLocation+Extended.h"
#import "IMDBManager.h"


@implementation IMInterceptionLocationUpdater

- (void)submitInterceptionLocation:(NSDictionary *)params
{
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client postJSONWithPath:@"interceptionLocation/save"
                  parameters:params success:^(NSDictionary *jsonData, int statusCode){
                      NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                      context.parentContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
                      InterceptionLocation *location = [InterceptionLocation locationWithDictionary:jsonData inManagedObjectContext:context];
                      
                      NSError *error;
                      if (!location) {
                          error = [NSError errorWithDomain:@"Null Interception Location" code:0 userInfo:nil];
                          if (self.failureHandler) self.failureHandler(error);
                      }else if ([context save:&error] && self.successHandler) {
                          self.successHandler();
                      }else if (self.failureHandler) {
                          self.failureHandler (error);
                      }
//                       [context reset];
                  }
                     failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                         if (statusCode == 409 && self.conflictHandler) self.conflictHandler(jsonData);
                         else if (self.failureHandler) self.failureHandler(error);
                     }];
}

@end