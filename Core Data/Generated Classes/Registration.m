//
//  Registration.m
//  RAMS Client
//
//  Created by IOM Jakarta on 10/8/14.
//  Copyright (c) 2014 International Organization for Migration. All rights reserved.
//

#import "Registration.h"
#import "Accommodation.h"
#import "IomOffice.h"
#import "RegistrationBioData.h"
#import "RegistrationBiometric.h"
#import "RegistrationInterception.h"


@implementation Registration
@synthesize failureHandler;
@synthesize failureHandlerAndCode;
@synthesize successHandler;
@synthesize successHandlerAndCode;
@synthesize onProgress;
@dynamic active;
@dynamic captureDevice;
@dynamic complete;
@dynamic dateCreated;
@dynamic detentionLocation;
@dynamic detentionLocationName;
@dynamic registrationId;
@dynamic selfReporting;
@dynamic skipFinger;
@dynamic transferDate;
@dynamic transferId;
@dynamic underIOMCare;
@dynamic unhcrDocument;
@dynamic unhcrNumber;
@dynamic vulnerability;
@dynamic backupName;
@dynamic associatedOffice;
@dynamic bioData;
@dynamic biometric;
@dynamic interceptionData;
@dynamic transferDestination;

@end
