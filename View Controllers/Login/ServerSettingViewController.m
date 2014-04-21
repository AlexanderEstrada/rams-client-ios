//
//  ServerSettingViewController.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 4/8/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "ServerSettingViewController.h"
#import "IMConstants.h"
#import "IMHTTPClient.h"

@implementation IMServerSettingViewController




- (IBAction)save:(id)sender {
    
    if (_ServerSide.text.length) {
        //save new server path
        [IMConstants setConstantForKey:@"API URL" withValue:_ServerSide.text];
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }else [self showAlertWithTitle:@"" message:@"Please fill out  server address before  press save."];
    
    return;
}


- (IBAction)cancel:(id)sender {
        [self dismissViewControllerAnimated:YES completion:nil];
    return;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (IMBaseURL) {
        self.ServerSide.text = IMBaseURL;
    }

}

@end
