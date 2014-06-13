//
//  InterceptionMovement+Extended.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/14/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "InterceptionMovement.h"

@interface InterceptionMovement (Extended)

+ (InterceptionMovement *)movementWithId:(NSNumber *)movementId inManagedObjectContext:(NSManagedObjectContext *)context;
+ (InterceptionMovement *)movementWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context;

- (BOOL)validateForSubmission;
- (NSDictionary *)prepareForSubmission;

+ (NSArray *)movementTypes;

@end