//
//  IMRegistrationFilterDataVC.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 4/11/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMTableViewController.h"
#import "Country.h"
#import "Accommodation.h"


typedef struct age_struct{
    int min;
    int max;
}age_struct;

@interface IMRegistrationFilterDataVC : IMTableViewController


@property (nonatomic) Country * country;
@property (nonatomic) Accommodation * detentionLocation;
@property (nonatomic) NSString* gender;
@property (nonatomic) NSString* name;
@property (nonatomic) NSMutableDictionary* result;
@property (nonatomic, strong) NSPredicate *basePredicate;
@property int age_max;
@property int age_min;
@property (nonatomic) BOOL activeMigrant;


@property (nonatomic, copy) void (^onSelected)(NSPredicate *basePredicate);
@property (nonatomic, copy) void (^doneCompletionBlock)(NSMutableDictionary *data);


- (id)initWithAction:(void (^)(NSPredicate *basePredicate))onSelected andBasePredicate:(NSPredicate *)basepredicate;
- (id)initWithAction:(void (^)(NSPredicate *basePredicate))onSelected;
- (void)resetValue;
- (NSDate *)calculateAge:(int)ageValue;

@end
