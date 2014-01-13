//
//  ImmigrationOfficer+Extended.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/20/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "ImmigrationOfficer.h"

@interface ImmigrationOfficer (Extended)

extern NSString *const IMMI_ENTITY_NAME;
extern NSString *const IMMI_ID;
extern NSString *const IMMI_NAME;
extern NSString *const IMMI_PHONE;


+ (ImmigrationOfficer *)officerWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context;
+ (ImmigrationOfficer *)officerWithId:(NSNumber *)officerId inManagedObjectContext:(NSManagedObjectContext *)context;
- (NSDictionary *)prepareForSubmission;

@end