//
//  MYGooglePlaces.h
//  Google Places
//
//  Created by Mario Yohanes on 8/1/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "IMGPlace.h"


typedef void(^IMGPlacesHandler)(NSArray *places, BOOL hasNext);
typedef void(^IMGPlaceDetailsHandler)(NSDictionary *details);

@interface IMGPlacesFetcher : NSObject

@property (nonatomic, copy) IMGPlacesHandler completionHandler;

+ (void)fetchDetailsForPlace:(IMGPlace *)place completionHandler:(IMGPlaceDetailsHandler)handler;

- (id)initWithCompletionHandler:(IMGPlacesHandler)completionHandler;

- (void)fetchNearbyLocations:(CLLocationCoordinate2D)coordinate;
- (void)searchPlacesWithKeyword:(NSString *)keyword;
- (void)resetRequest;

@end
