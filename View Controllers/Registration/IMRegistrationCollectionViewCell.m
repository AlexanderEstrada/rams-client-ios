//
//  IMRegistrationCollectionViewCell.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMRegistrationCollectionViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+IMMS.h"
#import "IMSSCheckMark.h"


@implementation IMRegistrationCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.photoView.layer.cornerRadius = 35;
    self.photoView.layer.masksToBounds = YES;
    
    self.contentView.layer.borderWidth = 1;
    self.contentView.layer.borderColor = [UIColor IMBorderColor].CGColor;
    self.contentView.layer.cornerRadius = 12;
    self.contentView.layer.masksToBounds = YES;
    
//    if (self.allowMultipleSelect) {
//        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
//        self.selectedBackgroundView.layer.cornerRadius = 12;
//        self.selectedBackgroundView.layer.masksToBounds = YES;
//        self.selectedBackgroundView.backgroundColor = [UIColor IMTurquoise];
//    }else{
//    
        CGRect rect = CGRectMake(290, 120, 30, 30);
        IMSSCheckMark * checkmark = [[IMSSCheckMark alloc] initWithFrame:rect];
        checkmark.checked = TRUE;
        checkmark.checkMarkStyle = SSCheckMarkStyleOpenCircle;
        self.selectedBackgroundView = checkmark;
        self.selectedBackgroundView.frame = rect;
        self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
//    }
    
    
    
}

- (void) changeBackgroundView:(BOOL) isMultipleSelect
{
    if (isMultipleSelect) {
        CGRect rect = CGRectMake(290, 120, 30, 30);
        IMSSCheckMark * checkmark = [[IMSSCheckMark alloc] initWithFrame:rect];
        checkmark.checked = TRUE;
        checkmark.checkMarkStyle = SSCheckMarkStyleOpenCircle;
        self.selectedBackgroundView = checkmark;
        self.selectedBackgroundView.frame = rect;
        self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
    }else{
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
        self.selectedBackgroundView.layer.cornerRadius = 12;
        self.selectedBackgroundView.layer.masksToBounds = YES;
        self.selectedBackgroundView.backgroundColor = [UIColor IMTurquoise];
    }
}

@end