//
//  IMTableHeaderView.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 7/29/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMTableHeaderView.h"
#import "UIFont+IMMS.h"


@implementation IMTableHeaderView

- (id)initWithTitle:(NSString *)title reuseIdentifier:(NSString *)identifier
{
    return [self initWithTitle:title actionTitle:nil alignCenterY:NO reuseIdentifier:identifier];
}

- (id)initWithTitle:(NSString *)title actionTitle:(NSString *)actionTitle reuseIdentifier:(NSString *)identifier
{
    return [self initWithTitle:title actionTitle:actionTitle alignCenterY:NO reuseIdentifier:identifier];
}

- (id)initWithInfoButtonAndTitle:(NSString *)title reuseIdentifier:(NSString *)identifier
{
    self = [super initWithReuseIdentifier:identifier];
    
    self.labelTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    self.labelTitle.textAlignment = NSTextAlignmentLeft;
    self.labelTitle.textColor = [UIColor blackColor];
    self.labelTitle.backgroundColor = [UIColor clearColor];
    self.labelTitle.text = title;
    [self.labelTitle setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.labelTitle setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
    [self.contentView addSubview:self.labelTitle];
    
    self.buttonAction = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [self.buttonAction setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.contentView addSubview:self.buttonAction];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_labelTitle, _buttonAction);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[_labelTitle]-[_buttonAction]-|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_labelTitle]|" options:0 metrics:nil views:views]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.buttonAction attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    return self;
}

- (id)initWithTitle:(NSString *)title actionTitle:(NSString *)actionTitle alignCenterY:(BOOL)alignCenterY reuseIdentifier:(NSString *)identifier
{
    self = [super initWithReuseIdentifier:identifier];
    
    self.labelTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    self.labelTitle.textAlignment = NSTextAlignmentLeft;
    self.labelTitle.textColor = [UIColor blackColor];
    self.labelTitle.backgroundColor = [UIColor clearColor];
    self.labelTitle.text = title;
    [self.labelTitle setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.labelTitle setFont:[UIFont lightHeaderFont]];
    [self.contentView addSubview:self.labelTitle];
    
    if (!actionTitle) {
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.labelTitle attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.labelTitle attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:20]];
        
        if (alignCenterY) {
            [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        }else {
            [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.labelTitle attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
        }
    }else {
        self.buttonAction = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.buttonAction setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [self.buttonAction.titleLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
        [self.buttonAction setTitle:actionTitle forState:UIControlStateNormal];
        [self.buttonAction setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.contentView addSubview:self.buttonAction];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.labelTitle attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:20]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.buttonAction attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:-20]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.buttonAction attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
        if (alignCenterY) {
            [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.labelTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        }else {
            [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.labelTitle attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-10]];
        }
    }
    
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.labelTitle invalidateIntrinsicContentSize];
    [self.buttonAction invalidateIntrinsicContentSize];
    [self.contentView needsUpdateConstraints];
}

@end
