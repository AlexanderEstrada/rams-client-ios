//
//  PoliceOfficer+Extended.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/26/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "PoliceOfficer+Extended.h"
#import "IMConstants.h"

@implementation PoliceOfficer (Extended)

NSString *const PO_ENTITY_NAME  = @"PoliceOfficer";
NSString *const PO_ID           = @"id";
NSString *const PO_NAME         = @"name";
NSString *const PO_PHONE        = @"phone";

+ (PoliceOfficer *)officerWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        if (dictionary) {
            
            
            NSNumber *officerId = CORE_DATA_OBJECT(dictionary[PO_ID]);
            PoliceOfficer *officer = [PoliceOfficer officerWithId:officerId inManagedObjectContext:context];
            
            if (!officer) {
                officer = [NSEntityDescription insertNewObjectForEntityForName:PO_ENTITY_NAME inManagedObjectContext:context];
                officer.officerId = officerId;
            }
            
            NSString *name = CORE_DATA_OBJECT(dictionary[PO_NAME]);
            NSString *phone = CORE_DATA_OBJECT(dictionary[PO_PHONE]);
            
            officer.name = name;
            officer.phone = phone;
            
            return officer;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while parsing Police officer with dictionary: %@\nError message: %@", [dictionary description], [exception description]);
        return nil;
    }
    
    return nil;
}

+ (PoliceOfficer *)officerWithId:(NSNumber *)officerId inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PO_ENTITY_NAME];
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
    if (self.officerId) [dict setObject:self.officerId forKey:PO_ID];
    if (self.name)      [dict setObject:self.name forKey:PO_NAME];
    if (self.phone)     [dict setObject:self.phone forKey:PO_PHONE];
    
    return dict;
}

- (NSString *)description
{
    return self.phone ? [NSString stringWithFormat:@"%@ (%@)", self.name, self.phone] : self.name;
}

@end