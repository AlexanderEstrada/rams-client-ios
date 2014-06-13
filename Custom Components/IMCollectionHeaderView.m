//
//  IMCollectionHeaderView.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 7/15/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMCollectionHeaderView.h"
#import "UIFont+IMMS.h"


@implementation IMCollectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    self.backgroundColor = [UIColor clearColor];
    
    self.labelTitle = [[UILabel alloc] init];
    self.labelTitle.backgroundColor = [UIColor clearColor];
    self.labelTitle.textAlignment = NSTextAlignmentCenter;
    self.labelTitle.font = [UIFont lightHeaderFont];
    self.labelTitle.minimumScaleFactor = 0.25f;
    [self.labelTitle setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:self.labelTitle];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_labelTitle);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_labelTitle]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_labelTitle]|" options:0 metrics:nil views:views]];
    
    return self;
}

@end
