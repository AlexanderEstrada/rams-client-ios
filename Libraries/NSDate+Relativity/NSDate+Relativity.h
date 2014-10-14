//
//  NSDate+Relativity.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 11/27/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Relativity)

+ (NSDate *)dateFromUTCString:(NSString *)utcString;

- (NSString *)toUTCString;
- (NSString *)toUTCStringWithTime;
- (NSString *)relativeTime;
- (NSString *)relativeTimeLongFormat;
- (NSString *)relativeTimeToFuture;
- (NSString *)relativeDayLongFormat;

- (NSInteger)age;
- (NSString *)ageString;
- (NSString *)shortFormatted;
- (NSString *)mediumFormatted;
- (NSString *)longFormatted;

- (BOOL)isDateBelongsToThisMonth;

- (NSDate *)dateByAddingAgeElement:(NSUInteger)age;
- (NSDate *)dateBySubstractingAgeElement:(NSUInteger)age;
- (NSDate *)firstDateOfTheMonth;

- (NSDate *)dateBySubstractingDayElement:(NSUInteger)daysAgo;
- (NSDate *)dateByAddingDayElement:(NSUInteger)days;

@end
