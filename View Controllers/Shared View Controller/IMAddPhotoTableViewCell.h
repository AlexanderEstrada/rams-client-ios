//
//  IMAddPhotoTableViewCell.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 7/29/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kPhotoImage @"image"
#define kPhotoId    @"id"

@interface IMAddPhotoTableViewCell : UITableViewCell

@property (nonatomic, strong) NSArray *photos;
@property (nonatomic) BOOL allowsEditing;

@property (nonatomic, copy) void (^onImageTapped)(UIImage *image);
@property (nonatomic, copy) void (^onDelete)(NSDictionary *deletedPhoto);

- (id)initWithPhotoDictionaries:(NSArray *)photos allowsEditing:(BOOL)allowsEditing;

@end