//
//  Accommodation.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 9/24/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class InterceptionMovement, Movement, Photo;

@interface Accommodation : NSManagedObject

@property (nonatomic, retain) NSString * accommodationId;
@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSNumber * familyCapacity;
@property (nonatomic, retain) NSNumber * familyOccupancy;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * singleCapacity;
@property (nonatomic, retain) NSNumber * singleOccupancy;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *interceptionMovements;
@property (nonatomic, retain) NSSet *movementOrigins;
@property (nonatomic, retain) NSSet *movementTransfers;
@property (nonatomic, retain) NSSet *photos;
@end

@interface Accommodation (CoreDataGeneratedAccessors)

- (void)addInterceptionMovementsObject:(InterceptionMovement *)value;
- (void)removeInterceptionMovementsObject:(InterceptionMovement *)value;
- (void)addInterceptionMovements:(NSSet *)values;
- (void)removeInterceptionMovements:(NSSet *)values;

- (void)addMovementOriginsObject:(Movement *)value;
- (void)removeMovementOriginsObject:(Movement *)value;
- (void)addMovementOrigins:(NSSet *)values;
- (void)removeMovementOrigins:(NSSet *)values;

- (void)addMovementTransfersObject:(Movement *)value;
- (void)removeMovementTransfersObject:(Movement *)value;
- (void)addMovementTransfers:(NSSet *)values;
- (void)removeMovementTransfers:(NSSet *)values;

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

@end
