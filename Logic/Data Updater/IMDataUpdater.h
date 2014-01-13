//
//  IMDataUpdater.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/12/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InterceptionLocation+Extended.h"

typedef void (^IMDataUpdaterSuccessHandler)(void);
typedef void (^IMDataUpdaterFailureHandler)(NSError *error);
typedef void (^IMDataUpdaterConflictHandler)(NSDictionary *jsonData);

@interface IMDataUpdater : NSObject

@property (nonatomic, copy) IMDataUpdaterSuccessHandler successHandler;
@property (nonatomic, copy) IMDataUpdaterFailureHandler failureHandler;
@property (nonatomic, copy) IMDataUpdaterConflictHandler conflictHandler;

@end