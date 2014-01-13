//
//  UIFont+IMMS.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 9/25/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "UIFont+IMMS.h"

@implementation UIFont (IMMS)

#define kDefaultFontRegular @"HelveticaNeue"
#define kDefaultFontThin    @"HelveticaNeue-Thin"
#define kDefaultFontLight   @"HelveticaNeue-Light"
#define kDefaultFontBold    @"HelveticaNeue-Medium"
#define kDefaultFontItalic  @"HelveticaNeue-Italic"

+ (UIFont *)lightHeaderFont
{
    CGFloat fontSize = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline].pointSize * 1.3;
    return [UIFont lightFontWithSize:fontSize];
}

+ (UIFont *)regularFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:kDefaultFontRegular size:size];
}

+ (UIFont *)boldFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:kDefaultFontBold size:size];
}

+ (UIFont *)lightFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:kDefaultFontLight size:size];
}

+ (UIFont *)thinFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:kDefaultFontThin size:size];
}

+ (UIFont *)italicFontWithSize:(CGFloat)size
{
    return [UIFont fontWithName:kDefaultFontItalic size:size];
}

@end
