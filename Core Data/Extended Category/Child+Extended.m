//
//  Child+Extended.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 4/4/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "Child+Extended.h"

@implementation Child (Extended)

+ (Child *)childWithId:(NSString *)registrationId inContext:(NSManagedObjectContext *)context
{
    @try {
        if (!registrationId) {
            return nil;
        }
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Child"];
        request.predicate = [NSPredicate predicateWithFormat:@"registrationNumber = %@", registrationId];
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception) {
        NSLog(@"Throw exception for interceptionWithId : %@",[exception description]);
        return nil;
    }
}
- (NSDictionary *)format
{
    @try {
        NSMutableDictionary *formatted = [NSMutableDictionary dictionary];
        
        if (self.registrationNumber) {
            [formatted setObject:self.registrationNumber forKey:@"registrationNumber"];
        }
        
        return formatted;
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception while creating formatted Migrant data: %@", [exception description]);
    }
    
    
    return nil;
}
@end
