//
//  PoliceOfficer+Extended.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/26/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "PoliceOfficer.h"

@interface PoliceOfficer (Extended)

extern NSString *const PO_ENTITY_NAME;
extern NSString *const PO_ID;
extern NSString *const PO_NAME;
extern NSString *const PO_PHONE;

+ (PoliceOfficer *)officerWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context;
+ (PoliceOfficer *)officerWithId:(NSNumber *)officerId inManagedObjectContext:(NSManagedObjectContext *)context;
- (NSDictionary *)prepareForSubmission;

@end