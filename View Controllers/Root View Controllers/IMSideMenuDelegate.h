//
//  ILSideMenuDelegate.h
//  Interceptions
//
//  Created by Mario Yohanes on 4/16/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IMSideMenuDelegate <NSObject>

@property (nonatomic, readonly) UISwipeGestureRecognizer *swipeLeftGesture;
@property (nonatomic, readonly) UISwipeGestureRecognizer *swipeRightGesture;
@property (nonatomic, readonly) UITapGestureRecognizer *tapGesture;

- (void)showMenu;
- (void)showLogin;
- (void)showContent;
- (void)openSynchronizationDialog:(NSNotification *)notification;

- (void)changeContentViewTo:(NSString *)viewIdentifier fromSideMenu:(BOOL)fromSideMenu;

@end