//
//  IMReferencesUpdater.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/14/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMReferencesFetcher.h"
#import "IMDBManager.h"
#import "Country+Extended.h"
#import "Port+Extended.h"
#import "IomOffice+Extended.h"

#import "IMHTTPClient.h"
#import "NSDate+Relativity.h"
#import "IMConstants.h"


@implementation IMReferencesFetcher

- (void)fetchUpdates
{
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client getJSONWithPath:@"references"
                 parameters:nil
                    success:^(NSDictionary *jsonData, int statusCode){ [self parseReferences:jsonData]; }
                    failure:self.onFailure];
}

#pragma mark References Parser
- (void)parseReferences:(NSDictionary *)references
{
    dispatch_queue_t queue = dispatch_queue_create("ReferencesParser", NULL);
    dispatch_async(queue, ^{
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        context.parentContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        
        @try {
            self.total = [references[@"total"] intValue];
            
            for (NSString *key in [references allKeys]){
                NSArray *data = [references objectForKey:key];
                
                if ([key isEqualToString:@"iomOffices"]){
                    [self parseIomOffices:data inManagedObjectContext:context];
                }else if ([key isEqualToString:@"countries"]){
                    [self parseCountries:data inManagedObjectContext:context];
                }else if ([key isEqualToString:@"ports"]){
                    [self parsePorts:data inManagedObjectContext:context];
                }
            }
            
            NSError *error;
            if ([context save:&error]) {
                [self postFinished];
            }else {
                [context rollback];
                NSLog(@"Error saving context for references table with message: \n%@", [error description]);
                [self postFailureWithError:error];
            }
            
             [context reset];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception while parsing references: %@", [exception description]);
            [context rollback];
            [self postFailureWithError:[NSError errorWithDomain:@"Updater Exception" code:0 userInfo:@{IMSyncKeyError: [exception description]}]];
        }
    });
}

- (void)parseCountries:(NSArray *)countries inManagedObjectContext:(NSManagedObjectContext *)context
{
    for (NSDictionary *dict in countries) {
        [context performBlockAndWait:^{
            Country *ref = [Country countryWithDictionary:dict inManagedObjectContext:context];
            if (!ref) NSLog(@"Failed parsing country: %@", dict);
            self.progress++;
        }];
    }
}

- (void)parsePorts:(NSArray *)ports inManagedObjectContext:(NSManagedObjectContext *)context
{
    for (NSDictionary *dict in ports) {
        [context performBlockAndWait:^{
            Port *ref = [Port portWithDictionary:dict inManagedObjectContext:context];
            if (!ref) NSLog(@"Failed parsing port: %@", dict);
            self.progress++;
        }];
    }
}

- (void)parseIomOffices:(NSArray *)offices inManagedObjectContext:(NSManagedObjectContext *)context
{
    for (NSDictionary *dict in offices) {
        [context performBlockAndWait:^{
            IomOffice *ref = [IomOffice officeWithDictionary:dict inManagedObjectContext:context];
            if (!ref) NSLog(@"Failed parsing iom office: %@", dict);
            self.progress++;
        }];
    }
}

@end