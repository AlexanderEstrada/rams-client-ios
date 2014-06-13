//
//  FamilyData+Extended.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "FamilyData.h"

@interface FamilyData (Extended)

+ (FamilyData *)familyWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;
+ (FamilyData *)familyWithFatherId:(NSString *)fatherId inContext:(NSManagedObjectContext *)context;


@end
