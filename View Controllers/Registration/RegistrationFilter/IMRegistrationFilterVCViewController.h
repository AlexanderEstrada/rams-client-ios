//
//  IMRegistrationFilterVCViewController.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 4/10/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMViewController.h"
#import "Country.h"
#import "Accommodation.h"

@import UIKit;


@interface IMRegistrationFilterVCViewController : UITabBarController


@property (nonatomic, strong) NSDictionary *result;

@property (nonatomic) Country* country;
@property (nonatomic) Accommodation * detentionLocation;
@property (nonatomic) NSString* gender;
@property (nonatomic) NSString* name;


-(BOOL)isNumeric:(NSString*)inputString;


@end
