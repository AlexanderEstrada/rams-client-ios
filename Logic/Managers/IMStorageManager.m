//
//  IMStorageManager.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/21/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMStorageManager.h"
#import "Biometric+Storage.h"
#import "Photo+Storage.h"


@implementation IMStorageManager

+ (void)deleteAllCaches
{
    [[NSFileManager defaultManager] removeItemAtPath:[Photo photosDir] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[Biometric photograpDir] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[Biometric leftIndexImageDir] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[Biometric leftIndexTemplateDir] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[Biometric leftThumbImageDir] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[Biometric leftThumbTemplateDir] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[Biometric rightIndexImageDir] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[Biometric rightIndexTemplateDir] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[Biometric rightThumbImageDir] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[Biometric rightThumbTemplateDir] error:nil];
}

@end
