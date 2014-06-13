//
//  RegistrationBiometric+Storage.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "RegistrationBiometric.h"
#import "Biometric+Storage.h"

@interface RegistrationBiometric (Storage)

+ (NSString *)photograpDir;
+ (NSString *)leftIndexImageDir;
+ (NSString *)rightIndexImageDir;
+ (NSString *)leftThumbImageDir;
+ (NSString *)rightThumbImageDir;

- (NSData *)photographData;
- (UIImage *)photographImage;
- (UIImage *)fingerImageForPosition:(FingerPosition)position;

- (NSString *)base64Photograph;
- (NSString *)base64FingerImageWithPosition:(FingerPosition)position;

- (void)updatePhotographData:(NSData *)photographData;
- (void)updateFingerImageWithData:(NSData *)imageData forFingerPosition:(FingerPosition)position;
- (void)deleteBiometricData;
- (void)deleteBiometricData:(FingerPosition)position;

@end