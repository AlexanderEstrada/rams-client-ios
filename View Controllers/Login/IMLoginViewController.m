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
#import "IMConstants.h"
#import "Parse/Parse.h"


@interface IMLoginViewController ()<UITextFieldDelegate>

@property (nonatomic) BOOL keyboardVisible;

@end


@implementation IMLoginViewController


- (IBAction)forgotPassword
{
    
    UIAlertView * forgotPassword=[[UIAlertView alloc] initWithTitle:@"Forgot Password"      message:@"Please enter your email id" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    forgotPassword.alertViewStyle=UIAlertViewStylePlainTextInput;
    [forgotPassword textFieldAtIndex:0].delegate=self;
    forgotPassword.tag = IMForgotPassword_Tag;
    [forgotPassword show];
    
}



- (IBAction)callAssistance
{
     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"telprompt://2135554321"]];
    UIAlertView *display;
    display=[[UIAlertView alloc] initWithTitle:@"Call for assistance" message:@"Please call IOM representative for assistance" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [display show];
}


- (BOOL)validateEmail:(NSString *)emailStr {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:emailStr];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == IMForgotPassword_Tag && buttonIndex != [alertView cancelButtonIndex]) {
        NSString *femailId=[alertView textFieldAtIndex:0].text;
        if ([femailId isEqualToString:@""] || ![self validateEmail:[alertView textFieldAtIndex:0].text]) {
            UIAlertView *display;
            display=[[UIAlertView alloc] initWithTitle:@"Email" message:@"Please enter valid E-mail for resetting password" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [display show];
            
        }else{
            @try {
                
                //show loading view
                [self showLoadingView];
                
                IMHTTPClient *client = [IMHTTPClient sharedClient];
                NSMutableDictionary *params = [NSMutableDictionary dictionary];
                NSString * path = [IMConstants getIMConstantKey:CONST_IMForgotPassword];
                    [params setObject:femailId forKey:@"email"];

                [client postJSONWithPath:path
                              parameters:params
                                 success:^(NSDictionary *jsonData, int statusCode){
                                       [self hideLoadingView];
                                 UIAlertView *display;
                                     NSLog(@"Upload Success");
                                     NSLog(@"return JSON : %@",[jsonData description]);
                                      display=[[UIAlertView alloc] initWithTitle:@"Password email" message:@"Please check your email for resetting the password" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                             [display show];
                                     
                                 }
                                 failure:^(NSDictionary *jsonData, NSError *error, int statusCode){
                                       [self hideLoadingView];
                                     UIAlertView *display;
                                     NSLog(@"Upload Fail : %@",[error description]);
                                     NSLog(@"return JSON : %@",[jsonData description]);
                                   display=[[UIAlertView alloc] initWithTitle:@"Email" message:@"Email doesn't exists in our database" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
                                     [display show];
                                 }];

                
//                [PFUser requestPasswordResetForEmailInBackground:femailId block:^(BOOL succeeded, NSError *error) {
//                    UIAlertView *display;
//                    if(succeeded){
//                        display=[[UIAlertView alloc] initWithTitle:@"Password email" message:@"Please check your email for resetting the password" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
//                        
//                    }else{
//                        display=[[UIAlertView alloc] initWithTitle:@"Email" message:@"Email doesn't exists in our database" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
//                    }
//                    [display show];
//                }];
            }
            @catch (NSException *exception) {
                NSLog(@"Exeption on alertView : %@",[exception description]);
            }
            
          
        }
        
        
        
    }
    
}

- (void) ExpiredToken{
//get expired notification, then hide loading view
    [self hideLoadingView];
}

- (IBAction)settings
{
    
    IMServerSettingViewController *serverSettingVC = [self.storyboard instantiateViewControllerWithIdentifier:@"IMServerSettingViewController"];
    serverSettingVC.modalPresentationStyle = UIModalPresentationFormSheet;

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
        [self showAlertWithTitle:@"" message:@"Please input email and password before signing in."];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ExpiredToken) name:IMAccessExpiredCloseNotification object:nil];
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