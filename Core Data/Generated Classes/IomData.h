//
//  IomData.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/3/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Allowance, IomOffice, Migrant;

@interface IomData : NSManagedObject

@property (nonatomic, retain) NSString * iomDataId;
@property (nonatomic, retain) NSSet *allowances;
@property (nonatomic, retain) IomOffice *associatedOffice;
@property (nonatomic, retain) Migrant *migrant;
@end

@interface IomData (CoreDataGeneratedAccessors)

- (void)addAllowancesObject:(Allowance *)value;
- (void)removeAllowancesObject:(Allowance *)value;
- (void)addAllowances:(NSSet *)values;
- (void)removeAllowances:(NSSet *)values;

@end
