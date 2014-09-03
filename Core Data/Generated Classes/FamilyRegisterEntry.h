//
//  FamilyRegisterEntry.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 9/2/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FamilyRegister;

@interface FamilyRegisterEntry : NSManagedObject

@property (nonatomic, retain) NSString * migrantId;
@property (nonatomic, retain) NSString * registerEntryId;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *familyID;
@end

@interface FamilyRegisterEntry (CoreDataGeneratedAccessors)

- (void)addFamilyIDObject:(FamilyRegister *)value;
- (void)removeFamilyIDObject:(FamilyRegister *)value;
- (void)addFamilyID:(NSSet *)values;
- (void)removeFamilyID:(NSSet *)values;

@end
