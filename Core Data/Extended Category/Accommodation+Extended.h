//
//  Accommodation+Extended.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/14/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "Accommodation.h"


@interface Accommodation (Extended)

extern NSString *const ACC_ENTITY_NAME;
extern NSString *const ACC_ID;
extern NSString *const ACC_ACTIVE;
extern NSString *const ACC_NAME;
extern NSString *const ACC_ADDRESS;
extern NSString *const ACC_TYPE;
extern NSString *const ACC_CITY;
extern NSString *const ACC_LATITUDE;
extern NSString *const ACC_LONGITUDE;
extern NSString *const ACC_SINGLE_CAPACITY;
extern NSString *const ACC_FAMILY_CAPACITY;
extern NSString *const ACC_SINGLE_OCCCUPANCY;
extern NSString *const ACC_FAMILY_OCCCUPANCY;
extern NSString *const ACC_PHOTOS;


+ (Accommodation *)accommodationWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Accommodation *)accommodationWithId:(NSString *)locationName inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Accommodation *)accommodationWithName:(NSString *)locationId inManagedObjectContext:(NSManagedObjectContext *)context;
+ (BOOL)validateLocationDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)format;

@end
