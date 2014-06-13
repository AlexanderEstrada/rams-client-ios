//
//  Photo+Extended.m
//  Interceptions
//
//  Created by Mario Yohanes on 4/25/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Photo+Extended.h"
#import "IMConstants.h"


@implementation Photo (Extended)

NSString *const PHOTO_ENTITY_NAME       = @"Photo";
NSString *const PHOTO_FILENAME          = @"filename";
NSString *const PHOTO_CAPTION           = @"caption";

+ (Photo *)photoWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context
{
    @try {
        NSString *photoId = CORE_DATA_OBJECT([dictionary objectForKey:PHOTO_FILENAME]);
        
        Photo *photo = [Photo photoWithId:photoId inManagedObjectContext:context];
        if (!photo) {
            photo = [NSEntityDescription insertNewObjectForEntityForName:PHOTO_ENTITY_NAME inManagedObjectContext:context];
        }
        
        photo.photoId = photoId;
        
        return photo;
    }
    @catch (NSException *exception) {
        NSLog(@"Error creating Photo: %@", [exception description]);
        return nil;
    }
}

+ (Photo *)photoWithId:(NSString *)photoId inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photo *photo = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO_ENTITY_NAME];
    request.predicate = [NSPredicate predicateWithFormat:@"photoId = %@", photoId];
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    photo = [results lastObject];
    
    return photo;
}

- (NSDictionary *)format
{
    return @{PHOTO_FILENAME:self.photoId};
}

@end