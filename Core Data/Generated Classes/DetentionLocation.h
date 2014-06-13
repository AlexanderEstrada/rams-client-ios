//
//  DetentionLocation.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/14/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class InterceptionMovement, Movement, Photo;

@interface DetentionLocation : NSManagedObject

@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSNumber * accommodationId;
@property (nonatomic, retain) NSNumber * familyCapacity;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * singleCapacity;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *interceptionMovements;
@property (nonatomic, retain) NSSet *movementOrigins;
@property (nonatomic, retain) NSSet *movementTransfers;
@property (nonatomic, retain) NSSet *photos;
@end

@interface DetentionLocation (CoreDataGeneratedAccessors)

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
