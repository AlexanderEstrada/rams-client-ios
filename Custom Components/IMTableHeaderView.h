//
//  IMTableHeaderView.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 7/29/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IMTableHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) UILabel *labelTitle;
@property (nonatomic, strong) UIButton *buttonAction;
@property (nonatomic, strong) UIButton *buttonAdd;

- (id)initWithTitle:(NSString *)title actionTitle:(NSString *)actionTitle reuseIdentifier:(NSString *)identifier;
- (id)initWithTitle:(NSString *)title actionTitle:(NSString *)actionTitle alignCenterY:(BOOL)alignCenterY reuseIdentifier:(NSString *)identifier;
- (id)initWithTitle:(NSString *)title reuseIdentifier:(NSString *)identifier;
- (id)initWithInfoButtonAndTitle:(NSString *)title reuseIdentifier:(NSString *)identifier;

@end
