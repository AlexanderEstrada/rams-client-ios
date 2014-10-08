//
//  RegistrationBiometric+Storage.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "RegistrationBiometric+Storage.h"
#import "Registration.h"
#import "UIImage+ImageUtils.h"



@implementation RegistrationBiometric (Storage)

@dynamic isMigrant;

+ (NSString *)photograpDir
{
//    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
     NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"Registration"] stringByAppendingPathComponent:@"Photograph"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)photograpThumbnailDir
{
//    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
     NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"Registration"] stringByAppendingPathComponent:@"PhotographThumbnail"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}



+ (NSString *)leftIndexImageDir
{
//    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
     NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"Registration"] stringByAppendingPathComponent:@"LeftIndex"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)rightIndexImageDir
{
//    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
     NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"Registration"] stringByAppendingPathComponent:@"RightIndex"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)leftThumbImageDir
{
//    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
     NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"Registration"] stringByAppendingPathComponent:@"LeftThumb"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

+ (NSString *)rightThumbImageDir
{
//    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
     NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [[cachesPath stringByAppendingPathComponent:@"Registration"] stringByAppendingPathComponent:@"RightThumb"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

- (NSData *)photographData
{
    @try {
        //check if the path has change
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.photograph] && self.photograph) {
            //save last filename before change
            NSString * tmp = [self.photograph lastPathComponent];
            
            //case has change then update the path before show
            NSString *identifier = [NSString stringWithFormat:@"%f", [self.registration.dateCreated timeIntervalSince1970]];
            NSString *dir = [RegistrationBiometric photograpDir];
            self.photograph = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
            
            //check if this from migrant
            if (![[NSFileManager defaultManager] fileExistsAtPath:self.photograph]) {
                //case has change then update the path before show
                NSString *dir = [Biometric photograpDir];
                self.photograph = [dir stringByAppendingPathComponent:tmp];
            }
        }
        
        return self.photograph ? [[NSData alloc] initWithContentsOfFile:self.photograph] : nil;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception on RegistrationBiometric - photographData : %@",[exception description]);
    }
    return Nil;
}

- (UIImage *)photographImage
{
    @try{
        //check if the path has change
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.photograph] && self.photograph) {
            //save last filename before change
            NSString * tmp = [self.photograph lastPathComponent];
            //case has change then update the path before show
            NSString *identifier = [NSString stringWithFormat:@"%f", [self.registration.dateCreated timeIntervalSince1970]];
            NSString *dir = [RegistrationBiometric photograpDir];
            self.photograph = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
            //check if this from migrant
            if (![[NSFileManager defaultManager] fileExistsAtPath:self.photograph]) {
                //case has change then update the path before show
                NSString *dir = [Biometric photograpDir];
                self.photograph = [dir stringByAppendingPathComponent:tmp];
            }
        }
        return self.photograph ? [UIImage imageWithContentsOfFile:self.photograph] : nil;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception on RegistrationBiometric - photographImage : %@",[exception description]);
    }
    return Nil;
}

- (UIImage *)photographImageThumbnail
{
    @try {
        //check if the path has change
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.photographThumbnail] && self.photographThumbnail) {
            NSString * tmp = [self.photographThumbnail lastPathComponent];
            //case has change then update the path before show
            NSString *identifier = [NSString stringWithFormat:@"%f", [self.registration.dateCreated timeIntervalSince1970]];
            NSString *dir = [RegistrationBiometric photograpThumbnailDir];
            self.photographThumbnail = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", identifier]];
            
            //check if this from migrant
            if (![[NSFileManager defaultManager] fileExistsAtPath:self.photographThumbnail]) {
                //case has change then update the path before show
                NSString *dir = [Biometric photograpThumbnailDir];
                self.photographThumbnail = [dir stringByAppendingPathComponent:tmp];
            }
            
        }
        return self.photographThumbnail ? [UIImage imageWithContentsOfFile:self.photographThumbnail] : nil;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception on RegistrationBiometric - photographImageThumbnail : %@",[exception description]);
    }
    return Nil;
}

- (UIImage *)fingerImageForPosition:(FingerPosition)position
{
    @try{
        NSString *file;
        NSString * tmp;
        NSString *identifier = [NSString stringWithFormat:@"%f", [self.registration.dateCreated timeIntervalSince1970]];
        switch (position) {
            case RightThumb:{
                file = self.rightThumb;
                //check if the path has change
                if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
                    tmp = [file lastPathComponent];
                    //case has change then update the path before show
                    NSString *dir = [RegistrationBiometric rightThumbImageDir];
                    file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
                    
                    //check if this from migrant
                    if (![[NSFileManager defaultManager] fileExistsAtPath:self.rightThumb]) {
                        //case has change then update the path before show
                        NSString *dir = [Biometric rightThumbImageDir];
                        self.rightThumb = [dir stringByAppendingPathComponent:tmp];
                    }
                }
                break;
            }
            case RightIndex:{
                file = self.rightIndex;
                //check if the path has change
                if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
                    tmp = [file lastPathComponent];
                    
                    //case has change then update the path before show
                    NSString *dir = [RegistrationBiometric rightIndexImageDir];
                    file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
                    
                    //check if this from migrant
                    if (![[NSFileManager defaultManager] fileExistsAtPath:self.rightIndex]) {
                        //case has change then update the path before show
                        NSString *dir = [Biometric rightIndexImageDir];
                        self.rightIndex = [dir stringByAppendingPathComponent:tmp];
                    }
                    
                }
                break;
            }
            case LeftThumb:{
                file = self.leftThumb;
                //check if the path has change
                if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
                    tmp = [file lastPathComponent];
                    
                    //case has change then update the path before show
                    NSString *dir = [RegistrationBiometric leftThumbImageDir];
                    file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
                    
                    //check if this from migrant
                    if (![[NSFileManager defaultManager] fileExistsAtPath:self.leftThumb]) {
                        //case has change then update the path before show
                        NSString *dir = [Biometric leftThumbImageDir];
                        self.leftThumb = [dir stringByAppendingPathComponent:tmp];
                    }
                }
                break;
            }
            case LeftIndex:{
                file = self.leftIndex;
                //check if the path has change
                if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
                    tmp = [file lastPathComponent];
                    
                    //case has change then update the path before show
                    NSString *dir = [RegistrationBiometric leftIndexImageDir];
                    file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
                    
                    //check if this from migrant
                    if (![[NSFileManager defaultManager] fileExistsAtPath:self.leftIndex]) {
                        //case has change then update the path before show
                        NSString *dir = [Biometric leftIndexImageDir];
                        self.leftIndex = [dir stringByAppendingPathComponent:tmp];
                    }
                    
                }
                break;
            }
        }
        
        return file ? [UIImage imageWithContentsOfFile:file] : nil;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception on RegistrationBiometric - fingerImageForPosition : %@",[exception description]);
    }
    return Nil;
}

- (void)deleteBiometricData:(FingerPosition)position
{
    NSFileManager *manager = [NSFileManager defaultManager];
    @try {
        NSString *file;
        NSString * tmp;
        NSString *identifier = [NSString stringWithFormat:@"%f", [self.registration.dateCreated timeIntervalSince1970]];
        switch (position) {
            case RightThumb:{
                file = self.rightThumb;
                //check if the path has change
                if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
                    tmp = [file lastPathComponent];
                    //case has change then update the path before show
                    NSString *dir = [RegistrationBiometric rightThumbImageDir];
                    file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
                    
                    //check if this from migrant
                    if (![[NSFileManager defaultManager] fileExistsAtPath:self.rightThumb]) {
                        //case has change then update the path before show
                        NSString *dir = [Biometric rightThumbImageDir];
                        self.rightThumb = [dir stringByAppendingPathComponent:tmp];
                    }
                }
                break;
                
            }
            case RightIndex:{
                file = self.rightIndex;
                //check if the path has change
                if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
                    tmp = [file lastPathComponent];
                    
                    //case has change then update the path before show
                    NSString *dir = [RegistrationBiometric rightIndexImageDir];
                    file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
                    
                    //check if this from migrant
                    if (![[NSFileManager defaultManager] fileExistsAtPath:self.rightIndex]) {
                        //case has change then update the path before show
                        NSString *dir = [Biometric rightIndexImageDir];
                        self.rightIndex = [dir stringByAppendingPathComponent:tmp];
                    }
                    
                }
                break;
            }
                
            case LeftThumb:{
                file = self.leftThumb;
                //check if the path has change
                if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
                    tmp = [file lastPathComponent];
                    
                    //case has change then update the path before show
                    NSString *dir = [RegistrationBiometric leftThumbImageDir];
                    file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
                    
                    //check if this from migrant
                    if (![[NSFileManager defaultManager] fileExistsAtPath:self.leftThumb]) {
                        //case has change then update the path before show
                        NSString *dir = [Biometric leftThumbImageDir];
                        self.leftThumb = [dir stringByAppendingPathComponent:tmp];
                    }
                }
                break;
            }
                
            case LeftIndex:{
                file = self.leftIndex;
                //check if the path has change
                if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
                    tmp = [file lastPathComponent];
                    
                    //case has change then update the path before show
                    NSString *dir = [RegistrationBiometric leftIndexImageDir];
                    file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
                    
                    //check if this from migrant
                    if (![[NSFileManager defaultManager] fileExistsAtPath:self.leftIndex]) {
                        //case has change then update the path before show
                        NSString *dir = [Biometric leftIndexImageDir];
                        self.leftIndex = [dir stringByAppendingPathComponent:tmp];
                    }
                    
                }
                break;
            }
                
            default:
                break;
        }
        //delete file
        [manager removeItemAtPath:file error:nil];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception while deleteBiometricData by FingerPosition : %u - description : %@", position,[exception description]);
        
    }
}
- (void)deleteBiometricData
{
    NSFileManager *manager = [NSFileManager defaultManager];
    //    @try {
    //        [manager removeItemAtPath:self.photograph error:nil];
    //        [manager removeItemAtPath:self.photographThumbnail error:nil];
    //        [manager removeItemAtPath:self.leftThumb error:nil];
    //        [manager removeItemAtPath:self.leftIndex error:nil];
    //        [manager removeItemAtPath:self.rightThumb error:nil];
    //        [manager removeItemAtPath:self.rightIndex error:nil];
    @try {
        NSString *file;
        NSString * tmp;
        NSString *identifier = [NSString stringWithFormat:@"%f", [self.registration.dateCreated timeIntervalSince1970]];
        
        file = self.rightThumb;
        //check if the path has change
        if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
            tmp = [file lastPathComponent];
            //case has change then update the path before show
            NSString *dir = [RegistrationBiometric rightThumbImageDir];
            file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
            
            //check if this from migrant
            if (![[NSFileManager defaultManager] fileExistsAtPath:self.rightThumb]) {
                //case has change then update the path before show
                NSString *dir = [Biometric rightThumbImageDir];
                self.rightThumb = [dir stringByAppendingPathComponent:tmp];
            }
        }
        //delete right thumb
        [manager removeItemAtPath:file error:nil];
        
        file = self.rightIndex;
        //check if the path has change
        if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
            tmp = [file lastPathComponent];
            
            //case has change then update the path before show
            NSString *dir = [RegistrationBiometric rightIndexImageDir];
            file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
            
            //check if this from migrant
            if (![[NSFileManager defaultManager] fileExistsAtPath:self.rightIndex]) {
                //case has change then update the path before show
                NSString *dir = [Biometric rightIndexImageDir];
                self.rightIndex = [dir stringByAppendingPathComponent:tmp];
            }
            
        }
        //delete right index
        [manager removeItemAtPath:file error:nil];
        
        //left thumb
        file = self.leftThumb;
        //check if the path has change
        if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
            tmp = [file lastPathComponent];
            
            //case has change then update the path before show
            NSString *dir = [RegistrationBiometric leftThumbImageDir];
            file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
            
            //check if this from migrant
            if (![[NSFileManager defaultManager] fileExistsAtPath:self.leftThumb]) {
                //case has change then update the path before show
                NSString *dir = [Biometric leftThumbImageDir];
                self.leftThumb = [dir stringByAppendingPathComponent:tmp];
            }
        }
        //delete left thumb
        [manager removeItemAtPath:file error:nil];
        
        // left Index
        file = self.leftIndex;
        //check if the path has change
        if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
            tmp = [file lastPathComponent];
            
            //case has change then update the path before show
            NSString *dir = [RegistrationBiometric leftIndexImageDir];
            file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
            
            //check if this from migrant
            if (![[NSFileManager defaultManager] fileExistsAtPath:self.leftIndex]) {
                //case has change then update the path before show
                NSString *dir = [Biometric leftIndexImageDir];
                self.leftIndex = [dir stringByAppendingPathComponent:tmp];
            }
            
        }
        //delete left index
        [manager removeItemAtPath:file error:nil];
        
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
    NSString * tmp;
    NSString *identifier = [NSString stringWithFormat:@"%f", [self.registration.dateCreated timeIntervalSince1970]];
    switch (position) {
        case RightThumb:{
            file = self.rightThumb;
            //check if the path has change
            if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
                tmp = [file lastPathComponent];
                //case has change then update the path before show
                NSString *dir = [RegistrationBiometric rightThumbImageDir];
                file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
                
                //check if this from migrant
                if (![[NSFileManager defaultManager] fileExistsAtPath:self.rightThumb]) {
                    //case has change then update the path before show
                    NSString *dir = [Biometric rightThumbImageDir];
                    self.rightThumb = [dir stringByAppendingPathComponent:tmp];
                }
            }
            break;
        }
        case RightIndex:{
            file = self.rightIndex;
            //check if the path has change
            if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
                tmp = [file lastPathComponent];
                
                //case has change then update the path before show
                NSString *dir = [RegistrationBiometric rightIndexImageDir];
                file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
                
                //check if this from migrant
                if (![[NSFileManager defaultManager] fileExistsAtPath:self.rightIndex]) {
                    //case has change then update the path before show
                    NSString *dir = [Biometric rightIndexImageDir];
                    self.rightIndex = [dir stringByAppendingPathComponent:tmp];
                }
                
            }
            break;
        }
        case LeftThumb:{
            file = self.leftThumb;
            //check if the path has change
            if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
                tmp = [file lastPathComponent];
                
                //case has change then update the path before show
                NSString *dir = [RegistrationBiometric leftThumbImageDir];
                file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
                
                //check if this from migrant
                if (![[NSFileManager defaultManager] fileExistsAtPath:self.leftThumb]) {
                    //case has change then update the path before show
                    NSString *dir = [Biometric leftThumbImageDir];
                    self.leftThumb = [dir stringByAppendingPathComponent:tmp];
                }
            }
            break;
        }
        case LeftIndex:{
            file = self.leftIndex;
            //check if the path has change
            if (![[NSFileManager defaultManager] fileExistsAtPath:file] && file) {
                tmp = [file lastPathComponent];
                
                //case has change then update the path before show
                NSString *dir = [RegistrationBiometric leftIndexImageDir];
                file = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", identifier]];
                
                //check if this from migrant
                if (![[NSFileManager defaultManager] fileExistsAtPath:self.leftIndex]) {
                    //case has change then update the path before show
                    NSString *dir = [Biometric leftIndexImageDir];
                    self.leftIndex = [dir stringByAppendingPathComponent:tmp];
                }
                
            }
            break;
        }
    }
    
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
    
    //save to thumbnail
    UIImage *image = [[self photographImage] scaledToWidthInPoint:125];
    NSData *imgData= UIImagePNGRepresentation(image);
    [self updatePhotographThumbnail:imgData];
}

- (void)updatePhotographThumbnail:(NSData *)photographData
{
    if (!self.registration.dateCreated) {
        NSException *exception = [NSException exceptionWithName:@"NullPointerException" reason:@"Field dateCreated on Registration cannot be nil." userInfo:nil];
        @throw exception;
        return;
    }
    
    NSString *identifier = [NSString stringWithFormat:@"%f", [self.registration.dateCreated timeIntervalSince1970]];
    NSString *dir = [RegistrationBiometric photograpThumbnailDir];
    self.photographThumbnail = [self writeData:photographData toPath:[dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", identifier]]];
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