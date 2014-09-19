//
//  IMBiometricEngine.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 31/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMBiometricEngine.h"
#import "NBISWrapper.h"


@implementation IMBiometricEngine



- (void)validateFingerprintImage:(UIImage *)grayscaleFingerprintImage onComplete:(void (^)(BOOL valid))onComplete
{
    if (!onComplete) return;
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
     dispatch_async(dispatch_get_main_queue(), ^{
        NSData *imageData = UIImageJPEGRepresentation(grayscaleFingerprintImage, 1);
        NSString *imageFileName = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
        NSString *imagePath = [[IMBiometricEngine dirNFIQ] stringByAppendingPathComponent:imageFileName];
        [imageData writeToFile:imagePath atomically:NO];
        NSInteger nfiq = [NBISWrapper computeNFIQ:imagePath deleteInputWhenDone:YES];
        onComplete(nfiq <= 3 && nfiq > 0);
    });
}


#pragma mark File Management
+ (NSString *)dirNFIQ
{
    NSURL *cachesURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
    NSString *cachesPath = [cachesURL path];
    NSString *dir = [cachesPath stringByAppendingPathComponent:@"NFIQ"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return dir;
}

@end