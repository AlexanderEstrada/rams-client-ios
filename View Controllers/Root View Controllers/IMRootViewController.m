//
//  IMRootViewController.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/1/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMRootViewController.h"
#import "IMMenuViewController.h"
#import "IMAuthManager.h"
#import "IMSyncViewController.h"
#import "IMDBManager.h"
#import "IMHTTPClient.h"
#import "NSDate+Relativity.h"




@interface IMRootViewController ()<IMSideMenuDelegate, UIAlertViewDelegate>

@property (nonatomic, readwrite) BOOL menuHidden;
@property (nonatomic, readwrite) BOOL menuDisable;
@property (nonatomic, strong) NSString *currentViewControllerId;
@property (nonatomic) BOOL firstLaunch;
@property (nonatomic, weak) UIViewController *childViewController;
@property (nonatomic, weak) IMMenuViewController *menuViewController;

@end


@implementation IMRootViewController

@synthesize swipeLeftGesture = _swipeLeftGesture;
@synthesize swipeRightGesture = _swipeRightGesture;
@synthesize tapGesture = _tapGesture;


- (CGRect)rectWithOffsetX:(CGFloat)offsetX originalRect:(CGRect)rect
{
    return CGRectMake(offsetX, rect.origin.y, rect.size.width, rect.size.height);
}

#pragma mark Delegate Methods
- (void)showMenu
{
    if (self.menuDisable) {
        return;
    }
    [self.childViewController.view removeGestureRecognizer:self.tapGesture];
    [self.childViewController.view removeGestureRecognizer:self.swipeLeftGesture];
    UIViewController *topViewController = [((UINavigationController *)self.childViewController) topViewController];
    topViewController.view.userInteractionEnabled = NO;
    
    if (self.menuHidden) {
        self.menuContainerView.frame = [self rectWithOffsetX:IMRootViewSideMenuOffsetX originalRect:self.menuContainerView.frame];
        [self.menuViewController viewWillAppear:YES];
        [UIView animateWithDuration:IMRootViewAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.contentContainerView.frame = [self rectWithOffsetX:IMRootViewContentCenterOffsetX originalRect:self.contentContainerView.frame];
                             self.menuContainerView.frame = [self rectWithOffsetX:0 originalRect:self.menuContainerView.frame];
                         } completion:^(BOOL finished){
                             self.menuHidden = !self.menuHidden;
                             topViewController.view.userInteractionEnabled = self.menuHidden;
                             [self.childViewController.view addGestureRecognizer:self.tapGesture];
                             [self.childViewController.view addGestureRecognizer:self.swipeLeftGesture];
                         }];
        
    }else {
        [UIView animateWithDuration:IMRootViewAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.contentContainerView.frame = [self rectWithOffsetX:0 originalRect:self.contentContainerView.frame];
                             self.menuContainerView.frame = [self rectWithOffsetX:IMRootViewSideMenuOffsetX originalRect:self.menuContainerView.frame];
                         }
                         completion:^(BOOL finished){
                             self.menuHidden = !self.menuHidden;
                             topViewController.view.userInteractionEnabled = self.menuHidden;
                         }];
    }
}

- (void)disableMenu:(BOOL)value
{
    self.menuDisable = value;
}

- (void)ExpiredToken
{
    //show alert to let user know that token has expired
    [self showAlertWithTitle:@"Token Expired" message:@"Please Relogin."];
    
}

- (void)Logout
{
    //show alert to let user know that token has expired
    [self showAlertWithTitle:@"Logout" message:@"Please Relogin."];
    
}

#pragma mark UIAlertViewDelegate



- (void)showLogin
{
    [self changeContentViewTo:@"IMLoginViewController" fromSideMenu:NO];
}

- (void)showContent
{
    [self changeContentViewTo:@"IMInterceptionViewController" fromSideMenu:NO];
    //    [self changeContentViewTo:@"IMRegistrationViewController" fromSideMenu:NO];
}

- (void)openSynchronizationDialog:(NSNotification *)notification
{
    if (notification && notification.userInfo) {
        int numUpdates = [[notification.userInfo objectForKey:IMUpdatesAvailable] intValue];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Updates Available" message:[NSString stringWithFormat:@"You have %i data updates available. Do you want to sync now?", numUpdates] delegate:self cancelButtonTitle:@"Later" otherButtonTitles:@"Sync Now", nil];
        alert.tag = IMAlertUpdate_Tag;
        [alert show];
    }else {
        [self changeContentViewTo:@"IMSyncViewController" fromSideMenu:NO];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == IMAlertUpdate_Tag &&  buttonIndex != [alertView cancelButtonIndex]){ [self openSynchronizationDialog:nil];
    }else if (alertView.tag == IMDefaultAlertTag){
        [self showLogin];
          [[NSNotificationCenter defaultCenter] postNotificationName:IMAccessExpiredCloseNotification object:nil userInfo:nil];
    }
}


#pragma mark View Transition
- (void)changeContentViewTo:(NSString *)viewIdentifier fromSideMenu:(BOOL)fromSideMenu
{
    
    if (self.currentViewControllerId && [self.currentViewControllerId isEqualToString:viewIdentifier]) {
        if (!self.menuHidden) [self showMenu];
        return;
    }
    
    UIViewController *nextVC = [self.storyboard instantiateViewControllerWithIdentifier:viewIdentifier];
    if (self.childViewController) {
        [self.childViewController.view removeGestureRecognizer:self.tapGesture];
        
        [self addChildViewController:nextVC];
        nextVC.view.frame = self.contentContainerView.bounds;
        [self.childViewController willMoveToParentViewController:nil];
        if (fromSideMenu) [self showMenu];
        
        [self transitionFromViewController:self.childViewController
                          toViewController:nextVC
                                  duration:IMRootViewAnimationDuration
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{}
                                completion:^(BOOL finished){
                                    [self.childViewController removeFromParentViewController];
                                    [nextVC didMoveToParentViewController:self];
                                    self.childViewController = nextVC;
                                    [self updateChildViewControllerMenuButtonItem];
                                }];
    }else {
        [self addChildViewController:nextVC];
        nextVC.view.frame = self.contentContainerView.bounds;
        [self.contentContainerView addSubview:nextVC.view];
        [nextVC didMoveToParentViewController:self];
        self.childViewController = nextVC;
        [self updateChildViewControllerMenuButtonItem];
    }
    
    self.currentViewControllerId = viewIdentifier;
}

- (void)updateChildViewControllerMenuButtonItem
{
    if ([self.childViewController isKindOfClass:[UINavigationController class]]) {
        UIViewController *rootVC = [((UINavigationController *)self.childViewController) topViewController];
        UIBarButtonItem *itemMenu = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-menu"] style:UIBarButtonItemStyleBordered target:self action:@selector(showMenu)];
        rootVC.navigationItem.leftBarButtonItem = itemMenu;
        if ([rootVC respondsToSelector:@selector(setSideMenuDelegate:)]) {
            [rootVC performSelector:@selector(setSideMenuDelegate:) withObject:self];
        }
    }else if ([self.childViewController respondsToSelector:@selector(setSideMenuDelegate:)]) {
        [self.childViewController performSelector:@selector(setSideMenuDelegate:) withObject:self];
    }
    
    if ([self.currentViewControllerId isEqualToString:@"IMSyncViewController"]) return;
    [self.childViewController.view addGestureRecognizer:self.swipeRightGesture];
}


#pragma mark View Lifecycle
- (UISwipeGestureRecognizer *)swipeLeftGesture
{
    if (!_swipeLeftGesture){
        _swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu)];
        _swipeLeftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    }
    
    return _swipeLeftGesture;
}

- (UISwipeGestureRecognizer *)swipeRightGesture
{
    if (!_swipeRightGesture){
        _swipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu)];
        _swipeRightGesture.direction = UISwipeGestureRecognizerDirectionRight;
    }
    
    return _swipeRightGesture;
}

- (UITapGestureRecognizer *)tapGesture
{
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu)];
        [_tapGesture requireGestureRecognizerToFail:self.swipeLeftGesture];
        [_tapGesture requireGestureRecognizerToFail:self.swipeRightGesture];
    }
    
    return _tapGesture;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.menuHidden = YES;
    self.firstLaunch = YES;
    self.menuDisable = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ExpiredToken) name:IMAccessExpiredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(Logout) name:IMLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openSynchronizationDialog:) name:IMSyncShouldStartedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.firstLaunch) {
        for (UIViewController *vc in self.childViewControllers) {
            if ([vc isKindOfClass:[IMMenuViewController class]]) {
                self.menuViewController = (IMMenuViewController *)vc;
                self.menuViewController.sideMenuDelegate = self;
                break;
            }
        }
        
        self.childViewController = nil;
        
        if ([[IMAuthManager sharedManager] isLoggedOn]) {
            [self showContent];
        }else {
            [self showLogin];
        }
        
        self.firstLaunch = NO;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (!self.menuHidden) {
        [self showMenu];
    }
}

@end
