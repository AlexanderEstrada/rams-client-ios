//
//  Allowance+Extended.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 12/11/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import "Allowance.h"

@interface Allowance (Extended)

+ (Allowance *)allowanceFromDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Allowance *)allowanceWithId:(NSNumber *)allowanceId inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSArray *)allowancesFromArrayDictionary:(NSArray *)arrayDictionary inManagedObjectContext:(NSManagedObjectContext *)context;
+ (BOOL)validateAllowanceDictionary:(NSDictionary *)dictionary;

@end