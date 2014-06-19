//
//  IMCityChooserVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/8/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMViewController.h"

typedef enum : NSUInteger {
    type_predicate,
    type_value,
} filter_type;

@interface IMAccommodationFilterVC : IMViewController

@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic) BOOL active;
@property (nonatomic) NSString * city;

@property (nonatomic, copy) void (^onSelected)(NSPredicate *basePredicate);

@property (nonatomic, copy) void (^onSelectedValue)(BOOL active,NSString *city,NSPredicate *basePredicate);
@property (nonatomic, copy) void (^onUpdateView)(filter_type type);
@property (nonatomic, copy) void (^onFilterClear)(void);

- (id)initWithAction:(void (^)(NSPredicate *basePredicate))onSelected;
- (id)initWithValues:(void (^)(BOOL active,NSString * city,NSPredicate *basePredicate))onSelectedValue;

@end
