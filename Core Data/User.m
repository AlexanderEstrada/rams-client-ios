//
//  User.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/3/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "User.h"
#import "NSDate+Relativity.h"
#import "PDKeychainBindings.h"


@implementation User

NSString *const IM_USER_EMAIL           = @"email";
NSString *const IM_USER_NAME            = @"name";
NSString *const IM_USER_OFFICE          = @"office";
NSString *const IM_USER_TOKEN           = @"accessToken";
NSString *const IM_USER_TOKEN_EXPIRY    = @"tokenExpirationDate";
NSString *const IM_USER_ROLES           = @"roles";

NSString *const IM_ROLE_ADMINISTRATOR   = @"Administrator";
NSString *const IM_ROLE_INTERCEPTION    = @"Interception";
NSString *const IM_ROLE_ICC             = @"Icc";
NSString *const IM_ROLE_OPERATION       = @"Operation";


- (User *)initWithDictionary:(NSDictionary *)dictionary
{
    if (!dictionary) return nil;
    
    @try {
        self = [super init];
        
        self.name = dictionary[IM_USER_NAME];
        self.email = dictionary[IM_USER_EMAIL];
        self.officeName = dictionary[IM_USER_OFFICE];
        self.accessToken = dictionary[IM_USER_TOKEN];
        self.accessExpiryDate = [NSDate dateFromUTCString:dictionary[IM_USER_TOKEN_EXPIRY]];
        
        NSArray *roles = dictionary[IM_USER_ROLES];
        if ([roles containsObject:IM_ROLE_ADMINISTRATOR]) {
            _roleICC = YES;
            _roleInterception = YES;
            _roleOperation = YES;
        }else {
            _roleICC = [roles containsObject:IM_ROLE_ICC];
            _roleInterception = [roles containsObject:IM_ROLE_INTERCEPTION];
            _roleOperation = [roles containsObject:IM_ROLE_OPERATION];
        }

        return self;
    }
    @catch (NSException *exception) {
        NSLog(@"Error parsing user dictionary: %@\nError message: %@", dictionary, [exception description]);
        return nil;
    }
}

- (User *)initFromKeychain
{
    self = [super init];
    
    PDKeychainBindings *keychain = [PDKeychainBindings sharedKeychainBindings];
    NSString *name = [keychain objectForKey:IM_USER_NAME];
    if (!name) return nil;
    
    self.name = name;
    self.email = [keychain objectForKey:IM_USER_EMAIL];
    self.accessToken = [keychain objectForKey:IM_USER_TOKEN];
    self.accessExpiryDate = [NSDate dateFromUTCString:[keychain objectForKey:IM_USER_TOKEN_EXPIRY]];
    self.officeName = [keychain objectForKey:IM_USER_OFFICE];
    
    _roleOperation = [[keychain objectForKey:IM_ROLE_OPERATION] boolValue];
    _roleInterception = [[keychain objectForKey:IM_ROLE_INTERCEPTION] boolValue];
    _roleICC = [[keychain objectForKey:IM_ROLE_ICC] boolValue];
    
    return self;
}

- (void)saveToKeychain
{
    PDKeychainBindings *keychain = [PDKeychainBindings sharedKeychainBindings];
    [keychain setString:self.name forKey:IM_USER_NAME];
    [keychain setString:self.email forKey:IM_USER_NAME];
    [keychain setString:self.accessToken forKey:IM_USER_TOKEN];
    [keychain setString:[self.accessExpiryDate toUTCString] forKey:IM_USER_TOKEN_EXPIRY];
    [keychain setString:self.officeName forKey:IM_USER_OFFICE];

    [keychain setString:(self.roleICC ? @"YES" : @"NO") forKey:IM_ROLE_ICC];
    [keychain setString:(self.roleInterception ? @"YES" : @"NO") forKey:IM_ROLE_INTERCEPTION];
    [keychain setString:(self.roleOperation ? @"YES" : @"NO") forKey:IM_ROLE_OPERATION];
}

- (void)deleteFromKeychain
{
    PDKeychainBindings *keychain = [PDKeychainBindings sharedKeychainBindings];
    [keychain removeObjectForKey:IM_USER_NAME];
    [keychain removeObjectForKey:IM_USER_EMAIL];
    [keychain removeObjectForKey:IM_USER_OFFICE];
    [keychain removeObjectForKey:IM_USER_TOKEN];
    [keychain removeObjectForKey:IM_USER_TOKEN_EXPIRY];
    [keychain removeObjectForKey:IM_ROLE_ICC];
    [keychain removeObjectForKey:IM_ROLE_INTERCEPTION];
    [keychain removeObjectForKey:IM_ROLE_OPERATION];
}

@end