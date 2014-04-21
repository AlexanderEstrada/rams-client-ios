//
//  Country.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 31/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BioData, InterceptionGroup, Movement, RegistrationBioData;

@interface Country : NSManagedObject

@property (nonatomic, retain) NSString * code;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *bioDatas;
@property (nonatomic, retain) NSSet *interceptionGroups;
@property (nonatomic, retain) NSSet *movements;
@property (nonatomic, retain) RegistrationBioData *registrationCountryOfBirth;
@property (nonatomic, retain) RegistrationBioData *registrationNationality;
@property (nonatomic, retain) NSSet *bioDatasCountryOfBirth;
@end

@interface Country (CoreDataGeneratedAccessors)

- (void)addRegistrationBioDatasObject:(RegistrationBioData *)value;
- (void)removeRegistrationBioDatasObject:(RegistrationBioData *)value;
- (void)addBioDatasObject:(BioData *)value;
- (void)removeBioDatasObject:(BioData *)value;
- (void)addBioDatas:(NSSet *)values;
- (void)removeBioDatas:(NSSet *)values;

- (void)addInterceptionGroupsObject:(InterceptionGroup *)value;
- (void)removeInterceptionGroupsObject:(InterceptionGroup *)value;
- (void)addInterceptionGroups:(NSSet *)values;
- (void)removeInterceptionGroups:(NSSet *)values;

- (void)addMovementsObject:(Movement *)value;
- (void)removeMovementsObject:(Movement *)value;
- (void)addMovements:(NSSet *)values;
- (void)removeMovements:(NSSet *)values;

- (void)addBioDatasCountryOfBirthObject:(BioData *)value;
- (void)removeBioDatasCountryOfBirthObject:(BioData *)value;
- (void)addRegistrationCountryOfBirthObject:(RegistrationBioData *)value;
- (void)removeRegistrationCountryOfBirthObject:(RegistrationBioData *)value;
- (void)addBioDatasCountryOfBirth:(NSSet *)values;
- (void)removeBioDatasCountryOfBirth:(NSSet *)values;

@end
