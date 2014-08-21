//
//  IMMovementReviewTableVC.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 8/19/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IMTableViewController.h"
#import "Movement+Extended.h"


@class IMMovementReviewTableVC;
@protocol IMMovementReviewTableVCDelegate<NSObject>

@required
-(void)showMigrantList:(IMMovementReviewTableVC *)view shouldShowMigrantList:(BOOL)bShowMigrantList;
@end

@interface IMMovementReviewTableVC : IMTableViewController
@property (weak, atomic) id<IMMovementReviewTableVCDelegate> delegate;
@property (nonatomic,strong) NSMutableDictionary *migrantData;
@property (nonatomic, strong) NSMutableArray *migrants;
@property (nonatomic, strong) Movement *movement;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
@end

