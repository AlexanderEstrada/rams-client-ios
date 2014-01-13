//
//  InterceptionLocation+Extended.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/14/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "InterceptionLocation+Extended.h"
#import "IMConstants.h"


@implementation InterceptionLocation (Extended)

#define kLocationName                   @"name"
#define kLocationLocality               @"locality"
#define kLocationAdministrativeArea     @"administrativeArea"
#define kLocationLatitude               @"latitude"
#define kLocationLongitude              @"longitude"
#define kLocationId                     @"id"


+ (InterceptionLocation *)locationWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSNumber *locationId = CORE_DATA_OBJECT(dictionary[kLocationId]);
        InterceptionLocation *location = [InterceptionLocation locationWithId:locationId inManagedObjectContext:context];
        
        if (!location) {
            location = [NSEntityDescription insertNewObjectForEntityForName:@"InterceptionLocation" inManagedObjectContext:context];
            location.interceptionLocationId = locationId;
        }
        
        location.name = CORE_DATA_OBJECT(dictionary[kLocationName]);
        location.locality = CORE_DATA_OBJECT(dictionary[kLocationLocality]);
        location.administrativeArea = CORE_DATA_OBJECT(dictionary[kLocationAdministrativeArea]);
        location.latitude = CORE_DATA_OBJECT(dictionary[kLocationLatitude]);
        location.longitude = CORE_DATA_OBJECT(dictionary[kLocationLongitude]);
        
        return location;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", [exception description]);
    }
    
    return nil;
}

+ (InterceptionLocation *)locationWithId:(NSNumber *)locationId inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"InterceptionLocation"];
        request.predicate = [NSPredicate predicateWithFormat:@"interceptionLocationId = %@", locationId];
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", [exception description]);
    }
    
    return nil;
}

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(self.latitude.doubleValue, self.longitude.doubleValue);
}

- (BOOL)validateForSubmission
{
    return [self.name length] && [self.locality length] && [self.administrativeArea length] && (self.latitude != 0 && self.longitude != 0);
}

- (NSDictionary *)prepareForSubmission
{
    if (![self validateForSubmission]) return nil;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.interceptionLocationId.intValue) [dict setObject:self.interceptionLocationId forKey:kLocationId];
    
    [dict setObject:self.name forKey:kLocationName];
    [dict setObject:self.locality forKey:kLocationLocality];
    [dict setObject:self.administrativeArea forKey:kLocationAdministrativeArea];
    [dict setObject:self.latitude forKey:kLocationLatitude];
    [dict setObject:self.longitude forKey:kLocationLongitude];
    
    return dict;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@, %@, %@", self.name, self.locality, self.administrativeArea];
}

@end
