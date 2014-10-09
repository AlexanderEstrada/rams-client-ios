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
NSString *const REG_FATHER_NAME                  = @"fatherName";
NSString *const REG_MOTHER_NAME                  = @"motherName";
NSString *const REG_FAMILY_NAME                 = @"familyName";
NSString *const REG_GENDER                      = @"gender";
NSString *const  REG_SKIP_FINGER                = @"skipFinger";
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

+ (NSString *)jsonDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [cachesPath stringByAppendingPathComponent:@"JSON"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (Registration *) restore:(NSManagedObjectContext *)context
{
    
    Registration * data = nil;
    @try {
        NSError * err;
       
        NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[Registration jsonDir] error:&err];
        if (err) {
            NSLog(@"Error while restore : %@",[err description]);
        }else NSLog(@"directory %@ - Content : %@",[Registration jsonDir],[directoryContent description]);
        
        for (NSString * path in directoryContent)
        {
            //check if file exist
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                //case exist then read
             data = [Registration restoreFromFile:path inContext:context];
            }
            
            
        }
        
        return data;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception restore : %@",[exception description]);
        return data;
    }
    @finally{
        return data;
    }
}

+ (Registration *) restoreFromFile:(NSString*)path inContext:(NSManagedObjectContext *)context
{
    Registration * data = nil;
    @try {
        
        if (path) {
            NSString * tmp = [[Registration jsonDir] stringByAppendingPathComponent:path];
            
            //check if file exist
            if ([[NSFileManager defaultManager] fileExistsAtPath:tmp]) {
                //case exist then read
                NSDictionary *dictFromFile = [NSDictionary dictionaryWithContentsOfFile:path];
                //restore to object
                data =  [self registrationWithDictionary:dictFromFile inManagedObjectContext:context];
            }
            
        }
        return data;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception restoreFromFile : %@",[exception description]);
        return data;
    }
    @finally{
        return data;
    }
    
}

- (void) removeBackupFile
{
    @try {
        //TODO : removing backup files
        if (self.backupName) {
            //get the directory
            NSString * path = [[Registration jsonDir] stringByAppendingPathComponent:self.backupName];
            
            
            //check if file exist
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                NSError * err;
                //case exist then remove from file
                [[NSFileManager defaultManager] removeItemAtPath:path error:&err];
                if (err) {
                    NSLog(@"Error while deleting backup file :%@",[err description]);
                }else NSLog(@"Delete %@ Success",path);
            }
            
            
        }

    }
    @catch (NSException *exception) {
        NSLog(@"Exception while removeBackupFile : %@",[exception description]);
    }
    
   }

- (NSString *) dumpToFile
{
    //dump json format to file as backup
    @try {
        //create json format
        NSDictionary * json = [self format];
        
        //dump it to file
        
        //use id from database as file name
        NSString * objectId = [[Registration jsonDir] stringByAppendingPathComponent:[[[[self objectID] URIRepresentation] absoluteURL] lastPathComponent]];
        NSLog(@"objectId : %@",objectId);
        
        //get path
        // Write dictionary
        if ([json writeToFile:objectId atomically:YES]) {
            self.backupName = [objectId lastPathComponent];
            return self.backupName;
        }else return nil;
        
    }
    
    @catch (NSException *exception) {
        NSLog(@"dumpToFile exception : %@",[exception description]);
        return Nil;
    }
    
}

- (NSDictionary *)format
{
    @try {
        NSMutableDictionary *formatted = [NSMutableDictionary dictionary];
        //update file path
        [self.biometric photographImage];
        
        //Registration Data
        [formatted setObject:self.captureDevice forKey:REG_CAPTURE_DEVICE];
        [formatted setObject:self.underIOMCare.intValue?@"true":@"false" forKey:REG_IOM_CARE];
        
        //    [formatted setObject:self.underIOMCare forKey:REG_IOM_CARE];
        if (self.underIOMCare.boolValue) [formatted setObject:self.associatedOffice.name forKey:REG_IOM_OFFICE];
        if (self.unhcrDocument) [formatted setObject:self.unhcrDocument forKey:REG_UNHCR_DOCUMENT];
        if (self.unhcrNumber) [formatted setObject:self.unhcrNumber forKey:REG_UNHCR_DOCUMENT_NUMBER];
        //        if (self.vulnerability) [formatted setObject:self.vulnerability forKey:REG_VULNERABILITY];
        
        //Biodata
        NSMutableDictionary *bioData = [NSMutableDictionary dictionary];
        [bioData setObject:self.bioData.firstName forKey:REG_FIRST_NAME];
        if ([self.bioData.familyName length]) [bioData setObject:self.bioData.familyName forKey:REG_FAMILY_NAME];
         if ([self.bioData.motherName length]) [bioData setObject:self.bioData.motherName forKey:REG_MOTHER_NAME];
         if ([self.bioData.fatherName length]) [bioData setObject:self.bioData.fatherName forKey:REG_FATHER_NAME];
        //    [bioData setObject:self.bioData.gender forKey:REG_GENDER];
        [bioData setObject:[self.bioData.gender isEqual:@"Male"] ? @"M":@"F" forKey:REG_GENDER];
        [bioData setObject:self.bioData.maritalStatus forKey:REG_MARITAL_STATUS];
        [bioData setObject:self.bioData.nationality.code forKey:REG_NATIONALITY];
        [bioData setObject:self.bioData.countryOfBirth.code forKey:REG_COUNTRY_OF_BIRTH];
        [bioData setObject:self.bioData.placeOfBirth forKey:REG_PLACE_OF_BIRTH];
        [bioData setObject:[self.bioData.dateOfBirth toUTCString] forKey:REG_DATE_OF_BIRTH];
        [formatted setObject:bioData forKey:REG_BIO_DATA];
        
        NSLog(@"bioData.dateOfBirth : %@",[self.bioData.dateOfBirth toUTCString]);
        
        //Interception
        if ([self.interceptionData.interceptionLocation length]) {
            NSMutableDictionary *interception = [NSMutableDictionary dictionary];
            if (self.interceptionData.dateOfEntry == Nil) {
                self.interceptionData.dateOfEntry =self.dateCreated;
            }
            [interception setObject:[self.interceptionData.dateOfEntry toUTCString] forKey:REG_DATE_OF_ENTRY];
            
            [interception setObject:[self.interceptionData.interceptionDate toUTCString] forKey:REG_INTERCEPTION_DATE];
            [interception setObject:self.interceptionData.interceptionLocation forKey:REG_INTERCEPTION_LOCATION];
            [interception setObject:self.selfReporting.intValue?@"true":@"false" forKey:REG_SELF_REPORT];
            [formatted setObject:interception forKey:REG_INTERCEPTION];
            NSLog(@"interceptionData.interceptionDate : %@",[self.interceptionData.interceptionDate toUTCString]);
        }
        
        //Under IOM care
        //        if (self.underIOMCare.boolValue && self.transferDate && self.transferDestination.accommodationId) {
        //            NSDictionary *transfer = @{REG_TRANSFER_DATE: [self.transferDate toUTCString],
        //                                       REG_TRANSFER_DESTINATION: self.transferDestination.accommodationId};
        //            [formatted setObject:transfer forKey:REG_TRANSFER];
        //        }
        if (self.transferDate && self.transferDestination.accommodationId) {
            NSDictionary *transfer = @{REG_TRANSFER_DATE: [self.transferDate toUTCString],
                                       REG_TRANSFER_DESTINATION: self.transferDestination.accommodationId};
            NSLog(@"self.transferDate : %@",[self.transferDate toUTCString]);
            [formatted setObject:transfer forKey:REG_TRANSFER];
        }else if (!self.transferDestination.name && self.transferDate) {
            self.transferDestination = [Accommodation accommodationWithName:self.detentionLocationName inManagedObjectContext:self.managedObjectContext];
            if (self.transferDestination) {
                NSDictionary *transfer = @{REG_TRANSFER_DATE: [self.transferDate toUTCString],
                                           REG_TRANSFER_DESTINATION: self.transferDestination.accommodationId};
                [formatted setObject:transfer forKey:REG_TRANSFER];
                
                NSError * err;
                [self.managedObjectContext save:&err];
                if (err) {
                    NSLog(@"Error while saving : %@",[err description]);
                }else [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil userInfo:nil];
            }
            
        }
        
        //check for sending finger image flag
                 [formatted setObject:self.skipFinger.intValue?@"true":@"false" forKey:REG_SKIP_FINGER];
        
        NSLog(@"formatted without biometric: %@",[formatted description]);
                if (!self.skipFinger.boolValue) {
        //case not skip sending finger image
        NSMutableDictionary *biometric = [NSMutableDictionary dictionary];
        NSString * base64Str;
        [biometric setObject:[self.biometric base64Photograph] forKey:REG_PHOTOGRAPH];
        if (self.biometric.rightThumb){
            base64Str =[self.biometric base64FingerImageWithPosition:RightThumb];
            if (base64Str) {
                [biometric setObject:base64Str forKey:REG_RIGHT_THUMB];
            }
            
        }
        if (self.biometric.rightIndex){
            base64Str = [self.biometric base64FingerImageWithPosition:RightIndex];
            if (base64Str) {
                [biometric setObject:base64Str forKey:REG_RIGHT_INDEX];
            }
            
        }
        if (self.biometric.leftThumb){
            base64Str = [self.biometric base64FingerImageWithPosition:LeftThumb];
            if (base64Str) {
                [biometric setObject:base64Str forKey:REG_LEFT_THUMB];
            }
            
        }
        if (self.biometric.leftIndex){
            base64Str = [self.biometric base64FingerImageWithPosition:LeftIndex];
            if (base64Str) {
                [biometric setObject:base64Str forKey:REG_LEFT_INDEX];
            }
        }
        
        [formatted setObject:biometric forKey:REG_BIOMETRIC];
        
                }
        /*
         //Movement
         
         //check if There is movement to upload
         Migrant * migrant = [Migrant migrantWithId:self.registrationId inContext:self.managedObjectContext];
         
         if (migrant && [migrant.movements count]) {
         // using new format
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
         
         // using old format
         NSMutableArray * data = [NSMutableArray array];
         for (Movement * movement in migrant.movements) {
         //parse movement history
         [data addObject:[movement format]];
         }
         [formatted setObject:data forKey:REG_MOVEMENT];
         //end old format
         
         }
         */
        //        NSLog(@"formatted : %@",[formatted description]);
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
        
        dt.bioData.fatherName = CORE_DATA_OBJECT([bioData objectForKey:REG_FATHER_NAME]);
        dt.bioData.motherName = CORE_DATA_OBJECT([bioData objectForKey:REG_MOTHER_NAME]);
        
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
        
        if (dt) {
            NSError * err;
            if (![dt.managedObjectContext save:&err]) {
                NSLog(@"Error while saving registrationWithDictionary : %@ ",[err description]);
            }else [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil userInfo:nil];
        }
        
        return dt;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while registrationWithDictionary: %@", [exception description]);
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
                             
                             //save returned ID to Registration Data
                             self.registrationId = [jsonData objectForKey:REG_ID];
                             
                             //set status to local
                             self.complete = @(REG_STATUS_LOCAL);
                             //                             NSError *error;
                             //                             if (![self.managedObjectContext save:&error]){
                             //                                  self.failureHandler(error);
                             //                             }else {
                             
                             
                             if (self.successHandler) self.successHandler();
                             if (self.successHandlerAndCode) self.successHandlerAndCode(statusCode);
                             //                             }
                         }else{
                             if (self.failureHandler){
                                 self.failureHandler([NSError errorWithDomain:@"Failed Saving Database" code:0 userInfo:nil]);
                             }
                             
                             if (self.failureHandlerAndCode) {
                                 self.failureHandlerAndCode([NSError errorWithDomain:@"Failed Saving Database" code:0 userInfo:nil],1);
                             }
                         }
                     }
                     failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                         //                         NSLog(@"Error send json: %@\nError: %@", params, [error description]);
                         if (self.failureHandler) self.failureHandler(error);
                         if (self.failureHandlerAndCode) self.failureHandlerAndCode(error,statusCode);
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
                         }else{
                             if (self.failureHandler){
                                 self.failureHandler([NSError errorWithDomain:@"Failed Saving Database" code:0 userInfo:nil]);
                             }
                             if (self.failureHandlerAndCode) {
                                 self.failureHandlerAndCode([NSError errorWithDomain:@"Failed Saving Database" code:0 userInfo:nil],1);
                             }
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
        
        migrant.bioData.fatherName = CORE_DATA_OBJECT([bioData objectForKey:REG_FATHER_NAME]);
        migrant.bioData.motherName = CORE_DATA_OBJECT([bioData objectForKey:REG_MOTHER_NAME]);
        
        
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
            NSMutableDictionary *movement = [NSMutableDictionary dictionary];
            movement = CORE_DATA_OBJECT([dictionary [REG_TRANSFER] mutableCopy]);
            
            
            if ([movement count]) {
                //set movement type to Transfer as default
                NSString * text = @"Transfer";
                NSString * key = @"type";
                [movement setObject:text forKey:key];
                Movement *data = [Movement movementWithDictionary:movement inContext:context];
                //check location and date before adding new movement
                if (data) {
                    BOOL exist = NO;
                    for (Movement * movement in migrant.movements) {
                        if ([movement.date isEqualToDate:data.date] && [movement.transferLocation.name isEqualToString:data.transferLocation.name] ) {
                            //movement is already on database, then skipp it
                            exist = YES;
                            break;
                        }
                    }
                    
                    if (!exist) [migrant addMovementsObject:data];
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
        
        //        //remove photo on local registration folder
        //        NSFileManager *manager = [NSFileManager defaultManager];
        //
        //        //and delete the registration photo and move it to migrant placechange the path to migrant path
        //        if (migrant.biometric.photographThumbnail){
        //            [manager removeItemAtPath:self.biometric.photographThumbnail error:&error];
        //            if (error) {
        //                NSLog(@"while delete Error : %@",[error description]);
        //            }
        //            self.biometric.photographThumbnail = migrant.biometric.photographThumbnail;
        //        }
        //        if (migrant.biometric.photograph){
        //            [manager removeItemAtPath:self.biometric.photograph error:&error];
        //            if (error) {
        //                NSLog(@"while delete Error : %@",[error description]);
        //            }
        //            self.biometric.photograph = migrant.biometric.photograph;
        //        }
        //        if (migrant.biometric.rightIndexImage) {
        //            [manager removeItemAtPath:self.biometric.rightIndex error:&error];
        //            if (error) {
        //                NSLog(@"while delete Error : %@",[error description]);
        //            }
        //            self.biometric.rightIndex= migrant.biometric.rightIndexImage;
        //        }
        //        if (migrant.biometric.leftIndexImage){
        //            [manager removeItemAtPath:self.biometric.leftIndex error:&error];
        //            if (error) {
        //                NSLog(@"while delete Error : %@",[error description]);
        //            }
        //            self.biometric.leftIndex= migrant.biometric.leftIndexImage;
        //        }
        //        if (migrant.biometric.rightThumbImage){
        //            [manager removeItemAtPath:self.biometric.rightThumb error:&error];
        //            if (error) {
        //                NSLog(@"while delete Error : %@",[error description]);
        //            }
        //            self.biometric.rightThumb= migrant.biometric.rightThumbImage;
        //        }
        //        if (migrant.biometric.leftThumbImage){
        //            [manager removeItemAtPath:self.biometric.leftThumb error:&error];
        //            if (error) {
        //                NSLog(@"while delete Error : %@",[error description]);
        //            }
        //            self.biometric.leftThumb= migrant.biometric.leftThumbImage;
        //        }
        
        
        return YES;
    }
    @catch (NSException *exception) {
        NSLog(@"Registration+Export - Throw exeption while saveRegistrationData: %@",[exception description]);
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
    if (([self.interceptionData.interceptionLocation length]> 0?YES:NO)) {
        stat &= self.interceptionData.interceptionDate && [self.interceptionData.interceptionLocation length] && self.interceptionData.dateOfEntry;
    }
    
    //check photo and finger print
    stat &= [self.biometric.photograph length] > 0?YES:NO;
    
    if (!self.skipFinger.boolValue) {
        stat &= ([self.biometric.leftIndex length]> 0?YES:NO) || ([self.biometric.leftThumb length]> 0?YES:NO) || ([self.biometric.rightIndex length]> 0?YES:NO) || ([self.biometric.rightThumb length]> 0?YES:NO);
    }
    
    if (self.unhcrDocument) stat &= self.unhcrDocument && ([self.unhcrNumber length]> 0?YES:NO);
    //    if (self.underIOMCare.boolValue) stat &= self.transferDate && self.transferDestination;
    self.complete = @(stat);
}

- (void) setRegistrationToLocal
{
    self.complete = @(REG_STATUS_LOCAL);
}

+ (Registration *)createBackupReg:(Registration *)registration inManagedObjectContext:(NSManagedObjectContext *)context;
{
    @try {
        Registration * backup = [Registration registrationWithId:IMBackupKey inManagedObjectContext:context];
        
        if (!backup) {
            backup = [Registration newRegistrationInContext:context];
            backup.registrationId = IMBackupKey;
        }
        //set flag as backup
        backup.complete = @(REG_STATUS_BACKUP);
        
        //change value to latest
        backup.bioData.countryOfBirth = registration.bioData.countryOfBirth;
        backup.bioData.nationality =   registration.bioData.nationality;
        
        //unhcr document
        backup.unhcrDocument =  registration.unhcrDocument;
        backup.unhcrNumber =  registration.unhcrNumber;
        
        
        //interception data
        backup.associatedOffice =  registration.associatedOffice;
        backup.underIOMCare =  registration.underIOMCare;
        
        backup.selfReporting =  registration.selfReporting;
        backup.interceptionData.dateOfEntry =  registration.interceptionData.dateOfEntry;
        backup.interceptionData.interceptionDate =  registration.interceptionData.interceptionDate;
        backup.interceptionData.interceptionLocation =  registration.interceptionData.interceptionLocation;
        
        //location
        //        backup.transferDestination =  registration.transferDestination;
        backup.transferDestination = [Accommodation accommodationWithName:registration.transferDestination.name inManagedObjectContext:context];
        backup.transferDate =  registration.transferDate;
        
        NSError *error;
        if (![context save:&error]) {
            NSLog(@"Error saving context: %@", [error description]);
            return Nil;
        }else {
            //save database
            [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
            return backup;
        }
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception while registrationWithId : %@", [exception description]);
    }
    
    return nil;
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
        
        data.bioData.fatherName = migrant.bioData.fatherName;
        data.bioData.motherName = migrant.bioData.motherName;
        
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
        
        //skip finger flag
                data.skipFinger = migrant.skipFinger;
        
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
            data.unhcrNumber = migrant.unhcrNumber;
        }else data.unhcrNumber = Nil;
        data.underIOMCare = migrant.underIOMCare;
        data.vulnerability = migrant.vulnerabilityStatus;
        
        //deep copy
        data.associatedOffice = [IomOffice officeWithName:migrant.iomData.associatedOffice.name inManagedObjectContext:context];
        
        
        //Biodata
        data.bioData.firstName = migrant.bioData.firstName;
        data.bioData.familyName = migrant.bioData.familyName;
        
        data.bioData.fatherName = migrant.bioData.fatherName;
        data.bioData.motherName = migrant.bioData.motherName;
        
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
        data.biometric.photographThumbnail = migrant.biometric.photographThumbnail;
        
        
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
                        data.transferDestination = [Accommodation accommodationWithId:movement.transferLocation.accommodationId inManagedObjectContext:[[IMDBManager sharedManager] localDatabase].managedObjectContext];
                        data.transferDate = movement.date;
                        break;
                        //                        data.transferId = movement.movementId;
                    }
                }
                
                
                //            Movement *movement = [myArray firstObject];
                
            }else{
                data.transferDate =Nil;
                data.transferDestination = Nil;
            }
        }
        
        //skip finger flag
                data.skipFinger = migrant.skipFinger;
        
        //self Reporting
        data.selfReporting = migrant.selfReporting;
        
        NSError * err;
        //save to database
        if (![context save:&err]) {
            NSLog(@"error while saving : %@",[err description]);
        }
        
        return data;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while registrationFromMigrant with Error : %@",[exception description]);
        return Nil;
    }
    
    
}
@end