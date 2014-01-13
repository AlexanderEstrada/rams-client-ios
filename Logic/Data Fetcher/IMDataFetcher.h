//
//  IMDataFetcher.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/14/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^IMDataFetcherFinishedHandler)(void);
typedef void(^IMDataFetcherFailureHandler)(NSError *error);
typedef void(^IMDataFetcherProgressHandler)(float progress, float total);
typedef void(^IMDataFetcherSuccessHandler)(BOOL success);


@interface IMDataFetcher : NSObject

@property (nonatomic, copy) IMDataFetcherFinishedHandler onFinished;
@property (nonatomic, copy) IMDataFetcherFailureHandler onFailure;
@property (nonatomic, copy) IMDataFetcherProgressHandler onProgress;

@property (nonatomic) NSInteger total;
@property (nonatomic) NSInteger progress;

- (id)initWithFinished:(IMDataFetcherFinishedHandler)onFinished
             onFailure:(IMDataFetcherFailureHandler)onFailure
            onProgress:(IMDataFetcherProgressHandler)onProgress;

- (void)postFailureWithError:(NSError *)error;
- (void)postFinished;
- (void)fetchUpdates;

@end
