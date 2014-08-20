//
//  FamilyRegister+Extended.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 8/18/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "FamilyRegister.h"

@interface FamilyRegister (Extended)

+ (FamilyRegister *)familyRegisterWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;
+ (FamilyRegister *)familyRegisterWithId:(NSString *)familyId inContext:(NSManagedObjectContext *)context;
+ (FamilyRegister *)newFamilyRegisterInContext:(NSManagedObjectContext *)context;

- (NSDictionary *)format;
- (UIImage *)photographImageThumbnail;
- (UIImage *)photographImage;

@end
