//
//  IMSSCheckMark.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 7/31/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM( NSUInteger, SSCheckMarkStyle )
{
    SSCheckMarkStyleOpenCircle,
    SSCheckMarkStyleGrayedOut
};

@interface IMSSCheckMark : UIView

@property (nonatomic) bool checked;
@property (nonatomic) SSCheckMarkStyle checkMarkStyle;

@end
