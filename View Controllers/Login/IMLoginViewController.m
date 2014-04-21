//
//  IMLoginViewController.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/2/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMLoginViewController.h"
#import "IMTextField.h"
#import "NSString+Encryption.h"
#import "IMAuthManager.h"
#import "NSDate+Relativity.h"
#import "ServerSettingViewController.h"


@interface IMLoginViewController ()<UITextFieldDelegate>

@property (nonatomic) BOOL keyboardVisible;

@end


@implementation IMLoginViewController


- (IBAction)forgotPassword
{
    
}

- (IBAction)callAssistance
{
    
}

- (IBAction)settings
{
    NSLog(@"Finaly press setting");
    //IMServerSettingViewController
    
    IMServerSettingViewController *serverSettingVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IMServerSettingViewController"];
    serverSettingVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
    serverSettingVC.ServerSide.text =  IMBaseURL;
    serverSettingVC.title = @"Server Setting";

    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:serverSettingVC];
    
    navCon.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navCon animated:YES completion:nil];

}


#pragma mark View Transition
- (void)changeContentViewTo:(NSString *)viewIdentifier fromSideMenu:(BOOL)fromSideMenu
{
   //create view controller
    

}

- (IBAction)login
{
    if (!self.textEmail.text.length || !self.textPassword.text.length) {
        [self showAlertWithTitle:@"" message:@"Please fill out email and password before signing in."];
        return;
    }
    
    self.view.userInteractionEnabled = NO;
    [self.activityIndicator startAnimating];
    
    if (IMAPIKey == Nil) {
        [IMConstants initialize];
    }
    
    NSDictionary *params = @{@"username": self.textEmail.text,
                             @"password": [self.textPassword.text SHA256],
                             @"consumerKey": IMAPIKey};

    [[IMAuthManager sharedManager] sendLoginCredentialWithParams:params
                                                      completion:^(BOOL success, NSString *message){
                                                          [self.activityIndicator stopAnimating];
                                                          self.view.userInteractionEnabled = YES;
                                                          
                                                          if (success) {
                                                              NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:IMLastSyncDate];
                                                              if (date) {
                                                                  [self.sideMenuDelegate showContent];
                                                              }else {
                                                                  [self.sideMenuDelegate openSynchronizationDialog:nil];
                                                              }
                                                          }else {
                                                              [self showAlertWithTitle:message message:@""];
                                                              [self.textEmail becomeFirstResponder];
                                                          }
                                                      }];
}


#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.textEmail) {
        [self.textPassword becomeFirstResponder];
    }else {
        [textField resignFirstResponder];
        [self login];
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.textEmail toggleBorder];
    [self.textPassword toggleBorder];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.textEmail toggleBorder];
    [self.textPassword toggleBorder];
}

- (void)keyboardWillHide
{
    self.keyboardVisible = NO;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [UIView animateWithDuration:.35 animations:^{
            self.containerView.center = self.view.center;
        }];
    }
}

- (void)keyboardWillShow
{
    self.keyboardVisible = YES;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [UIView animateWithDuration:.35 animations:^{
            self.containerView.center = CGPointMake(self.view.center.x, self.view.center.y - 120);
        }];
    }
}


#pragma mark View lifecycle
- (void)viewDidLoad
{
    //reload constants key
//    [IMConstants initialize];
    
    [super viewDidLoad];
    
    self.view.tintColor = [UIColor IMLightBlue];
    self.textEmail.delegate = self;
    self.textPassword.delegate = self;
    
    self.textServer.delegate = self;
    self.formContainerView.alpha = 0;
    
    [self.textEmail toggleBorder];
    [self.textPassword toggleBorder];
    
    [self.textServer toggleBorder];
    
    [self.buttonLogin setTitleColor:[UIColor IMLightBlue] forState:UIControlStateNormal];
    [self.buttonSettings setTitleColor:[UIColor IMLightBlue] forState:UIControlStateNormal];

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.view removeGestureRecognizer:[self.sideMenuDelegate swipeRightGesture]];
    [self.view removeGestureRecognizer:[self.sideMenuDelegate swipeLeftGesture]];
    [self performSelector:@selector(showLoginWindow) withObject:nil afterDelay:0.5];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            self.containerView.center = CGPointMake(self.view.center.x, self.view.center.y - (self.keyboardVisible ? 120 : 0));
        }else {
            self.containerView.center = self.view.center;
        }
    } completion:nil];
}

- (void)showLoginWindow
{
    CGRect formRect = self.formContainerView.frame;
    self.formContainerView.frame = CGRectMake(self.containerView.frame.size.width, formRect.origin.y, formRect.size.width, formRect.size.height);
    [UIView animateWithDuration:.35 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.titleContainerView.alpha = 0;
        self.formContainerView.alpha = 1;
        self.formContainerView.frame = formRect;
    } completion:^(BOOL finished){
        [self.textEmail becomeFirstResponder];
    }];
}

@end