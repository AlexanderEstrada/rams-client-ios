//
//  User.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/3/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *officeName;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSDate *accessExpiryDate;

@property (nonatomic, readonly) BOOL roleInterception;
@property (nonatomic, readonly) BOOL roleICC;
@property (nonatomic, readonly) BOOL roleOperation;

- (User *)initWithDictionary:(NSDictionary *)dictionary;
- (User *)initFromKeychain;

- (void)saveToKeychain;
- (void)deleteFromKeychain;

@end