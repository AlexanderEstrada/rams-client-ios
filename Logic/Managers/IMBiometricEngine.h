//
//  IMBiometricEngine.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 31/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IMBiometricEngine : NSObject

- (void)validateFingerprintImage:(UIImage *)grayscaleFingerprintImage onComplete:(void (^)(BOOL valid))onComplete;

@end