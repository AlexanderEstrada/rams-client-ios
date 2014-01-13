//
//  IMInterceptionLocationUpdater.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/12/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMDataUpdater.h"

@interface IMInterceptionLocationUpdater : IMDataUpdater

- (void)submitInterceptionLocation:(NSDictionary *)params;

@end
