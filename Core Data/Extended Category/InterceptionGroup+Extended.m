//
//  InterceptionGroup+Extended.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/14/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "InterceptionGroup+Extended.h"
#import "IMConstants.h"
#import "Country+Extended.h"
#import "InterceptionMovement+Extended.h"


@implementation InterceptionGroup (Extended)

#define kGroupId            @"id"
#define kEthnicName         @"ethnicName"
#define kEthnicCountry      @"countryOfOrigin"
#define kGroupAdult         @"adult"
#define kGroupChild         @"child"
#define kGroupMale          @"male"
#define kGroupFemale        @"female"
#define kGroupUAM           @"unaccompaniedMinor"
#define kGroupMedical       @"medicalCondition"
#define kGroupMovements     @"interceptionMovements"


+ (InterceptionGroup *)groupWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSNumber *groupId = CORE_DATA_OBJECT(dictionary[kGroupId]);
        InterceptionGroup *group = [InterceptionGroup groupWithId:groupId inManagedObjectContext:context];
        if (!group) {
            group = [NSEntityDescription insertNewObjectForEntityForName:@"InterceptionGroup" inManagedObjectContext:context];
            group.interceptionGroupId = groupId;
        }
        
        Country *country = [Country countryWithCode:dictionary[kEthnicCountry] inManagedObjectContext:context];
        group.ethnicName = dictionary[kEthnicName];
        group.originCountry = country;
        
        group.adult = CORE_DATA_OBJECT(dictionary[kGroupAdult]);
        group.child = CORE_DATA_OBJECT(dictionary[kGroupChild]);
        group.male = CORE_DATA_OBJECT(dictionary[kGroupMale]);
        group.female = CORE_DATA_OBJECT(dictionary[kGroupFemale]);
        group.unaccompaniedMinor = CORE_DATA_OBJECT(dictionary[kGroupUAM]);
        group.medicalAttention = CORE_DATA_OBJECT(dictionary[kGroupMedical]);
        
        NSArray *interceptionMovements = dictionary[kGroupMovements];
        NSMutableSet *newMovements = [NSMutableSet set];
        for (NSDictionary *interceptionMovementDict in interceptionMovements) {
            InterceptionMovement *movement = [InterceptionMovement movementWithDictionary:interceptionMovementDict inManagedObjectContext:context];
            movement.interceptionGroup = group;
            [newMovements addObject:movement];
        }
        
        //remove deleted movements
        NSMutableSet *oldMovements = [group.interceptionMovements mutableCopy];
        [oldMovements minusSet:newMovements];
        [group removeInterceptionMovements:oldMovements];
        
        return group;
    }
    @catch (NSException *exception) {
        NSLog(@"Failed parsing InterceptionGroup : %@\nException: %@", dictionary, [exception description]);
    }
    
    return nil;
}

+ (InterceptionGroup *)groupWithId:(NSNumber *)groupId inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"InterceptionGroup"];
        request.predicate = [NSPredicate predicateWithFormat:@"interceptionGroupId = %@", groupId];
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", [exception description]);
    }
    
    return nil;
}

- (BOOL)isInterceptionMovementExists:(InterceptionMovement *)movement
{
    NSSet *filtered = [self.interceptionMovements filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"interceptionMovementId = %@", movement.interceptionMovementId]];
    
    return [filtered count] > 0;
}


#pragma mark Transients Properties
- (int)currentAdult
{
    int movements = [[self.interceptionMovements valueForKeyPath:@"@sum.adult"] intValue];
    int current = self.adult.intValue - movements;
    return current >= 0 ? current : 0;
}

- (int)currentChildren
{
    int movements = [[self.interceptionMovements valueForKeyPath:@"@sum.child"] intValue];
    int current = self.child.intValue - movements;
    return current >= 0 ? current : 0;
}

- (int)currentMale
{
    int movements = [[self.interceptionMovements valueForKeyPath:@"@sum.male"] intValue];
    int current = self.male.intValue - movements;
    return current >= 0 ? current : 0;
}

- (int)currentFemale
{
    int movements = [[self.interceptionMovements valueForKeyPath:@"@sum.female"] intValue];
    int current = self.female.intValue - movements;
    return current >= 0 ? current : 0;
}

- (int)currentUAM
{
    int movements = [[self.interceptionMovements valueForKeyPath:@"@sum.unaccompaniedMinor"] intValue];
    int current = self.unaccompaniedMinor.intValue - movements;
    return current >= 0 ? current : 0;
}

- (int)currentMedicalAttention
{
    int movements = [[self.interceptionMovements valueForKeyPath:@"@sum.medicalAttention"] intValue];
    int current = self.medicalAttention.intValue - movements;
    return current >= 0 ? current : 0;
}

- (int)currentPopulationByAgeGroup
{
    return [self currentAdult] + [self currentChildren];
}

- (int)currentPopulationByGender
{
    return [self currentMale] + [self currentFemale];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@, %@", self.ethnicName, self.originCountry.name];
}

- (NSString *)stringGroupPopulation
{
    return [NSString stringWithFormat:@"%i Adult, %i Children", self.currentAdult, self.currentChildren];
}

- (BOOL)validateForSubmission
{
    return ([self currentPopulationByAgeGroup] == [self currentPopulationByGender]) && [self.ethnicName length] && self.originCountry;
}

- (NSDictionary *)prepareForSubmission
{
    if (![self validateForSubmission]) return nil;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.interceptionGroupId.intValue) [dict setObject:self.interceptionGroupId forKey:kGroupId];
    
    [dict setObject:self.ethnicName forKey:kEthnicName];
    [dict setObject:self.originCountry.code forKey:kEthnicCountry];
    [dict setObject:self.adult forKey:kGroupAdult];
    [dict setObject:self.child forKey:kGroupChild];
    [dict setObject:self.male forKey:kGroupMale];
    [dict setObject:self.female forKey:kGroupFemale];
    [dict setObject:self.unaccompaniedMinor forKey:kGroupUAM];
    [dict setObject:self.medicalAttention forKey:kGroupMedical];
    
    if ([self.interceptionMovements count]) {
        NSMutableArray *movements = [NSMutableArray array];
        
        for (InterceptionMovement *movement in self.interceptionMovements) {
            [movements addObject:[movement prepareForSubmission]];
        }
        
        [dict setObject:movements forKey:kGroupMovements];
    }
    
    return dict;
}

@end
