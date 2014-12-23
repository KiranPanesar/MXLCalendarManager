//
//  NSDateComponents+ISO8601Duration.m
//  ISO8601Duration
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Kevin Randrup
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "NSDateComponents+ISO8601Duration.h"

@implementation NSDateComponents (ISO8601Duration)

//Note: Does not handle decimal values or overflow values
+ (NSDateComponents *)durationFrom8601String:(NSString *)durationString //Format: PnYnMnDTnHnMnS or PnW
{
    NSCharacterSet *timeDesignators = [NSCharacterSet characterSetWithCharactersInString:@"HMS"];
    NSCharacterSet *periodDesignators = [NSCharacterSet characterSetWithCharactersInString:@"YMD"];
    
    NSDateComponents *dateComponents = [NSDateComponents new];
    NSMutableString *mutableDurationString = [durationString mutableCopy];
    
    NSRange pRange = [mutableDurationString rangeOfString:@"P"];
    if (pRange.location == NSNotFound) {
        [self logErrorMessage:durationString];
        return nil;
    }
    else {
        [mutableDurationString deleteCharactersInRange:pRange];
    }
    
    if ([durationString containsString:@"W"]) {
        NSDictionary *weekValues = [self componentsForString:mutableDurationString fromDesignatorSet:[NSCharacterSet characterSetWithCharactersInString:@"W"]];
        
        dateComponents.day = [weekValues[@"W"] doubleValue] * 7; //7 day week specified in ISO 8601 standard
        return dateComponents;
    }
    
    NSRange tRange = [mutableDurationString rangeOfString:@"T" options:NSLiteralSearch];
    NSString *periodString = nil;
    NSString *timeString = nil;
    if (tRange.location == NSNotFound) {
        periodString = mutableDurationString;
    } else {
        periodString = [mutableDurationString substringToIndex:tRange.location];
        timeString = [mutableDurationString substringFromIndex:tRange.location+1];
    }
    
//    //Might be faster; needs testing for speed
//    NSArray *timePeriodSplit = [mutableDurationString componentsSeparatedByString:@"T"];
//    timeString = [timePeriodSplit lastObject];
//    periodString = [timePeriodSplit firstObject];
    
    //SnMnHn
    NSDictionary *timeValues = [self componentsForString:timeString fromDesignatorSet:timeDesignators];
    [timeValues enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSInteger value = [obj integerValue];
        if ([key isEqualToString:@"S"]) {
            dateComponents.second = value;
        } else if ([key isEqualToString:@"M"]) {
            dateComponents.minute = value;
        } else if ([key isEqualToString:@"H"]) {
            dateComponents.hour = value;
        }
    }];
    
    //DnMnYn
    NSDictionary *periodValues = [self componentsForString:periodString fromDesignatorSet:periodDesignators];
    [periodValues enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSInteger value = [obj integerValue];
        if ([key isEqualToString:@"D"]) {
            dateComponents.day = value;
        } else if ([key isEqualToString:@"M"]) {
            dateComponents.month = value;
        } else if ([key isEqualToString:@"Y"]) {
            dateComponents.year = value;
        }
    }];
    
    return dateComponents;
}

+ (NSDictionary *)componentsForString:(NSString *)string fromDesignatorSet:(NSCharacterSet *)designatorSet
{
    if (!string) return nil;
    static NSCharacterSet *numericalSet = nil;
    if (!numericalSet) numericalSet = [NSCharacterSet decimalDigitCharacterSet];
    NSMutableArray *componentValues = [[string componentsSeparatedByCharactersInSet:designatorSet] mutableCopy];
    NSMutableArray *designatorValues = [[string componentsSeparatedByCharactersInSet:numericalSet] mutableCopy];
    [componentValues removeObject:@""];
    [designatorValues removeObject:@""];
    if (componentValues.count == designatorValues.count) {
        return [NSDictionary dictionaryWithObjects:componentValues forKeys:designatorValues];
    } else {
        NSLog(@"String: %@ has an invalid format.", string);
        return nil;
    }
}

+ (void)logErrorMessage:(NSString *)durationString
{
    NSLog(@"String: %@ has an invalid format.", durationString);
    NSLog(@"durationString must have a format of PnYnMnDTnHnMnS or PnW");
}

@end
