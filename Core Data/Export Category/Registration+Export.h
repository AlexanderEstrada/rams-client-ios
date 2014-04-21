//
//  Registration+Export.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Registration.h"

#import "Country.h"
#import "IomOffice.h"
#import "Accommodation.h"

#import "RegistrationBioData.h"
#import "RegistrationInterception.h"
#import "RegistrationBiometric+Storage.h"

#import "NSDate+Relativity.h"

@class Migrant,Interception;

@interface Registration (Export)




+ (Registration *)newRegistrationInContext:(NSManagedObjectContext *)context;
+ (Registration *)registrationWithId:(NSString *)registrationId
              inManagedObjectContext:(NSManagedObjectContext *)context;
+ (BOOL)validateRegistrationDictionary:(NSDictionary *)dictionary;
+ (Registration *)registrationWithDictionary:(NSDictionary *)dictionary
                      inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Registration *)registrationFromMigrant:(Migrant *)migrant inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Registration *)registrationFromMigrantAndDictionary:(Migrant *)migrant withdictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context;

- (NSDictionary *)format;

- (void)validateCompletion;
- (NSString *)fullname;
- (NSString *)bioDataSummary;
- (NSString *)interceptionSummary;
- (NSString *)unhcrSummary;
- (BOOL)saveRegistrationData:(NSDictionary *)dictionary;
- (BOOL)saveRegistrationData:(NSDictionary *)dictionary withId:(NSString*)Id;
- (void) sendRegistration:(NSDictionary *)params;
- (void) setToLocal:(NSNumber *)value;
- (void) setRegistrationToLocal;
@end