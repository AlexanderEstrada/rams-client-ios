//
//  Interception.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/2/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Migrant;

@interface Interception : NSManagedObject

@property (nonatomic, retain) NSDate * dateOfEntry;
@property (nonatomic, retain) NSDate * interceptionDate;
@property (nonatomic, retain) NSString * interceptionId;
@property (nonatomic, retain) NSString * interceptionLocation;
@property (nonatomic, retain) Migrant *migrant;

@end
