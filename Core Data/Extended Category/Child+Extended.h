//
//  Child+Extended.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 4/4/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "Child.h"

@interface Child (Extended)

+ (Child *)childWithId:(NSString *)registrationId inContext:(NSManagedObjectContext *)context;

@end
