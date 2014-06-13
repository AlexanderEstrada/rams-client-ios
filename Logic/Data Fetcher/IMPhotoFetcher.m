//
//  IMPhotoFetcher.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/14/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMPhotoFetcher.h"
#import "IMConstants.h"
#import "IMDBManager.h"
#import "Photo+Extended.h"
#import "IMHTTPClient.h"

@interface IMPhotoFetcher()
{
    dispatch_queue_t photoFetcher;
}

@end


@implementation IMPhotoFetcher

- (void)fetchUpdates
{
    if (!photoFetcher) {
        photoFetcher = dispatch_queue_create("PhotoFetcher", NULL);
    }

    dispatch_async(photoFetcher, ^{
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        context.parentContext = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        
        NSError *error;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:PHOTO_ENTITY_NAME];
        NSArray *photos = [context executeFetchRequest:request error:&error];
        
        for (Photo *photo in photos) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:photo.photoPath]) {
                self.total++;
                [self downloadPhoto:photo];
            }
        }
        
        if (self.total == 0) [self postFinished];
    });
}

- (void)downloadPhoto:(Photo *)photo
{
    NSString *photoId = photo.photoId;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        IMHTTPClient *client = [IMHTTPClient sharedClient];
        [client getPhotoWithId:photoId
                       success:^(NSData *imageData){
                           NSError *error;
                           BOOL stat = [imageData writeToFile:[[Photo photosDir] stringByAppendingPathComponent:photoId]
                                                      options:NSDataWritingFileProtectionCompleteUnlessOpen
                                                        error:&error];
                           if (!stat) {
                               NSLog(@"Error writing photo data: %@", [error description]);
                           }
                           
                           self.progress++;
                           if (self.progress == self.total) [self postFinished];
                       } failure:^(NSError *error){
                           self.progress++;
                           if (self.progress == self.total) [self postFinished];
                           NSLog(@"Failed downloading image: %@", [error description]);
                       }];
    });
}

@end