//
//  InterceptionMovement+Extended.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/14/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "InterceptionMovement+Extended.h"
#import "IMConstants.h"
#import "Accommodation+Extended.h"
#import "NSDate+Relativity.h"


@implementation InterceptionMovement (Extended)


#define kMovementType           @"type"
#define kMovementId             @"id"
#define kMovementDate           @"date"
#define kMovementDestination    @"destination"
#define kMovementMale           @"male"
#define kMovementFemale         @"female"
#define kMovementAdult          @"adult"
#define kMovementChild          @"child"
#define kMovementUAM            @"unaccompaniedMinor"
#define kMovementMedical        @"medicalCondition"


+ (InterceptionMovement *)movementWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSNumber *movementId = CORE_DATA_OBJECT(dictionary[kMovementId]);
        InterceptionMovement *movement = [InterceptionMovement movementWithId:movementId inManagedObjectContext:context];
        if (!movement) {
            movement = [NSEntityDescription insertNewObjectForEntityForName:@"InterceptionMovement" inManagedObjectContext:context];
            movement.interceptionMovementId = movementId;
        }
        
        NSString *movementDateString = CORE_DATA_OBJECT(dictionary[kMovementDate]);
        movement.date = [NSDate dateFromUTCString:movementDateString];
        
        NSDictionary *locationDict = CORE_DATA_OBJECT(dictionary[kMovementDestination]);
        Accommodation *location = [Accommodation accommodationWithDictionary:locationDict inManagedObjectContext:context];
        movement.transferLocation = location;
        movement.type = CORE_DATA_OBJECT(dictionary[kMovementType]);
        movement.male = CORE_DATA_OBJECT(dictionary[kMovementMale]);
        movement.female = CORE_DATA_OBJECT(dictionary[kMovementFemale]);
        movement.adult = CORE_DATA_OBJECT(dictionary[kMovementAdult]);
        movement.child = CORE_DATA_OBJECT(dictionary[kMovementChild]);
        movement.unaccompaniedMinor = CORE_DATA_OBJECT(dictionary[kMovementUAM]);
        movement.medicalAttention = CORE_DATA_OBJECT(dictionary[kMovementMedical]);
        
        return movement;
    }
    @catch (NSException *exception) {
        NSLog(@"Error parsing InterceptionMovement: %@\nException: %@", dictionary, [exception description]);
    }
    
    return nil;
}

+ (InterceptionMovement *)movementWithId:(NSNumber *)movementId inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"InterceptionMovement"];
        request.predicate = [NSPredicate predicateWithFormat:@"interceptionMovementId = %@", movementId];
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", [exception description]);
    }
    
    return nil;
}

- (BOOL)validateForSubmission
{
    int ageGroup = [self.adult intValue] + [self.child intValue];
    int gender = [self.male intValue] + [self.female intValue];
    BOOL populationValid = ageGroup == gender;
    return self.date && self.transferLocation && populationValid;
}

- (NSDictionary *)prepareForSubmission
{
    if (![self validateForSubmission]) return nil;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.interceptionMovementId.intValue) [dict setObject:self.interceptionMovementId forKey:kMovementId];
    
    [dict setObject:[self.date toUTCString] forKey:kMovementDate];
    if (self.transferLocation) [dict setObject:self.transferLocation.accommodationId forKey:kMovementDestination];
    [dict setObject:self.adult forKey:kMovementAdult];
    [dict setObject:self.child forKey:kMovementChild];
    [dict setObject:self.male forKey:kMovementMale];
    [dict setObject:self.female forKey:kMovementFemale];
    [dict setObject:self.unaccompaniedMinor forKey:kMovementUAM];
    [dict setObject:self.medicalAttention forKey:kMovementMedical];
    
    return dict;
}

+ (NSArray *)movementTypes
{
    return @[@"Deceased", @"Deportation", @"Escape", @"Released", @"Transfer"];
}

@end