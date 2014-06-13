//
//  IMInterceptionMapVC.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/10/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMViewController.h"
#import "IMInterceptionDataSource.h"
#import <GoogleMaps/GoogleMaps.h>


@interface IMInterceptionMapVC : IMViewController

@property (nonatomic, assign) id<IMInterceptionDataSource> dataSource;
@property (nonatomic, assign) id<IMInterceptionDelegate> delegate;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) GMSMapView *mapView;

- (void)reloadData;
- (void)hidePopover;

@end