//
//  InterceptionLocation.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/2/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class InterceptionData, Photo;

@interface InterceptionLocation : NSManagedObject

@property (nonatomic, retain) NSString * administrativeArea;
@property (nonatomic, retain) NSNumber * interceptionLocationId;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * locality;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *interceptionDatas;
@property (nonatomic, retain) NSSet *photos;
@end

@interface InterceptionLocation (CoreDataGeneratedAccessors)

- (void)addInterceptionDatasObject:(InterceptionData *)value;
- (void)removeInterceptionDatasObject:(InterceptionData *)value;
- (void)addInterceptionDatas:(NSSet *)values;
- (void)removeInterceptionDatas:(NSSet *)values;

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

@end
