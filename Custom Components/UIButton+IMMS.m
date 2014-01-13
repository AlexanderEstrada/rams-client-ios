//
//  UIButton+IMMS.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 9/24/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "UIButton+IMMS.h"
#import "UIColor+IMMS.h"
#import "UIImage+ImageUtils.h"
#import <QuartzCore/QuartzCore.h>


@implementation UIButton (IMMS)

+ (UIButton *)buttonWithTitle:(NSString *)title
                   titleColor:(UIColor *)titleColor
              backgroundColor:(UIColor *)backgroundColor
                     fontSize:(CGFloat)fontSize
{
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.titleLabel.font = font;
    button.tintColor = titleColor;
    [button setTitle:title forState:UIControlStateNormal];
    [button sizeToFit];
    
    UIImage *backgroundImage = [UIImage imageWithSize:CGSizeMake(1, 1) backgroundColor:backgroundColor borderColor:titleColor];
    [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    
    return button;
}
+ (UIButton *)buttonWithTitle:(NSString *)title titleColor:(UIColor *)titleColor fontSize:(CGFloat)fontSize
{
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.titleLabel.font = font;
    button.tintColor = titleColor;
    [button setTitle:title forState:UIControlStateNormal];
    [button sizeToFit];
    
    return button;
}

- (void)setBackgroundImageWithColor:(UIColor *)backgroundColor
{
    UIFont *font = self.titleLabel.font;
    CGSize size = [self.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:font}];
    UIImage *backgroundImage = [UIImage imageWithSize:CGSizeMake(size.width + 20, font.lineHeight + 10) maskColor:backgroundColor];
    [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    self.layer.cornerRadius = 8;
}

@end
