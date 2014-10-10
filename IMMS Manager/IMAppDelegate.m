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
//#import <GoogleMaps/GoogleMaps.h>
#import "GoogleMaps/GoogleMaps.h"
#import "IMHTTPClient.h"
#import "IMConstants.h"

@interface IMAppDelegate ()<NSFileManagerDelegate>

@end

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

#pragma mark - NSFileManagerDelegate

- (BOOL)fileManager:(NSFileManager *)fileManager shouldCopyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath
{
     return YES;
}
- (BOOL)fileManager:(NSFileManager *)fileManager shouldCopyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL
{
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    @try {
        
         NSError* err;
        //old directory is on cache, case exist then move it to Library directory
        NSURL *oldURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&err];
        oldURL = [oldURL URLByAppendingPathComponent:IMLocaDBName];
        
        
        //check if the database path is on cache
        if ([[NSFileManager defaultManager] fileExistsAtPath:[oldURL path]]) {
            //case in cache then move to document
            oldURL = nil;
            oldURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&err];
            
             NSFileManager *manager = [[NSFileManager alloc] init];
           
            manager.delegate = self;
            
            NSArray *properties = [NSArray arrayWithObjects: NSURLLocalizedNameKey,
                                   NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey, nil];
            
            NSArray *array = [[NSFileManager defaultManager]
                              contentsOfDirectoryAtURL:oldURL
                              includingPropertiesForKeys:properties
                              options:(NSDirectoryEnumerationSkipsHiddenFiles)
                              error:&err];
            NSString * tmp;
            if ([array count]) {
                for (NSURL * path in array) {
                    //create new destination name base on source file
                    tmp = [path lastPathComponent];
                     NSURL *newURL = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&err];
                     newURL = [newURL URLByAppendingPathComponent:tmp];
                    
                    if ([[NSFileManager defaultManager] fileExistsAtPath:[newURL path]]) {
                        [[NSFileManager defaultManager] removeItemAtPath:[newURL path] error:nil];
                    }
                    if (![manager moveItemAtPath:[path path] toPath:[newURL path] error:&err]) {
                        NSLog(@"Fail to move directory %@ to %@ with err : %@",[path path],[newURL path],[err description]);
                    }
                }
            }
            
        }
        
        
        //case not run RAMS as ussual
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
    @catch (NSException *exception) {
        NSLog(@"Exception on applicationDidBecomeActive : %@",[exception description]);
    }
    
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