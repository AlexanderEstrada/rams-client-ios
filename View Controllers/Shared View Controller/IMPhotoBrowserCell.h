//
//  IMPhotoBrowserCell.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/9/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IMPhotoBrowserCell : UITableViewCell

extern NSString *const PHOTO_ID;
extern NSString *const PHOTO_IMAGE;
extern NSString *const PHOTO_LOCAL_PATH;

@property (nonatomic, copy) void (^onPhotoDeleted)(NSInteger photoIndex);
@property (nonatomic, strong) NSArray *photos;

- (id)initWithPhotos:(NSArray *)photos;

@end
