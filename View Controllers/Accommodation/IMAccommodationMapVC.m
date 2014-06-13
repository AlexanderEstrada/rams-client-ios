//
//  IMAccommodationMapVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/21/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMAccommodationMapVC.h"
#import "Accommodation+Extended.h"
#import <GoogleMaps/GoogleMaps.h>
#import "IMDBManager.h"
#import "IMAccommodationInfoWindow.h"
#import "IMEditAccommodationVC.h"
#import "IMAccommodationDetailVC.h"


@interface IMAccommodationMapVC ()<GMSMapViewDelegate, UIPopoverControllerDelegate, IMAccommodationInfoWindowDelegate>

@property (nonatomic, strong) GMSMapView *mapView;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) GMSMarker *selectedMarker;
@property (nonatomic, strong) IMAccommodationInfoWindow *infoWindow;

@end


@implementation IMAccommodationMapVC

#define kLatitude -0.5
#define kLongitude 117


#pragma mark Marker Selection Worfklow
- (void)setSelectedMarker:(GMSMarker *)selectedMarker
{
    if (!selectedMarker && _selectedMarker) {
        _selectedMarker.icon = [GMSMarker markerImageWithColor:[UIColor IMLightBlue]];
    }
    
    _selectedMarker = selectedMarker;
    
    if (self.selectedMarker) {
        self.selectedMarker.icon = [GMSMarker markerImageWithColor:[UIColor IMYellow]];
    }
}

#pragma mark GMSMapViewDelegate
- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
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
        self.infoWindow = [self.storyboard instantiateViewControllerWithIdentifier:@"IMAccommodationInfoWindow"];
        self.infoWindow.delegate = self;
        self.infoWindow.accommodation = marker.userData;
    }
    
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:self.infoWindow];
    navCon.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
    self.infoWindow.view.tintColor = self.view.tintColor;
    
    if (!self.popover) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:navCon];
        self.popover.delegate = self;
    }
}

- (void)showPopoverFromCoordinate:(CLLocationCoordinate2D)coordinate
{
    CGPoint point = [self.mapView.projection pointForCoordinate:coordinate];
    CGRect rect = CGRectMake(point.x, point.y, 1, 1);
    [self.popover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)hidePopover
{
    if (self.popover) [self.popover dismissPopoverAnimated:YES];
}


#pragma mark IMAccommodationInfoWindowDelegate
- (void)showAccommodationDetail:(Accommodation *)accommodation
{
    [self.popover dismissPopoverAnimated:YES];
    [self popoverControllerDidDismissPopover:self.popover];
    
    IMAccommodationDetailVC *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IMAccommodationDetailVC"];
    vc.accommodation = accommodation;
    [self.parentViewController.navigationController pushViewController:vc animated:YES];
}

- (void)showEditAccommodation:(Accommodation *)accommodation
{
    [self.popover dismissPopoverAnimated:YES];
    [self popoverControllerDidDismissPopover:self.popover];
    
    IMEditAccommodationVC *vc = [[IMEditAccommodationVC alloc] initWithAccommodation:accommodation];
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
    navCon.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
    [self.parentViewController presentViewController:navCon animated:YES completion:nil];
}


#pragma mark UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
    self.selectedMarker = nil;
    self.infoWindow = nil;
}


#pragma mark Data Management
- (void)reloadData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapView clear];
        [self.mapView setCamera:[GMSCameraPosition cameraWithLatitude:kLatitude longitude:kLongitude zoom:5]];
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ACC_ENTITY_NAME];
        request.predicate = self.basePredicate;
        NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        NSError *error;
        NSArray *data = [context executeFetchRequest:request error:&error];
        
        GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] init];
        
        for (Accommodation *acc in data) {
            if (acc.latitude.doubleValue != 0 && acc.longitude.doubleValue != 0) {
                GMSMarker *marker = [[GMSMarker alloc] init];
                marker.userData = acc;
                marker.appearAnimation = kGMSMarkerAnimationNone;
                marker.position = CLLocationCoordinate2DMake(acc.latitude.doubleValue, acc.longitude.doubleValue);
                marker.icon = [GMSMarker markerImageWithColor:[UIColor IMLightBlue]];
                marker.map = self.mapView;
                bounds = [bounds includingCoordinate:marker.position];
            }
        }
        
        GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds withEdgeInsets:UIEdgeInsetsMake(50, 50, 50, 50)];
        [self.mapView moveCamera:update];
    });
}

- (void)setBasePredicate:(NSPredicate *)basePredicate
{
    _basePredicate = basePredicate;
    [self reloadData];
}


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.basePredicate) _basePredicate = [NSPredicate predicateWithFormat:@"active = YES"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:IMDatabaseChangedNotification object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:kLatitude longitude:kLongitude zoom:5];
        self.mapView = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
        self.mapView.delegate = self;
        self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.mapView.translatesAutoresizingMaskIntoConstraints = YES;
        [self.view addSubview:self.mapView];
        [self reloadData];
    });
}

@end
