//
//  MXLCalendarEvent.m
//  Part of MXLCalendarManager framework
//
//  Created by Kiran Panesar on 09/04/2013.
//  Algorithm optimised by Cory Withers
//
//  Copyright (c) 2013 MobileX Labs. All rights reserved.
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

#import "MXLCalendarEvent.h"
#import <EventKit/EventKit.h>

#define DAILY_FREQUENCY @"DAILY"
#define WEEKLY_FREQUENCY @"WEEKLY"
#define MONTHLY_FREQUENCY @"MONTHLY"
#define YEARLY_FREQUENCY @"YEARLY"

@interface MXLCalendarEvent ()

-(NSString *)dayOfWeekFromInteger:(NSInteger)day;

@end

@implementation MXLCalendarEvent

-(id)initWithStartDate:(NSString *)startString
               endDate:(NSString *)endString
             createdAt:(NSString *)createdString
          lastModified:(NSString *)lastModifiedString
              uniqueID:(NSString *)uniqueID
          recurrenceID:(NSString *)recurrenceID
               summary:(NSString *)summary
           description:(NSString *)description
              location:(NSString *)location
                status:(NSString *)status
       recurrenceRules:(NSString *)recurRules
        exceptionDates:(NSMutableArray *)exceptionDates
         exceptionRule:(NSString *)exceptionRule
    timeZoneIdentifier:(NSString *)timezoneID
             attendees:(NSArray<MXLCalendarAttendee> *)attendees {

    self = [super init];

    if (self) {
        calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

        // Set up the shared NSDateFormatter instance to convert the strings to NSDate objects
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:([NSTimeZone timeZoneWithName:timezoneID] ?: [NSTimeZone localTimeZone])];

        [dateFormatter setDateFormat:@"yyyyMMdd HHmmss"];

        // Set the date objects to the converted NSString objects
        self.eventStartDate = [self dateFromString:startString];

        self.eventEndDate   = [self dateFromString:endString];
        self.eventCreatedDate = [self dateFromString:createdString];
        self.eventLastModifiedDate = [self dateFromString:lastModifiedString];

        self.rruleString = recurRules;

        [self parseRules:recurRules    forType:MXLCalendarEventRuleTypeRepetition];
        [self parseRules:exceptionRule forType:MXLCalendarEventRuleTypeException];

        // Set the rest of the properties
        self.eventUniqueID = uniqueID;
        self.eventRecurrenceID  = recurrenceID;
        self.eventSummary = [summary stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        self.eventDescription = [description stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        self.eventLocation = [location stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        self.eventStatus = status;
        self.attendees = attendees;

    }
    return self;
}

-(NSDate *)dateFromString:(NSString *)dateString {
    NSDate *date = nil;
    
    dateString = [dateString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
    
    BOOL containsZone = [dateString rangeOfString:@"z" options:NSCaseInsensitiveSearch].location != NSNotFound;
    
    if (containsZone) {
        dateFormatter.dateFormat = @"yyyyMMdd HHmmssz";
    }
    
    date = [dateFormatter dateFromString:dateString];
    
    if (!date) {
        if (containsZone) {
            dateFormatter.dateFormat = @"yyyyMMddz";
        }
        else {
            dateFormatter.dateFormat = @"yyyyMMdd";
        }
        
        date = [dateFormatter dateFromString:dateString];
            
        if (date) {
            self.eventIsAllDay = YES;
        }
    }
    
    dateFormatter.dateFormat = @"yyyyMMdd HHmmss";
    
    return date;
}

-(void)parseRules:(NSString *)rule
          forType:(MXLCalendarEventRuleType)type {

    if (!rule)
        return;

    NSScanner *ruleScanner;

    NSArray *rulesArray = [rule componentsSeparatedByString:@";"]; // Split up rules string into array

    NSString *frequency;
    NSString *count;
    NSString *untilString;
    NSString *interval;
    NSString *byDay;
    NSString *byMonthDay;
    NSString *byYearDay;
    NSString *byWeekNo;
    NSString *byMonth;
    NSString *weekStart;

    // Loop through each rule
    for (NSString *rule in rulesArray) {
        ruleScanner = [[NSScanner alloc] initWithString:rule];

        // If the rule is for the FREQuency
        if ([rule rangeOfString:@"FREQ"].location != NSNotFound) {
            [ruleScanner scanUpToString:@"=" intoString:nil];
            [ruleScanner scanUpToString:@";" intoString:&frequency];
            frequency = [frequency stringByReplacingOccurrencesOfString:@"=" withString:@""];

            if (type == MXLCalendarEventRuleTypeRepetition) {
                repeatRuleFrequency = frequency;
            } else {
                exRuleFrequency = frequency;
            }
        }

        // If the rule is for the COUNT
        if ([rule rangeOfString:@"COUNT"].location != NSNotFound) {
            [ruleScanner scanUpToString:@"=" intoString:nil];
            [ruleScanner scanUpToString:@";" intoString:&count];
            count = [count stringByReplacingOccurrencesOfString:@"=" withString:@""];

            if (type == MXLCalendarEventRuleTypeRepetition) {
                repeatRuleCount = count;
            } else {
                exRuleCount = count;
            }
        }

        // If the rule is for the UNTIL date
        if ([rule rangeOfString:@"UNTIL"].location != NSNotFound) {
            [ruleScanner scanUpToString:@"=" intoString:nil];
            [ruleScanner scanUpToString:@";" intoString:&untilString];
            untilString = [untilString stringByReplacingOccurrencesOfString:@"=" withString:@""];

            if (type == MXLCalendarEventRuleTypeRepetition) {
                repeatRuleUntilDate = [self dateFromString:untilString];
            } else {
                exRuleUntilDate = [self dateFromString:untilString];
            }
        }

        // If the rule is for the INTERVAL
        if ([rule rangeOfString:@"INTERVAL"].location != NSNotFound) {
            [ruleScanner scanUpToString:@"=" intoString:nil];
            [ruleScanner scanUpToString:@";" intoString:&interval];
            interval = [interval stringByReplacingOccurrencesOfString:@"=" withString:@""];

            if (type == MXLCalendarEventRuleTypeRepetition) {
                repeatRuleInterval = interval;
            } else {
                exRuleInterval = interval;
            }
        }

        // If the rule is for the BYDAY
        if ([rule rangeOfString:@"BYDAY"].location != NSNotFound) {
            [ruleScanner scanUpToString:@"=" intoString:nil];
            [ruleScanner scanUpToString:@";" intoString:&byDay];
            byDay = [byDay stringByReplacingOccurrencesOfString:@"=" withString:@""];

            if (type == MXLCalendarEventRuleTypeRepetition) {
                repeatRuleByDay = [byDay componentsSeparatedByString:@","];
            } else {
                exRuleByDay = [byDay componentsSeparatedByString:@","];
            }

        }

        // If the rule is for the BYMONTHDAY
        if ([rule rangeOfString:@"BYMONTHDAY"].location != NSNotFound) {
            [ruleScanner scanUpToString:@"=" intoString:nil];
            [ruleScanner scanUpToString:@";" intoString:&byMonthDay];
            byMonthDay = [byMonthDay stringByReplacingOccurrencesOfString:@"=" withString:@""];

            if (type == MXLCalendarEventRuleTypeRepetition) {
                repeatRuleByMonthDay = [byMonthDay componentsSeparatedByString:@","];
            } else {
                exRuleByMonthDay = [byMonthDay componentsSeparatedByString:@","];
            }

        }

        // If the rule is for the BYYEARDAY
        if ([rule rangeOfString:@"BYYEARDAY"].location != NSNotFound) {
            [ruleScanner scanUpToString:@"=" intoString:nil];
            [ruleScanner scanUpToString:@";" intoString:&byYearDay];
            byYearDay = [byYearDay stringByReplacingOccurrencesOfString:@"=" withString:@""];

            if (type ==  MXLCalendarEventRuleTypeRepetition) {
                repeatRuleByYearDay = [byYearDay componentsSeparatedByString:@","];
            } else {
                exRuleByYearDay = [byYearDay componentsSeparatedByString:@","];
            }
        }

        // If the rule is for the BYWEEKNO
        if ([rule rangeOfString:@"BYWEEKNO"].location != NSNotFound) {
            [ruleScanner scanUpToString:@"=" intoString:nil];
            [ruleScanner scanUpToString:@";" intoString:&byWeekNo];
            byWeekNo = [byWeekNo stringByReplacingOccurrencesOfString:@"=" withString:@""];

            if (type == MXLCalendarEventRuleTypeRepetition) {
                repeatRuleByWeekNo = [byWeekNo componentsSeparatedByString:@","];
            } else {
                exRuleByWeekNo = [byWeekNo componentsSeparatedByString:@","];
            }
        }

        // If the rule is for the BYMONTH
        if ([rule rangeOfString:@"BYMONTH"].location != NSNotFound) {
            [ruleScanner scanUpToString:@"=" intoString:nil];
            [ruleScanner scanUpToString:@";" intoString:&byMonth];
            byMonth = [byMonth stringByReplacingOccurrencesOfString:@"=" withString:@""];

            if (type == MXLCalendarEventRuleTypeRepetition) {
                repeatRuleByMonth = [byMonth componentsSeparatedByString:@","];
            } else {
                exRuleByMonth = [byMonth componentsSeparatedByString:@","];
            }
        }

        // If the rule is for the WKST
        if ([rule rangeOfString:@"WKST"].location != NSNotFound) {
            [ruleScanner scanUpToString:@"=" intoString:nil];
            [ruleScanner scanUpToString:@";" intoString:&weekStart];
            weekStart = [weekStart stringByReplacingOccurrencesOfString:@"=" withString:@""];

            if (type == MXLCalendarEventRuleTypeRepetition) {
                repeatRuleWeekStart = weekStart;
            } else {
                exRuleWeekStart = weekStart;
            }
        }
    }
}

-(BOOL)checkDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year {
    NSDateComponents *components = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth| NSCalendarUnitYear fromDate:[NSDate date]];

    [components setDay:day];
    [components setMonth:month];
    [components setYear:year];

    return [self checkDate:[calendar dateFromComponents:components]];
}

-(BOOL)checkDate:(NSDate *)date {

    // If the event starts in the future
    if ([self.eventStartDate compare:[NSDate date]] == NSOrderedDescending) {
        return NO;
    }

    // If the event does not repeat, the 'date' must be the event's start date for event to occur on this date
    if (!repeatRuleFrequency) {

        // Load date into NSDateComponent from the NSCalendar instance
        NSDateComponents *difference = [calendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
                                                   fromDate:self.eventStartDate toDate:date options:0];

        // Check if the event's start date is equal to the provided date
        if ([difference day] == 0 &&  [difference month] == 0 && [difference year] == 0 &&  [difference hour] == 0 && [difference minute] == 0 && [difference second] == 0) {
            return ([self exceptionOnDate:date] ? NO : YES); // Check if there's an exception rule covering this date. Return accordingly
        } else {
            return NO; // Event won't occur on this date
        }
    }

    // If the date is in the event's exception dates, event won't occur
    if ([eventExceptionDates containsObject:date]) {
        return NO;
    }

    // Extract the components from the provided date
    NSDateComponents *components = [calendar components:NSCalendarUnitDay | NSCalendarUnitWeekOfYear | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitWeekday
                                                                   fromDate:date];
    NSInteger d = [components day];
    NSInteger m = [components month];
    NSInteger dayOfYear = [calendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitYear forDate:date];

    NSString *dayString = [self dayOfWeekFromInteger:components.weekday];
    NSString *weekNumberString  = [NSString stringWithFormat:@"%li", (long)[components weekOfYear]];
    NSString *monthString = [NSString stringWithFormat:@"%li", (long)m];

    // If the event is set to repeat on a certain day of the week,
    // it MUST be the current date's weekday for it to occur
    if (repeatRuleByDay   && ![repeatRuleByDay containsObject:dayString]) {
        // These checks are to catch if the event is set to repeat on a particular weekday of the month (e.g., every third Sunday)
        if (repeatRuleByDay && ![repeatRuleByDay containsObject:[NSString stringWithFormat:@"1%@", dayString]]) {
            if (repeatRuleByDay && ![repeatRuleByDay containsObject:[NSString stringWithFormat:@"2%@", dayString]]) {
                if (repeatRuleByDay && ![repeatRuleByDay containsObject:[NSString stringWithFormat:@"3%@", dayString]]) {
                    return NO;
                }

            }
        }
    }

    // Same as above (and below)
    if (repeatRuleByMonthDay && ![repeatRuleByMonthDay containsObject:[NSString stringWithFormat:@"%li", (long)d]])
        return NO;

    if (repeatRuleByYearDay && ![repeatRuleByYearDay containsObject:[NSString stringWithFormat:@"%li", (long)dayOfYear]])
        return NO;

    if (repeatRuleByWeekNo && ![repeatRuleByWeekNo containsObject:weekNumberString])
        return NO;

    if (repeatRuleByMonth && ![repeatRuleByMonth containsObject:monthString])
        return NO;

    // If there's no repetition interval provided, it means the interval = 1.
    // We explicitly set it to "1" for use in calculations below
    repeatRuleInterval = (repeatRuleInterval ? repeatRuleInterval : @"1");

    // If it's set to repeat weekly...
    if ([repeatRuleFrequency isEqualToString:WEEKLY_FREQUENCY]) {

        // Is there a limit on the number of repetitions
        // (e.g., event repeats for the 3 occurrences after it first occurred)
        if (repeatRuleCount) {

            // Get the final possible time the event will be repeated
            NSDateComponents *comp = [[NSDateComponents alloc] init];
            [comp setDay:[repeatRuleCount integerValue] * [repeatRuleInterval integerValue]];

            // Create a date by adding the final week it'll occur onto the first occurrence
            NSDate *maximumDate = [calendar dateByAddingComponents:comp
                                                            toDate:self.eventCreatedDate
                                                           options:0];

            // If the final possible occurrence is in the future...
            if ([maximumDate compare:date] == NSOrderedDescending || [maximumDate compare:date] == NSOrderedSame) {

                // Get the number of weeks between the final date and current date
                NSInteger difference = [[calendar components:NSCalendarUnitDay fromDate:maximumDate toDate:date options:0] day];

                // If the difference between the two dates fits the recurrance pattern
                if (difference % [repeatRuleInterval integerValue])
                    // If it doesn't fit into the pattern, it won't occur on this date
                    return NO;
                else
                    // If it does fit the pattern, check the EXRULEs of the event
                    return ([self exceptionOnDate:date] ? NO : YES);
            } else {
                return NO;
            }
            // If, instead of a count, a date is specified to cap repetitions...
        } else if (repeatRuleUntilDate) {
            // See if the repeat until date is AFTER the provided date
            if ([repeatRuleUntilDate compare:date] == NSOrderedDescending || [repeatRuleUntilDate compare:date] == NSOrderedDescending) {

                // Find the difference (as before)
                NSInteger difference = [[calendar components:NSCalendarUnitDay fromDate:repeatRuleUntilDate toDate:date options:0] day];

                // If the difference between the two dates fits the recurrance pattern
                if (difference % [repeatRuleInterval integerValue]) {
                    // if not, event won't occur on date
                    return NO;
                } else {
                    // If it does fit the pattern, check the EXRULEs of the event
                    return ([self exceptionOnDate:date] ? NO : YES);
                }
            } else {
                return NO;
            }
        } else {
            // If there's no recurrance limit, we just have to check if the
            NSInteger difference = [[calendar components:NSCalendarUnitDay fromDate:self.eventCreatedDate toDate:date options:0] day];
            if (difference % [repeatRuleInterval integerValue]) {
                return NO;
            } else {
                return ([self exceptionOnDate:date] ? NO : YES);
            }
        }
        // Same rules apply to above tests
    } else if ([repeatRuleFrequency isEqualToString:MONTHLY_FREQUENCY]) {
        if (repeatRuleCount) {

            NSInteger finalMonth = [repeatRuleCount integerValue] * [repeatRuleInterval integerValue];

            NSDateComponents *comp = [[NSDateComponents alloc] init];
            [comp setMonth:finalMonth];

            NSDate *maximumDate = [calendar dateByAddingComponents:comp
                                                                                toDate:self.eventCreatedDate
                                                                               options:0];

            if ([maximumDate compare:date] == NSOrderedDescending || [maximumDate compare:date] == NSOrderedSame) {
                NSInteger difference = [[calendar components:NSCalendarUnitMonth fromDate:[calendar dateFromComponents:comp] toDate:date options:0] month];
                if (difference % [repeatRuleInterval integerValue]) {
                    return NO;
                } else {
                    return ([self exceptionOnDate:date] ? NO : YES);
                }
            } else {
                return NO;
            }
        } else if (repeatRuleUntilDate) {
            if ([repeatRuleUntilDate compare:date] == NSOrderedDescending || [repeatRuleUntilDate compare:date] == NSOrderedSame) {
                NSInteger difference = [[calendar components:NSCalendarUnitMonth fromDate:repeatRuleUntilDate toDate:date options:0] month];

                if (difference % [repeatRuleInterval integerValue]) {
                    return NO;
                } else {
                    return ([self exceptionOnDate:date] ? NO : YES);
                }

            } else {
                return NO;
            }
        } else {
            NSInteger difference = [[calendar components:NSCalendarUnitDay fromDate:self.eventCreatedDate toDate:date options:0] month];
            if (difference % [repeatRuleInterval integerValue]) {
                return NO;
            } else {
                return ([self exceptionOnDate:date] ? NO : YES);
            }
        }
    } else if ([repeatRuleFrequency isEqualToString:YEARLY_FREQUENCY]) {
        if (repeatRuleCount) {
            NSInteger finalYear = [repeatRuleCount integerValue] * [repeatRuleInterval integerValue];

            NSDateComponents *comp = [[NSDateComponents alloc] init];
            [comp setYear:finalYear];

            NSDate *maximumDate = [calendar dateByAddingComponents:comp
                                                                                toDate:self.eventCreatedDate
                                                                               options:0];

            if ([maximumDate compare:date] == NSOrderedDescending || [maximumDate compare:date] == NSOrderedSame) {
                NSInteger difference = [[calendar components:NSCalendarUnitYear fromDate:[calendar dateFromComponents:comp] toDate:date options:0] year];

                if (difference % [repeatRuleInterval integerValue]) {
                    return NO;
                } else {
                    return ([self exceptionOnDate:date] ? NO : YES);
                }
            }
        } else if (repeatRuleUntilDate) {
            NSInteger difference = [[calendar components:NSCalendarUnitYear fromDate:repeatRuleUntilDate toDate:date options:0] year];

            if (difference % [repeatRuleInterval integerValue]) {
                return NO;
            } else {
                return ([self exceptionOnDate:date] ? NO : YES);
            }
        } else {
            NSInteger difference = [[calendar components:NSCalendarUnitYear fromDate:self.eventCreatedDate toDate:date options:0] year];
            if (difference % [repeatRuleInterval integerValue]) {
                return NO;
            } else {
                return ([self exceptionOnDate:date] ? NO : YES);
            }
        }
    } else {
        return NO;
    }

    return NO;
}

// This algorithm functions the same as checkDate: except rather than checking repeatRule parameters, it checks exRule
-(BOOL)exceptionOnDate:(NSDate *)date {
    // If the event does not repeat, the 'date' must be the event's start date for event to occur on this date
    if (!exRuleFrequency)
        return  NO;

    // If the date is in the event's exception dates, event won't occur
    if ([eventExceptionDates containsObject:date]) {
        return NO;
    }


    NSDateComponents *components = [calendar components:NSCalendarUnitDay | NSCalendarUnitWeekOfYear | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitWeekday
                                                                   fromDate:date];

    NSInteger d = [components day];
    NSInteger m = [components month];

    NSInteger dayOfYear = [calendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitYear forDate:date];

    NSString *dayString = [self dayOfWeekFromInteger:components.weekday];
    NSString *weekNumberString  = [NSString stringWithFormat:@"%li", (long)[components weekOfYear]];
    NSString *monthString = [NSString stringWithFormat:@"%li", (long)m];

    // If the event is set to repeat on a certain day of the week,
    // it MUST be the current date's weekday for it to occur
    if (exRuleByDay   && ![exRuleByDay containsObject:dayString]) {
        // These checks are to catch if the event is set to repeat on a particular weekday of the month (e.g., every third Sunday)
        if (exRuleByDay && ![exRuleByDay containsObject:[NSString stringWithFormat:@"1%@", dayString]]) {
            if (exRuleByDay && ![exRuleByDay containsObject:[NSString stringWithFormat:@"2%@", dayString]]) {
                if (exRuleByDay && ![exRuleByDay containsObject:[NSString stringWithFormat:@"3%@", dayString]]) {
                    return NO;
                }

            }
        }
    }

    // Same as above (and below)
    if (exRuleByMonthDay && ![exRuleByMonthDay containsObject:[NSString stringWithFormat:@"%li", (long)d]])
        return NO;

    if (exRuleByYearDay && ![exRuleByYearDay containsObject:[NSString stringWithFormat:@"%li", (long)dayOfYear]])
        return NO;

    if (exRuleByWeekNo && ![exRuleByWeekNo containsObject:weekNumberString])
        return NO;

    if (exRuleByMonth && ![exRuleByMonth containsObject:monthString])
        return NO;

    exRuleInterval = (exRuleInterval ? exRuleInterval : @"1");

    // If it's set to repeat every week...
    if ([exRuleFrequency isEqualToString:WEEKLY_FREQUENCY]) {

        // Is there a limit on the number of repetitions
        // (e.g., event repeats for the 3 occurrences after it first occurred)
        if (exRuleCount) {

            // Get the final possible time the event will be repeated
            NSDateComponents *comp = [[NSDateComponents alloc] init];
            [comp setDay:[exRuleCount integerValue] * [exRuleInterval integerValue]];

            // Create a date by adding the final week it'll occur onto the first occurrence
            NSDate *maximumDate = [calendar dateByAddingComponents:comp
                                                                                toDate:self.eventCreatedDate
                                                                               options:0];

            // If the final possible occurrence is in the future...
            if ([maximumDate compare:date] == NSOrderedDescending || [maximumDate compare:date] == NSOrderedSame) {

                // Get the number of weeks between the final date and current date
                NSInteger difference = [[calendar components:NSCalendarUnitDay fromDate:maximumDate toDate:date options:0] day];

                if (difference % [exRuleInterval integerValue])
                    return NO;
                else
                    return YES;
            } else {
                return NO;
            }
        } else if (exRuleUntilDate) {
            if ([exRuleUntilDate compare:date] == NSOrderedDescending || [exRuleUntilDate compare:date] == NSOrderedDescending) {
                NSInteger difference = [[calendar components:NSCalendarUnitDay fromDate:exRuleUntilDate toDate:date options:0] day];

                if (difference % [exRuleInterval integerValue]) {
                    return NO;
                } else {
                    return YES;
                }
            } else {
                return NO;
            }
        } else {
            NSInteger difference = [[calendar components:NSCalendarUnitDay fromDate:self.eventCreatedDate toDate:date options:0] day];
            if (difference % [exRuleInterval integerValue]) {
                return NO;
            } else {
                return YES;
            }
        }
    } else if ([exRuleFrequency isEqualToString:MONTHLY_FREQUENCY]) {
        if (exRuleCount) {

            NSInteger finalMonth = [exRuleCount integerValue] * [exRuleInterval integerValue];

            NSDateComponents *comp = [[NSDateComponents alloc] init];
            [comp setMonth:finalMonth];

            NSDate *maximumDate = [calendar dateByAddingComponents:comp
                                                                                toDate:self.eventCreatedDate
                                                                               options:0];

            if ([maximumDate compare:date] == NSOrderedDescending || [maximumDate compare:date] == NSOrderedSame) {
                NSInteger difference = [[calendar components:NSCalendarUnitMonth fromDate:[calendar dateFromComponents:comp] toDate:date options:0] month];
                if (difference % [exRuleInterval integerValue]) {
                    return NO;
                } else {
                    return YES;
                }
            } else {
                return NO;
            }
        } else if (exRuleUntilDate) {
            if ([exRuleUntilDate compare:date] == NSOrderedDescending || [exRuleUntilDate compare:date] == NSOrderedSame) {
                NSInteger difference = [[calendar components:NSCalendarUnitMonth fromDate:exRuleUntilDate toDate:date options:0] month];

                if (difference % [exRuleInterval integerValue]) {
                    return NO;
                } else {
                    return YES;
                }

            } else {
                return NO;
            }
        } else {
            NSInteger difference = [[calendar components:NSCalendarUnitDay fromDate:self.eventCreatedDate toDate:date options:0] month];
            if (difference % [exRuleInterval integerValue]) {
                return NO;
            } else {
                return YES;
            }
        }
    } else if ([exRuleFrequency isEqualToString:YEARLY_FREQUENCY]) {
        if (exRuleCount) {
            NSInteger finalYear = [exRuleCount integerValue] * [exRuleInterval integerValue];

            NSDateComponents *comp = [[NSDateComponents alloc] init];
            [comp setYear:finalYear];

            NSDate *maximumDate = [calendar dateByAddingComponents:comp
                                                                                toDate:self.eventCreatedDate
                                                                               options:0];

            if ([maximumDate compare:date] == NSOrderedDescending || [maximumDate compare:date] == NSOrderedSame) {
                NSInteger difference = [[calendar components:NSCalendarUnitYear fromDate:[calendar dateFromComponents:comp] toDate:date options:0] year];

                if (difference % [exRuleInterval integerValue]) {
                    return NO;
                } else {
                    return YES;
                }
            }
        } else if (exRuleUntilDate) {
            NSInteger difference = [[calendar components:NSCalendarUnitYear fromDate:exRuleUntilDate toDate:date options:0] year];

            if (difference % [exRuleInterval integerValue]) {
                return NO;
            } else {
                return YES;
            }
        } else {
            NSInteger difference = [[calendar components:NSCalendarUnitYear fromDate:self.eventCreatedDate toDate:date options:0] year];
            if (difference % [exRuleInterval integerValue]) {
                return NO;
            } else {
                return YES;
            }
        }
    } else {
        return NO;
    }

    return NO;
}

- (EKEvent *)convertToEKEventOnDate:(NSDate *)date store:(EKEventStore *)eventStore {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                                   fromDate:self.eventStartDate];

    NSDateComponents *endComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                                      fromDate:self.eventEndDate];

    NSDateComponents *selectedDayComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                                              fromDate:date];

    [components setDay:[selectedDayComponents day]];
    [components setMonth:[selectedDayComponents month]];
    [components setYear:[selectedDayComponents year]];

    [endComponents setDay:[selectedDayComponents day]];
    [endComponents setMonth:[selectedDayComponents month]];
    [endComponents setYear:[selectedDayComponents year]];

    EKEvent *event = [EKEvent eventWithEventStore:eventStore];
    [event setTitle:[self eventSummary]];
    [event setNotes:[self eventDescription]];
    [event setLocation:[self eventLocation]];
    [event setAllDay:[self eventIsAllDay]];

    [event setStartDate:[[NSCalendar currentCalendar] dateFromComponents:components]];
    [event setEndDate:[[NSCalendar currentCalendar] dateFromComponents:endComponents]];

    return event;
}


-(NSString *)dayOfWeekFromInteger:(NSInteger)day {
    switch (day) {
        case 1:
            return @"SU";
            break;
        case 2:
            return @"MO";
            break;
        case 3:
            return @"TU";
            break;
        case 4:
            return @"WE";
            break;
        case 5:
            return @"TH";
            break;
        case 6:
            return @"FR";
            break;
        case 7:
            return @"SA";
            break;
        default:
            return @"";
            break;
    }
}
@end
