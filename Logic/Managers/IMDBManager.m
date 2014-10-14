//
//  IMDBManager.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 12/5/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import "IMDBManager.h"
#import "NSDate+Relativity.h"
#import "IMConstants.h"
#import "IMHTTPClient.h"
#import "IMBackgroundFetcher.h"
#import "IMAuthManager.h"
//#import "NSMigrationManager.h"
//#import "NSMappingModel.h"



@interface IMDBManager ()
@property (nonatomic, strong) UIManagedDocument *destinationDatabase;
@end


@implementation IMDBManager

#pragma mark Initializer
+ (IMDBManager *)sharedManager
{
    static dispatch_once_t once;
    static IMDBManager *singleton = nil;
    
    dispatch_once(&once, ^{
        singleton = [[IMDBManager alloc] init];
    });
    
    return singleton;
}

- (UIManagedDocument *)localDatabase
{
    if (!_localDatabase) {
        
        NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        url = [url URLByAppendingPathComponent:IMLocaDBName];
        _localDatabase = [[UIManagedDocument alloc] initWithFileURL:url];

        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        
        _localDatabase.persistentStoreOptions = options;
    }
    
    return _localDatabase;
}


- (UIManagedDocument *)destinationDatabase
{
    if (!_destinationDatabase) {
        NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        url = [url URLByAppendingPathComponent:IMDestinationDBName];
        _destinationDatabase = [[UIManagedDocument alloc] initWithFileURL:url];
    
        // Set our document up for automatic migrations
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        
        _destinationDatabase.persistentStoreOptions = options;
    }
    
    return _destinationDatabase;
}


- (void)performWithDocument:(OnDocumentReady)onDocumentReady
{
    void (^OnDocumentDidLoad)(BOOL) = ^(BOOL success) {
        onDocumentReady(self.localDatabase);
    };
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.localDatabase.fileURL path]]) {
        [self.localDatabase saveToURL:self.localDatabase.fileURL
                     forSaveOperation:UIDocumentSaveForCreating
                    completionHandler:OnDocumentDidLoad];
    } else if (self.localDatabase.documentState == UIDocumentStateClosed) {
        [self.localDatabase openWithCompletionHandler:OnDocumentDidLoad];
    } else if (self.localDatabase.documentState == UIDocumentStateNormal) {
        OnDocumentDidLoad(YES);
    }
}


- (void)openDatabase:(void (^)(BOOL success))successBlock
{
    @try {
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self.localDatabase.fileURL path]]) {
            [self.localDatabase saveToURL:self.localDatabase.fileURL
                         forSaveOperation:UIDocumentSaveForCreating
                        completionHandler:^(BOOL success){
                            [self.localDatabase openWithCompletionHandler:successBlock];
                        }];
        }else if (self.localDatabase.documentState == UIDocumentStateClosed){
            
            [self.localDatabase openWithCompletionHandler:^(BOOL success){
                if (!success) {
                    NSError * err;
                    NSMigrationManager * manager = [[NSMigrationManager alloc] init];
                    NSURL * oldData = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
                    oldData = [oldData URLByAppendingPathComponent:IMLocaDBName];
                    
                    NSURL * newData = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
                    newData = [newData URLByAppendingPathComponent:IMDestinationDBName];
                    
                    
                    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"modelMapping" withExtension:@"cdm"];
                    NSMappingModel *mappingModel = [[NSMappingModel alloc] initWithContentsOfURL:fileURL];
                    
                    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
                    //try to change the model
                    if (![manager migrateStoreFromURL:oldData type:NSSQLiteStoreType options:options withMappingModel:mappingModel toDestinationURL:newData destinationType:NSSQLiteStoreType destinationOptions:options error:&err]) {
                        NSLog(@"Error while change mapping : %@",[err description]);
                    }else {
                        //change local to destination
                        _localDatabase = Nil;
                        _localDatabase = _destinationDatabase;
                        //set to success
                        success = YES;
                    }
                    
                }
                
                if (successBlock) {
                    successBlock(success);
                }
                
            }];
        
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exeption while openDatabase : %@",[exception description]);
    }
    
}

- (void)closeDatabase
{
    [self.localDatabase closeWithCompletionHandler:^(BOOL success){
        self.localDatabase = nil;
    }];
}

- (void)saveDatabase:(void (^)(BOOL success))successBlock
{
    [self.localDatabase saveToURL:self.localDatabase.fileURL
                 forSaveOperation:UIDocumentSaveForOverwriting
                completionHandler:^(BOOL success){
                    if (success) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil userInfo:nil];
                    }
                    if (successBlock) successBlock(success);
                }];
}

- (void)removeDatabase:(void (^)(BOOL success))successHandler
{
    @try {
        if (self.onProgress) {
            self.onProgress();
        }
        NSDictionary *options = @{
                                  NSMigratePersistentStoresAutomaticallyOption : @YES,
                                  NSInferMappingModelAutomaticallyOption : @YES
                                  };
        
        NSManagedObjectContext *managedObjectContext = self.localDatabase.managedObjectContext;
        NSError * error;
        // retrieve the store URL
        NSURL * storeURL = [[managedObjectContext persistentStoreCoordinator] URLForPersistentStore:[[[managedObjectContext persistentStoreCoordinator] persistentStores] lastObject]];
        // lock the current context
        [managedObjectContext lock];
        [managedObjectContext reset];//to drop pending changes
        //delete the store from the current managedObjectContext
        if ([[managedObjectContext persistentStoreCoordinator] removePersistentStore:[[[managedObjectContext persistentStoreCoordinator] persistentStores] lastObject] error:&error])
        {
            // remove the file containing the data
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
            //recreate the store like in the  appDelegate method
            [[managedObjectContext persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];//recreates the persistent store
        }
        [managedObjectContext unlock];
        [IMDBManager resetDBPreferences];
        
        //recreate database
        [self openDatabase:^(BOOL databaseOpened){
            if (successHandler) successHandler(databaseOpened);
        }];
        if (successHandler) successHandler(YES);
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while removing database: %@", [exception description]);
        if (successHandler) successHandler(NO);
    }
}

- (void)checkForUpdates
{
    NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:IMLastSyncDate];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (lastSyncDate) [params setObject:[lastSyncDate toUTCStringWithTime] forKey:@"since"];
    
    [[IMHTTPClient sharedClient] getJSONWithPath:@"update/data"
                                      parameters:params
                                         success:^(NSDictionary *jsonData, int statusCode){
                                             int interception = [jsonData[@"interception"] intValue];
                                             int accommodation = [jsonData[@"accommodation"] intValue];
                                             int total = interception + accommodation;
                                             BOOL backgroundUpdates = [[[NSUserDefaults standardUserDefaults] objectForKey:IMBackgroundUpdates] boolValue];
                                             
                                             if (total && backgroundUpdates) {
                                                 [self startBackgroundUpdates];
                                             }else if (total && !backgroundUpdates) {
                                                 [[NSNotificationCenter defaultCenter] postNotificationName:IMSyncShouldStartedNotification object:nil userInfo:@{IMUpdatesAvailable: @(total)}];
                                             }
                                         }
                                         failure:nil];
}

- (void)startBackgroundUpdates
{
    _updating = YES;
    IMBackgroundFetcher *updater = [[IMBackgroundFetcher alloc] init];
    [updater startBackgroundUpdatesWithCompletionHandler:^(BOOL success){
        _updating = NO;
        if (success) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[NSDate date] forKey:IMLastSyncDate];
            [defaults synchronize];
            
            [self saveDatabase:nil];
        }else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Updates Failed"
                                                            message:@"Failed updating application data. Go to Settings > Check Data Updates to restart.\nIf problem persist, please contact administrator."
                                                           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
}


#pragma mark Preferences Methods
+ (void)resetDBPreferences
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def removeObjectForKey:IMLastSyncDate];
    [def removeObjectForKey:IMInterceptionFetcherUpdate];
    [def synchronize];
}

@end