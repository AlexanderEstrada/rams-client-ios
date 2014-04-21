//
//  IMAppDelegate.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 9/24/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMAppDelegate.h"
#import "IMDBManager.h"
#import "IMAuthManager.h"
#import <GoogleMaps/GoogleMaps.h>
#import "IMHTTPClient.h"
#import "IMConstants.h"


@implementation IMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if (IMGoogleAPIKey == Nil) {
        [IMConstants initialize];
    }
    
    [GMSServices provideAPIKey:IMGoogleAPIKey];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"FirstRun"]) {
        if ([IMAuthManager sharedManager].activeUser) {
            [[IMAuthManager sharedManager].activeUser deleteFromKeychain];
            [IMAuthManager sharedManager].activeUser = nil;
        }
        
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        [def setBool:NO forKey:@"FirstRun"];
        [def setBool:YES forKey:IMBackgroundUpdates];
        [def synchronize];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[IMDBManager sharedManager] saveDatabase:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // do something in background
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    if ([[IMAuthManager sharedManager] isTokenExpired]) [[IMAuthManager sharedManager] logout];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if ([[IMAuthManager sharedManager] isLoggedOn]) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:IMLastSyncDate]) {
            //TODO : comment for testing
            [[IMDBManager sharedManager] checkForUpdates];
        }else {
            [[NSNotificationCenter defaultCenter] postNotificationName:IMSyncShouldStartedNotification object:nil userInfo:nil];
        }
        //TODO : comment for testing
        [self checkAppUpdates];
    }
    
    [[IMDBManager sharedManager] openDatabase:^(BOOL success){
        if (!success) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed Opening Database" message:@"Local database may corrupt, please relaunch the application or reset local database from Settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[IMDBManager sharedManager] closeDatabase];
}


- (void)checkAppUpdates
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSNumber *version    = infoDictionary[@"CFBundleShortVersionString"];
    NSString *bundleName = infoDictionary[(NSString *)kCFBundleNameKey];
    
    IMHTTPClient *client = [IMHTTPClient sharedClient];
    [client getJSONWithPath:@"update/app"
                 parameters:@{@"appVersion": version, @"appName": bundleName}
                    success:^(NSDictionary *jsonData, int statusCode){
                        NSString *stringUrl = jsonData[@"payloadUrl"];
                        if (stringUrl) {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:stringUrl]];
                        }
                    }
                    failure:nil];
}

@end