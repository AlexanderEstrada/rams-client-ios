//
//  Movement.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/21/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Accommodation, Country, Migrant, Port;

@interface Movement : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * documentNumber;
@property (nonatomic, retain) NSNumber * movementId;
@property (nonatomic, retain) NSDate * proposedDate;
@property (nonatomic, retain) NSString * travelMode;
@property (nonatomic, retain) NSString * referenceCode;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Port *departurePort;
@property (nonatomic, retain) Country *destinationCountry;
@property (nonatomic, retain) Migrant *migrant;
@property (nonatomic, retain) Accommodation *originLocation;
@property (nonatomic, retain) Accommodation *transferLocation;

@end
