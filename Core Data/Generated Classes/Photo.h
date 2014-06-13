//
//  Photo.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 9/25/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Accommodation, InterceptionData, InterceptionLocation;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSString * photoId;
@property (nonatomic, retain) Accommodation *accommodation;
@property (nonatomic, retain) InterceptionData *interceptionData;
@property (nonatomic, retain) InterceptionLocation *interceptionLocation;

@end
