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

#define apps_tag        @"/api"
#define HTTP            @"http://"
#define HTTPS           @"https://"


@interface IMConstants : NSObject

#define FluentPagingCollectionViewPreloadMargin  10;

#define IMGoogleAPIKey      [[NSUserDefaults standardUserDefaults] stringForKey:@"Google Places API KEY"]
#define IMBaseURL           [[NSUserDefaults standardUserDefaults] stringForKey:@"API URL"]
#define IMAPIKey            [[NSUserDefaults standardUserDefaults] stringForKey:@"API Key"]
#define IMAPISecret         [[NSUserDefaults standardUserDefaults] stringForKey:@"API Secret"]


#define CORE_DATA_OBJECT(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

#define IMLocaDBName                    @"RAMS"

#define IMShowMigrantListNotification   @"IMShowMigrantListNotification"
#define IMCancelNotification            @"IMCancelNotification"

#define IMDatabaseChangedNotification   @"IMDatabaseChangedNotification"
#define IMAccessExpiredNotification     @"IMAccessExpiredNotification"
#define IMAccessExpiredCloseNotification     @"IMAccessExpiredCloseNotification"
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


// Tag value
#define IMDefaultAlertTag               666
#define IMAlertUpload_Tag                   1
#define IMAlertUpdate_Tag                   2
#define IMAlertRelogin_Tag                  3
#define IMAlertNeedSynch_Tag                4
#define IMAlertNOUNHCR_Tag                  5
#define IMAlertLocationConfirmation_Tag     6
#define IMAlertLocationExists_Tag           7
#define IMAlertContinueToPopNavigation_Tag  8
#define IMAlertStartWithoutSynch_Tag        9
#define IMAlertUploadSuccess_Tag                   10
#define IMDeleteItems_Tag                   11
#define IMForgotPassword_Tag                   12
#define IMSkipFinger_Tag                   13



//Longitude & Latitude
#define IMLatitude                          -0.5
#define IMLongitude                         117


//Root View Controller
#define IMRootViewSideMenuOffsetX        -50
#define IMRootViewContentCenterOffsetX   300
#define IMRootViewAnimationDuration      0.3

//Anymous

extern NSString *const CONST_UNHCR_DOCUMENT;
extern NSString *const CONST_UNHCR_STATUS;
extern NSString *const CONST_GENDER;
extern NSString *const CONST_MARITAL_STATUS;
extern NSString *const CONST_MOVEMENT_TYPE;
extern NSString *const CONST_TRAVEL_MODE;
extern NSString *const CONST_VULNERABILITY;
extern NSString *const CONST_ROOT;
extern NSString *const CONST_IOM_OFFICE;
extern NSString *const CONST_LOCATION;
extern NSString *const CONST_FAMILY_TYPE;
extern NSString * _UrlName;
extern NSInteger const Default_Page_Size;


//value for path address
extern NSString *const CONST_IMReferences;
extern NSString *const CONST_IMMigrantShow;
extern NSString *const CONST_IMFamilyGet;
extern NSString *const CONST_IMUpdateApp;
extern NSString *const CONST_IMMigrantUpdate;
extern NSString *const CONST_IMInterceptionUpdateMovement;
extern NSString *const CONST_IMMigrantList;
extern NSString *const CONST_IMInterceptionLocationList;
extern NSString *const CONST_IMInterceptionList;
extern NSString *const CONST_IMFamilyList;
extern NSString *const CONST_IMAccomodationList;
extern NSString *const CONST_IMMigrantSave;
extern NSString *const CONST_IMMovementSave;
extern NSString *const CONST_IMInterceptionLocationSave;
extern NSString *const CONST_IMInterceptionSave;
extern NSString *const CONST_IMAccomodationSave;
extern NSString *const CONST_IMFamilySave;
extern NSString *const CONST_IMSleepDefault;
extern NSString *const CONST_IMForgotPassword;


#define FAMILY_TYPE_HEAD_OF_FAMILY @"HEAD_OF_FAMILY"
#define FAMILY_TYPE_GRAND_FATHER @"GRAND_FATHER"
#define FAMILY_TYPE_GRAND_MOTHER @"GRAND_MOTHER"
#define FAMILY_TYPE_GUARDIAN @"GUARDIAN"
#define FAMILY_TYPE_SPOUSE @"SPOUSE"
#define FAMILY_TYPE_CHILD @"CHILD"
#define FAMILY_TYPE_OTHER_EXTENDED_MEMBER @"OTHER_EXTENDED_MEMBER"


- (NSString *)getURL;
- (void)setURL:(NSString*)URLname;
+ (void) initialize;
+ (NSString *) getIMConstantKey:(NSString *)key;
+ (NSNumber *) getIMConstantKeyNumber:(NSString *)key;
+ (NSArray *)constantsForKey:(NSString *)key;
+ (void)setConstantForKey:(NSString *)key withValue:(NSString *)value;
+ (NSString *) constantStringForKey:(NSString *)key;

@end