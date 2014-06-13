//
//  IMTableViewController.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 11/8/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IMSideMenuDelegate.h"
#import "IMConstants.h"
#import "IMHTTPClient.h"
#import "UIColor+IMMS.h"
#import "UIButton+IMMS.h"
#import "IMTableViewCell.h"
#import "UIFont+IMMS.h"
#import "IMTableHeaderView.h"


@interface IMTableViewController : UITableViewController

@property (nonatomic, assign) id<IMSideMenuDelegate>sideMenuDelegate;
@property (nonatomic, strong) UILabel *labelLoading;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showLoadingView;
- (void)showLoadingViewWithTitle:(NSString *)title;
- (void)hideLoadingView;

@end
