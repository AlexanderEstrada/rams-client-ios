//
//  Biometric+Extended.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 12/11/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import "Biometric.h"
#import "Biometric+Storage.h"


@interface Biometric (Extended)

extern NSString *const BIO_ENTITY_NAME;
extern NSString *const BIO_ID;
extern NSString *const BIO_PHOTOGRAPH;

extern NSString *const BIO_LEFT_THUMB_IMAGE;
extern NSString *const BIO_LEFT_THUMB_TEMPLATE;
extern NSString *const BIO_RIGHT_THUMB_IMAGE;
extern NSString *const BIO_RIGHT_THUMB_TEMPLATE;

extern NSString *const BIO_LEFT_INDEX_IMAGE;
extern NSString *const BIO_LEFT_INDEX_TEMPLATE;
extern NSString *const BIO_RIGHT_INDEX_IMAGE;
extern NSString *const BIO_RIGHT_INDEX_TEMPLATE;

+ (Biometric *)biometricFromDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;
+ (Biometric *)biometricWithId:(NSString *)biometricId inContext:(NSManagedObjectContext *)context;
- (void)updateBiometricWithDictionary:(NSDictionary *)dictionary;

@end