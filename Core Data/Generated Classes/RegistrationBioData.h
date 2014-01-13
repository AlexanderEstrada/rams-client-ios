//
//  RegistrationBioData.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Country, Registration;

@interface RegistrationBioData : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * familyName;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * maritalStatus;
@property (nonatomic, retain) NSString * placeOfBirth;
@property (nonatomic, retain) NSDate * dateOfBirth;
@property (nonatomic, retain) Country *countryOfBirth;
@property (nonatomic, retain) Registration *registration;
@property (nonatomic, retain) Country *nationality;

@end
