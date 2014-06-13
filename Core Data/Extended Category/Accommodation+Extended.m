//
//  Accommodation+Extended.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/14/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "Accommodation+Extended.h"
#import "Photo+Extended.h"
#import "IMConstants.h"


@implementation Accommodation (Extended)

/** Constants for import/export from and to JSON */

NSString *const ACC_ENTITY_NAME          = @"Accommodation";
NSString *const ACC_ID                   = @"id";
NSString *const ACC_ACTIVE               = @"active";
NSString *const ACC_NAME                 = @"location";
NSString *const ACC_ADDRESS              = @"address";
NSString *const ACC_TYPE                 = @"type";
NSString *const ACC_CITY                 = @"city";
NSString *const ACC_LATITUDE             = @"latitude";
NSString *const ACC_LONGITUDE            = @"longitude";
NSString *const ACC_SINGLE_CAPACITY      = @"singleCapacity";
NSString *const ACC_FAMILY_CAPACITY      = @"familyCapacity";
NSString *const ACC_SINGLE_OCCCUPANCY    = @"singleOccupancy";
NSString *const ACC_FAMILY_OCCCUPANCY    = @"familyOccupancy";
NSString *const ACC_PHOTOS               = @"photos";


+ (Accommodation *)accommodationWithDictionary:(NSDictionary *)dictionary
                       inManagedObjectContext:(NSManagedObjectContext *)context
{
    if (![Accommodation validateLocationDictionary:dictionary]) return nil;
    
    @try {
        NSString *locationId = CORE_DATA_OBJECT([dictionary objectForKey:ACC_ID]);
        Accommodation *dt = [Accommodation accommodationWithId:locationId inManagedObjectContext:context];
        
        if (!dt) {
            dt = [NSEntityDescription insertNewObjectForEntityForName:ACC_ENTITY_NAME
                                               inManagedObjectContext:context];
            dt.accommodationId = locationId;
        }
        
        dt.type = CORE_DATA_OBJECT([dictionary objectForKey:ACC_TYPE]);
        dt.name = CORE_DATA_OBJECT([dictionary objectForKey:ACC_NAME]);
        dt.address = CORE_DATA_OBJECT([dictionary objectForKey:ACC_ADDRESS]);
        dt.city = CORE_DATA_OBJECT([dictionary objectForKey:ACC_CITY]);;
        dt.latitude = CORE_DATA_OBJECT([dictionary objectForKey:ACC_LATITUDE]);
        dt.longitude = CORE_DATA_OBJECT([dictionary objectForKey:ACC_LONGITUDE]);
        dt.singleCapacity = CORE_DATA_OBJECT([dictionary objectForKey:ACC_SINGLE_CAPACITY]);
        dt.familyCapacity = CORE_DATA_OBJECT([dictionary objectForKey:ACC_FAMILY_CAPACITY]);
        dt.singleOccupancy = CORE_DATA_OBJECT(dictionary[ACC_SINGLE_OCCCUPANCY]);
        dt.familyOccupancy = CORE_DATA_OBJECT(dictionary[ACC_FAMILY_OCCCUPANCY]);
        dt.active = CORE_DATA_OBJECT(dictionary[ACC_ACTIVE]);
        
        [dt updatePhotos:[dictionary objectForKey:ACC_PHOTOS]];
        
        return dt;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while creating Detention Location: %@", [exception description]);
    }
    
    return nil;
}

+ (Accommodation *)accommodationWithId:(NSString *)locationId
               inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ACC_ENTITY_NAME];
        request.predicate = [NSPredicate predicateWithFormat:@"accommodationId = %@", locationId];
        
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:request error:&error];
//        NSLog(@"error : %@",[error description]);
        return [results lastObject];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception while accommodationWithId : %@", [exception description]);
    }
    
    return nil;
}

+ (BOOL)validateLocationDictionary:(NSDictionary *)dictionary
{
    return dictionary && [dictionary objectForKey:ACC_ID] && [dictionary objectForKey:ACC_NAME] && [dictionary objectForKey:ACC_TYPE];
}

- (void)updatePhotos:(NSArray *)photosDict
{
    @try {
        NSMutableSet *existingPhotos = [self.photos mutableCopy];
        NSMutableSet *newPhotos = [NSMutableSet set];
        
        for(NSDictionary *photoDict in photosDict) {
            Photo *photo = [Photo photoWithDictionary:photoDict inManagedObjectContext:self.managedObjectContext];
            [self addPhotosObject:photo];
            [newPhotos addObject:photo];
        }
        
        [existingPhotos minusSet:newPhotos];
        for (Photo *photo in existingPhotos) {
            [photo deletePhoto];
            [self removePhotosObject:photo];
            [self.managedObjectContext deleteObject:photo];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while updating accommodation photos: %@,\ndictionary: %@\nError Message: %@", self.name, photosDict, [exception description]);
    }
}

- (NSDictionary *)format
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (self.accommodationId) [dict setObject:self.accommodationId forKey:ACC_ID];
    [dict setObject:self.name forKey:ACC_NAME];
    if (self.address) [dict setObject:self.address forKey:ACC_ADDRESS];
    [dict setObject:self.city forKey:ACC_CITY];
    [dict setObject:self.type forKey:ACC_TYPE];
    [dict setObject:self.active forKey:ACC_ACTIVE];
    
    if (self.latitude) [dict setObject:self.latitude forKey:ACC_LATITUDE];
    if (self.longitude) [dict setObject:self.longitude forKey:ACC_LONGITUDE];
    if (self.singleCapacity) [dict setObject:self.singleCapacity forKey:ACC_SINGLE_CAPACITY];
    if (self.familyCapacity) [dict setObject:self.familyCapacity forKey:ACC_FAMILY_CAPACITY];
    
    NSMutableArray *photos = [NSMutableArray array];
    for (Photo *photo in self.photos) {
        [photos addObject:[photo format]];
    }
    
    [dict setObject:photos forKey:ACC_PHOTOS];
    
    return dict;
}

- (NSString *)description
{
    return self.name;
}

@end