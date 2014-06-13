//
//  IMSyncViewController.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/14/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMViewController.h"

@interface IMSyncViewController : IMViewController

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UILabel *labelProgress;
@property (weak, nonatomic) IBOutlet UIButton *buttonStart;

@property (weak, nonatomic) IBOutlet UILabel *labelWarning1;
@property (weak, nonatomic) IBOutlet UILabel *labelWarning2;
@property (weak, nonatomic) IBOutlet UILabel *labelWarning3;
@property (nonatomic) NSInteger updateState;
@property (nonatomic) int try_counter;

@property (weak, nonatomic) IBOutlet UIView *warningContainer;

@end
