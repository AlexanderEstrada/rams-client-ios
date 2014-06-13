//
//  NBISWrapper.h
//  NBIS
//
//  Created by Mario Yohanes on 1/23/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NBISWrapper : NSObject

+ (NSUInteger)computeNFIQ:(NSString *)imagePath deleteInputWhenDone:(BOOL)shouldDeleteInput;
+ (NSString *)extractTemplate:(NSString *)inputPath intoDirectory:(NSString *)outputPath;

@end
