//
//  IomOffice.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class InterceptionData, IomData, Registration;

@interface IomOffice : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phoneNumber;
@property (nonatomic, retain) NSSet *interceptionData;
@property (nonatomic, retain) NSSet *iomData;
@property (nonatomic, retain) NSSet *registrations;
@end

@interface IomOffice (CoreDataGeneratedAccessors)

- (void)addInterceptionDataObject:(InterceptionData *)value;
- (void)removeInterceptionDataObject:(InterceptionData *)value;
- (void)addInterceptionData:(NSSet *)values;
- (void)removeInterceptionData:(NSSet *)values;

- (void)addIomDataObject:(IomData *)value;
- (void)removeIomDataObject:(IomData *)value;
- (void)addIomData:(NSSet *)values;
- (void)removeIomData:(NSSet *)values;

- (void)addRegistrationsObject:(Registration *)value;
- (void)removeRegistrationsObject:(Registration *)value;
- (void)addRegistrations:(NSSet *)values;
- (void)removeRegistrations:(NSSet *)values;

@end
