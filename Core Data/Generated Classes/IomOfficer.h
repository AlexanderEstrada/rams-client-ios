//
//  IomOfficer.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/26/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class InterceptionData;

@interface IomOfficer : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSSet *interceptionDatas;
@end

@interface IomOfficer (CoreDataGeneratedAccessors)

- (void)addInterceptionDatasObject:(InterceptionData *)value;
- (void)removeInterceptionDatasObject:(InterceptionData *)value;
- (void)addInterceptionDatas:(NSSet *)values;
- (void)removeInterceptionDatas:(NSSet *)values;

@end
