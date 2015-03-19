//
//  CalendarViewController.h
//  ICSExporter
//
//  Created by Kiran Panesar on 19/03/2015.
//  Copyright (c) 2015 MobileX Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JTCalendar.h"
#import "MXLCalendar.h"

@interface CalendarViewController : UIViewController <JTCalendarDataSource> {
    MXLCalendar *currentCalendar;
    
    NSDate *selectedDate;
    NSMutableDictionary *savedDates;
    
    NSMutableArray *currentEvents;
}
@property (strong, nonatomic) JTCalendarMenuView *calendarMenuView;
@property (strong, nonatomic) JTCalendarContentView *calendarContentView;

@property (strong, nonatomic) JTCalendar *calendar;

@property (strong, nonatomic, readwrite) UITableView *currentDayTableView;

@end
