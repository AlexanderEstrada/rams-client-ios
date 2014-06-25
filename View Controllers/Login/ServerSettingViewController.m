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


-(BOOL)isNumeric:(NSString*)inputString{
    BOOL isValid = NO;
    NSCharacterSet *alphaNumbersSet = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *stringSet = [NSCharacterSet characterSetWithCharactersInString:inputString];
    isValid = [alphaNumbersSet isSupersetOfSet:stringSet];
    return isValid;
}


- (IBAction)save:(id)sender {
    
    NSMutableString *server;
    if (_ServerSide.text.length) {
        //check port
        if (_ServerPort.text.length) {
            if (![self isNumeric:_ServerPort.text]) {
                [self showAlertWithTitle:@"" message:@"Please fill Server port with numeric."];
                return;
            }
            //get the port
            server = [NSMutableString stringWithFormat:@"%@%@:%@%@",_Use_SSL.on == TRUE ?HTTPS:HTTP,_ServerSide.text,_ServerPort.text,apps_tag];
        }else{
             server = [NSMutableString stringWithFormat:@"%@%@%@",_Use_SSL.on == TRUE ?HTTPS:HTTP,_ServerSide.text,apps_tag];
        }
        
        //save new server path
        [IMConstants setConstantForKey:@"API URL" withValue:server];
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
        //get the previous value

        NSURL* url = [NSURL URLWithString:IMBaseURL];
        self.Use_SSL.on = [url.scheme isEqualToString:@"https"];
        self.ServerSide.text =  url.host;
        self.ServerPort.text = url.port.description;
        NSLog(@"host : %@, port : %@, ssl :%@",url.host,url.port.description,url.scheme);
        

    }

}


-(BOOL)shouldAutorotate
{
    
    return UIInterfaceOrientationMaskPortrait;
    
}

-(NSUInteger)supportedInterfaceOrientations
{
    
    return UIInterfaceOrientationMaskPortrait;
    
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    
    return UIInterfaceOrientationPortrait;
    
}

@end
