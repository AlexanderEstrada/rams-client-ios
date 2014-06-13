//
//  InterceptionLocation+Extended.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/14/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "InterceptionLocation.h"
#import <CoreLocation/CoreLocation.h>

@interface InterceptionLocation (Extended)

+ (InterceptionLocation *)locationWithId:(NSNumber *)locationId inManagedObjectContext:(NSManagedObjectContext *)context;
+ (InterceptionLocation *)locationWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context;

- (CLLocationCoordinate2D)coordinate;

- (BOOL)validateForSubmission;
- (NSDictionary *)prepareForSubmission;

@end
