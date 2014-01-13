//
//  IMDataFetcher.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/14/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMDataFetcher.h"
#import "IMDBManager.h"


@implementation IMDataFetcher

- (id)initWithFinished:(IMDataFetcherFinishedHandler)onFinished
             onFailure:(IMDataFetcherFailureHandler)onFailure
            onProgress:(IMDataFetcherProgressHandler)onProgress
{
    self = [super init];
    self.onFinished = onFinished;
    self.onFailure = onFailure;
    self.onProgress = onProgress;
    self.total = 0;
    self.progress = 0;
    return self;
}

- (void)fetchUpdates
{
    
}

- (void)postFailureWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onFailure) self.onFailure(error);
    });
}

- (void)setProgress:(NSInteger)progress
{
    _progress = progress;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.onProgress) self.onProgress(self.progress, self.total);
    });
}

- (void)postFinished
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[IMDBManager sharedManager] saveDatabase:^(BOOL success){
            if (!success) NSLog(@"Failed saving database");
            if (self.onFinished) self.onFinished();
        }];
    });
}

@end
