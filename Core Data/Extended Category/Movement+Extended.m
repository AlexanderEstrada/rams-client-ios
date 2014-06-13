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


+ (Movement *)movementWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    @try {
        NSString *Id = [dictionary objectForKey:@"id"];
        Movement *data = [Movement movementWithId:Id inContext:context];
        if (!data) {
            data = [Movement newMovementInContext:context];
            data.movementId = Id;
        }
        data.date = [NSDate dateFromUTCString:[dictionary objectForKey:@"interceptionDate"]];
        data.type = [dictionary objectForKey:@"type"];
        if (![data.type isEqual:@"Escape"]) {
            data.documentNumber = CORE_DATA_OBJECT([dictionary objectForKey:@"documentNumber"]);
            data.proposedDate = [NSDate dateFromUTCString:[dictionary objectForKey:@"proposedDate"]];
            data.travelMode = CORE_DATA_OBJECT([dictionary objectForKey:@"travelMode"]);
            data.referenceCode = CORE_DATA_OBJECT([dictionary objectForKey:@"referenceCode"]);
            data.departurePort = [Port portWithName:[dictionary objectForKey:@"departurePort"] inManagedObjectContext:context];
            if ([data.type isEqual:@"Transfer"]) {
                data.originLocation = [Accommodation accommodationWithId:[dictionary objectForKey:@"origin"] inManagedObjectContext:context];
                data.transferLocation = [Accommodation accommodationWithId:[dictionary objectForKey:@"destination"] inManagedObjectContext:context];
                data.date = [NSDate dateFromUTCString:[dictionary objectForKey:@"date"]];
            }else{
                data.originLocation = Nil;
                data.transferLocation = Nil;
            }
            
            if ([data.type isEqual:@"AVR"] || [data.type isEqual:@"Deportation"] || [data.type isEqual:@"Resettlement"]) {
                
                data.destinationCountry = [Country countryWithCode:[dictionary objectForKey:@"destinationCountry"] inManagedObjectContext:context];
            }else{
                data.destinationCountry = nil;
            }
            
        }else{
            data.documentNumber = nil;
            data.proposedDate = Nil;
            data.travelMode = Nil;
            data.referenceCode = Nil;
            data.departurePort = Nil;
            data.originLocation = Nil;
            data.transferLocation = Nil;
            data.destinationCountry = nil;
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
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Movement"];
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
    Movement *data = [NSEntityDescription insertNewObjectForEntityForName:@"Movement" inManagedObjectContext:context];
    
    
    return data;
}

@end
