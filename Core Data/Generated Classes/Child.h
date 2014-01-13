//
//  Child.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/21/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FamilyData;

@interface Child : NSManagedObject

@property (nonatomic, retain) NSString * registrationNumber;
@property (nonatomic, retain) FamilyData *familyData;

@end
