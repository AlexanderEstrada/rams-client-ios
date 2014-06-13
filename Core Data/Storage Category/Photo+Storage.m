//
//  Photo+Storage.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/21/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Photo+Storage.h"

@implementation Photo (Storage)

NSString *const PHOTO_CACHE_DIR_NAME    = @"Photos";

+ (NSString *)photosDir
{
    NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *dir = [url.path stringByAppendingPathComponent:PHOTO_CACHE_DIR_NAME];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

- (NSString *)photoPath
{
    return [[Photo photosDir] stringByAppendingPathComponent:self.photoId];
}

- (UIImage *)photoImage
{
    return [UIImage imageWithContentsOfFile:self.photoPath];
}

- (NSData *)photoData
{
    return [[NSData alloc] initWithContentsOfFile:self.photoPath];
}

- (void)updatePhotoFromBase64String:(NSString *)base64String
{
    NSData *photoData = nil;
    @try {
        photoData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception while creating updatePhotoFromBase64String: \n%@", [exception description]);

    }
    
    [self updatePhotoWithData:photoData];
}

- (void)updatePhotoWithData:(NSData *)photoData
{
    if (!photoData) {
        [self deletePhoto];
        return;
    }
    
    NSError *error;
    BOOL stat = [photoData writeToFile:self.photoPath options:NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
    if (!stat) {
        NSLog(@"Error writing photo data: %@", [error description]);
    }
}

- (void)deletePhoto
{
    [[NSFileManager defaultManager] removeItemAtPath:self.photoPath error:nil];
}

@end
