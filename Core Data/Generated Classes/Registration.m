//
//  Registration.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Registration.h"
#import "Accommodation.h"
#import "IomOffice.h"
#import "RegistrationBioData.h"
#import "RegistrationBiometric.h"
#import "RegistrationInterception.h"


@implementation Registration
@synthesize failureHandler;
@synthesize successHandler;
@synthesize onProgress;
@dynamic registrationId;
@dynamic dateCreated;
@dynamic unhcrDocument;
@dynamic unhcrNumber;
@dynamic captureDevice;
@dynamic underIOMCare;
@dynamic selfReporting;
//@dynamic skipFinger;
@dynamic transferDate;
@dynamic complete;
@dynamic vulnerability;
@dynamic associatedOffice;
@dynamic interceptionData;
@dynamic bioData;
@dynamic biometric;
@dynamic transferDestination;
@dynamic detentionLocation;
@dynamic detentionLocationName;
//@dynamic transferId;

@end
