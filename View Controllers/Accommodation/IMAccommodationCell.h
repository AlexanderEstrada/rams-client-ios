//
//  IMAccommodationCell.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/2/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IMAccommodationCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelSingle;
@property (weak, nonatomic) IBOutlet UILabel *labelFamily;
@property (weak, nonatomic) IBOutlet UILabel *labelSingleValue;
@property (weak, nonatomic) IBOutlet UILabel *labelFamilyValue;

@property (weak, nonatomic) IBOutlet UIButton *buttonEdit;
@property (weak, nonatomic) IBOutlet UIButton *buttonDetails;

@property (weak, nonatomic) IBOutlet UIView *contentContainerView;
@property (weak, nonatomic) IBOutlet UIView *controlContainerView;

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, copy) void (^onShowDetails)(NSIndexPath *indexPath);
@property (nonatomic, copy) void (^onEdit)(NSIndexPath *indexPath);
@property (nonatomic, copy) void (^onShowPhotos)(NSIndexPath *indexPath);

- (void)setSingleOccupancy:(NSUInteger)singleOccupancy forCapacity:(NSUInteger)capacity;
- (void)setFamilyOccupancy:(NSUInteger)familyOccupancy forCapacity:(NSUInteger)capacity;

@end
