//
//  IMCollectionViewController.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/2/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IMSideMenuDelegate.h"
#import "IMHTTPClient.h"
#import "UIColor+IMMS.h"
#import "UIButton+IMMS.h"
#import "UIFont+IMMS.h"


@interface IMCollectionViewController : UICollectionViewController<UICollectionViewDelegateFlowLayout>

@property (nonatomic, assign) id<IMSideMenuDelegate>sideMenuDelegate;
@property (nonatomic, strong) UILabel *labelLoading;

@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL useBackground;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showLoadingView;
- (void)showLoadingViewWithTitle:(NSString *)title;
- (void)hideLoadingView;

@end