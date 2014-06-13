//
//  IomData+Extended.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 12/11/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import "IomData+Extended.h"
#import "IMConstants.h"
#import "NSDate+Relativity.h"


@implementation IomData (Extended)

#define kIomDataEntityName          @"IomData"
#define kIomDataAssociatedOffice    @"associatedOffice"
#define kIomDataId                  @"id"

+ (IomData *)iomDataFromDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context{
    if (![IomData validateIomDataDictionary:dictionary]) return nil;
        
    @try {
        NSString *dataId = CORE_DATA_OBJECT([dictionary objectForKey:kIomDataId]);
        IomData *data = [IomData iomDataWithId:dataId inManagedObjectContext:context];
        
        if (!data) {
            data = [NSEntityDescription insertNewObjectForEntityForName:kIomDataEntityName inManagedObjectContext:context];
            data.iomDataId = dataId;
        }
        
        NSString *officeName = CORE_DATA_OBJECT([dictionary objectForKey:kIomDataAssociatedOffice]);
        data.associatedOffice = [IomOffice officeWithName:officeName inManagedObjectContext:context];
        
        NSArray *allowanceArray = [Allowance allowancesFromArrayDictionary:[dictionary objectForKey:@"allowances"] inManagedObjectContext:context];
        for (Allowance *allowance in allowanceArray) {
            if (![IomData isAllowanceExists:allowance inList:data.allowances]) [data addAllowancesObject:allowance];
        }
        
        return data;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while creating IOM Data: \n%@", [exception description]);
        return nil;
    }
}

+ (BOOL)isAllowanceExists:(Allowance *)allowance inList:(NSSet *)list{
    for (Allowance *al in list) {
        if ([al.allowanceId isEqualToNumber:allowance.allowanceId]) return YES;
    }
    
    return NO;
}

+ (IomData *)iomDataWithId:(NSString *)iomDataId inManagedObjectContext:(NSManagedObjectContext *)context{
    IomData *data = nil;
    
    @try {
        if (!iomDataId) {
            return data;
        }
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kIomDataEntityName];
        [request setFetchLimit:1];
        request.predicate = [NSPredicate predicateWithFormat:@"iomDataId = %@", iomDataId];
        
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:request error:&error];
        data = [results lastObject];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception while creating iomDataWithId: \n%@", [exception description]);

    }
    
    return data;
}

+ (BOOL)validateIomDataDictionary:(NSDictionary *)dictionary{
    return dictionary && [dictionary objectForKey:kIomDataId] != nil;
}

- (Allowance *)latestAllowance{
    if (!self.allowances || [self.allowances count] == 0) return nil;
    
    NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    NSArray *sortedAllowances = [self.allowances sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDate]];
    
    return [sortedAllowances lastObject];
}

- (Allowance *)thisMonthAllowance{
    if (!self.allowances || [self.allowances count] == 0) return nil;
    
    NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    NSArray *sortedAllowances = [self.allowances sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDate]];
    Allowance *lastAllowance = [sortedAllowances lastObject];
    
    return [lastAllowance.date isDateBelongsToThisMonth] ? lastAllowance : nil;
}

@end
