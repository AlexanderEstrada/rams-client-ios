//
//  NSString+NamingConvention.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 2/12/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "NSString+NamingConvention.h"

@implementation NSString (NamingConvention)

- (NSString *)autoCapitalizeStringForName{
    NSArray *words = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableString *name = [NSMutableString string];
    
    for (int i=0; i<[words count]; i++) {
        NSString *word = [words objectAtIndex:i];
        if (![word length]) break;
        if ([word length] == 1) [name appendString:[word uppercaseString]];
        else {
            NSString *firstLetter = [[word substringToIndex:1] uppercaseString];
            [name appendString:firstLetter];
            [name appendString:[word substringFromIndex:1]];
        }
        
        if (i < [words count] - 1) [name appendString:@" "];
    }
    
    return name;
}

@end
