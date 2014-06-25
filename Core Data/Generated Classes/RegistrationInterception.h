//
//  RegistrationInterception.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Registration;

@interface RegistrationInterception : NSManagedObject

@property (nonatomic, retain) NSDate * dateOfEntry;
@property (nonatomic, retain) NSDate * interceptionDate;
@property (nonatomic, retain) NSString * interceptionLocation;
@property (nonatomic, retain) NSNumber * selfReporting;
@property (nonatomic, retain) Registration *registration;

@end
