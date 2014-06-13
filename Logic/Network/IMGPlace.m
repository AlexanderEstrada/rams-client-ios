//
//  MYPlace.m
//  Google Places
//
//  Created by Mario Yohanes on 8/1/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMGPlace.h"

@implementation IMGPlace

#define kGPLocationName             @"name"
#define kGPAddress                  @"formatted_address"
#define kGPVicinity                 @"vicinity"
#define kGPIcon                     @"icon"
#define kGPReference                @"reference"
#define kGPGeometry                 @"geometry"
#define kGPGeometryLocation         @"location"
#define kGPGeometryLocationLat      @"lat"
#define kGPGeometryLocationLon      @"lng"

#define kGPResult                   @"result"
#define kGPAddressComponents        @"address_components"
#define kGPAALongName               @"long_name"
#define kGPAATypes                  @"types"

#define kGPTypeNature               @"natural_feature"
#define kGPTypeEstablishment        @"establishment"
#define kGPTypeLocality             @"locality"
#define kGPTypeSubLocality          @"sublocality"
#define kGPTypeAdministrative1      @"administrative_area_level_1"
#define kGPTypeAdministrative2      @"administrative_area_level_2"
#define kGPTypeAdministrative3      @"administrative_area_level_3"


- (id)init { return nil; }

- (id)initWithDictionary:(NSDictionary *)dictionary fromGooglePlaces:(BOOL)googlePlaces
{
    self = [super init];
    
    @try {
        if (dictionary[kGPAddress]) _address = dictionary[kGPAddress];
        else _address = dictionary[kGPVicinity];
        
        _name = dictionary[kGPLocationName];
        _reference = dictionary[kGPReference];
        
        NSDictionary *location = [dictionary[kGPGeometry] objectForKey:kGPGeometryLocation];
        double lat = [location[kGPGeometryLocationLat] doubleValue];
        double lon = [location[kGPGeometryLocationLon] doubleValue];
        _coordinate = CLLocationCoordinate2DMake(lat, lon);
        
        NSString *iconPath = dictionary[kGPIcon];
        if (iconPath) _icon = [NSURL URLWithString:iconPath];
        
        if (!googlePlaces) {
            [self setPlaceDetail:dictionary];
        }else {
            self.city = nil;
            self.province = nil;
        }
        
        _googlePlaces = googlePlaces;
    }
    @catch (NSException *exception) {
        NSLog(@"Error while parsing Google Place: %@\nError Message: %@", dictionary, [exception description]);
        return nil;
    }
    
    return self;
}

- (void)setPlaceDetail:(NSDictionary *)dictionary
{
    @try {
        NSArray *addressComponents = self.googlePlaces ? [dictionary[kGPResult] objectForKey:kGPAddressComponents] : dictionary[kGPAddressComponents];
        for (NSDictionary *component in addressComponents) {
            NSString *name = component[kGPAALongName];
            NSArray *types = component[kGPAATypes];
            
            if (!self.name && [types containsObject:kGPTypeEstablishment]) self.name = name;
            
            if (!self.city) {
                if ([types containsObject:kGPTypeAdministrative2]) self.city = name;
                else if ([types containsObject:kGPTypeLocality]) self.city = name;
                else if ([types containsObject:kGPTypeSubLocality]) self.city = name;
            }
            
            if (!self.province) {
                if ([types containsObject:kGPTypeAdministrative1]) self.province = name;
                else if ([types containsObject:kGPTypeNature]) self.province = name;
            }
            
            if (self.city && self.province) break;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Error while parsing Place Details: %@\nError Message: %@", dictionary, [exception description]);
    }
}

- (NSString *)description
{
    if (self.googlePlaces) return self.name;
    return self.address;
}

@end
