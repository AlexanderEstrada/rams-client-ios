//
//  IMDBManager.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 12/5/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef void (^IMDBManagerOnProgressHandler)(void);
typedef void (^OnDocumentReady) (UIManagedDocument *document);

@interface IMDBManager : NSObject

@property (nonatomic, strong) UIManagedDocument *localDatabase;
@property (nonatomic, readonly) BOOL updating;

+ (IMDBManager *)sharedManager;

//Database operations
- (void)closeDatabase;
- (void)openDatabase:(void (^)(BOOL success))success;
- (void)saveDatabase:(void (^)(BOOL success))success;
- (void)removeDatabase:(void (^)(BOOL success))success;
- (void)performWithDocument:(OnDocumentReady)onDocumentReady;
@property (nonatomic, copy) IMDBManagerOnProgressHandler onProgress;

//Updates
- (void)checkForUpdates;

//App Preferences operations
+ (void)resetDBPreferences;

@end