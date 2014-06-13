//
//  Country+Extended.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/1/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Country+Extended.h"
#import "IMConstants.h"


@implementation Country (Extended)

NSString *const COUNTRY_ENTITY_NAME = @"Country";
NSString *const COUNTRY_CODE        = @"code";
NSString *const COUNTRY_NAME        = @"countryName";


+ (Country *)countryWithDictionary:(NSDictionary *)dictionary
            inManagedObjectContext:(NSManagedObjectContext *)context
{
    Country *country;
    
    @try {
        NSString *code = CORE_DATA_OBJECT([dictionary objectForKey:COUNTRY_CODE]);
        
        country = [Country countryWithCode:code inManagedObjectContext:context];
        if (!country) {
            country = [NSEntityDescription insertNewObjectForEntityForName:COUNTRY_ENTITY_NAME inManagedObjectContext:context];
            country.code = code;
        }
        
        country.name = CORE_DATA_OBJECT([dictionary objectForKey:COUNTRY_NAME]);
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while creating new Country: \n%@", [exception description]);
        return nil;
    }
    
    return country;
}

+ (Country *)countryWithCode:(NSString *)code
      inManagedObjectContext:(NSManagedObjectContext *)context
{
    Country *country = nil;
    
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:COUNTRY_ENTITY_NAME];
        request.predicate = [NSPredicate predicateWithFormat:@"code = %@", code];
        
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:request error:&error];
        if (results && [results count] > 0) {
            country = [results lastObject];
        }

    }
    @catch (NSException *exception)
    {
    NSLog(@"Exception while creating countryWithCode: \n%@", [exception description]);
    }
    
    return country;
}

+ (Country *)countryWithName:(NSString *)name
      inManagedObjectContext:(NSManagedObjectContext *)context
{
    Country *country = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:COUNTRY_ENTITY_NAME];
    request.predicate = [NSPredicate predicateWithFormat:@"name = %@", name];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    
    if (results && [results count] > 0) country = [results lastObject];
    
    return country;
    
}

- (NSString *)description{
    return self.name;
}


@end
