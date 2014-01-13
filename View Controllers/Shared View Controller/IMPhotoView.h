//
//  IMPhotoView.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 7/29/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IMPhotoView : UIView

@property (nonatomic, readwrite) BOOL editable;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *buttonDelete;

- (id)initWithImage:(UIImage *)image editable:(BOOL)editable contentScaleFactor:(CGFloat)contentScaleFactor;

@end
