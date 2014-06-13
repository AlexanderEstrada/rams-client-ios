//
//  Photo+Storage.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/21/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Photo.h"

@interface Photo (Storage)

+ (NSString *)photosDir;

- (NSString *)photoPath;
- (UIImage *)photoImage;
- (NSData *)photoData;

- (void)updatePhotoFromBase64String:(NSString *)base64String;
- (void)updatePhotoWithData:(NSData *)photoData;
- (void)deletePhoto;

@end
