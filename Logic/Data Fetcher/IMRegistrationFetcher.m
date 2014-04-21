//
//  IMRegistrationFetcher.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 3/29/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMRegistrationFetcher.h"
#import "Registration+Export.h"
#import "Migrant.h"
#import "IMDBManager.h"

@interface IMRegistrationFetcher()
{
    dispatch_queue_t registrationFetcher;
    NSManagedObjectContext *context;
}
@end

@implementation IMRegistrationFetcher

- (void)fetchUpdates
{
    
    if (!registrationFetcher) {
        registrationFetcher = dispatch_queue_create("RegistrationFetcher", NULL);
    }
    
    
    @try {
        dispatch_async(registrationFetcher, ^{
            context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            context.parentContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
            //get all Migrant Data from database
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Migrant"];
            
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO]];
            request.returnsObjectsAsFaults = YES;
            
            NSError *error;
            BOOL result;
            NSArray *migrants = [context executeFetchRequest:request error:&error];
            //set total
            self.total = [migrants count];
            
            for (Migrant *migrant in migrants) {
                // copy all migrant into registration table
                Registration * reg = [Registration registrationFromMigrant:migrant inManagedObjectContext:context];
                result = [context save:&error];
                if (!reg || !result) {
                    [context rollback];
                    NSLog(@"Fail to copy Migrant to Registration : %@",[error description]);
                }
                
                self.progress++;
                if (self.progress == self.total) {
                    [self postFinished];
                }
                
                NSLog(@"Process %ld from %ld",(long)self.progress,(long)self.total);
            }
            
        });
    }
    @catch (NSException *exception) {
        NSLog(@"Error while parsing migrant to registration: Error message: %@", [exception description]);
        [context rollback];
        [self postFailureWithError:[NSError errorWithDomain:@"Exception Occurred" code:0 userInfo:@{@"errorMessage":[exception description]}]];
    }
    
}
@end
