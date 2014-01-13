//
//  Registration.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Accommodation, IomOffice, RegistrationBioData, RegistrationBiometric, RegistrationInterception;

@interface Registration : NSManagedObject

@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSString * unhcrDocument;
@property (nonatomic, retain) NSString * unhcrNumber;
@property (nonatomic, retain) NSString * captureDevice;
@property (nonatomic, retain) NSNumber * underIOMCare;
@property (nonatomic, retain) NSDate * transferDate;
@property (nonatomic, retain) NSNumber * complete;
@property (nonatomic, retain) NSString * vulnerability;
@property (nonatomic, retain) IomOffice *associatedOffice;
@property (nonatomic, retain) RegistrationInterception *interceptionData;
@property (nonatomic, retain) RegistrationBioData *bioData;
@property (nonatomic, retain) RegistrationBiometric *biometric;
@property (nonatomic, retain) Accommodation *transferDestination;

@end
