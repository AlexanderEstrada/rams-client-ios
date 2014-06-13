//
//  IMConstants.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 29/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMConstants.h"

@implementation IMConstants

NSString *const CONST_UNHCR_DOCUMENT            = @"UNHCRDocument";
NSString *const CONST_UNHCR_STATUS              = @"UNHCRStatus";
NSString *const CONST_GENDER                    = @"Gender";
NSString *const CONST_DETENTION_LOCATION_TYPE   = @"MovementType";
NSString *const CONST_MARITAL_STATUS            = @"MaritalStatus";
NSString *const CONST_MOVEMENT_TYPE             = @"MovementType";
NSString *const CONST_TRAVEL_MODE               = @"TravelMode";
NSString *const CONST_VULNERABILITY             = @"Vulnerability";
NSString *const CONST_ROOT                      = @"Root";
NSString *const CONST_IMConstantKeys            = @"IMConstantKeys";
NSString *const CONST_LOCATION                  = @"DetentionLocationType";


//NSString  * _UrlName = @"http://172.25.137.149:8080/";
NSString  * _UrlName = @"https://im.iom.or.id/api";


+ (NSArray *)constantsForKey:(NSString *)key
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Constants" ofType:@"plist"]];
    return [dictionary objectForKey:key];
}

+ (void)setConstantForKey:(NSString *)key withValue:(NSString *)value;
{
    dispatch_queue_t constantQueue;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    constantQueue = dispatch_queue_create("constantQueue", NULL);
    dispatch_sync(constantQueue, ^{
        
        [defaults setObject:value forKey:key];
        [defaults synchronize];
    });
    
    
}

+ (void) initialize
{
    if (self == [IMConstants class]) {
         NSDictionary *dictionary = [[self constantsForKey:CONST_IMConstantKeys] mutableCopy];
        
        if (!IMAPIKey)[self setConstantForKey:@"API Key" withValue:[dictionary objectForKey:IMAPIKeyConstant]];
        
        if (!IMAPISecret)[self setConstantForKey:@"API Secret" withValue:[dictionary objectForKey:IMAPISecretKey]];
        
   
        if (!IMBaseURL)[self setConstantForKey:@"API URL" withValue:[dictionary objectForKey:IMBaseURLKey]];

        if (!IMGoogleAPIKey)[self setConstantForKey:@"Google Places API KEY" withValue:[dictionary objectForKey:IMGoogleAPIKeyConstant]];
	}
}


+ (NSString *) constantStringForKey:(NSString *)key
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (NSString *)getURL
{
    return _UrlName;
}
- (void)setURL:(NSString*)URLname
{
    if ( URLname != _UrlName ) {
        _UrlName = [URLname copy];
    }
}
@end