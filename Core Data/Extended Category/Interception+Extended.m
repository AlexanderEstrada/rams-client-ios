//
//  Interception+Extended.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Interception+Extended.h"
#import "IMConstants.h"
#import "NSDate+Relativity.h"
 

@implementation Interception (Extended)

+ (Interception *)interceptionWithDictionary:(NSDictionary *)dictionary withMigrantId:(NSString*)migrantId inContext:(NSManagedObjectContext *)context
{
    @try {
        NSString *Id = CORE_DATA_OBJECT([dictionary objectForKey:@"id"]);
        
        Interception *data = [Interception interceptionWithId:Id inContext:context];
        if (!data) {
            data = [NSEntityDescription insertNewObjectForEntityForName:@"Interception" inManagedObjectContext:context];
            if (Id != Nil) {
                //case if ID is empty string
                data.interceptionId = Id;
            }else {
                data.interceptionId = migrantId;
            }
            
        }
        
        data.interceptionDate = [NSDate dateFromUTCString:[dictionary objectForKey:@"interceptionDate"]];
        data.dateOfEntry = data.interceptionDate;
        data.interceptionLocation = CORE_DATA_OBJECT([dictionary objectForKey:@"interceptionLocation"]);
        
        //save selfReporting
        if (dictionary[@"selfReporting"]) {
            data.selfReporting = [[dictionary objectForKey:@"selfReporting"] isEqualToString:@"true"] ? @(1):@(0);
            
        }else data.selfReporting = FALSE;

        return data;
    }
    @catch (NSException *exception) {
        return Nil;
    }
}

+ (Interception *)interceptionWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    @try {
        NSString *Id = CORE_DATA_OBJECT([dictionary objectForKey:@"id"]);
        
        Interception *data = [Interception interceptionWithId:Id inContext:context];
        if (!data) {
                data = [NSEntityDescription insertNewObjectForEntityForName:@"Interception" inManagedObjectContext:context];
            if (Id != Nil) {
                //case if ID is empty string
                data.interceptionId = Id;
            }
            
        }
        
        data.interceptionDate = [NSDate dateFromUTCString:[dictionary objectForKey:@"interceptionDate"]];
        data.dateOfEntry = data.interceptionDate;
        data.interceptionLocation = CORE_DATA_OBJECT([dictionary objectForKey:@"interceptionLocation"]);
        //save selfReporting
        if (dictionary[@"selfReporting"]) {
            data.selfReporting = [[dictionary objectForKey:@"selfReporting"] isEqualToString:@"true"] ? @(1):@(0);
            
        }else data.selfReporting = FALSE;
        
        
        return data;
    }
    @catch (NSException *exception) {
        return Nil;
    }
    
    
}
+ (Interception *)interceptionWithId:(NSString *)interceptionId inContext:(NSManagedObjectContext *)context
{
    @try {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Interception"];
            request.predicate = [NSPredicate predicateWithFormat:@"interceptionId = %@", interceptionId];
            NSError *error;
            NSArray *results = [context executeFetchRequest:request error:&error];
            return [results lastObject];
        }
        @catch (NSException *exception) {
            NSLog(@"Throw exception for interceptionWithId : %@",[exception description]);
            return nil;
        }
}
+ (Interception *)newInterceptionInContext:(NSManagedObjectContext *)context
{
    @try {
        Interception *interception = [NSEntityDescription insertNewObjectForEntityForName:@"Interception" inManagedObjectContext:context];
        
        
        return interception;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while create newInterceptionInContext : %@",[exception description]);
        return Nil;
    }
    
    
}


@end
