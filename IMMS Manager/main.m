//
//  main.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 9/24/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IMAppDelegate.h"
#include "IMConstants.h"

int main(int argc, char * argv[])
{
    [IMConstants initialize];
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([IMAppDelegate class]));
    }
}
