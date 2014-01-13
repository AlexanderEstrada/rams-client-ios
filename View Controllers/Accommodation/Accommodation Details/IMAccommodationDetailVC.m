//
//  IMAccommodationDetailVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/8/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMAccommodationDetailVC.h"
#import "Accommodation+Extended.h"
#import "IMAccommodationInfoVC.h"
#import "IMAccommodationPhotoView.h"
#import "Photo+Extended.h"


@interface IMAccommodationDetailVC ()<UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *infoContainerView;
@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;
@property (nonatomic, weak) IMAccommodationInfoVC *infoVC;

@property (nonatomic, strong) NSArray *photos;
@property (nonatomic) BOOL firstLaunch;

@end


@implementation IMAccommodationDetailVC

#pragma mark View Lifecycle
- (void)setAccommodation:(Accommodation *)accommodation
{
    _accommodation = accommodation;
    self.photos = [accommodation.photos allObjects];
    self.infoVC.accommodation = accommodation;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.accommodation.name;
    self.navigationController.navigationBar.tintColor = [UIColor IMLightBlue];
    self.view.tintColor = [UIColor IMLightBlue];

    self.firstLaunch = YES;
    self.infoContainerView.backgroundColor = [UIColor clearColor];
    self.scrollView.delegate = self;
    self.pageControl.currentPage = 0;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControls)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)toggleControls
{
    if (self.navigationController.navigationBarHidden) {
        [UIView animateWithDuration:.25 animations:^{
            self.navigationController.navigationBarHidden = NO;
            self.infoContainerView.transform = CGAffineTransformMakeScale(1, 1);
            self.infoContainerView.alpha = 1;
            self.pageControl.alpha = 1;
        }];
    }else {
        [UIView animateWithDuration:.25 animations:^{
            self.navigationController.navigationBarHidden = YES;
            self.infoContainerView.transform = CGAffineTransformMakeScale(1, 0);
            self.infoContainerView.alpha = 0;
            self.pageControl.alpha = 0;
        }];
    }
}

- (void)setupUI
{
    [[self.scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if (![self.photos count]) {
        IMAccommodationPhotoView *photoView = [[IMAccommodationPhotoView alloc] initDefaultPhotoViewWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        
        self.pageControl.numberOfPages = 0;
        [self.scrollView addSubview:photoView];
        [self.scrollView setContentSize:CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height)];
        [self.scrollView setContentOffset:CGPointZero];
        return;
    }
    
    int page = 0;
    for (Photo *photo in self.photos) {
        CGRect photoFrame = CGRectMake(page * self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        IMAccommodationPhotoView *photoView = [[IMAccommodationPhotoView alloc] initWithFrame:photoFrame photoPath:photo.photoPath];
        [self.scrollView addSubview:photoView];
        page++;
    }
    
    self.pageControl.numberOfPages = page;
    [self.scrollView setContentSize:CGSizeMake(page * self.view.bounds.size.width, self.view.bounds.size.height)];
    [self.scrollView setContentOffset:CGPointMake(self.pageControl.currentPage * self.view.bounds.size.width, 0) animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.firstLaunch) {
        [self setupUI];
        self.infoVC = [self.childViewControllers lastObject];
        self.infoVC.accommodation = self.accommodation;
        self.firstLaunch = NO;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setupUI];
}


#pragma mark UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) [self updatePageControl];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updatePageControl];
}

- (void)updatePageControl
{
    int offsetx = self.scrollView.contentOffset.x;
    int page = (offsetx / self.view.bounds.size.width);
    self.pageControl.currentPage = page;
}

@end
