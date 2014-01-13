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

@interface IMConstants : NSObject

#define IMGoogleAPIKey      @"AIzaSyBX9FNqp2GnryIZGk_yeLY_OrN_9xCORQE"

//#define IMBaseURL           @"http://localhost:8080/api"
//#define IMBaseURL           @"http://172.20.10.2:8080/api"
#define IMBaseURL           @"https://im.iom.or.id/api"

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

#define IMAPIKey                        @"d67acd1c1fa33b68055f9f7dafaa3ae0"
#define IMAPISecret                     @"7cb0533b94446f4c49f1eadcffe5f19a31b25d5d"

#define IMInterceptionFetcherUpdate     @"IMInterceptionFetcherUpdate"
#define IMLastSyncDate                  @"IMLastSyncDate"
#define IMBackgroundUpdates             @"IMBackgroundUpdates"

extern NSString *const CONST_UNHCR_DOCUMENT;
extern NSString *const CONST_UNHCR_STATUS;
extern NSString *const CONST_GENDER;
extern NSString *const CONST_DETENTION_LOCATION_TYPE;
extern NSString *const CONST_MARITAL_STATUS;
extern NSString *const CONST_MOVEMENT_TYPE;
extern NSString *const CONST_TRAVEL_MODE;
extern NSString *const CONST_VULNERABILITY;

+ (NSArray *)constantsForKey:(NSString *)key;

@end