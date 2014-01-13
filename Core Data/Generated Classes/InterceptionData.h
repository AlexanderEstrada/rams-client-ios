//
//  InterceptionData.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 9/4/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ImmigrationOfficer, InterceptionGroup, InterceptionLocation, IomOffice, IomOfficer, Photo, PoliceOfficer;

@interface InterceptionData : NSManagedObject

@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSDate * expectedMovementDate;
@property (nonatomic, retain) NSNumber * interceptionDataId;
@property (nonatomic, retain) NSDate * interceptionDate;
@property (nonatomic, retain) NSString * issues;
@property (nonatomic, retain) ImmigrationOfficer *immigrationOfficer;
@property (nonatomic, retain) NSSet *interceptionGroups;
@property (nonatomic, retain) InterceptionLocation *interceptionLocation;
@property (nonatomic, retain) IomOffice *iomOffice;
@property (nonatomic, retain) IomOfficer *iomOfficer;
@property (nonatomic, retain) NSSet *photos;
@property (nonatomic, retain) PoliceOfficer *policeOfficer;
@end

@interface InterceptionData (CoreDataGeneratedAccessors)

- (void)addInterceptionGroupsObject:(InterceptionGroup *)value;
- (void)removeInterceptionGroupsObject:(InterceptionGroup *)value;
- (void)addInterceptionGroups:(NSSet *)values;
- (void)removeInterceptionGroups:(NSSet *)values;

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

@end
