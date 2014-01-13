//
//  IMAddPhotoTableViewCell.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 7/29/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMAddPhotoTableViewCell.h"
#import "IMPhotoView.h"
#import "Photo+Extended.h"


@interface IMAddPhotoTableViewCell ()

@property (nonatomic, strong) UIScrollView *scrollView;

@end


@implementation IMAddPhotoTableViewCell

- (id)initWithPhotoDictionaries:(NSArray *)photos allowsEditing:(BOOL)allowsEditing
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"IMAddPhotoTableViewCell"];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [self.scrollView setShowsVerticalScrollIndicator:NO];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.contentView addSubview:self.scrollView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_scrollView);
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_scrollView]" options:NSLayoutFormatDirectionLeftToRight metrics:0 views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_scrollView]|" options:NSLayoutFormatAlignAllTop metrics:0 views:views]];

    self.allowsEditing = allowsEditing;
    self.photos = photos;
    
    return self;
}

- (void)setPhotos:(NSArray *)photos
{
    _photos = photos;
    
    for (UIView *view in [self.scrollView subviews]) { [view removeFromSuperview]; }
    
    CGFloat x = 0;
    CGFloat w = 0;
    
    for (NSDictionary *photoDict in photos) {
        UIImage *image = photoDict[kPhotoImage];
        IMPhotoView *photoView = [[IMPhotoView alloc] initWithImage:image editable:self.allowsEditing contentScaleFactor:self.contentView.contentScaleFactor];
        photoView.frame = CGRectMake(x, 0, photoView.frame.size.width, photoView.frame.size.height);
        [self.scrollView addSubview:photoView];
        
        w += photoView.frame.size.width;
        x += photoView.frame.size.width + 20;
    }
    
    [self.scrollView setContentSize:CGSizeMake(w, self.contentView.frame.size.height)];
}

- (void)deletePhoto:(UIButton *)sender
{
    if (self.onDelete) self.onDelete([self.photos objectAtIndex:sender.tag]);
}

@end
