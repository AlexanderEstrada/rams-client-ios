//
//  IMPhotoView.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 7/29/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMPhotoView.h"
#import "UIImage+ImageUtils.h"
#import "UIColor+IMMS.h"


@implementation IMPhotoView

- (id)initWithImage:(UIImage *)image editable:(BOOL)editable contentScaleFactor:(CGFloat)contentScaleFactor
{
    UIImage *thumbnail = [image thumbnailFitForSize:CGSizeMake(100 * contentScaleFactor, 100 * contentScaleFactor)];
    CGRect frame = CGRectMake(0, 0, 100, 100);
    self = [super initWithFrame:frame];
    
    self.imageView = [[UIImageView alloc] initWithFrame:frame];
    self.imageView.image = thumbnail;
    self.imageView.contentMode = UIViewContentModeCenter;
    self.imageView.translatesAutoresizingMaskIntoConstraints = YES;
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.imageView.clipsToBounds = YES;
    
    self.buttonDelete = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.buttonDelete setImage:[[UIImage imageNamed:@"icon-delete"] imageMaskWithColor:[UIColor IMMagenta]] forState:UIControlStateNormal];
    [self.buttonDelete setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self addSubview:self.imageView];
    [self addSubview:self.buttonDelete];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.buttonDelete attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.buttonDelete attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    
    self.editable = editable;
    
    return self;
}

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    self.imageView.userInteractionEnabled = !editable;
    [self.buttonDelete setHidden:!editable];
}

@end