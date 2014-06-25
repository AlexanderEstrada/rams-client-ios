//
//  IMInterceptionMapVC.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/10/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMInterceptionMapVC.h"
#import "InterceptionData+Extended.h"
#import "NSDate+Relativity.h"
#import "IMinterceptionInfoVC.h"


@interface IMInterceptionMapVC ()<GMSMapViewDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) UINavigationController *inforWindowNavigation;
@property (nonatomic, strong) IMinterceptionInfoVC *infoWindow;
@property (nonatomic) BOOL firstLaunch;
@property (nonatomic, weak) GMSMarker *selectedMarker;

@end


@implementation IMInterceptionMapVC




#pragma mark UI Logic
- (void)reloadData
{
    [self.mapView clear];
    [self.mapView setCamera:[GMSCameraPosition cameraWithLatitude:IMLatitude longitude:IMLongitude zoom:5]];
        
    for (NSDictionary *groupDict in [self.dataSource interceptionDataByLocation]) {
        GMSMarker *marker = [[GMSMarker alloc] init];
        marker.userData = groupDict;
        marker.appearAnimation = kGMSMarkerAnimationNone;
        marker.position = CLLocationCoordinate2DMake([groupDict[kLocationGroupLatitude] doubleValue], [groupDict[kLocationGroupLongitude] doubleValue]);
        marker.icon = [GMSMarker markerImageWithColor:[UIColor IMRed]];
        marker.map = self.mapView;
    }
}

- (void)setSelectedMarker:(GMSMarker *)selectedMarker
{
    if (!selectedMarker && _selectedMarker) {
        _selectedMarker.icon = [GMSMarker markerImageWithColor:[UIColor IMRed]];
    }
    
    _selectedMarker = selectedMarker;
    
    if (self.selectedMarker) {
        self.selectedMarker.icon = [GMSMarker markerImageWithColor:[UIColor IMLightBlue]];
    }
}

#pragma mark GMSMapViewDelegate
- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    [self.delegate willShowPopoverOnMap];
    [self buildPopoverForMarker:marker];
    [self showPopoverFromCoordinate:marker.position];
    self.selectedMarker = marker;
    
    return NO;
}

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position
{
    if (self.popover) [self showPopoverFromCoordinate:position.target];
}


#pragma mark Info Window Management
- (void)buildPopoverForMarker:(GMSMarker *)marker
{
    if (!self.infoWindow) {
        self.infoWindow = [[IMinterceptionInfoVC alloc] initWithData:[marker.userData objectForKey:kLocationGroupData]
                                                                    title:[marker.userData objectForKey:kLocationGroupTitle]
                                                                 delegate:self.delegate];
        self.inforWindowNavigation = [[UINavigationController alloc] initWithRootViewController:self.infoWindow];
    }else {
        [self.infoWindow setData:[marker.userData objectForKey:kLocationGroupData]
                        forTitle:[marker.userData objectForKey:kLocationGroupTitle]];
    }
    
    if (!self.popover) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:self.inforWindowNavigation];
        self.popover.delegate = self;
    }
}

- (void)showPopoverFromCoordinate:(CLLocationCoordinate2D)coordinate
{
    CGPoint point = [self.mapView.projection pointForCoordinate:coordinate];
    CGRect rect = CGRectMake(point.x, point.y, 1, 1);
    [self.popover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight animated:YES];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
    self.selectedMarker = nil;
}

- (void)hidePopover
{
    if (self.popover) [self.popover dismissPopoverAnimated:YES];
}


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:IMDatabaseChangedNotification object:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:IMLatitude longitude:IMLongitude zoom:5];
        self.mapView = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
        self.mapView.delegate = self;
        self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.mapView.translatesAutoresizingMaskIntoConstraints = YES;
        [self.view addSubview:self.mapView];
        [self reloadData];
    });
}

@end