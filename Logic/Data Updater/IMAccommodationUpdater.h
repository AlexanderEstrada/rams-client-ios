//
//  IMAccommodationUpdater.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/11/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMDataUpdater.h"

@interface IMAccommodationUpdater : IMDataUpdater

- (void)sendUpdate:(NSDictionary *)params;

@end