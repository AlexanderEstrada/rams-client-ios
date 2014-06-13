//
//  RegistrationBiometric+Storage.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "RegistrationBiometric+Storage.h"
#import "Registration.h"



@implementation RegistrationBiometric (Storage)

+ (NSString *)photograpDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"Registration"] stringByAppendingPathComponent:@"Photograph"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)leftIndexImageDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"Registration"] stringByAppendingPathComponent:@"LeftIndex"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)rightIndexImageDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"Registration"] stringByAppendingPathComponent:@"RightIndex"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)leftThumbImageDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"Registration"] stringByAppendingPathComponent:@"LeftThumb"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)rightThumbImageDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"Registration"] stringByAppendingPathComponent:@"RightThumb"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

- (NSData *)photographData
{
    return self.photograph ? [[NSData alloc] initWithContentsOfFile:self.photograph] : nil;
}

- (UIImage *)photographImage
{
    return self.photograph ? [UIImage imageWithContentsOfFile:self.photograph] : nil;
}

- (UIImage *)fingerImageForPosition:(FingerPosition)position
{
    NSString *file;
    
    switch (position) {
        case RightThumb:
            file = self.rightThumb; break;
        case RightIndex:
            file = self.rightIndex; break;
        case LeftThumb:
            file = self.leftThumb; break;
        case LeftIndex:
            file = self.leftIndex; break;
    }
    
    return file ? [UIImage imageWithContentsOfFile:file] : nil;
}

- (void)deleteBiometricData:(FingerPosition)position
{
    NSFileManager *manager = [NSFileManager defaultManager];
    @try {
    switch (position) {
        case RightThumb:
            [manager removeItemAtPath:self.rightThumb error:nil]; break;
        case RightIndex:
            [manager removeItemAtPath:self.rightIndex error:nil]; break;
        case LeftThumb:
            [manager removeItemAtPath:self.leftThumb error:nil]; break;
        case LeftIndex:
            [manager removeItemAtPath:self.leftIndex error:nil]; break;
        default:
            break;
    }
    }
    @catch (NSException *exception)
    {
         NSLog(@"Exception while deleteBiometricData by FingerPosition : %u - description : %@", position,[exception description]);
        
    }
}
- (void)deleteBiometricData
{
    NSFileManager *manager = [NSFileManager defaultManager];
    @try {
        [manager removeItemAtPath:self.photograph error:nil];
        [manager removeItemAtPath:self.leftThumb error:nil];
        [manager removeItemAtPath:self.leftIndex error:nil];
        [manager removeItemAtPath:self.rightThumb error:nil];
        [manager removeItemAtPath:self.rightIndex error:nil];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception while creating deleteBiometricData: \n%@", [exception description]);

    }
}

- (NSString *)base64Photograph
{
    return self.photograph ? [self.photographData base64EncodedStringWithOptions:0] : nil;
}

- (NSString *)base64FingerImageWithPosition:(FingerPosition)position
{
    NSString *file;
   
    
    switch (position) {
        case RightThumb:
            file = self.rightThumb; break;
        case RightIndex:
            file = self.rightIndex; break;
        case LeftThumb:
            file = self.leftThumb; break;
        case LeftIndex:
            file = self.leftIndex; break;
    }
//    if (file != Nil) {
//        [LibBase64 initialize];
//        UIImage*image = [[self fingerImageForPosition:position] mutableCopy];
//        NSData * data = [UIImageJPEGRepresentation(image, 1.0f) mutableCopy];
//        return  [LibBase64 encode:data];
//    }else return Nil;

    return file ? [[NSData dataWithContentsOfFile:file] base64EncodedStringWithOptions:0] : nil;
}

- (void)updatePhotographData:(NSData *)photographData
{
    if (!self.registration.dateCreated) {
        NSException *exception = [NSException exceptionWithName:@"NullPointerException" reason:@"Field dateCreated on Registration cannot be nil." userInfo:nil];
        @throw exception;
        return;
    }
    
    NSString *identifier = [NSString stringWithFormat:@"%f", [self.registration.dateCreated timeIntervalSince1970]];
    NSString *dir = [RegistrationBiometric photograpDir];
    self.photograph = [self writeData:photographData toPath:[dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]]];
}

- (void)updateFingerImageWithData:(NSData *)imageData forFingerPosition:(FingerPosition)position
{
    if (!self.registration.dateCreated) {
        NSException *exception = [NSException exceptionWithName:@"NullPointerException" reason:@"Field dateCreated on Registration cannot be nil." userInfo:nil];
        @throw exception;
        return;
    }
    
    NSString *identifier = [NSString stringWithFormat:@"%f", [self.registration.dateCreated timeIntervalSince1970]];
    NSString *imagePath = nil;
    NSString *imageName = [NSString stringWithFormat:@"%@.jpg", identifier];
    
    switch (position) {
        case RightIndex:
            imagePath = [[RegistrationBiometric rightIndexImageDir] stringByAppendingPathComponent:imageName];
            self.rightIndex = [self writeData:imageData toPath:imagePath];
            break;
        case RightThumb:
            imagePath = [[RegistrationBiometric rightThumbImageDir] stringByAppendingPathComponent:imageName];
            self.rightThumb = [self writeData:imageData toPath:imagePath];
            break;
        case LeftIndex:
            imagePath = [[RegistrationBiometric leftIndexImageDir] stringByAppendingPathComponent:imageName];
            self.leftIndex = [self writeData:imageData toPath:imagePath];
            break;
        case LeftThumb:
            imagePath = [[RegistrationBiometric leftThumbImageDir] stringByAppendingPathComponent:imageName];
            self.leftThumb = [self writeData:imageData toPath:imagePath];
            break;
    }
}

- (NSString *)writeData:(NSData *)data toPath:(NSString *)path
{
    if (!data) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:NO]) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
        return nil;
    }
    
    NSError *error;
    BOOL stat = [data writeToFile:path options:NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
    if (!stat) {
        NSLog(@"Error writing file to path: %@\nError message: %@", path, [error description]);
    }
    
    return stat ? path : nil;
}

@end