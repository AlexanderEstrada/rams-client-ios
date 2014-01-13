//
//  BozorthIO.h
//  Bozorth3
//
//  Created by Mario Yohanes on 1/25/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BozorthSort.h"

@interface BozorthIO : NSObject

@property (nonatomic, readwrite) BOOL verbose;

- (struct xyt_struct *)load:(NSString *)templatePath;

@end
