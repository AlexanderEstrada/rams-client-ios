//
//  Photo+Extended.h
//  Interceptions
//
//  Created by Mario Yohanes on 4/25/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Photo.h"
#import "Photo+Storage.h"

@interface Photo (Extended)

extern NSString *const PHOTO_ENTITY_NAME;
extern NSString *const PHOTO_FILENAME;
extern NSString *const PHOTO_CAPTION;

+ (Photo *)photoWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Photo *)photoWithId:(NSString *)photoId inManagedObjectContext:(NSManagedObjectContext *)context;

- (NSDictionary *)format;

@end
