//
//  IMMigrantCell.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMMigrantTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+ImageUtils.h"


@implementation IMMigrantTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.photoView.layer.cornerRadius = 35;
    self.photoView.layer.masksToBounds = YES;
}

@end