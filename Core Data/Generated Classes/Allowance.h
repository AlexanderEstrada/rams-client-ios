//
//  Allowance.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/2/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class IomData;

@interface Allowance : NSManagedObject

@property (nonatomic, retain) NSNumber * allowanceId;
@property (nonatomic, retain) NSDecimalNumber * amount;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * family;
@property (nonatomic, retain) IomData *iomData;

@end
