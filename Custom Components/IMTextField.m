//
//  IMTextField.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMTextField.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+IMMS.h"


@implementation IMTextField


- (void)toggleBorder
{
    UIColor *borderColor = self.editing ? [UIColor IMLightBlue] : [UIColor IMBorderColor];
    CGFloat borderWidth = 1;
    CGFloat shadowRadius = 0;
    
    CALayer *theLayer = [self layer];
    [theLayer setBorderWidth:borderWidth];
    [theLayer setBorderColor:[borderColor CGColor]];
    [theLayer setShadowColor:[borderColor CGColor]];
    [theLayer setShadowOpacity:0];
    [theLayer setShadowRadius:shadowRadius];
    [theLayer setShadowOffset:CGSizeZero];
    [self setClipsToBounds:NO];
}


#define kTextRectMargin    10

- (CGRect)textRectForBounds:(CGRect)bounds
{
    if (self.leftViewMode == UITextFieldViewModeAlways) {
        CGRect leftViewRect = self.leftView.frame;
        return CGRectMake(bounds.origin.x + (2 * kTextRectMargin) + leftViewRect.size.width, bounds.origin.y + kTextRectMargin, bounds.size.width - (2 * kTextRectMargin) - leftViewRect.size.width, bounds.size.height - (2 * kTextRectMargin));
    }
    
    return CGRectMake(bounds.origin.x + kTextRectMargin, bounds.origin.y + kTextRectMargin, bounds.size.width - (2 * kTextRectMargin), bounds.size.height - (2 * kTextRectMargin));
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    return CGRectMake(bounds.origin.x + kTextRectMargin, bounds.origin.y + kTextRectMargin, bounds.size.width - (2 * kTextRectMargin), bounds.size.height - (2 * kTextRectMargin));
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    if (self.leftViewMode != UITextFieldViewModeNever) {
        CGRect leftViewRect = self.leftView.frame;
        return CGRectMake(bounds.origin.x + (2 * kTextRectMargin) + leftViewRect.size.width, bounds.origin.y + kTextRectMargin, bounds.size.width - (2 * kTextRectMargin) - leftViewRect.size.width, bounds.size.height - (2 * kTextRectMargin));
    }
    
    return CGRectMake(bounds.origin.x + kTextRectMargin, bounds.origin.y + kTextRectMargin, bounds.size.width - (2 * kTextRectMargin), bounds.size.height - (2 * kTextRectMargin));
}

- (CGRect)clearButtonRectForBounds:(CGRect)bounds
{
    CGRect oldRect = [super clearButtonRectForBounds:bounds];
    return CGRectMake(oldRect.origin.x - (2 * kTextRectMargin), oldRect.origin.y, oldRect.size.width, oldRect.size.height);
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds
{
    CGRect oldRect = [super leftViewRectForBounds:bounds];
    return CGRectMake(oldRect.origin.x + (2 * kTextRectMargin), oldRect.origin.y, oldRect.size.width, oldRect.size.height);
}

@end
