//
//  MXLCalendarEvent.h
//  ICSExporter
//
//  Created by Kiran Panesar on 09/04/2013.
//  Copyright (c) 2013 MobileX Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@property (strong, nonatomic) NSString *eventUniqueID;
@property (strong, nonatomic) NSString *eventRecurrenceID;
@property (strong, nonatomic) NSString *eventSummary;
@property (strong, nonatomic) NSString *eventDescription;
@property (strong, nonatomic) NSString *eventLocation;
@property (strong, nonatomic) NSString *eventStatus;
@property (strong, nonatomic) NSTimeZone *timeZone;

@property (strong, nonatomic) NSString *rruleString;

-(id)initWithStartDate:(NSString *)startString endDate:(NSString *)endString createdAt:(NSString *)createdString lastModified:(NSString *)lastModifiedString uniqueID:(NSString *)uniqueID recurrenceID:(NSString *)recurrenceID summary:(NSString *)summary description:(NSString *)description location:(NSString *)location status:(NSString *)status recurrenceRules:(NSString *)recurRules exceptionDates:(NSMutableArray *)exceptionDates exceptionRule:(NSString *)exceptionRule timeZoneIdentifier:(NSString *)timezoneID;

-(NSDate *)dateFromString:(NSString *)dateString;

-(void)parseRules:(NSString *)rule forType:(MXLCalendarEventRuleType)type;

-(BOOL)checkDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year;
-(BOOL)checkDate:(NSDate *)date;
-(BOOL)exceptionOnDate:(NSDate *)date;
@end
