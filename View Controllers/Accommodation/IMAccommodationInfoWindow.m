//
//  IMAccommodationInfoWindow.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/22/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMAccommodationInfoWindow.h"
#import "Accommodation.h"
#import "IMAccommodationPhotoView.h"
#import "Photo+Extended.h"
#import "IMAccommodationInfoVC.h"
#import "IMAuthManager.h"


@interface IMAccommodationInfoWindow ()<UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@property (nonatomic, weak) IMAccommodationInfoVC *infoVC;
@property (nonatomic, strong) NSArray *photos;
@property (nonatomic) BOOL firstLaunch;

@end


@implementation IMAccommodationInfoWindow

#pragma mark Data Management
- (void)showEditAccommodation
{
    [self.delegate showEditAccommodation:self.accommodation];
}

- (void)showAccommodationDetail
{
    [self.delegate showAccommodationDetail:self.accommodation];
}


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.infoVC = [self.childViewControllers lastObject];
    self.infoVC.accommodation = self.accommodation;
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.firstLaunch = YES;
    
    if ([IMAuthManager sharedManager].activeUser.roleOperation) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(showEditAccommodation)];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Details" style:UIBarButtonItemStyleBordered target:self action:@selector(showAccommodationDetail)];
    self.pageControl.numberOfPages = 0;
    self.preferredContentSize = CGSizeMake(400, 460);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupUI];
}

- (void)setupUI
{
    [[self.scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.title = self.accommodation.name;
    self.photos = [self.accommodation.photos allObjects];
    self.infoVC.accommodation = self.accommodation;
    
    if (![self.photos count]) {
        IMAccommodationPhotoView *photoView = [[IMAccommodationPhotoView alloc] initDefaultPhotoViewWithFrame:CGRectMake(0, 0, 400, 300)];
        
        self.pageControl.numberOfPages = 0;
        [self.scrollView addSubview:photoView];
        [self.scrollView setContentSize:CGSizeMake(400, 300)];
        [self.scrollView setContentOffset:CGPointZero];
        return;
    }
    
    int page = 0;
    for (Photo *photo in self.photos) {
        CGRect photoFrame = CGRectMake(page * 400, 0, 400, 300);
        IMAccommodationPhotoView *photoView = [[IMAccommodationPhotoView alloc] initWithFrame:photoFrame photoPath:photo.photoPath];
        [self.scrollView addSubview:photoView];
        page++;
    }
    
    self.pageControl.numberOfPages = page;
    [self.scrollView setContentSize:CGSizeMake(page * 400, 300)];
    [self.scrollView setContentOffset:CGPointMake(self.pageControl.currentPage * self.scrollView.bounds.size.width, 0) animated:YES];
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
    int page = (offsetx / 400);
    self.pageControl.currentPage = page;
}

@end
