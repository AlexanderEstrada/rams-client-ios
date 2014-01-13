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

+ (NSArray *)constantsForKey:(NSString *)key
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Constants" ofType:@"plist"]];
    return [dictionary objectForKey:key];
}

@end