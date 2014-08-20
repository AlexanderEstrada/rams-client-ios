//
//  FamilyRegisterEntry+Extended.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 8/18/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "FamilyRegisterEntry.h"

@interface FamilyRegisterEntry (Extended)

+ (FamilyRegisterEntry *)familyRegisterEntryWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;
+ (FamilyRegisterEntry *)familyRegisterEntryWithId:(NSString *)familyEntryId inContext:(NSManagedObjectContext *)context;
+ (FamilyRegisterEntry *)newFamilyRegisterEntryInContext:(NSManagedObjectContext *)context;

- (NSDictionary *)format;

@end
