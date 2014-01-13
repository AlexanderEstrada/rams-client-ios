//
//  IMAccommodationPhotoView.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/8/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IMAccommodationPhotoView : UIView

@property (nonatomic, strong) NSString *photoPath;
@property (nonatomic, strong) UIImageView *imageView;

- (id)initWithFrame:(CGRect)frame photoPath:(NSString *)photoPath;
- (id)initDefaultPhotoViewWithFrame:(CGRect)frame;

@end
