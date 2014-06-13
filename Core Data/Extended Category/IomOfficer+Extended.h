//
//  IomOfficer+Extended.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/20/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IomOfficer.h"

@interface IomOfficer (Extended)

extern NSString *const IOM_OFFICER_ENTITY_NAME;
extern NSString *const IOM_OFFICER_EMAIL;
extern NSString *const IOM_OFFICER_NAME;
extern NSString *const IOM_OFFICER_PHONE;

+ (NSArray *)officersInManagedObjectContext:(NSManagedObjectContext *)context;

+ (IomOfficer *)officerWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context;
+ (IomOfficer *)officerWithEmail:(NSString *)email inManagedObjectContext:(NSManagedObjectContext *)context;

- (NSDictionary *)prepareForSubmission;

@end
