//
//  Country+Extended.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/1/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Country.h"

@interface Country (Extended)

extern NSString *const COUNTRY_ENTITY_NAME;
extern NSString *const COUNTRY_CODE;
extern NSString *const COUNTRY_NAME;


+ (Country *)countryWithDictionary:(NSDictionary *)dictionary
            inManagedObjectContext:(NSManagedObjectContext *)context;

+ (Country *)countryWithCode:(NSString *)code
      inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Country *)countryWithName:(NSString *)name
      inManagedObjectContext:(NSManagedObjectContext *)context;


@end
