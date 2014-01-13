//
//  IMViewController.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 10/23/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IMSideMenuDelegate.h"
#import "IMConstants.h"
#import "IMHTTPClient.h"
#import "UIColor+IMMS.h"
#import "UIButton+IMMS.h"
#import "UIFont+IMMS.h"


@interface IMViewController : UIViewController

@property (nonatomic, assign) id<IMSideMenuDelegate>sideMenuDelegate;
@property (nonatomic, strong) UILabel *labelLoading;

- (void)showLoadingView;
- (void)showLoadingViewWithTitle:(NSString *)title;
- (void)hideLoadingView;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;

@end