//
//  Movement+Extended.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Movement+Extended.h"
#import "IMConstants.h"
#import "NSDate+Relativity.h"
#import "Port+Extended.h"
#import "Country+Extended.h"
#import "Accommodation+Extended.h"

@implementation Movement (Extended)

NSString *const MOVEMENT_ENTITY_NAME                            = @"Movement";
NSString *const MOVEMENT_ID                                     = @"movementId";
NSString *const MOVEMENT_TYPE                                   = @"type";
NSString *const MOVEMENT_DATE                                   = @"date";
NSString *const MOVEMENT_DATE_OLD                               = @"movementDate";
NSString *const MOVEMENT_DOCUMENT_NUMBER                        = @"documentNumber";
NSString *const MOVEMENT_PROPOSED_DATE                          = @"proposedDate";
NSString *const MOVEMENT_TRAVEL_MODE                            = @"travelMode";
NSString *const MOVEMENT_REFERENCE_CODE                         = @"referenceCode";
NSString *const MOVEMENT_DEPARTURE_PORT                         = @"departurePort";
NSString *const MOVEMENT_ORIGINAL_LOCATION                      = @"origin";
NSString *const MOVEMENT_TRANSFER_LOCATION                      = @"destination";
NSString *const MOVEMENT_DESTINATION_COUNTRY                    = @"destinationCountry";
NSString *const MOVEMENT_DETENTION_LOCATION                    = @"detentionLocation";





- (NSDictionary *)format
{
    @try {
        NSMutableDictionary *formatted = [NSMutableDictionary dictionary];
        
        
        //save type
        [formatted setObject:self.type forKey:MOVEMENT_TYPE];
        //save date
        [formatted setObject:[self.date toUTCString] forKey:MOVEMENT_DATE_OLD];
        
        //save movement id
        if (self.movementId) {
            [formatted setObject:self.movementId forKey:MOVEMENT_ID];
        }
        
        
        if (![self.type isEqual:MOVEMENT_TYPE_ESCAPE] && ![self.type isEqual:MOVEMENT_TYPE_RELEASE] && ![self.type isEqual:MOVEMENT_TYPE_DECEASE]) {
            //document number
            if (self.documentNumber) {
                [formatted setObject:self.documentNumber forKey:MOVEMENT_DOCUMENT_NUMBER];
            }
            
            //proposed date
            if (self.proposedDate) {
                [formatted setObject:[self.proposedDate toUTCString]forKey:MOVEMENT_PROPOSED_DATE];
            }
            
            //travel mode
            if (self.travelMode) {
                [formatted setObject:self.travelMode forKey:MOVEMENT_TRAVEL_MODE];
            }
            
            //reference code
            if (self.referenceCode) {
                [formatted setObject:self.referenceCode forKey:MOVEMENT_REFERENCE_CODE];
            }
            
            //departure port
            if (self.departurePort.name) {
                [formatted setObject:self.departurePort.name forKey:MOVEMENT_DEPARTURE_PORT];
            }
            
            if ([self.type isEqual:MOVEMENT_TYPE_TRANSFER]) {
                //origin
                if (self.originLocation.accommodationId) {
                    [formatted setObject:self.originLocation.accommodationId forKey:MOVEMENT_ORIGINAL_LOCATION];
                }
                
                //destination
                if (self.transferLocation.accommodationId) {
                    [formatted setObject:self.transferLocation.accommodationId forKey:MOVEMENT_TRANSFER_LOCATION];
                }
                
            }
            
            if ([self.type isEqual:MOVEMENT_TYPE_AVR] || [self.type isEqual:MOVEMENT_TYPE_DEPORTATION] || [self.type isEqual:MOVEMENT_TYPE_RESETTLEMENT]) {
                //destination country
                if (self.destinationCountry.code) {
                    [formatted setObject:self.destinationCountry.code forKey:MOVEMENT_DESTINATION_COUNTRY];
                }
                
            }
            
        }else {
                if (self.originLocation.accommodationId) {
                    [formatted setObject:self.originLocation.accommodationId forKey:MOVEMENT_DETENTION_LOCATION];
                }
        }
        
        return formatted;
        
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while creating formatted Movement data: %@", [exception description]);
    }
    return Nil;
}
+ (Movement *)movementWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    @try {
        NSString *Id = [dictionary objectForKey:@"id"];
        Movement *data = [Movement movementWithId:Id inContext:context];
        if (!data) {
            data = [Movement newMovementInContext:context];
            data.movementId = Id;
        }
        data.type = [dictionary objectForKey:MOVEMENT_TYPE];
        data.date = [NSDate dateFromUTCString:[dictionary objectForKey:MOVEMENT_DATE]];
        if (![data.type isEqual:MOVEMENT_TYPE_ESCAPE] && ![data.type isEqual:MOVEMENT_TYPE_RELEASE] && ![data.type isEqual:MOVEMENT_TYPE_DECEASE]) {
            data.documentNumber = CORE_DATA_OBJECT([dictionary objectForKey:MOVEMENT_DOCUMENT_NUMBER]);
            data.proposedDate = [NSDate dateFromUTCString:[dictionary objectForKey:MOVEMENT_PROPOSED_DATE]];
            data.travelMode = CORE_DATA_OBJECT([dictionary objectForKey:MOVEMENT_TRAVEL_MODE]);
            data.referenceCode = CORE_DATA_OBJECT([dictionary objectForKey:MOVEMENT_REFERENCE_CODE]);
            data.departurePort = [Port portWithName:[dictionary objectForKey:MOVEMENT_DEPARTURE_PORT] inManagedObjectContext:context];
            if ([data.type isEqual:MOVEMENT_TYPE_TRANSFER]) {
                data.originLocation = [Accommodation accommodationWithId:[dictionary objectForKey:MOVEMENT_ORIGINAL_LOCATION] inManagedObjectContext:context];
                data.transferLocation = [Accommodation accommodationWithId:[dictionary objectForKey:MOVEMENT_TRANSFER_LOCATION] inManagedObjectContext:context];
            }else{
                data.originLocation = Nil;
                data.transferLocation = Nil;
            }
            
            if ([data.type isEqual:MOVEMENT_TYPE_AVR] || [data.type isEqual:MOVEMENT_TYPE_DEPORTATION] || [data.type isEqual:MOVEMENT_TYPE_RESETTLEMENT]) {
                
                data.destinationCountry = [Country countryWithCode:[dictionary objectForKey:MOVEMENT_DESTINATION_COUNTRY] inManagedObjectContext:context];
            }else if ([data.type isEqual:MOVEMENT_TYPE_RELEASE] && [dictionary objectForKey:MOVEMENT_DETENTION_LOCATION]){
                 data.originLocation = [Accommodation accommodationWithId:[dictionary objectForKey:MOVEMENT_DETENTION_LOCATION] inManagedObjectContext:context];
            }else{
                data.destinationCountry = nil;
            }
            
        }else{
            if ([dictionary objectForKey:MOVEMENT_DETENTION_LOCATION]) {
                data.originLocation = [Accommodation accommodationWithId:[dictionary objectForKey:MOVEMENT_DETENTION_LOCATION] inManagedObjectContext:context];
                data.documentNumber = nil;
                data.proposedDate = Nil;
                data.travelMode = Nil;
                data.referenceCode = Nil;
                data.departurePort = Nil;
                data.transferLocation = Nil;
                data.destinationCountry = nil;
            }else {
                data.documentNumber = nil;
                data.proposedDate = Nil;
                data.travelMode = Nil;
                data.referenceCode = Nil;
                data.departurePort = Nil;
                data.originLocation = Nil;
                data.transferLocation = Nil;
                data.destinationCountry = nil;
            }
        }
        return data;
    }
    @catch (NSException *exception) {
        return Nil;
    }
}
+ (Movement *)movementWithId:(NSString *)movementId inContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:MOVEMENT_ENTITY_NAME];
        request.predicate = [NSPredicate predicateWithFormat:@"movementId = %@", movementId];
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception) {
        return nil;
    }
}
+ (Movement *)newMovementInContext:(NSManagedObjectContext *)context
{
    @try {
        Movement *data = [NSEntityDescription insertNewObjectForEntityForName:MOVEMENT_ENTITY_NAME inManagedObjectContext:context];
        //        Port *port = [NSEntityDescription insertNewObjectForEntityForName:@"Port" inManagedObjectContext:context];
        //        Country * country = [NSEntityDescription insertNewObjectForEntityForName:@"Country" inManagedObjectContext:context];
        //        Accommodation * origin= [NSEntityDescription insertNewObjectForEntityForName:@"Accommodation" inManagedObjectContext:context];
        //        Accommodation * transfer= [NSEntityDescription insertNewObjectForEntityForName:@"Accommodation" inManagedObjectContext:context];
        //save data
        //        data.departurePort = port;
        //        data.destinationCountry = country;
        //        data.originLocation = origin;
        //        data.transferLocation = transfer;
        
        return data;
    }
    @catch (NSException *exception) {
        NSLog(@"Error : %@",[exception description]);
        return Nil;
    }
    
    
}

@end
