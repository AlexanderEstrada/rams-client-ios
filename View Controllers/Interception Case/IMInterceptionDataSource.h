//
//  IMInterceptionDataSource.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 7/17/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>


#define kLocationGroupTitle         @"kLocationGroupTitle"
#define kLocationGroupLatitude      @"kLocationGroupLatitude"
#define kLocationGroupLongitude     @"kLocationGroupLongitude"
#define kLocationGroupData          @"kLocationGroupData"

@class InterceptionData;
@protocol IMInterceptionDataSource <NSObject>
- (NSArray *)interceptionDataByLocation;
@end

@protocol IMInterceptionDelegate <NSObject>
- (void)showDetailsForInterceptionData:(InterceptionData *)data;
- (void)showEditForInterceptionData:(InterceptionData *)data;
- (void)willShowPopoverOnMap;
@end