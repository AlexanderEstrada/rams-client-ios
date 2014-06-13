//
//  IMPhotoViewer.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/6/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMPhotoViewer.h"
#import "IMPhotoCell.h"

@interface IMPhotoViewer ()<UIPopoverControllerDelegate>

@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) UIImage *image;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UITapGestureRecognizer *toggleNavigationGesture;
@property (strong, nonatomic) UITapGestureRecognizer *gestureDoubleTap;
@property (strong, nonatomic) UIPopoverController *popover;

@end


@implementation IMPhotoViewer

#pragma mark UICollectionView
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.photoPaths count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    IMPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCellIdentifier" forIndexPath:indexPath];
    cell.imageView.image = [UIImage imageWithContentsOfFile:self.photoPaths[indexPath.row]];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.selectedIndexPath isEqual:indexPath]) return;
    
    self.selectedIndexPath = indexPath;
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    IMPhotoCell *cell = (IMPhotoCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.frame = CGRectMake(cell.frame.origin.x - 10, cell.frame.origin.y - 10, 130, 100);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath isEqual:self.selectedIndexPath]) {
        return CGSizeMake(130, 100);
    }
    
    return CGSizeMake(90, 70);
}

#pragma mark View Lifecycle
- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    _selectedIndexPath = selectedIndexPath;
    self.image = [UIImage imageWithContentsOfFile:self.photoPaths[self.selectedIndexPath.row]];
    [self resetImage];
}

- (void)showShareSheet:(id)sender
{
    if (self.image) {
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[@"Share Image", self.image]
                                                                                         applicationActivities:nil];
        if (!self.popover) {
            self.popover = [[UIPopoverController alloc] initWithContentViewController:activityController];
            self.popover.delegate = self;
        }
        
        [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.contentMode = UIViewContentModeCenter;
        _imageView.userInteractionEnabled = YES;
    }
    return _imageView;
}

- (void)toggleNavigation
{
    self.navigationController.navigationBarHidden = !self.navigationController.navigationBarHidden;
}

- (UITapGestureRecognizer *)toggleNavigationGesture
{
    if (!_toggleNavigationGesture) {
        _toggleNavigationGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleNavigation)];
        _toggleNavigationGesture.numberOfTapsRequired = 1;
        [_toggleNavigationGesture requireGestureRecognizerToFail:self.gestureDoubleTap];
    }
    
    return _toggleNavigationGesture;
}

- (UITapGestureRecognizer *)gestureDoubleTap
{
    if (!_gestureDoubleTap) {
        _gestureDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap)];
        _gestureDoubleTap.numberOfTapsRequired = 2;
    }
    
    return _gestureDoubleTap;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.scrollView addSubview:self.imageView];
    self.scrollView.delegate = self;
    
    self.navigationItem.title = self.title;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showShareSheet:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalViewControllerAnimated:)];
    [self.scrollView addGestureRecognizer:self.gestureDoubleTap];
    [self.scrollView addGestureRecognizer:self.toggleNavigationGesture];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"IMPhotoCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"PhotoCellIdentifier"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.selectedIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning
{
    self.photoPaths = nil;
    self.image = nil;
    [super didReceiveMemoryWarning];
}

#pragma mark Image Viewer Logic
- (void)resetImage
{
    self.scrollView.zoomScale = 1;
    self.scrollView.contentSize = CGSizeZero;
    self.imageView.image = nil;
    
    float minimumScale = 1;
    float maximumScale = 1;
    
    if (self.image.size.width >= self.scrollView.bounds.size.width) {
        minimumScale =  self.scrollView.bounds.size.width / self.image.size.width;
    }
    
    self.imageView.frame = CGRectMake(0, 0, self.image.size.width, self.image.size.height);
    self.imageView.image = self.image;
    self.scrollView.contentSize = self.image.size;
    self.scrollView.minimumZoomScale = minimumScale;
    self.scrollView.maximumZoomScale = maximumScale;
    [self.scrollView setZoomScale:minimumScale animated:NO];
    [self setImageCenter];
}

- (void)doubleTap
{
    if (self.scrollView.zoomScale < self.scrollView.maximumZoomScale) {
        [self.scrollView setZoomScale:self.scrollView.maximumZoomScale animated:YES];
    }else{
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    }
}

- (void)setImageCenter{
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect frameToCenter = self.imageView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.imageView.frame = frameToCenter;
}


#pragma mark UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.imageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    [UIView animateWithDuration:.2 animations:^{
        [self setImageCenter];
    }];
}

@end
