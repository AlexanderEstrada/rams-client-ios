//
//  InterceptionData+Extended.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/14/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "InterceptionData+Extended.h"
#import "IMConstants.h"
#import "NSDate+Relativity.h"
#import "UIImage+ImageUtils.h"
#import "InterceptionMovement+Extended.h"


@implementation InterceptionData (Extended)

#define kInterceptionId                 @"id"
#define kInterceptionIssues             @"issues"
#define kInterceptionDate               @"interceptionDate"
#define kInterceptionExpected           @"expectedMovementDate"
#define kInterceptionIOMOffice          @"associatedOffice"
#define kInterceptionLocation           @"interceptionLocation"
#define kInterceptionIOMOfficer         @"iomOfficer"
#define kInterceptionImmigrationOfficer @"immigrationOfficer"
#define kInterceptionPoliceOfficer      @"policeOfficer"
#define kInterceptionGroups             @"interceptionGroups"
#define kInterceptionPhotos             @"photos"
#define kInterceptionActive             @"active"


+ (InterceptionData *)dataWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSNumber *dataId = CORE_DATA_OBJECT(dictionary[kInterceptionId]);
        InterceptionData *data = [InterceptionData dataWithId:dataId inManagedObjectContext:context];
        
        if (!data) {
            data = [NSEntityDescription insertNewObjectForEntityForName:@"InterceptionData" inManagedObjectContext:context];
            data.interceptionDataId = dataId;
        }
        
        NSString *interceptionDateString = CORE_DATA_OBJECT(dictionary[kInterceptionDate]);
        data.interceptionDate = [NSDate dateFromUTCString:interceptionDateString];
        
        NSString *expectedMovementDateString = CORE_DATA_OBJECT(dictionary[kInterceptionExpected]);
        data.expectedMovementDate = [NSDate dateFromUTCString:expectedMovementDateString];
        
        data.iomOffice = [IomOffice officeWithDictionary:CORE_DATA_OBJECT(dictionary[kInterceptionIOMOffice]) inManagedObjectContext:context];
        data.interceptionLocation = [InterceptionLocation locationWithDictionary:CORE_DATA_OBJECT(dictionary[kInterceptionLocation]) inManagedObjectContext:context];
        data.iomOfficer = [IomOfficer officerWithDictionary:CORE_DATA_OBJECT(dictionary[kInterceptionIOMOfficer]) inManagedObjectContext:context];
        data.immigrationOfficer = [ImmigrationOfficer officerWithDictionary:CORE_DATA_OBJECT(dictionary[kInterceptionImmigrationOfficer]) inManagedObjectContext:context];
        data.policeOfficer = [PoliceOfficer officerWithDictionary:CORE_DATA_OBJECT(dictionary[kInterceptionPoliceOfficer]) inManagedObjectContext:context];
        data.issues = CORE_DATA_OBJECT(dictionary[kInterceptionIssues]);
        data.active = CORE_DATA_OBJECT(dictionary[kInterceptionActive]);
        
        //manage groups
        NSMutableSet *newGroups = [NSMutableSet set];
        NSArray *groupDicts = dictionary[kInterceptionGroups];
        for (NSDictionary *groupDict in groupDicts) {
            InterceptionGroup *group = [InterceptionGroup groupWithDictionary:groupDict inManagedObjectContext:context];
            if (group) {
                group.interceptionData = data;
                [newGroups addObject:group];
            }
        }
        
        //remove deleted interception groups
        NSMutableSet *oldGroups = [data.interceptionGroups mutableCopy];
        [oldGroups minusSet:newGroups];
        [data removeInterceptionGroups:oldGroups];
        if (CORE_DATA_OBJECT(dictionary[kInterceptionPhotos])) {
            //manage photos
            NSMutableSet *newPhotos = [NSMutableSet set];
            NSArray *photos = dictionary[kInterceptionPhotos];
            for (NSDictionary *photoDict in photos) {
                Photo *photo = [Photo photoWithDictionary:photoDict inManagedObjectContext:context];
                if (photo) {
                    photo.interceptionData = data;
                    [newPhotos addObject:photo];
                }
            }
            
            //remove deleted photos
            NSMutableSet *oldPhotos = [data.photos mutableCopy];
            [oldPhotos minusSet:newPhotos];
            [data removePhotos:oldPhotos];
        }
        //if active, recheck status
        if (data.active.boolValue) data.active = @(data.currentPopulation > 0);
        
        return data;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", [exception description]);
    }
    
    return nil;
}

+ (InterceptionData *)dataWithId:(NSNumber *)dataId inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"InterceptionData"];
        request.predicate = [NSPredicate predicateWithFormat:@"interceptionDataId = %@", dataId];
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", [exception description]);
    }
    
    return nil;
}

- (BOOL)isInterceptionGroupExists:(InterceptionGroup *)group
{
    NSSet *filtered = [self.interceptionGroups filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"interceptionGroupId = %@", group.interceptionGroupId]];
    return [filtered count] > 0;
}

- (InterceptionGroup *)interceptionGroupWithName:(NSString *)name countryCode:(NSString *)countryCode
{
    for (InterceptionGroup *group in self.interceptionGroups) {
        if ( (name && [group.ethnicName isEqualToString:name]) || (countryCode && [group.originCountry.code isEqualToString:countryCode]) ) {
            return group;
        }
    }
    
    return nil;
}


#pragma mark Transients Properties
- (NSInteger)currentPopulation
{
    return self.currentAdult + self.currentChildren;
}

- (NSInteger)currentAdult
{
    return [[self.interceptionGroups valueForKeyPath:@"@sum.currentAdult"] intValue];
}

- (NSInteger)currentChildren
{
    return [[self.interceptionGroups valueForKeyPath:@"@sum.currentChildren"] intValue];
}

- (NSInteger)currentMale
{
    return [[self.interceptionGroups valueForKeyPath:@"@sum.currentMale"] intValue];
}

- (NSInteger)currentFemale
{
    return [[self.interceptionGroups valueForKeyPath:@"@sum.currentFemale"] intValue];
}

- (NSInteger)currentUAM
{
    return [[self.interceptionGroups valueForKeyPath:@"@sum.currentUAM"] intValue];
}

- (NSInteger)currentMedicalAttention
{
    return [[self.interceptionGroups valueForKeyPath:@"@sum.currentMedicalAttention"] intValue];
}

- (NSInteger)totalAdult;

{
    return [[self.interceptionGroups valueForKeyPath:@"@sum.adult"] intValue];
}

- (NSInteger)totalChildren
{
    return [[self.interceptionGroups valueForKeyPath:@"@sum.child"] intValue];
}

- (NSInteger)totalMale
{
    return [[self.interceptionGroups valueForKeyPath:@"@sum.male"] intValue];
}

- (NSInteger)totalFemale
{
    return [[self.interceptionGroups valueForKeyPath:@"@sum.female"] intValue];
}

- (NSInteger)totalUAM
{
    return [[self.interceptionGroups valueForKeyPath:@"@sum.unaccompaniedMinor"] intValue];
}

- (NSInteger)totalMedicalAttention
{
    return [[self.interceptionGroups valueForKeyPath:@"@sum.medicalAttention"] intValue];
}

- (NSInteger)totalTransferred
{
    return [self countMovementWithType:@"Transfer"];
}

- (NSInteger)totalEscaped
{
    return [self countMovementWithType:@"Escape"];
}

- (NSInteger)totalDeported
{
    return [self countMovementWithType:@"Deportation"];
}

- (NSInteger)countMovementWithType:(NSString *)type
{
    int count = 0;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type = %@", type];
    
    for (InterceptionGroup *group in self.interceptionGroups) {
        for (InterceptionMovement *movement in [group.interceptionMovements filteredSetUsingPredicate:predicate]) {
            count += movement.male.intValue;
            count += movement.female.intValue;
        }
    }
    
    return count;
}


#pragma mark Submission Validation
- (BOOL)validateForSubmission
{
    return self.interceptionDate && self.interceptionLocation && self.iomOffice && self.iomOfficer && self.immigrationOfficer && [self.interceptionGroups count];
}

- (NSDictionary *)prepareForSubmissionWithPhotos:(NSArray *)photos
{
    if (![self validateForSubmission]) return nil;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (self.interceptionDataId.intValue) [dict setObject:self.interceptionDataId forKey:kInterceptionId];
    
    [dict setObject:[self.interceptionDate toUTCString] forKey:kInterceptionDate];
    if (self.expectedMovementDate) [dict setObject:[self.expectedMovementDate toUTCString] forKey:kInterceptionExpected];
    
    [dict setObject:self.iomOffice.name forKey:kInterceptionIOMOffice];
    [dict setObject:self.interceptionLocation.interceptionLocationId forKey:kInterceptionLocation];
    [dict setObject:[self.iomOfficer prepareForSubmission] forKey:kInterceptionIOMOfficer];
    [dict setObject:[self.immigrationOfficer prepareForSubmission] forKey:kInterceptionImmigrationOfficer];
    if (self.policeOfficer) [dict setObject:[self.policeOfficer prepareForSubmission] forKey:kInterceptionPoliceOfficer];
    if (self.issues) [dict setObject:self.issues forKey:kInterceptionIssues];
    
    NSMutableArray *groups = [NSMutableArray array];
    for (InterceptionGroup *group in self.interceptionGroups) {
        [groups addObject:[group prepareForSubmission]];
    }
    [dict setObject:groups forKey:kInterceptionGroups];
    
    //photos
    NSMutableArray *photoDicts = [NSMutableArray array];
    
    for (NSDictionary *photoDict in photos) {
        NSMutableDictionary *photo = [NSMutableDictionary dictionary];
        
        if (photoDict[@"photoId"]) {
            [photo setObject:photoDict[@"photoId"] forKey:@"id"];
        }else {
            UIImage *image = photoDict[@"image"];
            NSData *jpeg = [image scaledJPEGRepresentationToWidth:2048 compression:0.8];
            NSString *base64 = [jpeg base64EncodedStringWithOptions:0];
            [photo setObject:base64 forKey:@"photo"];
        }
        
        [photoDicts addObject:photo];
    }
    [dict setObject:photoDicts forKey:kInterceptionPhotos];
    
    return dict;
}

@end