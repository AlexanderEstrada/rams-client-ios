//
//  IMMovementListVC.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 7/24/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMCollectionViewController.h"
#import "DataReceiver.h"
#import "Movement.h"
#import "IMMovementsReviewVC.h"

@protocol IMMovementListVCDelegate;


@interface IMMovementListVC : IMCollectionViewController <DataReceiver,IMMovementsReviewVCDelegate>

@property (weak, atomic) id<IMMovementListVCDelegate> delegate;
@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic) BOOL reloadingData;
@property (nonatomic, strong) NSOperationQueue *thumbnailQueue;
@property (nonatomic) int currentIndex;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *navNext;
@property (nonatomic, strong) Movement *movement;

- (void)reloadData;
- (id)initWithPredicate:(NSPredicate *)basepredicate;


@end

@protocol IMMovementListVCDelegate <NSObject>

@end