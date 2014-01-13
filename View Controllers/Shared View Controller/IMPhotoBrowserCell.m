//
//  IMPhotoBrowserCell.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/9/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMPhotoBrowserCell.h"
#import "IMPhotoView.h"
#import "UIColor+IMMS.h"


@interface IMPhotoBrowserCell ()

@property (nonatomic, strong) UIScrollView *scrollView;

@end


@implementation IMPhotoBrowserCell

NSString *const PHOTO_ID            = @"PHOTO_ID";
NSString *const PHOTO_IMAGE         = @"PHOTO_IMAGE";
NSString *const PHOTO_LOCAL_PATH    = @"PHOTO_LOCAL_PATH";


- (id)initWithPhotos:(NSArray *)photos
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PhotoBrowserIdentifier"];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.scrollView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_scrollView);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_scrollView]|"
                                                                             options:NSLayoutFormatAlignAllCenterY
                                                                             metrics:nil
                                                                               views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_scrollView]|" options:0 metrics:nil views:views]];
    self.photos = photos;
    
    return self;
}

- (void)setPhotos:(NSArray *)photos
{
    _photos = photos;
    [self updateUI];
}

- (void)updateUI
{
    [[self.scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    int index = 0;
    
    for (NSDictionary *dict in self.photos) {
        UIImage *photo;
        
        if (dict[PHOTO_LOCAL_PATH]) {
            photo = [UIImage imageWithContentsOfFile:dict[PHOTO_LOCAL_PATH]];
        }else {
            photo = dict[PHOTO_IMAGE];
        }
        
        IMPhotoView *photoView = [[IMPhotoView alloc] initWithImage:photo editable:YES contentScaleFactor:self.contentScaleFactor];
        CGFloat padding = index ? 5 * index : 0;
        photoView.frame = CGRectMake((index * 100) + padding, 0, 100, 100);
        photoView.buttonDelete.tag = index;
        [photoView.buttonDelete addTarget:self action:@selector(deletePhotoAtIndex:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:photoView];
        index++;
    }
    
    [self.scrollView setContentSize:CGSizeMake(100 * index, 100)];
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}

- (void)deletePhotoAtIndex:(UIButton *)sender
{
    if (self.onPhotoDeleted) {
        self.onPhotoDeleted(sender.tag);
    }
}

@end
