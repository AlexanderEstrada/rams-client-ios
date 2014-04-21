//
//  IMScanFingerprintViewController.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMViewController.h"
#import "Biometric+Storage.h"


@interface IMScanFingerprintViewController : IMViewController

@property (nonatomic) FingerPosition currentFingerPosition;
@property (nonatomic, copy) void (^doneCompletionBlock)(NSMutableDictionary *data);

@end