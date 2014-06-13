//
//  Allowance+Extended.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 12/11/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import "Allowance+Extended.h"
#import "NSDate+Relativity.h"
#import "IMConstants.h"


@implementation Allowance (Extended)

#define kAllowanceEntityName    @"Allowance"
#define kAllowanceId            @"id"
#define kAllowanceDate          @"date"
#define kAllowanceAmount        @"amount"
#define kAllowanceFamily        @"family"

+ (Allowance *)allowanceFromDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context{
    if (![Allowance validateAllowanceDictionary:dictionary]) return nil;
    
    @try {
        NSNumber *allowanceId = CORE_DATA_OBJECT([dictionary objectForKey:kAllowanceId]);
        Allowance *allowance = [Allowance allowanceWithId:allowanceId inManagedObjectContext:context];
        
        if (!allowance) {
            allowance = [NSEntityDescription insertNewObjectForEntityForName:kAllowanceEntityName inManagedObjectContext:context];
            allowance.allowanceId = allowanceId;
        }
        
        allowance.amount = [NSDecimalNumber decimalNumberWithString:CORE_DATA_OBJECT([dictionary objectForKey:kAllowanceAmount])];
        allowance.family = CORE_DATA_OBJECT([dictionary objectForKey:kAllowanceFamily]);
        allowance.date = [NSDate dateFromUTCString:[dictionary objectForKey:kAllowanceDate]];
        
        return allowance;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while creating Allowance: \n%@", [exception description]);
        return nil;
    }
}

+ (Allowance *)allowanceWithId:(NSNumber *)allowanceId inManagedObjectContext:(NSManagedObjectContext *)context{
    Allowance *allowance = nil;
    
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kAllowanceEntityName];
        request.fetchLimit = 1;
        request.predicate = [NSPredicate predicateWithFormat:@"allowanceId = %@", allowanceId];
        
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:request error:&error];
        
        allowance = [results lastObject];
    }
    @catch (NSException *exception)
    {
    NSLog(@"Exception while creating allowanceWithId: \n%@", [exception description]);
    }
    
    return allowance;
}

+ (NSArray *)allowancesFromArrayDictionary:(NSArray *)arrayDictionary inManagedObjectContext:(NSManagedObjectContext *)context{
    NSMutableArray *result = [NSMutableArray array];
    
    @try {
        for (NSDictionary *entry in arrayDictionary) {
            Allowance *allowance = [Allowance allowanceFromDictionary:entry inManagedObjectContext:context];
            if (allowance) [result addObject:allowance];
        }
    }
    @catch (NSException *exception)
    {
     NSLog(@"Exception while creating allowancesFromArrayDictionary: \n%@", [exception description]);
    }
    
    return result;
}

+ (BOOL)validateAllowanceDictionary:(NSDictionary *)dictionary{
    return dictionary && [dictionary objectForKey:kAllowanceId] && [dictionary objectForKey:kAllowanceDate];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@, %@", [self.date mediumFormatted], [self.amount stringValue], [self.family boolValue] ? @"Family" : @"Non Family"];
}

@end
