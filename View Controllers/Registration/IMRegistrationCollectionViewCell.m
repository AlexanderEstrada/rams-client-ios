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
    
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView.layer.cornerRadius = 12;
    self.selectedBackgroundView.layer.masksToBounds = YES;
    self.selectedBackgroundView.backgroundColor = [UIColor IMTurquoise];
}

@end