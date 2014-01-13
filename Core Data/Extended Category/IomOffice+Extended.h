//
//  IomOffice+Extended.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 12/7/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import "IomOffice.h"

@interface IomOffice (Extended)

+ (IomOffice *)officeWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context;
+ (IomOffice *)officeWithName:(NSString *)officeName inManagedObjectContext:(NSManagedObjectContext *)context;

+ (BOOL)validateOfficeDictionary:(NSDictionary *)dictionary;

+ (NSArray *)officeNamesInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSArray *)officesInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
