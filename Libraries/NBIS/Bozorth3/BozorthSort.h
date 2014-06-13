//
//  BozorthSort.h
//  Bozorth3
//
//  Created by Mario Yohanes on 1/25/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Bozorth.h"


@interface BozorthSort : NSObject

- (int)sortQualityDecreasing:(const void *)a pair:(const void *)b;
- (int)sortX:(const void *)a withY:(const void *)b;
- (int)qsortDecreasing:(struct cell [])v left:(int)left right:(int)right;
- (int)sortOrderDecreasing:(int [])values num:(int)num order:(int [])order;

@end
