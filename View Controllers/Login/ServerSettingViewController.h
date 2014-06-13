//
//  ServerSettingViewController.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 4/8/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMViewController.h"

@interface IMServerSettingViewController : IMViewController

@property (weak, nonatomic) IBOutlet UITextField *ServerSide;
@property (weak, nonatomic) IBOutlet UITextField *ServerPort;
@property (weak, nonatomic) IBOutlet UISwitch *Use_SSL;
@property (weak, nonatomic) IBOutlet UIButton *save;
@property (weak, nonatomic) IBOutlet UIButton *cancel;

@end
