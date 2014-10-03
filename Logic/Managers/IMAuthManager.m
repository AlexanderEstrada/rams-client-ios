//
//  IMDataManager.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 10/24/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import "IMAuthManager.h"
#import "IMHTTPClient.h"
#import "NSDate+Relativity.h"
#import "IMConstants.h"
#import "PDKeychainBindings.h"


@implementation IMAuthManager

#define kUserKey    @"user"

+ (IMAuthManager *)sharedManager
{
    static dispatch_once_t once;
    static IMAuthManager *singleton = nil;
    
    dispatch_once(&once, ^{
        singleton = [[IMAuthManager alloc] init];
    });
    
    return singleton;
}

- (void)reInit {
    
    if ([IMAuthManager sharedManager]) {
//        [self.sharedManager ]
    }
}
- (void)sendLoginCredentialWithParams:(NSDictionary *)params completion:(void (^)(BOOL success, NSString *message))completion
{
    NSMutableURLRequest *request = [[IMHTTPClient sharedClient] requestWithMethod:@"POST" path:@"login" parameters:params];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json){
                                                                                            BOOL status = [self validateLoginResponse:json];
                                                                                            if (status) {
                                                                                                [[NSNotificationCenter defaultCenter] postNotificationName:IMUserChangedNotification object:nil userInfo:nil];
                                                                                                [[IMHTTPClient sharedClient] setupAuthenticationHeader];
                                                                                                completion(status, nil);
                                                                                            }else {
                                                                                                completion(status,@"Authentication Failed");
                                                                                                //reset connection
                                                                                                 [self logout];
                                                                                            }
                                                                                        }
                                                                                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id json){
                                                                                            NSLog(@"%@", [error description]);
                                                                                            NSString *message;
                                                                                            
                                                                                            if (response.statusCode == 401) {
                                                                                                message = @"Authentication Failed";
                                                                                                 //reset connection
                                                                                                 [self logout];
                                                                                            }else if (response.statusCode == 403) {
                                                                                                message = @"Forbidden Access";
                                                                                            }else {
                                                                                                message = @"Connection Error";
                                                                                            }
                                                                                            
                                                                                            completion(NO, message);
                                                                                        }];
    [operation setAllowsInvalidSSLCertificate:YES];
    [[IMHTTPClient sharedClient] enqueueHTTPRequestOperation:operation];
}

- (User *)activeUser
{
    if (!_activeUser) _activeUser = [[User alloc] initFromKeychain];
    return _activeUser;
}

- (BOOL)validateLoginResponse:(id)jsonData
{
    if ([jsonData isKindOfClass:[NSDictionary class]]) {
        self.activeUser = [[User alloc] initWithDictionary:jsonData];
        
        if (self.activeUser) {
            [self.activeUser saveToKeychain];
            self.activeUser = [[User alloc] initFromKeychain];
            return self.activeUser != nil;
        }
    }
    
    return NO;
}

- (BOOL)isLoggedOn
{
    return self.activeUser != nil;
}

- (BOOL)isTokenExpired
{
    NSDate *expired = self.activeUser.accessExpiryDate;
    if (!expired) return YES;
    return [expired compare:[NSDate date]] == NSOrderedAscending;
}

- (void)logout
{
    [self.activeUser deleteFromKeychain];
    self.activeUser = Nil;
    [[IMHTTPClient sharedClient] clearAuthorizationHeader];
    [[NSNotificationCenter defaultCenter] postNotificationName:IMLogoutNotification object:nil userInfo:nil];
}

@end