//
//  MXLCalendar.h
//  ICSExporter
//
//  Created by Kiran Panesar on 09/04/2013.
//  Copyright (c) 2013 MobileX Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MXLCalendarEvent;

@interface MXLCalendar : NSObject {
    NSMutableDictionary *daysOfEvents;
    NSMutableDictionary *loadedEvents;
    
    NSCalendar *calendar;
}

@property (strong, nonatomic) NSMutableArray *events;

- (void)addEvent:(MXLCalendarEvent *)event;

-(void)addEvent:(MXLCalendarEvent *)event onDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year;
- (void)addEvent:(MXLCalendarEvent *)event onDateString:(NSString *)dateString;
- (void)addEvent:(MXLCalendarEvent *)event onDate:(NSDate *)date;

- (BOOL)hasLoadedAllEventsForDate:(NSDate *)date;
- (void)loadedAllEventsForDate:(NSDate *)date;
- (NSMutableArray *)eventsForDate:(NSDate *)date;

@end
