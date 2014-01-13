//
//  UIFont+IMMS.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 9/25/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFont (IMMS)

+ (UIFont *)lightHeaderFont;
+ (UIFont *)regularFontWithSize:(CGFloat)size;
+ (UIFont *)boldFontWithSize:(CGFloat)size;
+ (UIFont *)lightFontWithSize:(CGFloat)size;
+ (UIFont *)thinFontWithSize:(CGFloat)size;
+ (UIFont *)italicFontWithSize:(CGFloat)size;

@end
