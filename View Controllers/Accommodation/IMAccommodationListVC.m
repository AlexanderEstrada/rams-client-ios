//
//  IMAccommodationViewController.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/2/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMAccommodationListVC.h"
#import "IMDBManager.h"
#import "IMAccommodationCell.h"
#import "Accommodation+Extended.h"
#import "Photo+Extended.h"
#import "UIImage+ImageUtils.h"
#import "IMCollectionHeaderView.h"
#import "IMPhotoViewer.h"
#import "IMAccommodationFilterVC.h"
#import <QuickLook/QuickLook.h>
#import "IMAccommodationDetailVC.h"
#import "IMEditAccommodationVC.h"
#import "IMAuthManager.h"
#import "IMAccommodationMapVC.h"


@interface IMAccommodationListVC ()<UIPopoverControllerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSArray *cities;
@property (nonatomic, strong) NSDictionary *locations;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) IMAccommodationFilterVC *cityChooser;
@property (nonatomic, strong) NSArray *previewingPhotos;
@property (nonatomic) BOOL loadingPhotos;

@end


@implementation IMAccommodationListVC

#pragma mark Data Management
- (void)setBasePredicate:(NSPredicate *)basePredicate
{
    _basePredicate = basePredicate;
    [self reloadData];
}

- (void)reloadData
{
    if (self.selectedIndexPath) [self.collectionView deselectItemAtIndexPath:self.selectedIndexPath animated:NO];
    
    self.selectedIndexPath = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Accommodation"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"city" ascending:YES]];
        request.predicate = self.basePredicate;
        
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        
        NSMutableArray *cityList = [NSMutableArray array];
        NSMutableDictionary *locationList = [NSMutableDictionary dictionary];
        
        for (Accommodation *location in results) {
            NSString *cityName = location.city;
            
            if (![cityList containsObject:cityName]) [cityList addObject:cityName];
            
            NSMutableArray *locationInCity = [locationList[cityName] mutableCopy];
            if (!locationInCity) locationInCity = [NSMutableArray array];
            
            [locationInCity addObject:location];
            locationList[cityName] = [locationInCity sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
        }
        
        self.cities = cityList;
        self.locations = locationList;
        [self.collectionView reloadData];
    });
}

- (void)showPhotoViewer:(NSIndexPath *)indexPath
{
    Accommodation *location = [self.locations[self.cities[indexPath.section]] objectAtIndex:indexPath.row];

    if ([location.photos count]) {
        self.previewingPhotos = [location.photos allObjects];
        QLPreviewController *previewController = [[QLPreviewController alloc] init];
        previewController.dataSource = self;
        previewController.delegate = self;
        
        [self presentViewController:previewController animated:YES completion:^{
            previewController.view.tintColor = [UIColor IMLightBlue];
            previewController.view.backgroundColor = [UIColor blackColor];
        }];
    }
}

- (void)showEdit:(NSIndexPath *)indexPath
{
    Accommodation *location = [self.locations[self.cities[indexPath.section]] objectAtIndex:indexPath.row];
    IMEditAccommodationVC *vc = [[IMEditAccommodationVC alloc] initWithAccommodation:location];
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
    navCon.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
    [self.parentViewController presentViewController:navCon animated:YES completion:nil];
}

- (void)showDetails:(NSIndexPath *)indexPath
{
    IMAccommodationDetailVC *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IMAccommodationDetailVC"];
    vc.accommodation = [self.locations[self.cities[indexPath.section]] objectAtIndex:indexPath.row];
    [self.parentViewController.navigationController pushViewController:vc animated:YES];
}


#pragma mark QLPreviewControllerDataSource
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return [self.previewingPhotos count];
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    Photo *photo = self.previewingPhotos[index];
    if (photo.photoPath) return [NSURL fileURLWithPath:photo.photoPath];
    
    return nil;
}


#pragma mark QLPreviewControllerDelegate
- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
    self.previewingPhotos = nil;
}


#pragma mark UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}


#pragma mark Collection View
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.cities ? [self.cities count] : 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.locations[self.cities[section]] count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(320, 100);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(self.collectionView.bounds.size.width, 80);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    CGFloat padding = [self padding];
    return UIEdgeInsetsMake(20, padding, 20, padding);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return [self padding];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return [self padding];
}

- (CGFloat)padding
{
    CGFloat padding = 0;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        padding = (self.view.bounds.size.width - (320 * 2)) / 3;
    }else {
        padding = (self.view.bounds.size.width - (320 * 3)) / 4;
    }
    
    return padding;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    IMAccommodationCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AccommodationCell" forIndexPath:indexPath];
    Accommodation *location = [self.locations[self.cities[indexPath.section]] objectAtIndex:indexPath.row];
    
    cell.buttonEdit.tintColor = [UIColor IMLightBlue];
    cell.buttonDetails.tintColor = [UIColor IMLightBlue];
    cell.labelTitle.text = location.name;
    cell.indexPath = indexPath;
    cell.onEdit = ^(NSIndexPath *currentIndexPath){ [self showEdit:currentIndexPath]; };
    cell.onShowDetails = ^(NSIndexPath *currentIndexPath) { [self showDetails:currentIndexPath]; };
    [cell setSingleOccupancy:location.singleOccupancy.integerValue forCapacity:location.singleCapacity.integerValue];
    [cell setFamilyOccupancy:location.familyOccupancy.integerValue forCapacity:location.familyCapacity.integerValue];
    
    if ([location.photos count] && self.collectionView.dragging == NO && self.collectionView.decelerating == NO) {
        [self updatePhotoForCell:cell withAccommodation:location];
    }else {
        UIImage *image = [UIImage imageNamed:@"PhotoPlaceholder"];
        cell.imageView.image = image;
        cell.onShowPhotos = nil;
    }
    
    cell.buttonEdit.enabled = [IMAuthManager sharedManager].activeUser.roleOperation;
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    IMCollectionHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
    header.labelTitle.text = self.cities[indexPath.section];
    header.labelTitle.textColor = [UIColor IMLightBlue];
    
    return header;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.selectedIndexPath isEqual:indexPath]) {
        self.selectedIndexPath = nil;
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }else {
        self.selectedIndexPath = indexPath;
    }
}


#pragma mark UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) [self loadPhotoForVisibleItems];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (!self.loadingPhotos) [self loadPhotoForVisibleItems];
}


#pragma mark Responsive Image Loader
- (void)loadPhotoForVisibleItems
{
    self.loadingPhotos = YES;
    for (NSIndexPath *indexPath in [self.collectionView indexPathsForVisibleItems]) {
        Accommodation *location = [self.locations[self.cities[indexPath.section]] objectAtIndex:indexPath.row];
        IMAccommodationCell *cell = (IMAccommodationCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if ([location.photos count]) [self updatePhotoForCell:cell withAccommodation:location];
    }
    self.loadingPhotos = NO;
}

- (void)updatePhotoForCell:(IMAccommodationCell *)cell withAccommodation:(Accommodation *)accommodation
{
    UIImage *image = [[accommodation.photos anyObject] photoImage];
    cell.imageView.image = image ? image : [UIImage imageNamed:@"PhotoPlaceholder"];
    cell.onShowPhotos = ^(NSIndexPath *currentIndexPath){ [self showPhotoViewer:currentIndexPath]; };
}


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    if (!self.basePredicate) _basePredicate = [NSPredicate predicateWithFormat:@"active = YES"];
    
    self.view.tintColor = [UIColor IMLightBlue];
    [self.collectionView setContentInset:UIEdgeInsetsMake(0, 0, 44, 0)];
    [self.collectionView registerNib:[UINib nibWithNibName:@"AccommodationCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"AccommodationCell"];
    [self.collectionView registerClass:[IMCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:IMDatabaseChangedNotification object:nil];
    
    [self reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (![self.locations count]) [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.selectedIndexPath) {
        [self.collectionView deselectItemAtIndexPath:self.selectedIndexPath animated:YES];
        self.selectedIndexPath = nil;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.collectionView reloadData];
}

@end