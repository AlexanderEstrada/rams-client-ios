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
#import "Child+Extended.h"
#import "Interception.h"


@implementation Migrant (Extended)


+ (Migrant *)migrantWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    @try {
        NSString *migrantId = [dictionary objectForKey:@"id"];
        Migrant *migrant = [Migrant migrantWithId:migrantId inContext:context];
        if (!migrant) {
            migrant = [Migrant newMigrantInContext:context];
            migrant.registrationNumber = migrantId;
        }
        
        
        //detention location
        migrant.detentionLocation = CORE_DATA_OBJECT([dictionary objectForKey:@"detentionLocation"]);
        
        //save date created
        migrant.dateCreated =[NSDate dateFromUTCString:[dictionary objectForKey:@"dateCreated"]];
        if (dictionary[@"biometric"]) {
            NSMutableDictionary *biometric = [dictionary objectForKey:@"biometric"];
            
            //update data
            NSString *biometricId = CORE_DATA_OBJECT([biometric objectForKey:BIO_ID]);
            migrant.biometric = [Biometric biometricWithId:biometricId inContext:context];
            if (!migrant.biometric) {
                migrant.biometric = [NSEntityDescription insertNewObjectForEntityForName:BIO_ENTITY_NAME inManagedObjectContext:context];
                if (biometricId != Nil) {
                    migrant.biometric.biometricId = biometricId;
                }else{
                    migrant.biometric.biometricId = migrantId;
                }
                
            }
            
            //photo
            [migrant.biometric updatePhotographFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:BIO_PHOTOGRAPH])];
            
            //template
            [migrant.biometric updateTemplateFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:BIO_RIGHT_THUMB_TEMPLATE]) forFingerPosition:RightThumb];
            [migrant.biometric updateTemplateFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:BIO_RIGHT_INDEX_TEMPLATE]) forFingerPosition:RightIndex];
            [migrant.biometric updateTemplateFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:BIO_LEFT_THUMB_TEMPLATE]) forFingerPosition:LeftThumb];
            [migrant.biometric updateTemplateFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:BIO_LEFT_INDEX_TEMPLATE]) forFingerPosition:LeftIndex];
            
            //finger image
            [migrant.biometric updateFingerImageFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:BIO_RIGHT_THUMB_IMAGE]) forFingerPosition:RightThumb];
            [migrant.biometric updateFingerImageFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:BIO_RIGHT_INDEX_IMAGE]) forFingerPosition:RightIndex];
            [migrant.biometric updateFingerImageFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:BIO_LEFT_THUMB_IMAGE]) forFingerPosition:LeftThumb];
            [migrant.biometric updateFingerImageFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:BIO_LEFT_INDEX_IMAGE]) forFingerPosition:LeftIndex];
        }else {
            migrant.biometric = Nil;
        }
        
        //Bio data
        
        if (dictionary[@"bioData"]) {
            NSDictionary *bioData = [dictionary objectForKey:@"bioData"];
            migrant.bioData.firstName = CORE_DATA_OBJECT([bioData objectForKey:@"firstName"]);
            migrant.bioData.familyName = CORE_DATA_OBJECT([bioData objectForKey:@"familyName"]);
            migrant.bioData.alias = CORE_DATA_OBJECT([bioData objectForKey:@"alias"]);
            
            NSString *gender = CORE_DATA_OBJECT([bioData objectForKey:@"gender"]);
            
            if ([gender length] == 1 || [gender length] == 2) {
                gender = [gender isEqualToString:@"M"] ? @"Male" : @"Female";
            }
            
            
            migrant.bioData.gender = gender;
            
            migrant.bioData.maritalStatus = CORE_DATA_OBJECT([bioData objectForKey:@"status"]);
            migrant.bioData.cityOfBirth = CORE_DATA_OBJECT([bioData objectForKey:@"placeOfBirth"]);
            migrant.bioData.countryOfBirth = [Country countryWithCode:[bioData objectForKey:@"countryOfBirth"] inManagedObjectContext:context];
            migrant.bioData.nationality = [Country countryWithCode:[bioData objectForKey:@"nationality"] inManagedObjectContext:context];
            NSString *dateOfBirth = CORE_DATA_OBJECT([bioData objectForKey:@"dateOfBirth"]);
            migrant.bioData.dateOfBirth = [NSDate dateFromUTCString:dateOfBirth];
            
        }else{
            migrant.bioData = Nil;
        }
        
        //general information
        migrant.unhcrDocument = CORE_DATA_OBJECT([dictionary objectForKey:@"unhcrDocument"]);
        migrant.unhcrNumber = CORE_DATA_OBJECT([dictionary objectForKey:@"unhcrNumber"]);
        migrant.vulnerabilityStatus = CORE_DATA_OBJECT([dictionary objectForKey:@"vulnerability"]);
        migrant.deceased = CORE_DATA_OBJECT([dictionary objectForKey:@"deceased"]);
        migrant.active = CORE_DATA_OBJECT([dictionary objectForKey:@"active"]);
        migrant.underIOMCare = CORE_DATA_OBJECT([dictionary  objectForKey:@"underIomCare"]);
        
        
        
        
        //Under IOM care
        if (migrant.underIOMCare.boolValue && dictionary [@"movements"]) {
            //add movement
            NSArray *movements = CORE_DATA_OBJECT(dictionary [@"movements"]);
            for (NSDictionary *movement in movements) {
                Movement *data = [Movement movementWithDictionary:movement inContext:context];
                if (data) {
                    [migrant addMovementsObject:data];
                }
            }
        }
        
        //familyData
        
        if (dictionary [@"familyData"]) {
            NSDictionary *family = CORE_DATA_OBJECT([dictionary objectForKey:@"familyData"]);
            NSArray *childs = Nil;
            migrant.familyData.father = CORE_DATA_OBJECT([family objectForKey:@"father"]);
            migrant.familyData.mother = CORE_DATA_OBJECT([family objectForKey:@"mother"]);
            migrant.familyData.spouse = CORE_DATA_OBJECT([family objectForKey:@"spouse"]);
            
            //get childs
            if (dictionary [@"childs"]) {
                childs = CORE_DATA_OBJECT(dictionary [@"childs"]);
                for (NSDictionary *child in childs) {
                    NSString *registrationNumber = CORE_DATA_OBJECT([child objectForKey:@"registrationNumber"]);
                    Child *data = [Child childWithId:registrationNumber inContext:context];
                    if (!data) {
                        data = [NSEntityDescription insertNewObjectForEntityForName:@"Child" inManagedObjectContext:context];
                        if (registrationNumber) {
                            data.registrationNumber = [child objectForKey:registrationNumber];
                        }
                        
                    }
                    //add child to family
                    [migrant.familyData addChildsObject:data];
                }
            }
            
            //case all data is empty, then Family data to Nil
            if (!migrant.familyData.father && !migrant.familyData.mother && !migrant.familyData.spouse && !childs) {
                migrant.familyData = nil;
            }
        }
        
        //Interception
        if (dictionary [@"interceptions"]) {
            NSArray *interceptions = CORE_DATA_OBJECT(dictionary [@"interceptions"]);
            for (NSDictionary *interception in interceptions) {
                Interception *data = [Interception interceptionWithDictionary:interception inContext:context];
                if (data) {
                    if (!data.interceptionId) {
                        //                    use migrant ID as default
                        data.interceptionId = migrantId;
                    }
                    [migrant addInterceptionsObject:data];
                }
                
            }
            
        }
        
        //IOMData
        if (dictionary[@"iomData"]) {
            NSDictionary *iomData = CORE_DATA_OBJECT([dictionary objectForKey:@"iomData"]);
            NSString *iomId = CORE_DATA_OBJECT([iomData objectForKey:@"id"]);
            migrant.iomData = [IomData iomDataWithId:iomId inManagedObjectContext:context];
            
            if (!migrant.iomData) {
                migrant.iomData = [NSEntityDescription insertNewObjectForEntityForName:@"IomData" inManagedObjectContext:context];
                if (iomId) {
                    migrant.iomData.iomDataId = iomId;
                }else
                {
                    //use migrant ID as default
                    migrant.iomData.iomDataId = migrantId;
                }
                
                migrant.iomData.associatedOffice = [IomOffice officeWithName:CORE_DATA_OBJECT([iomData objectForKey:@"associatedOffice"]) inManagedObjectContext:context];
                
                NSArray *allowanceArray = [Allowance allowancesFromArrayDictionary:CORE_DATA_OBJECT([iomData objectForKey:@"allowances"]) inManagedObjectContext:context];
                for (Allowance *allowance in allowanceArray) {
                    if (![IomData isAllowanceExists:allowance inList:migrant.iomData.allowances]) [migrant.iomData addAllowancesObject:allowance];
                }
                
            }
            
        }else migrant.iomData = Nil;
        
        //save selfReporting
        if (dictionary[@"selfReporting"]) {
            migrant.selfReporting = [[dictionary objectForKey:@"selfReporting"] isEqualToString:@"true"] ? @(1):@(0);
            
        }else migrant.selfReporting = FALSE;
        
        
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
    BioData *data = [NSEntityDescription insertNewObjectForEntityForName:@"BioData" inManagedObjectContext:context];
    FamilyData *family = [NSEntityDescription insertNewObjectForEntityForName:@"FamilyData" inManagedObjectContext:context];
    //    IomData * iomData = [NSEntityDescription insertNewObjectForEntityForName:@"IomData" inManagedObjectContext:context];
    
    migrant.bioData = data;
    migrant.familyData = family;
    //    migrant.iomData = iomData;
    
    
    return migrant;
}

+ (Migrant *)newMigrantInContext:(NSManagedObjectContext *)context withId:(NSString*)Id
{
    Migrant *migrant = [NSEntityDescription insertNewObjectForEntityForName:@"Migrant" inManagedObjectContext:context];
    BioData *data = [NSEntityDescription insertNewObjectForEntityForName:@"BioData" inManagedObjectContext:context];
    //    FamilyData *family = [NSEntityDescription insertNewObjectForEntityForName:@"FamilyData" inManagedObjectContext:context];
    //    IomData * iomData = [NSEntityDescription insertNewObjectForEntityForName:@"IomData" inManagedObjectContext:context];
    
    migrant.registrationNumber = Id;
    //set IOM data ID as Migrant ID as default
    //    iomData.iomDataId = Id;
    
    migrant.bioData = data;
    //    migrant.familyData = family;
    //    migrant.iomData = iomData;
    
    
    return migrant;
}

- (NSString *)fullname
{
    if ([self.bioData.firstName length] && [self.bioData.familyName length]) {
        return [NSString stringWithFormat:@"%@ %@", self.bioData.firstName, self.bioData.familyName];
    }else if ([self.bioData.firstName length]) {
        return self.bioData.firstName;
    }else if ([self.bioData.familyName length]) {
        return self.bioData.familyName;
    }
    
    return nil;
}

- (NSString *)bioDataSummary
{
    if ([self.bioData.gender length] && self.bioData.nationality && self.bioData.dateOfBirth) {
        return [NSString stringWithFormat:@"%@, %@, %@", self.bioData.nationality.name, self.bioData.gender, [self.bioData.dateOfBirth ageString]];
    }else if ([self.bioData.gender length] && self.bioData.nationality) {
        return [NSString stringWithFormat:@"%@, %@", self.bioData.nationality.name, self.bioData.gender];
    }else if ([self.bioData.gender length] && self.bioData.dateOfBirth) {
        return [NSString stringWithFormat:@"%@, %@", self.bioData.gender, [self.bioData.dateOfBirth ageString]];
    }else if (self.bioData.nationality && self.bioData.dateOfBirth) {
        return [NSString stringWithFormat:@"%@, %@", self.bioData.nationality.name, [self.bioData.dateOfBirth ageString]];
    }else if (self.bioData.nationality) {
        return self.bioData.nationality.name;
    }else if (self.bioData.gender) {
        return self.bioData.gender;
    }else if (self.bioData.dateOfBirth) {
        return [self.bioData.dateOfBirth ageString];
    }
    
    return nil;
}

- (NSString *)interceptionSummary
{
    
    //sort interceptions
    [self.interceptions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"interceptionDate" ascending:YES]]];
    
    NSArray *myArray = [self.interceptions allObjects];
    
    
    
    //get newest interception data " interceptionDate"
    if ([myArray count]) {
        Interception * interception = [myArray firstObject];
        
        if (interception.interceptionDate && [interception.interceptionLocation length]) {
            return [NSString stringWithFormat:@"%@, %@", [interception.interceptionDate mediumFormatted], interception.interceptionLocation];
        }else if (interception.interceptionDate) {
            return [interception.interceptionDate mediumFormatted];
        }else if ([interception.interceptionLocation length]) {
            return interception.interceptionLocation;
        }
    }
    return nil;
}

- (NSString *)unhcrSummary
{
    if ([self.unhcrDocument length] && [self.unhcrNumber length]) {
        return [NSString stringWithFormat:@"%@, %@", self.unhcrDocument, self.unhcrNumber];
    }
    
    return @"No UNHCR Document";
}

@end