//
//  RegistrationBiometric.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 28/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Registration;

@interface RegistrationBiometric : NSManagedObject

@property (nonatomic, retain) NSString * leftIndex;
@property (nonatomic, retain) NSString * rightIndex;
@property (nonatomic, retain) NSString * rightThumb;
@property (nonatomic, retain) NSString * leftThumb;
@property (nonatomic, retain) NSString * photograph;
@property (nonatomic, retain) NSString * photographThumbnail;
@property (nonatomic, retain) Registration *registration;

@end
