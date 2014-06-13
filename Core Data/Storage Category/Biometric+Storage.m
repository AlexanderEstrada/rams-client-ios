//
//  Biometric+Storage.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/21/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Biometric+Storage.h"

@implementation Biometric (Storage)

+ (NSString *)photograpDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [cachesPath stringByAppendingPathComponent:@"Photograph"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)leftIndexTemplateDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"FTemplates"] stringByAppendingPathComponent:@"LeftIndex"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)rightIndexTemplateDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"FTemplates"] stringByAppendingPathComponent:@"RightIndex"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)leftThumbTemplateDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"FTemplates"] stringByAppendingPathComponent:@"LeftThumb"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)rightThumbTemplateDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"FTemplates"] stringByAppendingPathComponent:@"RightThumb"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)leftIndexImageDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"FImages"] stringByAppendingPathComponent:@"LeftIndex"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)rightIndexImageDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"FImages"] stringByAppendingPathComponent:@"RightIndex"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}
                     
+ (NSString *)leftThumbImageDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"FImages"] stringByAppendingPathComponent:@"LeftThumb"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)rightThumbImageDir
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"FImages"] stringByAppendingPathComponent:@"RightThumb"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

- (void)updatePhotographData:(NSData *)photographData
{
    NSString *dir = [Biometric photograpDir];
    self.photograph = [self writeData:photographData toPath:[dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", self.biometricId]]];
}

- (void)updatePhotographFromBase64String:(NSString *)base64PhotographString
{
    if (!base64PhotographString) self.photograph = nil;
    else [self updatePhotographData:[[NSData alloc] initWithBase64EncodedString:base64PhotographString options:0]];
}

- (void)updateTemplateFromBase64String:(NSString *)base64String forFingerPosition:(FingerPosition)position
{
    
    @try {
        if (!base64String) {
            switch (position) {
                case RightIndex:
                    self.rightIndexTemplate = Nil;
                    break;
                case RightThumb:
                    self.rightThumbTemplate = Nil;
                    break;
                case LeftIndex:
                    self.leftIndexTemplate = Nil;
                    break;
                case LeftThumb:
                    self.leftThumbTemplate = Nil;
                    break;
                    
                default:
                    break;
            }
        }
        else
        {
        NSData *templateData = nil;
        templateData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
            [self updateTemplateWithData:templateData forFingerPosition:position];
        }
        
    }
    @catch (NSException *exception) {
    NSLog(@"Exception while creating updateTemplateFromBase64String: \n%@", [exception description]);
    }
    
    
}

- (void)updateTemplateWithData:(NSData *)templateData forFingerPosition:(FingerPosition)position
{
    NSString *templatePath;
    NSString *templateName = [NSString stringWithFormat:@"%@.xyt", self.biometricId];
    
    switch (position) {
        case RightIndex:
            templatePath = [[Biometric rightIndexTemplateDir] stringByAppendingPathComponent:templateName];
            self.rightIndexTemplate = [self writeData:templateData toPath:templatePath];
            break;
        case RightThumb:
            templatePath = [[Biometric rightThumbTemplateDir] stringByAppendingPathComponent:templateName];
            self.rightThumbTemplate = [self writeData:templateData toPath:templatePath];
            break;
        case LeftIndex:
            templatePath = [[Biometric leftIndexTemplateDir] stringByAppendingPathComponent:templateName];
            self.leftIndexTemplate = [self writeData:templateData toPath:templatePath];
            break;
        case LeftThumb:
            templatePath = [[Biometric leftThumbTemplateDir] stringByAppendingPathComponent:templateName];
            self.leftThumbTemplate = [self writeData:templateData toPath:templatePath];
            break;
    }
}

- (void)updateFingerImageFromBase64String:(NSString *)base64String forFingerPosition:(FingerPosition)position
{
   
    @try {
        if (base64String == Nil) {
            switch (position) {
                case RightIndex:
                    self.rightIndexImage = Nil;
                    break;
                case RightThumb:
                    self.rightThumbImage = Nil;
                    break;
                case LeftIndex:
                    self.leftIndexImage = Nil;
                    break;
                case LeftThumb:
                    self.leftThumbImage = Nil;
                    break;
                    
                default:
                    break;
            }
            
        }
        else{
                NSData *imageData = nil;
                imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
                [self updateFingerImageWithData:imageData forFingerPosition:position];
        }
    }
    @catch (NSException *exception)
    {
    NSLog(@"Exception while creating updateFingerImageFromBase64String: \n%@", [exception description]);
    }
    
    
}

- (void)updateFingerImageWithData:(NSData *)imageData forFingerPosition:(FingerPosition)position
{
    NSString *imagePath = nil;
    NSString *imageName = [NSString stringWithFormat:@"%@.jpg", self.biometricId];
    
    switch (position) {
        case RightIndex:
            imagePath = [[Biometric rightIndexImageDir] stringByAppendingPathComponent:imageName];
            self.rightIndexImage = [self writeData:imageData toPath:imagePath];
            break;
        case RightThumb:
            imagePath = [[Biometric rightThumbImageDir] stringByAppendingPathComponent:imageName];
            self.rightThumbImage = [self writeData:imageData toPath:imagePath];
            break;
        case LeftIndex:
            imagePath = [[Biometric leftIndexImageDir] stringByAppendingPathComponent:imageName];
            self.leftIndexImage = [self writeData:imageData toPath:imagePath];
            break;
        case LeftThumb:
            imagePath = [[Biometric leftThumbImageDir] stringByAppendingPathComponent:imageName];
            self.leftThumbImage = [self writeData:imageData toPath:imagePath];
            break;
    }
}

- (NSString *)writeData:(NSData *)data toPath:(NSString *)path
{
    if (!data) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
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
            file = self.rightThumbImage; break;
        case RightIndex:
            file = self.rightIndexImage; break;
        case LeftThumb:
            file = self.leftThumbImage; break;
        case LeftIndex:
            file = self.leftIndexImage; break;
    }
    
    return file ? [UIImage imageWithContentsOfFile:file] : nil;
}

- (void)deleteBiometricData
{
    NSFileManager *manager = [NSFileManager defaultManager];
    @try {
        [manager removeItemAtPath:self.photograph error:nil];
        [manager removeItemAtPath:self.leftThumbImage error:nil];
        [manager removeItemAtPath:self.leftIndexImage error:nil];
        [manager removeItemAtPath:self.rightThumbImage error:nil];
        [manager removeItemAtPath:self.rightIndexImage error:nil];
        [manager removeItemAtPath:self.leftIndexTemplate error:nil];
        [manager removeItemAtPath:self.leftThumbTemplate error:nil];
        [manager removeItemAtPath:self.rightIndexTemplate error:nil];
        [manager removeItemAtPath:self.rightThumbTemplate error:nil];
    }
    @catch (NSException *exception)
    {
    NSLog(@"Exception while creating deleteBiometricData: \n%@", [exception description]);
    }
}

@end
