//
//  MXLCalendarEvent.h
//  Part of MXLCalendarManager framework
//
//  Created by Kiran Panesar on 09/04/2013.
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

#import <Foundation/Foundation.h>
#import "MXLCalendarAttendee.h"

@class EKEvent;
@class EKEventStore;

typedef enum {
    MXLCalendarEventRuleTypeRepetition,
    MXLCalendarEventRuleTypeException
}MXLCalendarEventRuleType;

@interface MXLCalendarEvent : NSObject {
    NSDateFormatter *dateFormatter;
    
    NSString *exRuleFrequency;
    NSString *exRuleCount;
    NSString *exRuleRuleWkSt;
    NSString *exRuleInterval;
    NSString *exRuleWeekStart;
    NSDate   *exRuleUntilDate;
    
    NSArray *exRuleBySecond;
    NSArray *exRuleByMinute;
    NSArray *exRuleByHour;
    NSArray *exRuleByDay;
    NSArray *exRuleByMonthDay;
    NSArray *exRuleByYearDay;
    NSArray *exRuleByWeekNo;
    NSArray *exRuleByMonth;
    NSArray *exRuleBySetPos;
    
    NSString *repeatRuleFrequency;
    NSString *repeatRuleCount;
    NSString *repeatRuleRuleWkSt;
    NSString *repeatRuleInterval;
    NSString *repeatRuleWeekStart;
    NSDate   *repeatRuleUntilDate;
    
    NSArray *repeatRuleBySecond;
    NSArray *repeatRuleByMinute;
    NSArray *repeatRuleByHour;
    NSArray *repeatRuleByDay;
    NSArray *repeatRuleByMonthDay;
    NSArray *repeatRuleByYearDay;
    NSArray *repeatRuleByWeekNo;
    NSArray *repeatRuleByMonth;
    NSArray *repeatRuleBySetPos;
    
    NSArray *eventExceptionDates;
    
    NSCalendar *calendar;
}

@property (strong, nonatomic) NSDate *eventStartDate;
@property (strong, nonatomic) NSDate *eventEndDate;
@property (strong, nonatomic) NSDate *eventCreatedDate;
@property (strong, nonatomic) NSDate *eventLastModifiedDate;

@property (assign, nonatomic) BOOL eventIsAllDay;

@property (strong, nonatomic) NSString *eventUniqueID;
@property (strong, nonatomic) NSString *eventRecurrenceID;
@property (strong, nonatomic) NSString *eventSummary;
@property (strong, nonatomic) NSString *eventDescription;
@property (strong, nonatomic) NSString *eventLocation;
@property (strong, nonatomic) NSString *eventStatus;
@property (strong, nonatomic) NSArray<MXLCalendarAttendee> *attendees;

@property (strong, nonatomic) NSString *rruleString;

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
             attendees:(NSArray<MXLCalendarAttendee> *)attendees;

-(NSDate *)dateFromString:(NSString *)dateString;

-(void)parseRules:(NSString *)rule
          forType:(MXLCalendarEventRuleType)type;

-(BOOL)checkDay:(NSInteger)day
          month:(NSInteger)month
           year:(NSInteger)year;

-(BOOL)checkDate:(NSDate *)date;

-(BOOL)exceptionOnDate:(NSDate *)date;

- (EKEvent *)convertToEKEventOnDate:(NSDate *)date
                              store:(EKEventStore *)eventStore;

@end
