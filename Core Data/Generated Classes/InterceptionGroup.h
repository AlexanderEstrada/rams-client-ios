//
//  InterceptionGroup.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Country, InterceptionData, InterceptionMovement;

@interface InterceptionGroup : NSManagedObject

@property (nonatomic, retain) NSNumber * adult;
@property (nonatomic, retain) NSNumber * child;
@property (nonatomic, retain) NSString * ethnicName;
@property (nonatomic, retain) NSNumber * female;
@property (nonatomic, retain) NSNumber * interceptionGroupId;
@property (nonatomic, retain) NSNumber * male;
@property (nonatomic, retain) NSNumber * medicalAttention;
@property (nonatomic, retain) NSNumber * unaccompaniedMinor;
@property (nonatomic, retain) InterceptionData *interceptionData;
@property (nonatomic, retain) NSSet *interceptionMovements;
@property (nonatomic, retain) Country *originCountry;
@end

@interface InterceptionGroup (CoreDataGeneratedAccessors)

- (void)addInterceptionMovementsObject:(InterceptionMovement *)value;
- (void)removeInterceptionMovementsObject:(InterceptionMovement *)value;
- (void)addInterceptionMovements:(NSSet *)values;
- (void)removeInterceptionMovements:(NSSet *)values;

@end
