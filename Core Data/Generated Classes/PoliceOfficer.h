//
//  PoliceOfficer.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/26/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class InterceptionData;

@interface PoliceOfficer : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSNumber * officerId;
@property (nonatomic, retain) InterceptionData *interceptionData;

@end
