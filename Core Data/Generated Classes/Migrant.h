//
//  Migrant.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/21/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BioData, Biometric, FamilyData, Interception, IomData, Movement,Accommodation;

@interface Migrant : NSManagedObject

@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSNumber * blacklist;
@property (nonatomic, retain) NSNumber * deceased;
@property (nonatomic, retain) NSString * registrationNumber;
@property (nonatomic, retain) NSString * unhcrDocument;
@property (nonatomic, retain) NSString * unhcrNumber;
@property (nonatomic, retain) NSString * unhcrStatus;
@property (nonatomic, retain) NSString * uploader;
@property (nonatomic, retain) NSString * lastUploader;
@property (nonatomic, retain) NSString * vulnerabilityStatus;
@property (nonatomic, retain) NSNumber * underIOMCare;
@property (nonatomic, retain) NSNumber * selfReporting;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) BioData *bioData;
@property (nonatomic, retain) Biometric *biometric;
@property (nonatomic, retain) FamilyData *familyData;
@property (nonatomic, retain) NSSet *interceptions;
@property (nonatomic, retain) IomData *iomData;
@property (nonatomic, retain) NSSet *movements;
@property (nonatomic, retain) NSString *detentionLocation;
@property (nonatomic, retain) NSString *detentionLocationName;
@property (nonatomic, retain) NSNumber * complete;
@end

@interface Migrant (CoreDataGeneratedAccessors)

- (void)addInterceptionsObject:(Interception *)value;
- (void)removeInterceptionsObject:(Interception *)value;
- (void)addInterceptions:(NSSet *)values;
- (void)removeInterceptions:(NSSet *)values;

- (void)addMovementsObject:(Movement *)value;
- (void)removeMovementsObject:(Movement *)value;
- (void)addMovements:(NSSet *)values;
- (void)removeMovements:(NSSet *)values;

@end
