//
//  InterceptionMovement.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/26/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Accommodation, InterceptionGroup;

@interface InterceptionMovement : NSManagedObject

@property (nonatomic, retain) NSNumber * adult;
@property (nonatomic, retain) NSNumber * child;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * female;
@property (nonatomic, retain) NSNumber * interceptionMovementId;
@property (nonatomic, retain) NSNumber * male;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * unaccompaniedMinor;
@property (nonatomic, retain) NSNumber * medicalAttention;
@property (nonatomic, retain) InterceptionGroup *interceptionGroup;
@property (nonatomic, retain) Accommodation *transferLocation;

@end
