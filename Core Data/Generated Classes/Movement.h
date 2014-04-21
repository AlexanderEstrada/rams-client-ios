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
@property (nonatomic, retain) NSString * documentNumber;//all exclude escape
@property (nonatomic, retain) NSString * movementId;
@property (nonatomic, retain) NSDate * proposedDate; //all exclude escape
@property (nonatomic, retain) NSString * travelMode; //all exclude escape
@property (nonatomic, retain) NSString * referenceCode; //all exclude escape
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Port *departurePort; // all exclude escape
@property (nonatomic, retain) Country *destinationCountry; //AVR , Deportation, Resettlement
@property (nonatomic, retain) Migrant *migrant;
@property (nonatomic, retain) Accommodation *originLocation; // transfer
@property (nonatomic, retain) Accommodation *transferLocation;// transfer

@end
