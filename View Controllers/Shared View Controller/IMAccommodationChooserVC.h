//
//  IMAccommodationListVC.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/5/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMViewController.h"
#import "Accommodation+Extended.h"


@interface IMAccommodationChooserVC : IMViewController

@property (nonatomic) BOOL allowsCreate;
@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic, strong) NSArray *options;

@property (nonatomic, copy) void (^onSelected)(Accommodation *selectedAccommodation);
@property (nonatomic, copy) void (^onCancel)(void);

- (id)initWithBasePredicate:(NSPredicate *)basePredicate presentAsModal:(BOOL)modal;
- (id)initWithBasePredicate:(NSPredicate *)basePredicate presentAsModal:(BOOL)modal withEntity:(NSString *)entity sortDescriptorWithKey:(NSString*)key;
- (void)setupFetchRequestWithPredicate:(NSPredicate *)filterPredicate;

@end