//
//  FamilyRegister.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 8/18/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FamilyRegisterEntry;

@interface FamilyRegister : NSManagedObject

@property (nonatomic, retain) NSString * familyID;
@property (nonatomic, retain) NSString * headOfFamilyId;
@property (nonatomic, retain) NSString * headOfFamilyName;
@property (nonatomic, retain) NSString * photographThumbnail;
@property (nonatomic, retain) NSString * photograph;
@property (nonatomic, retain) NSSet *familyEntryID;
@end

@interface FamilyRegister (CoreDataGeneratedAccessors)

- (void)addFamilyEntryIDObject:(FamilyRegisterEntry *)value;
- (void)removeFamilyEntryIDObject:(FamilyRegisterEntry *)value;
- (void)addFamilyEntryID:(NSSet *)values;
- (void)removeFamilyEntryID:(NSSet *)values;

@end
