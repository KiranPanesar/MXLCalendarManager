//
//  MXLCalendar.m
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

#import "MXLCalendar.h"
#import "MXLCalendarEvent.h"

@implementation MXLCalendar

-(id)init {
    self = [super init];
    if (self) {
        self.events = [[NSMutableArray alloc] init];
        daysOfEvents = [[NSMutableDictionary alloc] init];
        loadedEvents = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)addEvent:(MXLCalendarEvent *)event {
    [self.events addObject:event];
}

-(void)addEvent:(MXLCalendarEvent *)event onDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyddMM"];

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth| NSCalendarUnitYear fromDate:[NSDate date]];
    
    [components setDay:day];
    [components setMonth:month];
    [components setYear:year];
    
    [self addEvent:event onDateString:[formatter stringFromDate:[[NSCalendar currentCalendar] dateFromComponents:components]]];
}

-(void)addEvent:(MXLCalendarEvent *)event onDateString:(NSString *)dateString {
    // Check if the event has already been logged today
    for (MXLCalendarEvent *currentEvent in [daysOfEvents objectForKey:dateString]) {
        if ([currentEvent.eventUniqueID isEqualToString:event.eventUniqueID])
            return;
    }
    
    // If there are already events for this date...
    if ([daysOfEvents objectForKey:dateString]) {
        // If the event has already been logged on this day, just return.
        if ([[daysOfEvents objectForKey:dateString] containsObject:event])
            return;

        // If not, add it to the day
        [[daysOfEvents objectForKey:dateString] addObject:event];
    } else {
        // If there are no current dates on today, create a new array and save it for the day
        [daysOfEvents setObject:[NSMutableArray arrayWithObject:event] forKey:dateString];
    }
}

-(void)addEvent:(MXLCalendarEvent *)event onDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyddMM"];
    
    [self addEvent:event onDateString:[dateFormatter stringFromDate:date]];
}

-(void)loadedAllEventsForDate:(NSDate *)date {
    [loadedEvents setObject:[NSNumber numberWithBool:YES] forKey:date];
}

-(BOOL)hasLoadedAllEventsForDate:(NSDate *)date {
    if ([loadedEvents objectForKey:date]) {
        return YES;
    } else {
        return NO;
    }
}

-(NSMutableArray *)eventsForDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyddMM"];
    
    [daysOfEvents setObject:[NSMutableArray arrayWithArray:[[daysOfEvents objectForKey:[dateFormatter stringFromDate:date]] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        MXLCalendarEvent *firstEvent = obj1;
        MXLCalendarEvent *secondEvent = obj2;
        
        NSDateComponents *firstComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:firstEvent.eventStartDate];
        NSDateComponents *secondComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:secondEvent.eventStartDate];
        
        return [[[NSCalendar currentCalendar] dateFromComponents:firstComponents] compare:[[NSCalendar currentCalendar] dateFromComponents:secondComponents]];
    }]] forKey:[dateFormatter stringFromDate:date]];
    
    return [daysOfEvents objectForKey:[dateFormatter stringFromDate:date]];
}

@end
