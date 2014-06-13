//
//  RegistrationProfile.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 9/24/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface RegistrationProfile : NSManagedObject

@property (nonatomic, retain) NSString * accommodationId;
@property (nonatomic, retain) NSString * cityOfBirth;
@property (nonatomic, retain) NSString * countryOfBirthCountryCode;
@property (nonatomic, retain) NSDate * dateOfEntry;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSDate * interceptionDate;
@property (nonatomic, retain) NSString * interceptionLocation;
@property (nonatomic, retain) NSString * iomOfficeName;
@property (nonatomic, retain) NSString * maritalStatus;
@property (nonatomic, retain) NSString * nationalityCountryCode;
@property (nonatomic, retain) NSString * profileName;

@end
