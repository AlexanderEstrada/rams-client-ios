//
//  Port+Extended.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 12/7/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import "Port.h"

@interface Port (Extended)

+ (Port *)portWithDictionary:(NSDictionary *)dictionary
      inManagedObjectContext:(NSManagedObjectContext *)context;

+ (Port *)portWithName:(NSString *)portName
      inManagedObjectContext:(NSManagedObjectContext *)context;

+ (BOOL)validatePortDictionary:(NSDictionary *)dictionary;

@end