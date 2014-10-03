//
//  NSDate+Relativity.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 11/27/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import "NSDate+Relativity.h"

@implementation NSDate (Relativity)

- (NSString *)relativeTime{
    NSDate *todayDate = [NSDate date];
    
    double ti = [self timeIntervalSinceDate:todayDate];
    ti = ti * -1;
    
    if (ti < 60) {
        int seconds = ti < 1 ? 1 : ti;
    	return [NSString stringWithFormat:@"%ds", seconds];
    } else if (ti < 3600) {
    	int diff = round(ti / 60);
    	return [NSString stringWithFormat:@"%dm", diff];
    } else if (ti < 86400) {
    	int diff = round(ti / 60 / 60);
    	return[NSString stringWithFormat:@"%dh", diff];
    } else {
    	int diff = round(ti / 60 / 60 / 24);
    	return[NSString stringWithFormat:@"%dd", diff];
    }
}

- (NSString *)relativeTimeLongFormat{
    NSDate *todayDate = [NSDate date];
    
    double ti = [self timeIntervalSinceDate:todayDate];
    ti = ti * -1;
    
    if (ti <= 0) {
        return @"never";
    } else if (ti < 3600) {
    	int diff = round(ti / 60);
        diff += diff <= 0 ? 1 : 0;
    	return [NSString stringWithFormat:@"%d minute%@ ago", diff, diff > 1 ? @"s" : @""];
    } else if (ti < 86400) {
    	int diff = round(ti / 60 / 60);
    	return[NSString stringWithFormat:@"%d hour%@ ago", diff, diff > 1 ? @"s" : @""];
    } else{
    	int diff = round(ti / 60 / 60 / 24);
    	return[NSString stringWithFormat:@"%d day%@ ago", diff, diff > 1 ? @"s" : @""];
    }
}

- (NSString *)relativeDayLongFormat{
    NSDate *todayDate = [NSDate date];
    
    double ti = [self timeIntervalSinceDate:todayDate];
    ti = ti * -1;
    
    if (ti < 86400) {
    	return @"less than a day ago";
    } else if (ti < (86400 * 30)){
    	int diff = round(ti / 60 / 60 / 24);
    	return[NSString stringWithFormat:@"%d day%@ ago", diff, diff > 1 ? @"s" : @""];
    } else{
        int diff = round(ti / 60 / 60 / 24 / 30);
    	return[NSString stringWithFormat:@"%d month%@ ago", diff, diff > 1 ? @"s" : @""];
    }
}

- (NSString *)relativeTimeToFuture{
    NSDate *todayDate = [NSDate date];
    
    double ti = [todayDate timeIntervalSinceDate:self];
    ti = ti * -1;
    
    if (ti < 60) {
        int seconds = ti < 1 ? 1 : ti;
    	return [NSString stringWithFormat:@"%d second%@", seconds, seconds > 1 ? @"s" : @""];
    } else if (ti < 3600) {
    	int diff = round(ti / 60);
    	return [NSString stringWithFormat:@"%d minute%@", diff, diff > 1 ? @"s" : @""];
    } else if (ti < 86400) {
    	int diff = round(ti / 60 / 60);
    	return[NSString stringWithFormat:@"%d hour%@", diff, diff > 1 ? @"s" : @""];
    } else {
    	int diff = round(ti / 60 / 60 / 24);
    	return[NSString stringWithFormat:@"%d day%@", diff, diff > 1 ? @"s" : @""];
    }
}

- (NSString *)shortFormatted{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM yyyy"];
    return [formatter stringFromDate:self];
}

- (NSString *)mediumFormatted{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd MMM yyyy"];
    return [formatter stringFromDate:self];
}

- (NSString *)longFormatted
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd MMMM yyyy"];
    return [formatter stringFromDate:self];
}

- (NSInteger)age{
    NSDateComponents* ageComponents = [[NSCalendar currentCalendar]
                                       components:NSYearCalendarUnit
                                       fromDate:self
                                       toDate:[NSDate date]
                                       options:0];
    return [ageComponents year];
}

- (NSString *)ageString
{
    return [NSString stringWithFormat:@"%i year%@ old", [self age], [self age] > 1 ? @"s" : @""];
}

+ (NSDate *)dateFromUTCString:(NSString *)utcString{
    if (!utcString || [utcString isEqual:[NSNull null]]) return nil;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [formatter setTimeZone:timeZone];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    return [formatter dateFromString:utcString];
}

- (NSString *)toUTCString{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    NSTimeZone *timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
//    [formatter setTimeZone:timeZone];
    [formatter setDateFormat:@"yyyy-MM-dd'T'00:00:00'Z'"];
//    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:self];
}

- (BOOL)isDateBelongsToThisMonth{
    NSDateComponents *thisMonthComponents = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:[NSDate date]];
    NSDateComponents *dateMonthComponents = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:self];
    
    return [thisMonthComponents month] == [dateMonthComponents month];
}

- (NSDate *)dateByAddingAgeElement:(NSUInteger)age{
    NSDateComponents* ageComponents = [[NSCalendar currentCalendar]
                                       components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                       fromDate:self];

    [ageComponents setYear:([ageComponents year] + age)];
    return [[NSCalendar currentCalendar] dateFromComponents:ageComponents];
}

- (NSDate *)dateBySubstractingAgeElement:(NSUInteger)age{
    NSDateComponents* ageComponents = [[NSCalendar currentCalendar]
                                       components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                       fromDate:self];
    
    [ageComponents setYear:([ageComponents year] - age)];
    return [[NSCalendar currentCalendar] dateFromComponents:ageComponents];
}

- (NSDate *)firstDateOfTheMonth{
    NSDateComponents *monthComponents = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                                                        fromDate:self];
    [monthComponents setDay:1];
    return [[NSCalendar currentCalendar] dateFromComponents:monthComponents];
}

- (NSDate *)dateBySubstractingDayElement:(NSUInteger)daysAgo
{
    NSInteger timeToSubstract = 60 * 60 * 24 * daysAgo * -1;
    return [self dateByAddingTimeInterval:timeToSubstract];
}

- (NSDate *)dateByAddingDayElement:(NSUInteger)days
{
    NSInteger timeToAdd = 60 * 60 * 24 * days;
    return [self dateByAddingTimeInterval:timeToAdd];
}

@end
