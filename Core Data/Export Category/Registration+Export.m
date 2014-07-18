//
//  Registration+Export.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Registration+Export.h"
#import "IMDBManager.h"
#import "IMHTTPClient.h"
#import "Migrant+Extended.h"
#import "IMAuthManager.h"



@implementation Registration (Export)

NSString *const REG_ENTITY_NAME                 = @"Registration";
NSString *const REG_ID                          = @"id";

NSString *const REG_CAPTURE_DEVICE              = @"captureDevice";
NSString *const REG_IOM_CARE                    = @"underIomCare";
NSString *const REG_SELF_REPORT                 = @"selfReporting";
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


NSString *const REG_MOVEMENT                 = @"movements";

+ (Registration *)newRegistrationInContext:(NSManagedObjectContext *)context
{
    Registration *registration = [NSEntityDescription insertNewObjectForEntityForName:REG_ENTITY_NAME inManagedObjectContext:context];
    registration.dateCreated = [NSDate date];
    RegistrationBiometric * biometric = [NSEntityDescription insertNewObjectForEntityForName:@"RegistrationBiometric" inManagedObjectContext:context];
    RegistrationInterception *interceptionData = [NSEntityDescription insertNewObjectForEntityForName:@"RegistrationInterception" inManagedObjectContext:context];
    RegistrationBioData * biodata = [NSEntityDescription insertNewObjectForEntityForName:@"RegistrationBioData" inManagedObjectContext:context];
    registration.biometric = biometric;
    registration.interceptionData =interceptionData;
    registration.bioData = biodata;
    
    return registration;
}


- (NSDictionary *)format
{
    @try {
        NSMutableDictionary *formatted = [NSMutableDictionary dictionary];
        
        //Registration Data
        [formatted setObject:self.captureDevice forKey:REG_CAPTURE_DEVICE];
        [formatted setObject:self.underIOMCare?@"true":@"false" forKey:REG_IOM_CARE];
        
        //    [formatted setObject:self.underIOMCare forKey:REG_IOM_CARE];
        [formatted setObject:self.associatedOffice.name forKey:REG_IOM_OFFICE];
        if (self.unhcrDocument) [formatted setObject:self.unhcrDocument forKey:REG_UNHCR_DOCUMENT];
        if (self.unhcrNumber) [formatted setObject:self.unhcrNumber forKey:REG_UNHCR_DOCUMENT_NUMBER];
        if (self.vulnerability) [formatted setObject:self.vulnerability forKey:REG_VULNERABILITY];
        
        //Biodata
        NSMutableDictionary *bioData = [NSMutableDictionary dictionary];
        [bioData setObject:self.bioData.firstName forKey:REG_FIRST_NAME];
        if (self.bioData.familyName) [bioData setObject:self.bioData.familyName forKey:REG_FAMILY_NAME];
        //    [bioData setObject:self.bioData.gender forKey:REG_GENDER];
        [bioData setObject:[self.bioData.gender isEqual:@"Male"] ? @"M":@"F" forKey:REG_GENDER];
        [bioData setObject:self.bioData.maritalStatus forKey:REG_MARITAL_STATUS];
        [bioData setObject:self.bioData.nationality.code forKey:REG_NATIONALITY];
        [bioData setObject:self.bioData.countryOfBirth.code forKey:REG_COUNTRY_OF_BIRTH];
        [bioData setObject:self.bioData.placeOfBirth forKey:REG_PLACE_OF_BIRTH];
        [bioData setObject:[self.bioData.dateOfBirth toUTCString] forKey:REG_DATE_OF_BIRTH];
        [formatted setObject:bioData forKey:REG_BIO_DATA];
        
        //Interception
        NSMutableDictionary *interception = [NSMutableDictionary dictionary];
        if (self.interceptionData.dateOfEntry == Nil) {
            self.interceptionData.dateOfEntry =self.dateCreated;
        }
        [interception setObject:[self.interceptionData.dateOfEntry toUTCString] forKey:REG_DATE_OF_ENTRY];
        
        [interception setObject:[self.interceptionData.interceptionDate toUTCString] forKey:REG_INTERCEPTION_DATE];
        [interception setObject:self.interceptionData.interceptionLocation forKey:REG_INTERCEPTION_LOCATION];
        [interception setObject:self.selfReporting?@"true":@"false" forKey:REG_SELF_REPORT];
        [formatted setObject:interception forKey:REG_INTERCEPTION];
        
        //Under IOM care
        //        if (self.underIOMCare.boolValue && self.transferDate && self.transferDestination.accommodationId) {
        //            NSDictionary *transfer = @{REG_TRANSFER_DATE: [self.transferDate toUTCString],
        //                                       REG_TRANSFER_DESTINATION: self.transferDestination.accommodationId};
        //            [formatted setObject:transfer forKey:REG_TRANSFER];
        //        }
        
        NSMutableDictionary *biometric = [NSMutableDictionary dictionary];
        [biometric setObject:[self.biometric base64Photograph] forKey:REG_PHOTOGRAPH];
        if (self.biometric.rightThumb) [biometric setObject:[self.biometric base64FingerImageWithPosition:RightThumb] forKey:REG_RIGHT_THUMB];
        if (self.biometric.rightIndex) [biometric setObject:[self.biometric base64FingerImageWithPosition:RightIndex] forKey:REG_RIGHT_INDEX];
        if (self.biometric.leftThumb) [biometric setObject:[self.biometric base64FingerImageWithPosition:LeftThumb] forKey:REG_LEFT_THUMB];
        if (self.biometric.leftIndex) [biometric setObject:[self.biometric base64FingerImageWithPosition:LeftIndex] forKey:REG_LEFT_INDEX];
        [formatted setObject:biometric forKey:REG_BIOMETRIC];
        
        //Movement
        
        //check if There is movement to upload
        Migrant * migrant = [Migrant migrantWithId:self.registrationId inContext:self.managedObjectContext];
        
        if (migrant && [migrant.movements count]) {
            /* using new format*/
            //only proccess if there is movement history to upload
            //            NSMutableDictionary *movements = [NSMutableDictionary dictionary];
            //            int counter =0;
            //            NSString *key = [NSString string];
            //            for (Movement * movement in migrant.movements) {
            //                key =[NSString stringWithFormat:@"%@[%i]",REG_MOVEMENT,counter++];
            //                //parse movement history
            //                [formatted setObject:[movement format] forKey:key];
            //            }
            //end new format
            
            /* using old format*/
            NSMutableArray * data = [NSMutableArray array];
            for (Movement * movement in migrant.movements) {
                //parse movement history
                [data addObject:[movement format]];
            }
            [formatted setObject:data forKey:REG_MOVEMENT];
            //end old format
            
        }
        NSLog(@"format : %@",[formatted description]);
        
        return formatted;
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception while creating formatted Registration data: %@", [exception description]);
    }
    
    
    return nil;
}

+ (Registration *)registrationWithDictionary:(NSDictionary *)dictionary
                      inManagedObjectContext:(NSManagedObjectContext *)context
{
    if (![Registration validateRegistrationDictionary:dictionary]) return nil;
    
    @try {
        
        //check ID on local database
        NSString *registrationId = CORE_DATA_OBJECT([dictionary objectForKey:REG_ID]);
        Registration *dt = [Registration registrationWithId:registrationId inManagedObjectContext:context];
        
        if (!dt) {
            dt = [NSEntityDescription insertNewObjectForEntityForName:REG_ENTITY_NAME
                                               inManagedObjectContext:context];
            dt.registrationId = registrationId;
        }
        
        //device
        dt.captureDevice = CORE_DATA_OBJECT([dictionary objectForKey:REG_CAPTURE_DEVICE]);
        NSString * underIOMCare = [dictionary objectForKey:REG_IOM_CARE];
        dt.underIOMCare = [underIOMCare isEqual:@"true"] == TRUE ? @(1) : @(0);
        NSString * selfReporting = [dictionary objectForKey:REG_SELF_REPORT];
        dt.selfReporting = [selfReporting isEqual:@"true"] == TRUE ? @(1) : @(0);
        dt.unhcrDocument = CORE_DATA_OBJECT([dictionary objectForKey:REG_UNHCR_DOCUMENT]);
        dt.unhcrNumber = CORE_DATA_OBJECT([dictionary objectForKey:REG_UNHCR_DOCUMENT_NUMBER]);
        dt.vulnerability = CORE_DATA_OBJECT([dictionary objectForKey:REG_VULNERABILITY]);
        dt.dateCreated = CORE_DATA_OBJECT([dictionary objectForKey:REG_DATE_OF_ENTRY]);
        
        
        //biodata
        NSMutableDictionary *bioData = [NSMutableDictionary dictionary];
        bioData = CORE_DATA_OBJECT([dictionary objectForKey:REG_BIO_DATA]);
        dt.bioData = CORE_DATA_OBJECT([dictionary objectForKey:REG_BIO_DATA]);
        dt.bioData.firstName = CORE_DATA_OBJECT([bioData objectForKey:REG_FIRST_NAME]);
        dt.bioData.familyName = CORE_DATA_OBJECT([bioData objectForKey:REG_FAMILY_NAME]);
        
        dt.bioData.gender = CORE_DATA_OBJECT([bioData objectForKey:REG_GENDER]);
        dt.bioData.maritalStatus = CORE_DATA_OBJECT([bioData objectForKey:REG_MARITAL_STATUS]);
        dt.bioData.nationality.code = CORE_DATA_OBJECT([bioData objectForKey:REG_NATIONALITY]);
        dt.bioData.countryOfBirth.code = CORE_DATA_OBJECT([bioData objectForKey:REG_COUNTRY_OF_BIRTH]);
        dt.bioData.placeOfBirth = CORE_DATA_OBJECT([ bioData objectForKey:REG_PLACE_OF_BIRTH]);
        dt.bioData.dateOfBirth = CORE_DATA_OBJECT([bioData objectForKey:REG_DATE_OF_BIRTH]);
        
        //interception
        NSMutableDictionary *interception = [NSMutableDictionary dictionary];
        interception = CORE_DATA_OBJECT([dictionary objectForKey:REG_INTERCEPTION]);
        dt.interceptionData = CORE_DATA_OBJECT([dictionary objectForKey:REG_INTERCEPTION]);
        dt.interceptionData.interceptionLocation = CORE_DATA_OBJECT([interception objectForKey:REG_INTERCEPTION_LOCATION]);
        dt.interceptionData.interceptionDate = CORE_DATA_OBJECT([interception objectForKey:REG_INTERCEPTION_DATE]);
        dt.interceptionData.dateOfEntry = CORE_DATA_OBJECT([interception objectForKey:REG_DATE_OF_ENTRY]);
        dt.associatedOffice.name = CORE_DATA_OBJECT([interception objectForKey:REG_IOM_OFFICE]);
        
        //Under IOM care
        if (!dt.underIOMCare.boolValue) {
            NSMutableDictionary *transfer = [NSMutableDictionary dictionary];
            transfer = CORE_DATA_OBJECT([transfer objectForKey:REG_TRANSFER]);
            dt.transferDate = CORE_DATA_OBJECT([transfer objectForKey:REG_TRANSFER_DATE]);
            dt.transferDestination.accommodationId = CORE_DATA_OBJECT([transfer objectForKey:REG_TRANSFER_DESTINATION]);
        }
        
        //biometric
        NSMutableDictionary *biometric = [NSMutableDictionary dictionary];
        biometric = CORE_DATA_OBJECT([dictionary objectForKey:REG_BIOMETRIC]);
        dt.biometric = CORE_DATA_OBJECT([dictionary objectForKey:REG_BIOMETRIC]);
        dt.biometric.rightThumb  = CORE_DATA_OBJECT([biometric objectForKey:REG_RIGHT_THUMB]);
        dt.biometric.rightIndex  = CORE_DATA_OBJECT([biometric objectForKey:REG_RIGHT_INDEX]);
        dt.biometric.leftThumb = CORE_DATA_OBJECT([biometric objectForKey:REG_LEFT_THUMB]);
        dt.biometric.leftIndex = CORE_DATA_OBJECT([biometric objectForKey:REG_LEFT_INDEX]);
        dt.biometric.photograph = CORE_DATA_OBJECT([biometric objectForKey:REG_PHOTOGRAPH]);
        
        
        return dt;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while creating Detention Location: %@", [exception description]);
    }
    
    return nil;
}

- (void) setToLocal:(NSNumber *)value{
    self.complete = value;
}

- (void) sendRegistration:(NSDictionary *)params
{
    //show on progress
    if (self.onProgress) {
        self.onProgress();
    }
    
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client postJSONWithPath:@"migrant/save"
                  parameters:params
                     success:^(NSDictionary *jsonData, int statusCode){
                         if ([self saveRegistrationData:params withId:[jsonData objectForKey:REG_ID]] && self.successHandler) {
                             
                             //set status to local
                             self.complete = @(REG_STATUS_LOCAL);
                             //                             NSError *error;
                             //                             if (![self.managedObjectContext save:&error]){
                             //                                  self.failureHandler(error);
                             //                             }else {
                             self.successHandler();
                             //                             }
                         }else if (self.failureHandler){
                             self.failureHandler([NSError errorWithDomain:@"Failed Saving Database" code:0 userInfo:nil]);
                         }
                     }
                     failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                         //                         NSLog(@"Error send json: %@\nError: %@", params, [error description]);
                         if (self.failureHandler) self.failureHandler(error);
                     }];
}

- (void) sendRegistrationUpdate:(NSDictionary *)params
{
    //show on progress
    if (self.onProgress) {
        self.onProgress();
    }
    
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client postJSONWithPath:@"migrant/update"
                  parameters:params
                     success:^(NSDictionary *jsonData, int statusCode){
                         if ([self saveRegistrationData:params withId:[jsonData objectForKey:REG_ID]] && self.successHandler) {
                             self.successHandler();
                             //set status to local
                             self.complete = @(REG_STATUS_LOCAL);
                         }else if (self.failureHandler){
                             self.failureHandler([NSError errorWithDomain:@"Failed Saving Database" code:0 userInfo:nil]);
                         }
                     }
                     failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                         //                         NSLog(@"Error send json: %@\nError: %@", params, [error description]);
                         if (self.failureHandler) self.failureHandler(error);
                     }];
}


- (BOOL)saveRegistrationData:(NSDictionary *)dictionary withId:(NSString*)Id
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    @try {
        NSError *error;
        
        context.parentContext = [[IMDBManager sharedManager] localDatabase].managedObjectContext;
        
        Migrant *migrant = [Migrant migrantWithId:Id inContext:context];
        
        if (!migrant) {
            //create new migrant data
            migrant = [Migrant newMigrantInContext:context withId:Id];
        }
        migrant.registrationNumber = Id;
        //device
        
        //general information
        migrant.underIOMCare = [[dictionary objectForKey:REG_IOM_CARE] isEqualToString:@"true"] ? @(1):@(0);
        migrant.unhcrDocument = CORE_DATA_OBJECT([dictionary objectForKey:REG_UNHCR_DOCUMENT]);
        migrant.unhcrNumber = CORE_DATA_OBJECT([dictionary objectForKey:REG_UNHCR_DOCUMENT_NUMBER]);
        migrant.vulnerabilityStatus = CORE_DATA_OBJECT([dictionary objectForKey:REG_VULNERABILITY]);
        
        //        if (dictionary [REG_DATE_OF_ENTRY]) {
        //            migrant.dateCreated = [NSDate dateFromUTCString:[dictionary objectForKey:REG_DATE_OF_ENTRY]];
        //        }
        
        
        
        //biodata
        NSMutableDictionary *bioData = [NSMutableDictionary dictionary];
        bioData = CORE_DATA_OBJECT([dictionary objectForKey:REG_BIO_DATA]);
        //            dt.bioData = CORE_DATA_OBJECT([dictionary objectForKey:REG_BIO_DATA]);
        migrant.bioData.firstName = CORE_DATA_OBJECT([bioData objectForKey:REG_FIRST_NAME]);
        migrant.bioData.familyName = CORE_DATA_OBJECT([bioData objectForKey:REG_FAMILY_NAME]);
        
        NSString * gender = CORE_DATA_OBJECT([bioData objectForKey:REG_GENDER]);
        if ([gender length] == 1 || [gender length] == 2) {
            gender = [gender isEqualToString:@"M"] ? @"Male" : @"Female";
        }
        
        migrant.bioData.gender = gender;
        
        migrant.bioData.maritalStatus = CORE_DATA_OBJECT([bioData objectForKey:REG_MARITAL_STATUS]);
        migrant.bioData.nationality = [Country countryWithCode:[bioData objectForKey:REG_NATIONALITY] inManagedObjectContext:context];
        migrant.bioData.countryOfBirth = [Country countryWithCode:[bioData objectForKey:REG_COUNTRY_OF_BIRTH] inManagedObjectContext:context];
        migrant.bioData.cityOfBirth = CORE_DATA_OBJECT([ bioData objectForKey:REG_PLACE_OF_BIRTH]);
        migrant.bioData.dateOfBirth = [NSDate dateFromUTCString:[bioData objectForKey:REG_DATE_OF_BIRTH] ];
        
        if (dictionary [REG_INTERCEPTION]) {
            NSDictionary *interception = CORE_DATA_OBJECT([dictionary objectForKey:REG_INTERCEPTION]);
            if (interception) {
                //get value
                migrant.selfReporting = [[interception objectForKey:REG_SELF_REPORT] isEqualToString:@"true"] ? @(1):@(0);
            }
            
            Interception *data = [Interception interceptionWithDictionary:CORE_DATA_OBJECT([dictionary objectForKey:REG_INTERCEPTION])withMigrantId:Id inContext:context];
            if (data) {
                [migrant addInterceptionsObject:data];
            }
            
            
        }
        //IOM data
        if ([dictionary objectForKey:REG_IOM_OFFICE]) {
            //todo add object before save it
            if (!migrant.iomData) {
                IomData * iomData = [NSEntityDescription insertNewObjectForEntityForName:@"IomData" inManagedObjectContext:context];
                migrant.iomData = iomData;
                migrant.iomData.iomDataId = migrant.registrationNumber;
            }
            migrant.iomData.associatedOffice = [IomOffice officeWithName:CORE_DATA_OBJECT([dictionary objectForKey:REG_IOM_OFFICE]) inManagedObjectContext:context];
        }
        
        //Under IOM care
        if (!migrant.underIOMCare.boolValue && CORE_DATA_OBJECT([dictionary objectForKey:REG_TRANSFER])) {
            //add movement
            NSArray *movements = CORE_DATA_OBJECT(dictionary [REG_TRANSFER]);
            for (NSDictionary *movement in movements) {
                //set movement type to Transfer as default
                [movement setValue:@"Transfer" forKey:@"type"];
                Movement *data = [Movement movementWithDictionary:movement inContext:context];
                if (data) {
                    [migrant addMovementsObject:data];
                }
            }
        }
        
        //biometric
        if ([dictionary objectForKey:REG_BIOMETRIC]) {
            NSMutableDictionary *biometric = CORE_DATA_OBJECT([dictionary objectForKey:REG_BIOMETRIC]);
            
            //update data
            migrant.biometric = [Biometric biometricWithId:Id inContext:context];
            if (!migrant.biometric) {
                migrant.biometric = [NSEntityDescription insertNewObjectForEntityForName:BIO_ENTITY_NAME inManagedObjectContext:context];
                //migrant ID == Biometric ID
                migrant.biometric.biometricId = Id;
            }
            
            //device
            
            //photo
            [migrant.biometric updatePhotographFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:BIO_PHOTOGRAPH])];
            
            //finger image
            [migrant.biometric updateFingerImageFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:REG_RIGHT_THUMB]) forFingerPosition:RightThumb];
            [migrant.biometric updateFingerImageFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:REG_RIGHT_INDEX]) forFingerPosition:RightIndex];
            [migrant.biometric updateFingerImageFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:REG_LEFT_THUMB]) forFingerPosition:LeftThumb];
            [migrant.biometric updateFingerImageFromBase64String:CORE_DATA_OBJECT([biometric objectForKey:REG_LEFT_INDEX]) forFingerPosition:LeftIndex];
        }else {
            migrant.biometric = Nil;
        }
        
        //save flag to complete
        migrant.complete = @(TRUE);
        
        //save uploader and last uploader
        if (!migrant.uploader) {
            migrant.uploader = [IMAuthManager sharedManager].activeUser.email;
        }
        migrant.lastUploader  = [IMAuthManager sharedManager].activeUser.email;
        
        
        if (![context save:&error]) {
            NSLog(@"Error : %@",[error description]);
        }
        
        
        return YES;
    }
    @catch (NSException *exception) {
        NSLog(@"Throw exeption while saveRegistrationData: %@",[exception description]);
        [context rollback];
    }
    
    return NO;
}


- (BOOL)saveRegistrationData:(NSDictionary *)dictionary

{
    @try {
        NSError *error;
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        context.parentContext = [[IMDBManager sharedManager] localDatabase].managedObjectContext;
        
        
        Registration *data = [Registration registrationWithDictionary:dictionary inManagedObjectContext:context];
        
        if (data) {
            BOOL value = [context save:&error];
            if (value == FALSE) {
                NSLog(@"Fail to save to database : %@",[error description]);
            }else data.complete =@TRUE;
            
            //            [context reset];
            return value;
        }
        NSLog(@"Error saving registration data - Error: %@",  [error description]);
        [context rollback];
        //        [context reset];
    }
    @catch (NSException *exception) {
        NSLog(@"Throw exeption : %@",[exception description]);
    }
    
    
    return NO;
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
    //    if (self.underIOMCare.boolValue) stat &= self.transferDate && self.transferDestination;
    self.complete = @(stat);
}

- (void) setRegistrationToLocal
{
    self.complete = @(REG_STATUS_LOCAL);
}


+ (Registration *)registrationWithId:(NSString *)registrationId
              inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:REG_ENTITY_NAME];
        request.predicate = [NSPredicate predicateWithFormat:@"registrationId = %@", registrationId];
        
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception while registrationWithId : %@", [exception description]);
    }
    
    return nil;
}

+ (BOOL)validateRegistrationDictionary:(NSDictionary *)dictionary
{
    return dictionary && [dictionary objectForKey:REG_BIOMETRIC] && [dictionary objectForKey:REG_BIO_DATA] && [dictionary objectForKey:REG_INTERCEPTION];
}

+ (Registration *)registrationFromMigrantAndDictionary:(Migrant *)migrant withdictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        
        Registration * data = [Registration registrationWithId:migrant.registrationNumber inManagedObjectContext:context];
        if (!data) {
            //create new registration data
            data = [Registration newRegistrationInContext:context];
        }
        
        //set registration to local
        data.complete = @(REG_STATUS_LOCAL);
        
        //date ctreated
        data.dateCreated = migrant.dateCreated;
        
        //save detention location
        data.detentionLocation = migrant.detentionLocation;
        
        //copy Migrant to Registration
        data.registrationId = migrant.registrationNumber;
        data.unhcrDocument = migrant.unhcrDocument;
        data.unhcrNumber = migrant.unhcrNumber;
        data.underIOMCare = migrant.underIOMCare;
        data.vulnerability = migrant.vulnerabilityStatus;
        
        //deep copy
        data.associatedOffice = [IomOffice officeWithName:migrant.iomData.associatedOffice.name inManagedObjectContext:context];
        
        
        
        //Biodata
        data.bioData.firstName = migrant.bioData.firstName;
        data.bioData.familyName = migrant.bioData.familyName;
        data.bioData.gender = migrant.bioData.gender;
        data.bioData.maritalStatus = migrant.bioData.maritalStatus;
        data.bioData.placeOfBirth = migrant.bioData.cityOfBirth;
        data.bioData.dateOfBirth = migrant.bioData.dateOfBirth;
        
        
        //deep copy
        //        data.bioData.countryOfBirth = [Country countryWithName:migrant.bioData.countryOfBirth.name inManagedObjectContext:context];
        data.bioData.nationality = [Country countryWithName:migrant.bioData.nationality.name inManagedObjectContext:context];
        
        if (migrant.bioData.nationality.name != data.bioData.nationality.name) {
            NSLog(@"Something Wrong ...!!!");
            
        }
        
        
        
        //Biometric
        data.biometric.leftIndex = migrant.biometric.leftIndexImage;
        data.biometric.leftThumb = migrant.biometric.leftThumbImage;
        data.biometric.rightIndex = migrant.biometric.rightIndexImage;
        data.biometric.rightThumb = migrant.biometric.rightThumbImage;
        data.biometric.photograph = migrant.biometric.photograph;
        
        
        //interception
        if (migrant.interceptions) {
            if ([migrant.interceptions count] > 1) {
                //sort interceptions
                [migrant.interceptions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"interceptionDate" ascending:NO]]];
            }
            
            //get newest interception data
            Interception *interception = [migrant.interceptions anyObject];
            data.interceptionData.interceptionLocation = interception.interceptionLocation;
            data.interceptionData.interceptionDate = interception.interceptionDate;
            data.interceptionData.dateOfEntry = interception.dateOfEntry;
        }
        
        
        //under IOM Care
        if (data.underIOMCare.boolValue && migrant.movements)
        {
            if ([migrant.movements count] > 1) {
                //sort interceptions
                [migrant.movements sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]];
            }
            
            //get newest movement data
            Movement *movement = [migrant.movements anyObject];
            
            //Accommodation
            data.transferDestination = movement.transferLocation;
        }
        
        //self reporting
        data.selfReporting = migrant.selfReporting;
        
        return data;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while registrationFromMigrantAndDictionary with Error : %@",[exception description]);
        return Nil;
    }
    
}
+ (Registration *)registrationFromMigrant:(Migrant *)migrant inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        Registration * data = [Registration registrationWithId:migrant.registrationNumber inManagedObjectContext:context];
        if (!data) {
            //create new registration data
            data = [Registration newRegistrationInContext:context];
        }
        
        //set registration to local
        data.complete = @(REG_STATUS_LOCAL);
        
        //date ctreated
        data.dateCreated = migrant.dateCreated;
        
        //save detention location
        data.detentionLocation = migrant.detentionLocation;
        
        //copy Migrant to Registration
        data.registrationId = migrant.registrationNumber;
        if (![migrant.unhcrDocument isEqualToString:@"No Document"]) {
            data.unhcrDocument = migrant.unhcrDocument;
        }else data.unhcrNumber = Nil;
        data.underIOMCare = migrant.underIOMCare;
        data.vulnerability = migrant.vulnerabilityStatus;
        
        //deep copy
        data.associatedOffice = [IomOffice officeWithName:migrant.iomData.associatedOffice.name inManagedObjectContext:context];
        
        
        //Biodata
        data.bioData.firstName = migrant.bioData.firstName;
        data.bioData.familyName = migrant.bioData.familyName;
        data.bioData.gender = migrant.bioData.gender;
        data.bioData.maritalStatus = migrant.bioData.maritalStatus;
        data.bioData.placeOfBirth = migrant.bioData.cityOfBirth;
        data.bioData.dateOfBirth = migrant.bioData.dateOfBirth;
        
        //get country from dictionary
        
        //deep copy
        data.bioData.countryOfBirth = [Country countryWithCode:migrant.bioData.countryOfBirth.code inManagedObjectContext:context];
        data.bioData.nationality = [Country countryWithCode:migrant.bioData.nationality.code inManagedObjectContext:context];
        
        //Biometric
        data.biometric.leftIndex = migrant.biometric.leftIndexImage;
        data.biometric.leftThumb = migrant.biometric.leftThumbImage;
        data.biometric.rightIndex = migrant.biometric.rightIndexImage;
        data.biometric.rightThumb = migrant.biometric.rightThumbImage;
        data.biometric.photograph = migrant.biometric.photograph;
        
        
        //interception
        if (migrant.interceptions) {
            if ([migrant.interceptions count] > 1) {
                //sort interceptions
                [migrant.interceptions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"interceptionDate" ascending:YES]]];
            }
            
            //get newest interception data
            Interception *interception = [migrant.interceptions anyObject];
            data.interceptionData.interceptionLocation = interception.interceptionLocation;
            data.interceptionData.interceptionDate = interception.interceptionDate;
            data.interceptionData.dateOfEntry = interception.dateOfEntry;
        }
        
        
        //under IOM Care
        if (data.underIOMCare.boolValue && migrant.movements)
        {
            if ([migrant.movements count] > 1) {
                //sort interceptions
                [migrant.movements sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];
            }
            
            NSArray *myArray = [migrant.movements allObjects];
            if ([myArray count]) {
                for (Movement *movement in myArray){
                    //get newest movement data && have same location with detention location
                    if ([movement.transferLocation.accommodationId isEqualToString:migrant.detentionLocation]) {
                        //Accommodation
                        data.transferDestination = movement.transferLocation;
                        data.transferDate = movement.date;
                    }
                }
                
                
                //            Movement *movement = [myArray firstObject];
                
            }else{
                data.transferDate =Nil;
                data.transferDestination = Nil;
            }
        }
        
        //self Reporting
        data.selfReporting = migrant.selfReporting;
        
        return data;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while registrationFromMigrant with Error : %@",[exception description]);
        return Nil;
    }
    
    
}
@end