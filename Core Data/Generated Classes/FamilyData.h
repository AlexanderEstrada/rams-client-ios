//
//  FamilyData.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/21/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Child, Migrant;

@interface FamilyData : NSManagedObject

@property (nonatomic, retain) NSString * father;
@property (nonatomic, retain) NSString * mother;
@property (nonatomic, retain) NSString * spouse;
@property (nonatomic, retain) NSSet *childs;
@property (nonatomic, retain) Migrant *migrant;
@end

@interface FamilyData (CoreDataGeneratedAccessors)

- (void)addChildsObject:(Child *)value;
- (void)removeChildsObject:(Child *)value;
- (void)addChilds:(NSSet *)values;
- (void)removeChilds:(NSSet *)values;

@end
