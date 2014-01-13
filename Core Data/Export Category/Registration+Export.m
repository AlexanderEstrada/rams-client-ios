//
//  Registration+Export.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Registration+Export.h"


@implementation Registration (Export)

NSString *const REG_ENTITY_NAME                 = @"Registration";

NSString *const REG_CAPTURE_DEVICE              = @"captureDevice";
NSString *const REG_IOM_CARE                    = @"underIomCare";
NSString *const REG_IOM_OFFICE                  = @"associatedOffice";
NSString *const REG_UNHCR_DOCUMENT              = @"unhcrDocument";
NSString *const REG_UNHCR_DOCUMENT_NUMBER       = @"unhcrNumber";
NSString *const REG_VULNERABILITY               = @"vulnerability";

NSString *const REG_BIO_DATA                    = @"bioData";
NSString *const REG_FIRST_NAME                  = @"firstName";
NSString *const REG_FAMILY_NAME                 = @"familyName";
NSString *const REG_GENDER                      = @"gender";
NSString *const REG_MARITAL_STATUS              = @"maritalStatus";
NSString *const REG_NATIONALITY                 = @"nationality";
NSString *const REG_COUNTRY_OF_BIRTH            = @"countryOfBirth";
NSString *const REG_PLACE_OF_BIRTH              = @"placeOfBirth";
NSString *const REG_DATE_OF_BIRTH               = @"dateOfBirth";

NSString *const REG_INTERCEPTION                = @"interception";
NSString *const REG_DATE_OF_ENTRY               = @"dateOfEntry";
NSString *const REG_INTERCEPTION_DATE           = @"interceptionDate";
NSString *const REG_INTERCEPTION_LOCATION       = @"interceptionLocation";

NSString *const REG_TRANSFER                    = @"transfer";
NSString *const REG_TRANSFER_DESTINATION        = @"destination";
NSString *const REG_TRANSFER_DATE               = @"transferDate";

NSString *const REG_BIOMETRIC                   = @"biometric";
NSString *const REG_PHOTOGRAPH                  = @"photograph";
NSString *const REG_LEFT_THUMB                  = @"leftThumb";
NSString *const REG_LEFT_INDEX                  = @"leftIndex";
NSString *const REG_RIGHT_THUMB                 = @"rightThumb";
NSString *const REG_RIGHT_INDEX                 = @"rightIndex";


+ (Registration *)newRegistrationInContext:(NSManagedObjectContext *)context
{
    Registration *registration = [NSEntityDescription insertNewObjectForEntityForName:REG_ENTITY_NAME inManagedObjectContext:context];
    registration.dateCreated = [NSDate date];
    registration.biometric = [NSEntityDescription insertNewObjectForEntityForName:@"RegistrationBiometric" inManagedObjectContext:context];
    registration.interceptionData = [NSEntityDescription insertNewObjectForEntityForName:@"RegistrationInterception" inManagedObjectContext:context];
    registration.bioData = [NSEntityDescription insertNewObjectForEntityForName:@"RegistrationBioData" inManagedObjectContext:context];
    
    return registration;
}


- (NSDictionary *)format
{
    NSMutableDictionary *formatted = [NSMutableDictionary dictionary];
    
    [formatted setObject:self.captureDevice forKey:REG_CAPTURE_DEVICE];
    [formatted setObject:self.underIOMCare forKey:REG_IOM_CARE];
    [formatted setObject:self.associatedOffice.name forKey:REG_IOM_OFFICE];
    if (self.unhcrDocument) [formatted setObject:self.unhcrDocument forKey:REG_UNHCR_DOCUMENT];
    if (self.unhcrNumber) [formatted setObject:self.unhcrNumber forKey:REG_UNHCR_DOCUMENT_NUMBER];
    if (self.vulnerability) [formatted setObject:self.vulnerability forKey:REG_VULNERABILITY];
    
    //Biodata
    NSMutableDictionary *bioData = [NSMutableDictionary dictionary];
    [bioData setObject:self.bioData.firstName forKey:REG_FIRST_NAME];
    if (self.bioData.familyName) [bioData setObject:self.bioData.familyName forKey:REG_FAMILY_NAME];
    [bioData setObject:self.bioData.gender forKey:REG_GENDER];
    [bioData setObject:self.bioData.maritalStatus forKey:REG_MARITAL_STATUS];
    [bioData setObject:self.bioData.nationality.code forKey:REG_NATIONALITY];
    [bioData setObject:self.bioData.countryOfBirth.code forKey:REG_COUNTRY_OF_BIRTH];
    [bioData setObject:self.bioData.placeOfBirth forKey:REG_PLACE_OF_BIRTH];
    [bioData setObject:[self.bioData.dateOfBirth toUTCString] forKey:REG_DATE_OF_BIRTH];
    [formatted setObject:bioData forKey:REG_BIO_DATA];
    
    //Interception
    NSMutableDictionary *interception = [NSMutableDictionary dictionary];
    [interception setObject:[self.interceptionData.dateOfEntry toUTCString] forKey:REG_DATE_OF_ENTRY];
    [interception setObject:[self.interceptionData.interceptionDate toUTCString] forKey:REG_INTERCEPTION_DATE];
    [interception setObject:self.interceptionData.interceptionLocation forKey:REG_INTERCEPTION_LOCATION];
    [formatted setObject:interception forKey:REG_INTERCEPTION];
    
    
    if (!self.underIOMCare.boolValue) {
        NSDictionary *transfer = @{REG_TRANSFER_DATE: [self.transferDate toUTCString],
                                   REG_TRANSFER_DESTINATION: self.transferDestination.accommodationId};
        [formatted setObject:transfer forKey:REG_TRANSFER];
    }
    
    NSMutableDictionary *biometric = [NSMutableDictionary dictionary];
    [biometric setObject:[self.biometric base64Photograph] forKey:REG_PHOTOGRAPH];
    if (self.biometric.rightThumb) [biometric setObject:[self.biometric base64FingerImageWithPosition:RightThumb] forKey:REG_RIGHT_THUMB];
    if (self.biometric.rightIndex) [biometric setObject:[self.biometric base64FingerImageWithPosition:RightIndex] forKey:REG_RIGHT_INDEX];
    if (self.biometric.leftThumb) [biometric setObject:[self.biometric base64FingerImageWithPosition:LeftThumb] forKey:REG_LEFT_THUMB];
    if (self.biometric.leftIndex) [biometric setObject:[self.biometric base64FingerImageWithPosition:LeftIndex] forKey:REG_LEFT_INDEX];
    [formatted setObject:biometric forKey:REG_BIOMETRIC];
    
    return formatted;
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
    if (self.interceptionData.interceptionDate && [self.interceptionData.interceptionLocation length]) {
        return [NSString stringWithFormat:@"%@, %@", [self.interceptionData.interceptionDate mediumFormatted], self.interceptionData.interceptionLocation];
    }else if (self.interceptionData.interceptionDate) {
        return [self.interceptionData.interceptionDate mediumFormatted];
    }else if ([self.interceptionData.interceptionLocation length]) {
        return self.interceptionData.interceptionLocation;
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

- (void)validateCompletion
{
    BOOL stat = [self.bioData.firstName length] && self.bioData.gender && self.bioData.maritalStatus && self.bioData.dateOfBirth && [self.bioData.placeOfBirth length] && self.bioData.countryOfBirth && self.bioData.nationality;
    stat &= self.interceptionData.interceptionDate && [self.interceptionData.interceptionLocation length];
    
    if (self.unhcrDocument) stat &= self.unhcrDocument && [self.unhcrNumber length];
    if (self.underIOMCare.boolValue) stat &= self.transferDate && self.transferDestination;
    
    self.complete = @(stat);
}

@end