//
//  IMTableViewCell.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/2/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IMTableViewCell : UITableViewCell

- (void)setImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage;
- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType showsOnlyOnHighlighted:(BOOL)stat;

@end