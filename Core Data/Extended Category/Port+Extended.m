//
//  Port+Extended.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 12/7/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import "Port+Extended.h"
#import "IMConstants.h"

@implementation Port (Extended)

#define kPortName       @"name"
#define kPortCity       @"city"
#define kPortProvince   @"province"
#define kPortEntityName @"Port"


+ (Port *)portWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context{
    if (![Port validatePortDictionary:dictionary]) return nil;
    
    Port *port;
    
    @try {
        NSString *portName = CORE_DATA_OBJECT([dictionary objectForKey:kPortName]);
        port = [Port portWithName:portName inManagedObjectContext:context];
        
        if (!port) {
            port = [NSEntityDescription insertNewObjectForEntityForName:kPortEntityName
                                                 inManagedObjectContext:context];
            port.name = portName;
        }
        
        port.name = CORE_DATA_OBJECT([dictionary objectForKey:kPortName]);
        port.city = CORE_DATA_OBJECT([dictionary objectForKey:kPortCity]);
        port.province = CORE_DATA_OBJECT([dictionary objectForKey:kPortProvince]);
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while creating Port: %@", [exception description]);
        return nil;
    }
    
    return port;
}

+ (Port *)portWithName:(NSString *)portName inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kPortEntityName];
        request.predicate = [NSPredicate predicateWithFormat:@"name = %@", portName];
        
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception while creating portWithName: \n%@", [exception description]);

    }
    
    return nil;
}

+ (BOOL)validatePortDictionary:(NSDictionary *)dictionary{
    return dictionary && [dictionary objectForKey:kPortCity] && [dictionary objectForKey:kPortName] && [dictionary objectForKey:kPortProvince];
}

- (NSString *)description{
    return self.name;
}

@end
