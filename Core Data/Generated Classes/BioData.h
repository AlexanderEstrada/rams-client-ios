//
//  BioData.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 31/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Country, Migrant;

@interface BioData : NSManagedObject

@property (nonatomic, retain) NSString * alias;
@property (nonatomic, retain) NSString * cityOfBirth;
@property (nonatomic, retain) NSDate * dateOfBirth;
@property (nonatomic, retain) NSString * familyName;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * maritalStatus;
@property (nonatomic, retain) Migrant *migrant;
@property (nonatomic, retain) Country *nationality;
@property (nonatomic, retain) Country *countryOfBirth;

@end
