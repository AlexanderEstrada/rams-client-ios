//
//  IMFingerprintPreviewCell.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMFingerprintPreviewCell.h"
#import "UIColor+IMMS.h"

@implementation IMFingerprintPreviewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView.backgroundColor = [[UIColor IMRed] colorWithAlphaComponent:0.5];
}

@end