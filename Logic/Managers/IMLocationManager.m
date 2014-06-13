//
//  ILLocationManager.m
//  Interceptions
//
//  Created by Mario Yohanes on 4/16/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMLocationManager.h"
#import <UIKit/UIKit.h>


@interface IMLocationManager()<CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@end


@implementation IMLocationManager

NSString *const IMLOCATION_LATITUDE     = @"latitude";
NSString *const IMLOCATION_LONGITUDE    = @"longitude";

+ (IMLocationManager *)sharedManager
{
    static dispatch_once_t once;
    static IMLocationManager *singleton = nil;
    
    dispatch_once(&once, ^{
        singleton = [[IMLocationManager alloc] init];
    });
    
    return singleton;
}

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.delegate = self;
        _locationManager.pausesLocationUpdatesAutomatically = YES;
    }

    return _locationManager;
}

- (BOOL)locationServicesAvailable
{
    return [CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized;
}

- (CLLocationCoordinate2D)currentCoordinate
{
    return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

- (void)startUpdatingLocation
{
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation
{
    [self.locationManager stopUpdatingLocation];
}

- (void)startMonitoringRegions:(NSArray *)regions
{    
    for (CLRegion *region in regions) {
        [self.locationManager startMonitoringForRegion:region];
    }
}

- (void)stopMonitoringRegions
{
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }
    
    [self stopUpdatingLocation];
}

- (void)postLocationUpdate
{
    NSDictionary *userInfo = @{IMLOCATION_LATITUDE:@(self.latitude), IMLOCATION_LONGITUDE:@(self.longitude)};
    [[NSNotificationCenter defaultCenter] postNotificationName:IMLocationDidChangedNotification object:nil userInfo:userInfo];
}


#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorized) {
        [self.locationManager startUpdatingLocation];
    }else {
        [self postLocationUpdate];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    @try {
        CLLocation *location = [locations lastObject];
        _longitude = location.coordinate.longitude;
        _latitude = location.coordinate.latitude;
        
        if (_longitude != 0 && _latitude != 0) {
            [self.locationManager stopUpdatingLocation];
            [self postLocationUpdate];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception updating location: %@", [exception description]);
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSDictionary *userInfo = @{@"region":region};
    [[NSNotificationCenter defaultCenter] postNotificationName:IMUserEnteringRegionNotification object:nil userInfo:userInfo];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSDictionary *userInfo = @{@"region":region};
    [[NSNotificationCenter defaultCenter] postNotificationName:IMUserExitingRegionNotification object:nil userInfo:userInfo];
}

@end
