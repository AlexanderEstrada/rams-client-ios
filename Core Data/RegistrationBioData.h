//
//  RegistrationBioData.h
//  RAMS Client
//
//  Created by IOM Jakarta on 10/8/14.
//  Copyright (c) 2014 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Country, Registration;

@interface RegistrationBioData : NSManagedObject

@property (nonatomic, retain) NSDate * dateOfBirth;
@property (nonatomic, retain) NSString * familyName;
@property (nonatomic, retain) NSString * fatherName;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * maritalStatus;
@property (nonatomic, retain) NSString * motherName;
@property (nonatomic, retain) NSString * placeOfBirth;
@property (nonatomic, retain) Country *countryOfBirth;
@property (nonatomic, retain) Country *nationality;
@property (nonatomic, retain) Registration *registration;

@end
