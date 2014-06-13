//
//  IMAccommodationInfoWindow.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/22/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMViewController.h"

@class Accommodation;
@protocol IMAccommodationInfoWindowDelegate <NSObject>

- (void)showAccommodationDetail:(Accommodation *)accommodation;
- (void)showEditAccommodation:(Accommodation *)accommodation;

@end


@interface IMAccommodationInfoWindow : IMViewController

@property (nonatomic, assign) id<IMAccommodationInfoWindowDelegate> delegate;
@property (nonatomic, strong) Accommodation *accommodation;

@end
