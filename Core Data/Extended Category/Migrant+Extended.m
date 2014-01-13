//
//  Migrant+Extended.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Migrant+Extended.h"
#import "IMConstants.h"
#import "NSDate+Relativity.h"


@implementation Migrant (Extended)


+ (Migrant *)migrantWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    @try {
        NSString *migrantId = dictionary[@"id"];
        Migrant *migrant = [Migrant migrantWithId:migrantId inContext:context];
        if (!migrant) {
            migrant = [Migrant newMigrantInContext:context];
            migrant.registrationNumber = migrantId;
            migrant.biometric.biometricId = migrantId;
        }
        
        if (dictionary[@"biometric"]) {
            migrant.biometric = [Biometric biometricFromDictionary:dictionary[@"biometric"] inContext:context];
        }
        
        //Bio data
        NSDictionary *bioData = dictionary[@"bioData"];
        migrant.bioData.firstName = CORE_DATA_OBJECT(bioData[@"firstName"]);
        migrant.bioData.familyName = CORE_DATA_OBJECT(bioData[@"familyName"]);
        migrant.bioData.alias = CORE_DATA_OBJECT(bioData[@"alias"]);
        
        NSString *gender = CORE_DATA_OBJECT(bioData[@"gender"]);
        gender = [gender isEqualToString:@"M"] ? @"Male" : @"Female";
        migrant.bioData.gender = gender;
        
        migrant.bioData.maritalStatus = CORE_DATA_OBJECT(bioData[@"status"]);
        migrant.bioData.cityOfBirth = CORE_DATA_OBJECT(bioData[@"placeOfBirth"]);
        migrant.bioData.countryOfBirth = [Country countryWithCode:bioData[@"countryOfBirth"] inManagedObjectContext:context];
        
        NSString *dateOfBirth = CORE_DATA_OBJECT(bioData[@"dateOfBirth"]);
        migrant.bioData.dateOfBirth = [NSDate dateFromUTCString:dateOfBirth];
        
        //general information
        migrant.unhcrDocument = CORE_DATA_OBJECT(dictionary[@"unhcrDocument"]);
        migrant.unhcrNumber = CORE_DATA_OBJECT(dictionary[@"unhcrNumber"]);
        migrant.vulnerabilityStatus = CORE_DATA_OBJECT(dictionary[@"vulnerability"]);
        migrant.deceased = CORE_DATA_OBJECT(dictionary[@"deceased"]);
        migrant.active = dictionary[@"active"];
        migrant.underIOMCare = dictionary[@"underIomCare"];
        
        migrant.iomData = [IomData iomDataFromDictionary:dictionary[@"iomData"] inManagedObjectContext:context];
        
        return migrant;
    }
    @catch (NSException *exception) {
        return nil;
    }
}

+ (Migrant *)migrantWithId:(NSString *)migrantId inContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Migrant"];
        request.predicate = [NSPredicate predicateWithFormat:@"registrationNumber = %@", migrantId];
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception) {
        return nil;
    }
}

+ (Migrant *)newMigrantInContext:(NSManagedObjectContext *)context
{
    Migrant *migrant = [NSEntityDescription insertNewObjectForEntityForName:@"Migrant" inManagedObjectContext:context];
//    Biometric *biometric = [NSEntityDescription insertNewObjectForEntityForName:BIO_ENTITY_NAME inManagedObjectContext:context];
    BioData *data = [NSEntityDescription insertNewObjectForEntityForName:@"BioData" inManagedObjectContext:context];
    FamilyData *family = [NSEntityDescription insertNewObjectForEntityForName:@"FamilyData" inManagedObjectContext:context];
//    IomData *iomData = [NSEntityDescription insertNewObjectForEntityForName:@"IomData" inManagedObjectContext:context];
    
    migrant.bioData = data;
    migrant.familyData = family;
//    migrant.biometric = biometric;
//    migrant.iomData = iomData;
    
    return migrant;
}

@end