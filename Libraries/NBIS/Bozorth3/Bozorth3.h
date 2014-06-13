//
//  Bozorth3.h
//  Bozorth3
//
//  Created by Mario Yohanes on 1/25/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Bozorth.h"

@interface Bozorth3 : NSObject

- (int)computeBozortScore:(struct xyt_struct *)pstruct gstruct:(struct xyt_struct *)gstruct;

@end