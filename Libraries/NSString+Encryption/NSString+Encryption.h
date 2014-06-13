//
//  NSString+Encryption.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 11/6/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(Encryption)

- (NSString *)MD5;
- (NSString *)SHA1;
- (NSString *)SHA256;

@end
