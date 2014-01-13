//
//  IMAccommodationCell.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/2/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMAccommodationCell.h"
#import "IMConstants.h"
#import "UIColor+IMMS.h"
#import <QuartzCore/QuartzCore.h>


@implementation IMAccommodationCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.imageView.userInteractionEnabled = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.imageView setClipsToBounds:YES];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped)];
    tapGesture.numberOfTapsRequired = 1;
    [self.imageView addGestureRecognizer:tapGesture];
    
    [self.buttonDetails addTarget:self action:@selector(showDetails) forControlEvents:UIControlEventTouchUpInside];
    [self.buttonEdit addTarget:self action:@selector(showEdit) forControlEvents:UIControlEventTouchUpInside];
    
    self.controlContainerView.frame = CGRectMake(self.frame.size.width, 0, self.controlContainerView.frame.size.width, self.controlContainerView.frame.size.height);
    
    self.contentView.layer.borderWidth = 1;
    self.contentView.layer.borderColor = [UIColor IMBorderColor].CGColor;
    self.contentView.layer.cornerRadius = 12;
    self.contentView.layer.masksToBounds = YES;
}

- (void)setSingleOccupancy:(NSUInteger)singleOccupancy forCapacity:(NSUInteger)capacity
{
    if (capacity <= 0) {
        self.labelSingleValue.text = [NSString stringWithFormat:@"%i", singleOccupancy];
    }else {
        self.labelSingleValue.text = [NSString stringWithFormat:@"%i / %i", singleOccupancy, capacity];
    }
}

- (void)setFamilyOccupancy:(NSUInteger)familyOccupancy forCapacity:(NSUInteger)capacity
{
    if (capacity <= 0) {
        self.labelFamilyValue.text = [NSString stringWithFormat:@"%i", familyOccupancy];
    }else {
        self.labelFamilyValue.text = [NSString stringWithFormat:@"%i / %i", familyOccupancy, capacity];
    }
}

- (void)showPhotos
{
    if (self.onShowPhotos) self.onShowPhotos(self.indexPath);
}

- (void)showEdit
{
    if (self.onEdit) self.onEdit(self.indexPath);
}

- (void)showDetails
{
    if (self.onShowDetails) self.onShowDetails(self.indexPath);
}

- (void)imageViewTapped
{
    if (self.onShowPhotos) self.onShowPhotos(self.indexPath);
}

- (void)setSelected:(BOOL)selected
{
    CGRect contentRect;
    CGRect controlRect;
    CGFloat contentAlpha;
    CGFloat controlAlpha;
    
    if (selected) {
        contentRect = CGRectMake(self.controlContainerView.frame.size.width * -1, 0, self.contentContainerView.frame.size.width, self.contentContainerView.frame.size.height);
        controlRect = CGRectMake(self.frame.size.width - self.controlContainerView.frame.size.width, 0, self.controlContainerView.frame.size.width, self.controlContainerView.frame.size.height);
        contentAlpha = 0.15;
        controlAlpha = 1;
    }else {
        contentRect = CGRectMake(0, 0, self.contentContainerView.frame.size.width, self.contentContainerView.frame.size.height);
        controlRect = CGRectMake(self.frame.size.width, 0, self.controlContainerView.frame.size.width, self.controlContainerView.frame.size.height);
        contentAlpha = 1;
        controlAlpha = 0;
    }
    
    [UIView animateWithDuration:.25
                          delay:0
                        options:(selected ? UIViewAnimationOptionCurveEaseIn : UIViewAnimationOptionCurveEaseOut)
                     animations:^{
                         self.contentContainerView.frame = contentRect;
                         self.controlContainerView.frame = controlRect;
                         self.contentContainerView.alpha = contentAlpha;
                         self.controlContainerView.alpha = controlAlpha;
                     }
                     completion:nil];
}

@end
