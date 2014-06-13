//
//  ILLocationManager.h
//  Interceptions
//
//  Created by Mario Yohanes on 4/16/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define IMLocationDidChangedNotification        @"IMLocationDidChangedNotification"
#define IMUserEnteringRegionNotification        @"IMUserEnteringRegionNotification"
#define IMUserExitingRegionNotification         @"IMUserExitingRegionNotification"

@interface IMLocationManager : NSObject

extern NSString *const IMLOCATION_LATITUDE;
extern NSString *const IMLOCATION_LONGITUDE;

@property (nonatomic, readonly) double longitude;
@property (nonatomic, readonly) double latitude;

+ (IMLocationManager *)sharedManager;

- (CLLocationCoordinate2D)currentCoordinate;
- (BOOL)locationServicesAvailable;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

// Region monitoring
- (void)startMonitoringRegions:(NSArray *)regions;
- (void)stopMonitoringRegions;

@end
