//
//  IMAccommodationPhotoView.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/8/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMAccommodationPhotoView.h"
#import "UIImage+ImageEffects.h"


@implementation IMAccommodationPhotoView

- (id)initWithFrame:(CGRect)frame photoPath:(NSString *)photoPath
{
    self = [super initWithFrame:frame];
    
    self.photoPath = photoPath;
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    [self addSubview:self.imageView];
    
    self.imageView.image = [UIImage imageWithContentsOfFile:photoPath];
    
    return self;
}

- (id)initDefaultPhotoViewWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.contentMode = UIViewContentModeCenter;
    self.imageView.clipsToBounds = YES;
    [self addSubview:self.imageView];
    
    UIImage *background = [UIImage imageNamed:@"normal-background"];
    self.imageView.image = [background applyBlurWithRadius:100
                                                 tintColor:[UIColor colorWithWhite:0.97 alpha:0.75]
                                     saturationDeltaFactor:1.8
                                                 maskImage:nil];
    
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:16];
    label.textColor = [UIColor grayColor];
    label.backgroundColor = [UIColor clearColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"No Photo Available";
    
    [self addSubview:label];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    return self;
}

@end
