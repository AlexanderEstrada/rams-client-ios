//
//  IMMigrantViewController.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 4/15/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IMViewController.h"

@interface IMMigrantViewController : UITabBarController

@property (nonatomic, assign) id<IMSideMenuDelegate> sideMenuDelegate;

@end
