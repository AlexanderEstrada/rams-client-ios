//
//  Registration.h
//  RAMS Client
//
//  Created by IOM Jakarta on 10/8/14.
//  Copyright (c) 2014 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


typedef void (^IMRegistrationUploadSuccessHandler)(void);
typedef void (^IMRegistrationUploadSuccessHandlerAndCode)(int statusCode);
typedef void (^IMRegistrationUploadFailureHandler)(NSError *error);
typedef void (^IMRegistrationUploadFailureHandlerAndErrCode)(NSError *error,int statusCode);
typedef void (^IMRegistrationUploadOnProgress)(void);

@class Accommodation, IomOffice, RegistrationBioData, RegistrationBiometric, RegistrationInterception;

@interface Registration : NSManagedObject

@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSString * captureDevice;
@property (nonatomic, retain) NSNumber * complete;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSString * detentionLocation;
@property (nonatomic, retain) NSString * detentionLocationName;
@property (nonatomic, retain) NSString * registrationId;
@property (nonatomic, retain) NSNumber * selfReporting;
@property (nonatomic, retain) NSNumber * skipFinger;
@property (nonatomic, retain) NSDate * transferDate;
@property (nonatomic, retain) NSString * transferId;
@property (nonatomic, retain) NSNumber * underIOMCare;
@property (nonatomic, retain) NSString * unhcrDocument;
@property (nonatomic, retain) NSString * unhcrNumber;
@property (nonatomic, retain) NSString * vulnerability;
@property (nonatomic, retain) NSString * backupName;
@property (nonatomic, retain) IomOffice *associatedOffice;
@property (nonatomic, retain) RegistrationBioData *bioData;
@property (nonatomic, retain) RegistrationBiometric *biometric;
@property (nonatomic, retain) RegistrationInterception *interceptionData;
@property (nonatomic, retain) Accommodation *transferDestination;

@property (nonatomic, copy) IMRegistrationUploadSuccessHandler successHandler;
@property (nonatomic, copy) IMRegistrationUploadSuccessHandlerAndCode successHandlerAndCode;
@property (nonatomic, copy) IMRegistrationUploadFailureHandler failureHandler;
@property (nonatomic, copy) IMRegistrationUploadFailureHandlerAndErrCode failureHandlerAndCode;
@property (nonatomic, copy) IMRegistrationUploadOnProgress onProgress;

@end
