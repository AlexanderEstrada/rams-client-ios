//
//  IMInterceptionDataUpdater.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/27/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMDataUpdater.h"
#import "InterceptionGroup+Extended.h"
#import "InterceptionMovement+Extended.h"

@interface IMInterceptionDataUpdater : IMDataUpdater

- (void)submitInterceptionData:(NSDictionary *)params;
- (void)submitMovement:(NSDictionary *)params;
- (void)toggleActive:(NSDictionary *)params;

@end