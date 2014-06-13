//
//  IMTableViewCell.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/2/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMTableViewCell.h"

@interface IMTableViewCell()

@property (nonatomic) BOOL accessoryOnHighlighted;
@property (nonatomic) UITableViewCellAccessoryType accType;

@end


@implementation IMTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    self.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    return self;
}

- (void)setImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage
{
    self.imageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.imageView.highlightedImage = [highlightedImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType showsOnlyOnHighlighted:(BOOL)stat
{
    self.accType = accessoryType;
    self.accessoryOnHighlighted = stat;
    if (self.selected || !stat) self.accessoryType = self.accessoryType;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (self.accType && selected) {
        self.accessoryType = self.accessoryType;
    }else if (!selected && self.accessoryOnHighlighted) {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    
    self.textLabel.highlighted = selected;
    self.imageView.highlighted = selected;
    self.detailTextLabel.highlighted = selected;
}

@end
