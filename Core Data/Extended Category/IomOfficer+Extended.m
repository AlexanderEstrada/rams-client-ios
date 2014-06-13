//
//  IomOfficer+Extended.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/20/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IomOfficer+Extended.h"
#import "IMConstants.h"

@implementation IomOfficer (Extended)

NSString *const IOM_OFFICER_ENTITY_NAME  = @"IomOfficer";
NSString *const IOM_OFFICER_EMAIL        = @"email";
NSString *const IOM_OFFICER_NAME         = @"name";
NSString *const IOM_OFFICER_PHONE        = @"phone";


+ (NSArray *)officersInManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:IOM_OFFICER_ENTITY_NAME];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    NSError *error;
    return [context executeFetchRequest:request error:&error];

}

+ (IomOfficer *)officerWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        if (dictionary) {        
        NSString *email = CORE_DATA_OBJECT(dictionary[IOM_OFFICER_EMAIL]);
        IomOfficer *iomOfficer = [IomOfficer officerWithEmail:email inManagedObjectContext:context];
        if (!iomOfficer) {
            iomOfficer = [NSEntityDescription insertNewObjectForEntityForName:IOM_OFFICER_ENTITY_NAME inManagedObjectContext:context];
        }
        
        iomOfficer.email = email;
        iomOfficer.name = CORE_DATA_OBJECT(dictionary[IOM_OFFICER_NAME]);
        iomOfficer.phone = CORE_DATA_OBJECT(dictionary[IOM_OFFICER_PHONE]);
        
        return iomOfficer;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while parsing IOM officer with dictionary: %@\nError message: %@", dictionary, [exception description]);
        return nil;
    }
    
    return Nil;
}

+ (IomOfficer *)officerWithEmail:(NSString *)email inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:IOM_OFFICER_ENTITY_NAME];
        request.predicate = [NSPredicate predicateWithFormat:@"email = %@", email];
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception fetching IOM Officer with email: %@, error:\n%@", email, [exception description]);
        return nil;
    }
}

- (NSDictionary *)prepareForSubmission
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.email) [dict setObject:self.email forKey:IOM_OFFICER_EMAIL];
    
    [dict setObject:self.name forKey:IOM_OFFICER_NAME];
    [dict setObject:self.phone forKey:IOM_OFFICER_PHONE];
    
    return dict;
}

- (NSString *)description
{
    return self.phone ? [NSString stringWithFormat:@"%@ (%@)", self.name, self.phone] : self.name;
}

@end
