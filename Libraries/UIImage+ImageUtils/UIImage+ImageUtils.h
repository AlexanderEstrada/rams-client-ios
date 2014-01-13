//
//  UIImage+ImageUtils.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 11/29/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ImageUtils)

- (UIImage *)scaledToWidth:(float)_newWidth;
- (UIImage *)scaledToWidthInPoint:(CGFloat)widthInPoint;
- (UIImage *)scaledToSize:(CGSize)newSize;
- (UIImage*)scaledToHeight:(float)_newHeight;

- (NSData *)scaledJPEGRepresentationToWidth:(CGFloat)_newWidth;
- (NSData *)scaledJPEGRepresentationToWidth:(CGFloat)_newWidth compression:(CGFloat)compression;
- (NSData *)scaledJPEGRepresentationToSize:(CGSize)newSize;
- (NSData *)scaledJPEGRepresentationToSize:(CGSize)newSize compression:(CGFloat)compression;

- (UIImage *)thumbnailFitForSize:(CGSize)containerSize;
- (UIImage *)grayscaleImage;
+ (UIImage *)screenshot;
+ (UIImage *)screenshotForView:(UIView *)view;

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;

+ (UIImage *)imageWithSize:(CGSize)size backgroundColor:(UIColor *)backgroundColor borderColor:(UIColor *)borderColor;
+ (UIImage *)imageWithSize:(CGSize)size backgroundColor:(UIColor *)backgroundColor borderColor:(UIColor *)borderColor cornerRadius:(CGFloat)cornerRadius;
+ (UIImage *)navigationBackgroundImageWithColor:(UIColor *)backgroundColor borderColor:(UIColor *)borderColor;
+ (UIImage *)imageWithSize:(CGSize)size maskColor:(UIColor *)maskColor;
- (UIImage *)imageMaskWithColor:(UIColor *)maskColor;

@end