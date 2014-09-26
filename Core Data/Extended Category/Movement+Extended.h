//
//  Movement+Extended.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Movement.h"


#define MOVEMENT_TYPE_ESCAPE @"Escape"
#define MOVEMENT_TYPE_RELEASE @"Release"
#define MOVEMENT_TYPE_DECEASE @"Decease"
#define MOVEMENT_TYPE_TRANSFER @"Transfer"
#define MOVEMENT_TYPE_AVR @"AVR"
#define MOVEMENT_TYPE_DEPORTATION @"Deportation"
#define MOVEMENT_TYPE_RESETTLEMENT @"Resettlement"


@interface Movement (Extended)

+ (Movement *)movementWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;
+ (Movement *)movementWithId:(NSString *)movementId inContext:(NSManagedObjectContext *)context;
+ (Movement *)newMovementInContext:(NSManagedObjectContext *)context;

- (NSDictionary *)format;

@end
