//
//  MYGooglePlaces.m
//  Google Places
//
//  Created by Mario Yohanes on 8/1/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMGPlacesFetcher.h"
#import "IMConstants.h"

@interface IMGPlacesFetcher ()

@property (nonatomic, strong) NSString *nearbyPageToken;
@property (nonatomic, strong) NSString *searchPageToken;
@property (nonatomic, readwrite) BOOL hasNext;

@end


@implementation IMGPlacesFetcher

#define kGPTypes        @"airport|amusement_park|bus_station|campground|city_hall|courthouse|embassy|hospital|local_government_office|park|police|subway_station|train_station|establishment|lodging"
#define kGPResults      @"results"
#define kGPPageToken    @"next_page_token"


- (id)initWithCompletionHandler:(IMGPlacesHandler)completionHandler
{
    self = [super init];
    self.completionHandler = completionHandler;
    return self;
}

- (void)fetchNearbyLocations:(CLLocationCoordinate2D)coordinate
{
    dispatch_queue_t queue = dispatch_queue_create("NearbyLocationsFetcher", NULL);
    dispatch_async(queue, ^{
        NSMutableString *query = [[NSMutableString alloc] init];
        [query appendString:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json?"];
        [query appendFormat:@"location=%f,%f", coordinate.latitude, coordinate.longitude];
        [query appendFormat:@"&radius=1000"];
        [query appendString:@"&sensor=true"];
        [query appendFormat:@"&types=%@",kGPTypes];
        [query appendFormat:@"&key=%@", IMGoogleAPIKey];
        
        //add page token if exists
        if (self.nearbyPageToken) [query appendFormat:@"&pagetoken=%@", self.nearbyPageToken];
        
        NSURL *url = [NSURL URLWithString:[query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:15];
        
        NSError *error;
        NSHTTPURLResponse *response;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (data) {
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if (dictionary) {
                self.nearbyPageToken = CORE_DATA_OBJECT(dictionary[kGPPageToken]);
                
                NSMutableArray *places = [NSMutableArray array];
                NSArray *placesDictionaries = dictionary[kGPResults];
                for (NSDictionary *dict in placesDictionaries) {
                    IMGPlace *place = [[IMGPlace alloc] initWithDictionary:dict fromGooglePlaces:YES];
                    if (place) [places addObject:place];
                }
                
                [self finalizeRequest:places hasNext:self.nearbyPageToken != nil];
            }else {
                NSLog(@"Error parsing JSON from Google Places: %@", [error description]);
                [self finalizeRequest:nil hasNext:NO];
            }
        }else {
            NSLog(@"Error fetching nearby locations: %@", [error description]);
            [self finalizeRequest:nil hasNext:NO];
        }
    });
}

- (void)searchPlacesWithKeyword:(NSString *)keyword
{
    if ([[keyword lowercaseString] rangeOfString:@"indonesia"].location != NSNotFound) {
        keyword = [NSString stringWithFormat:@"%@,indonesia", keyword];
    }
    
    dispatch_queue_t queue = dispatch_queue_create("SearchLocationsFetcher", NULL);
    dispatch_async(queue, ^{
        NSURL *url = [self textSearchURLWithKeyword:keyword];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:15];
        
        NSError *error;
        NSHTTPURLResponse *response;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (data) {
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if (dictionary) {
                self.nearbyPageToken = CORE_DATA_OBJECT(dictionary[kGPPageToken]);
                
                NSMutableArray *places = [NSMutableArray array];
                NSArray *placesDictionaries = dictionary[kGPResults];
                for (NSDictionary *dict in placesDictionaries) {
                    IMGPlace *place = [[IMGPlace alloc] initWithDictionary:dict fromGooglePlaces:NO];
                    if (place) [places addObject:place];
                }
                
                [self finalizeRequest:places hasNext:self.nearbyPageToken != nil];
            }else {
                NSLog(@"Error parsing JSON from Google Places: %@", [error description]);
                [self finalizeRequest:nil hasNext:NO];
            }
        }else {
            NSLog(@"Error fetching nearby locations: %@", [error description]);
            [self finalizeRequest:nil hasNext:NO];
        }
    });
}

- (void)resetRequest
{
    self.nearbyPageToken = nil;
    self.searchPageToken = nil;
}

- (void)finalizeRequest:(NSArray *)result hasNext:(BOOL)hasNext;
{
    dispatch_async(dispatch_get_main_queue(), ^{ if (self.completionHandler) self.completionHandler(result, hasNext); });
}

- (NSURL *)textSearchURLWithKeyword:(NSString *)keyword
{
    NSMutableString *query = [[NSMutableString alloc] init];
    [query appendString:@"http://maps.googleapis.com/maps/api/geocode/json?address="];
    
    NSArray *fractions = [keyword componentsSeparatedByString:@","];
    for (int i=0; i<[fractions count]; i++) {
        NSString *fraction = fractions[i];
        NSArray *words = [fraction componentsSeparatedByString:@" "];
        
        for (int j=0; j<[words count]; j++) {
            [query appendString:words[j]];
            if (j < [words count] - 1) [query appendString:@"+"];
        }
        
        if (i < [fractions count] - 1) [query appendString:@",+"];
    }
    
    [query appendString:@"&sensor=true"];
    
    return [NSURL URLWithString:[query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (void)fetchDetailsForPlace:(IMGPlace *)place completionHandler:(IMGPlaceDetailsHandler)handler
{
    dispatch_queue_t queue = dispatch_queue_create("DetailsFetcher", NULL);
    dispatch_async(queue, ^{
        NSMutableString *query = [[NSMutableString alloc] init];
        [query appendString:@"https://maps.googleapis.com/maps/api/place/details/json?"];
        [query appendFormat:@"reference=%@", place.reference];
        [query appendString:@"&sensor=true"];
        [query appendFormat:@"&key=%@", IMGoogleAPIKey];
        
        NSURL *url = [NSURL URLWithString:[query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:15];
        
        NSError *error;
        NSHTTPURLResponse *response;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (data) {
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if (dictionary && handler) handler (dictionary);
            else NSLog(@"Error parsing JSON from Google Places: %@", [error description]);
        }else {
            NSLog(@"Error fetching nearby locations: %@", [error description]);
        }
    });
}

@end
