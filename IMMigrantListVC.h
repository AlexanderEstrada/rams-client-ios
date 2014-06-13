//
//  IMMigrantListVC.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 6/2/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMCollectionViewController.h"
#import <Foundation/NSObject.h>
#import <Foundation/NSOperation.h>


@interface IMMigrantListVC : IMCollectionViewController


@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic, strong) NSMutableArray *data;
@property (nonatomic) BOOL reloadingData;
@property (nonatomic, strong) NSOperationQueue *thumbnailQueue;
@property (nonatomic) BOOL firstLaunch;

@end
