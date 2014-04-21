//
//  Interception+Extended.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Interception.h"


@interface Interception (Extended)

+ (Interception *)interceptionWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;
+ (Interception *)interceptionWithDictionary:(NSDictionary *)dictionary withMigrantId:(NSString*)migrantId inContext:(NSManagedObjectContext *)context;
+ (Interception *)interceptionWithId:(NSString *)interceptionId inContext:(NSManagedObjectContext *)context;
+ (Interception *)newInterceptionInContext:(NSManagedObjectContext *)context;

@end
