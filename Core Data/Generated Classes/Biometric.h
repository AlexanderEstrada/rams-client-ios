//
//  Biometric.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/21/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Migrant;




@interface Biometric : NSManagedObject

@property (nonatomic, retain) NSString * biometricId;
@property (nonatomic, retain) NSString * leftIndexImage;
@property (nonatomic, retain) NSString * leftThumbImage;
@property (nonatomic, retain) NSString * photograph;
@property (nonatomic, retain) NSString * rightIndexImage;
@property (nonatomic, retain) NSString * rightThumbImage;
@property (nonatomic, retain) NSString * leftIndexTemplate;
@property (nonatomic, retain) NSString * rightIndexTemplate;
@property (nonatomic, retain) NSString * rightThumbTemplate;
@property (nonatomic, retain) NSString * leftThumbTemplate;
@property (nonatomic, retain) Migrant *migrant;

@end
