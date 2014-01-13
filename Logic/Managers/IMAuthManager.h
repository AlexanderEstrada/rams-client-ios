//
//  IMDataManager.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 10/24/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@interface IMAuthManager : NSObject

@property (nonatomic, strong) User *activeUser;

+ (IMAuthManager *)sharedManager;

- (void)sendLoginCredentialWithParams:(NSDictionary *)params completion:(void (^)(BOOL success, NSString *message))completion;
- (BOOL)isLoggedOn;
- (BOOL)isTokenExpired;
- (void)logout;

@end