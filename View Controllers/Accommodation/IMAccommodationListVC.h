//
//  IMAccommodationViewController.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/2/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMCollectionViewController.h"

@interface IMAccommodationListVC : IMCollectionViewController

@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic) NSString *city;
@property (nonatomic) NSNumber *active;

- (void)reloadData;
- (void)reloadDataAll;

@end