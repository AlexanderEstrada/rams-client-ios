//
//  IMCountryListVC.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/5/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMViewController.h"
#import "Country+Extended.h"

@interface IMCountryListVC : IMViewController

@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic, copy) void (^onSelected)(Country *selectedCountry);
@property (nonatomic, copy) void (^onCancel)(void);

- (id)initWithBasePredicate:(NSPredicate *)basePredicate presentAsModal:(BOOL)modal popover:(BOOL)popover;


- (id)initWithBasePredicate:(NSPredicate *)basePredicate presentAsModal:(BOOL)modal popover:(BOOL)popover withEntity:(NSString*)entity sortDescriptorWithKey:(NSString*)key;

@end
