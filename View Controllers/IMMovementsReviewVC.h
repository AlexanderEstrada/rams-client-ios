//
//  IMMovementsReviewVC.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 7/30/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMCollectionViewController.h"

@protocol IMMovementsReviewVCDelegate;


@interface IMMovementsReviewVC : IMCollectionViewController
@property (weak, atomic) id<IMMovementsReviewVCDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *navSubmitButton;
@property (nonatomic,strong) NSMutableDictionary *migrantData;

@end


@protocol IMMovementsReviewVCDelegate <NSObject>

@end