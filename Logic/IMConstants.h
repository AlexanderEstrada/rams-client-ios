//
//  IMConstants.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 29/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    RightThumb = 1,
    RightIndex = 2,
    LeftThumb = 3,
    LeftIndex = 4
}FingerPosition;

typedef enum
{
    REG_STATUS_UNCOMPLETE = 0,
    REG_STATUS_PENDING= 1,
    REG_STATUS_LOCAL = 2
    
}Registration_Status;

@interface IMConstants : NSObject

//@"AIzaSyBX9FNqp2GnryIZGk_yeLY_OrN_9xCORQE"
#define IMGoogleAPIKey      [[NSUserDefaults standardUserDefaults] stringForKey:@"Google Places API KEY"]
//#define IMGoogleAPIKey      @"AIzaSyCLrpojeFdP5RVK5M4iRbDgYRcOdIBcZc8"
#define IMBaseURL           [[NSUserDefaults standardUserDefaults] stringForKey:@"API URL"]
//#define IMBaseURL           @"https://im.iom.or.id/api"
//#define IMBaseURL           @"http://172.25.137.149:8080/api"
//#define IMBaseURL           @"http://172.25.137.227:8080/api"
//#define IMBaseURL           @"http://192.168.43.236:8080/api"
//#define IMBaseURL           @"http://172.25.137.125:50000/api"

//NSString *IMBaseURL;
//@"d67acd1c1fa33b68055f9f7dafaa3ae0"
#define IMAPIKey            [[NSUserDefaults standardUserDefaults] stringForKey:@"API Key"]
//#define IMAPIKey            @"d67acd1c1fa33b68055f9f7dafaa3ae0"
//@"7cb0533b94446f4c49f1eadcffe5f19a31b25d5d"
#define IMAPISecret         [[NSUserDefaults standardUserDefaults] stringForKey:@"API Secret"]
//#define IMAPISecret     @"7cb0533b94446f4c49f1eadcffe5f19a31b25d5d"


#define CORE_DATA_OBJECT(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

#define IMLocaDBName                    @"IMMS"

#define IMDatabaseChangedNotification   @"IMDatabaseChangedNotification"
#define IMAccessExpiredNotification     @"IMAccessExpiredNotification"
#define IMSyncShouldStartedNotification @"IMSyncShouldStartedNotification"
#define IMUserChangedNotification       @"IMUserChangedNotification"

#define IMRegistrationNotification      @"IMRegistrationNotification"

#define IMSyncKeyError                  @"error"
#define IMSyncKeySuccess                @"success"
#define IMUpdatesAvailable              @"updates"
#define IMAuthenticationStatus          @"authenticationStatus"

#define IMInterceptionFetcherUpdate     @"IMInterceptionFetcherUpdate"
#define IMLastSyncDate                  @"IMLastSyncDate"
#define IMBackgroundUpdates             @"IMBackgroundUpdates"

#define IMGoogleAPIKeyConstant          @"IMGoogleAPIKey"
#define IMBaseURLKey                    @"IMBaseURL"
#define IMAPIKeyConstant                @"IMAPIKey"
#define IMAPISecretKey                  @"IMAPISecret"

extern NSString *const CONST_UNHCR_DOCUMENT;
extern NSString *const CONST_UNHCR_STATUS;
extern NSString *const CONST_GENDER;
extern NSString *const CONST_DETENTION_LOCATION_TYPE;
extern NSString *const CONST_MARITAL_STATUS;
extern NSString *const CONST_MOVEMENT_TYPE;
extern NSString *const CONST_TRAVEL_MODE;
extern NSString *const CONST_VULNERABILITY;
extern NSString *const CONST_ROOT;
extern NSString *const CONST_IOM_OFFICE;
extern NSString * _UrlName;

- (NSString *)getURL;
- (void)setURL:(NSString*)URLname;
+ (void) initialize;
+ (NSArray *)constantsForKey:(NSString *)key;
+ (void)setConstantForKey:(NSString *)key withValue:(NSString *)value;
+ (NSString *) constantStringForKey:(NSString *)key;

@end