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

@interface Registration (Export)

+ (Registration *)newRegistrationInContext:(NSManagedObjectContext *)context;

- (NSDictionary *)format;

- (void)validateCompletion;
- (NSString *)fullname;
- (NSString *)bioDataSummary;
- (NSString *)interceptionSummary;
- (NSString *)unhcrSummary;

@end