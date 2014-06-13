//
//  IMLoginViewController.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/2/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMViewController.h"

@class IMTextField;
@interface IMLoginViewController : IMViewController

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet IMTextField *textEmail;
@property (weak, nonatomic) IBOutlet IMTextField *textPassword;
@property (weak, nonatomic) IBOutlet UIButton *buttonLogin;
@property (weak, nonatomic) IBOutlet UIButton *buttonForgotPassword;
@property (weak, nonatomic) IBOutlet UIButton *buttonAssistance;

//TODO : alex add
@property (weak, nonatomic) IBOutlet UIButton *buttonSettings;
@property (weak, nonatomic) IBOutlet IMTextField *textServer;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *formContainerView;
@property (weak, nonatomic) IBOutlet UIView *titleContainerView;

@end
