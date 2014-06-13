//
//  IMBackgroundUpdater.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/26/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IMBackgroundFetcher : NSObject

- (void)startBackgroundUpdatesWithCompletionHandler:(void (^)(BOOL success))completionHandler;

@end
