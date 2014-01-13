//
//  Biometric+Storage.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/21/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Biometric.h"
#import "IMConstants.h"
#import "Biometric+Extended.h"

@interface Biometric (Storage)

+ (NSString *)photograpDir;
+ (NSString *)leftIndexTemplateDir;
+ (NSString *)rightIndexTemplateDir;
+ (NSString *)leftThumbTemplateDir;
+ (NSString *)rightThumbTemplateDir;
+ (NSString *)leftIndexImageDir;
+ (NSString *)rightIndexImageDir;
+ (NSString *)leftThumbImageDir;
+ (NSString *)rightThumbImageDir;

- (NSData *)photographData;
- (UIImage *)photographImage;
- (UIImage *)fingerImageForPosition:(FingerPosition)position;

- (void)updatePhotographData:(NSData *)photographData;
- (void)updatePhotographFromBase64String:(NSString *)base64PhotographString;

- (void)updateTemplateFromBase64String:(NSString *)base64String forFingerPosition:(FingerPosition)position;
- (void)updateTemplateWithData:(NSData *)templateData forFingerPosition:(FingerPosition)position;

- (void)updateFingerImageFromBase64String:(NSString *)base64String forFingerPosition:(FingerPosition)position;
- (void)updateFingerImageWithData:(NSData *)imageData forFingerPosition:(FingerPosition)position;

- (void)deleteBiometricData;

@end
