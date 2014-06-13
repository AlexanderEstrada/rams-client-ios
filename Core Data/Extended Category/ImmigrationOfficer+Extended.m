//
//  ImmigrationOfficer+Extended.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/20/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "ImmigrationOfficer+Extended.h"
#import "IMConstants.h"

@implementation ImmigrationOfficer (Extended)

NSString *const IMMI_ENTITY_NAME    = @"ImmigrationOfficer";
NSString *const IMMI_ID             = @"id";
NSString *const IMMI_NAME           = @"name";
NSString *const IMMI_PHONE          = @"phone";


+ (ImmigrationOfficer *)officerWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        if (dictionary) {
            
            
            NSNumber *officerId = CORE_DATA_OBJECT(dictionary[IMMI_ID]);
            ImmigrationOfficer *officer = [ImmigrationOfficer officerWithId:officerId inManagedObjectContext:context];
            
            if (!officer) {
                officer = [NSEntityDescription insertNewObjectForEntityForName:IMMI_ENTITY_NAME inManagedObjectContext:context];
                officer.officerId = officerId;
            }
            
            NSString *name = CORE_DATA_OBJECT(dictionary[IMMI_NAME]);
            NSString *phone = CORE_DATA_OBJECT(dictionary[IMMI_PHONE]);
            
            officer.name = name;
            officer.phone = phone;
            return officer;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while parsing Immigration officer with dictionary: %@\nError message: %@", [dictionary description], [exception description]);
        return nil;
    }
    return Nil;
}

+ (ImmigrationOfficer *)officerWithId:(NSNumber *)officerId inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:IMMI_ENTITY_NAME];
        request.predicate = [NSPredicate predicateWithFormat:@"officerId = %@", officerId];
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception fetching Immigration Officer with ID: %@, error:\n%@", officerId, [exception description]);
        return nil;
    }
}

- (NSDictionary *)prepareForSubmission
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.officerId) [dict setObject:self.officerId forKey:IMMI_ID];
    if (self.name)      [dict setObject:self.name forKey:IMMI_NAME];
    if (self.phone)     [dict setObject:self.phone forKey:IMMI_PHONE];
    
    return dict;
}

- (NSString *)description
{
    return self.phone ? [NSString stringWithFormat:@"%@ (%@)", self.name, self.phone] : self.name;
}

@end