//
//  IomOffice+Extended.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 12/7/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import "IomOffice+Extended.h"
#import "IMConstants.h"


@implementation IomOffice (Extended)

#define kIOOfficeName               @"name"
#define kIOOfficeAddress            @"address"
#define kIOOfficeLatitude           @"latitude"
#define kIOOfficeLongitude          @"longitude"
#define kIOEntityName               @"IomOffice"

+ (IomOffice *)officeWithDictionary:(NSDictionary *)dictionary
             inManagedObjectContext:(NSManagedObjectContext *)context
{
    if (![IomOffice validateOfficeDictionary:dictionary]) return nil;
    
    NSString *officeName = CORE_DATA_OBJECT([dictionary objectForKey:kIOOfficeName]);
    
    @try {
        IomOffice *office = [IomOffice officeWithName:officeName inManagedObjectContext:context];
        
        if (!office) {
            office = [NSEntityDescription insertNewObjectForEntityForName:kIOEntityName
                                                   inManagedObjectContext:context];
        }
        
        office.name = officeName;
        office.address = CORE_DATA_OBJECT([dictionary objectForKey:kIOOfficeAddress]);
        office.latitude = CORE_DATA_OBJECT([dictionary objectForKey:kIOOfficeLatitude]);
        office.longitude = CORE_DATA_OBJECT([dictionary objectForKey:kIOOfficeLongitude]);
        return office;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while creating IOM Office: \n%@", [exception description]);
        return nil;
    }    
}

+ (IomOffice *)officeWithName:(NSString *)officeName inManagedObjectContext:(NSManagedObjectContext *)context
{
    if (!officeName) return nil;
    
    IomOffice *office = nil;
    
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kIOEntityName];
        request.predicate = [NSPredicate predicateWithFormat:@"name = %@", officeName];
        
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:request error:&error];
        office = [results lastObject];
    }
    @catch (NSException *exception) {}
    
    return office;
}

+ (BOOL)validateOfficeDictionary:(NSDictionary *)dictionary
{
    return dictionary && [dictionary objectForKey:kIOOfficeName] && [dictionary objectForKey:kIOOfficeName];
}

- (NSString *)description{
    return self.name;
}

+ (NSArray *)officeNamesInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSArray *offices = [IomOffice officesInManagedObjectContext:managedObjectContext];
    NSMutableArray *names = [NSMutableArray array];
    
    if (offices && [offices count] > 0) {
        for (IomOffice *office in offices){
            [names addObject:office.name];
        }
    }
    
    return names;
}

+ (NSArray *)officesInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kIOEntityName];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    NSError *error;
    return [managedObjectContext executeFetchRequest:request error:&error];
}

@end
