//
//  IMRegistrationListVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMCollectionViewController.h"


@interface IMRegistrationListVC : IMCollectionViewController

@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic, strong) NSMutableArray *data;
@property (nonatomic) BOOL reloadingData;
@property (nonatomic) BOOL firstLaunch;
@property (nonatomic, strong) NSOperationQueue *thumbnailQueue;
@end


