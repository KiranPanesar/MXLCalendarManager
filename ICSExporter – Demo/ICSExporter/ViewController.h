//
//  ViewController.h
//  ICSExporter
//
//  Created by Kiran Panesar on 09/04/2013.
//  Copyright (c) 2013 MobileX Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VRGCalendarView.h"

@class MXLCalendar;

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, VRGCalendarViewDelegate> {
    
    IBOutlet UITableView *eventsTableView;
    MXLCalendar *currentCalendar;
    
    NSDate *selectedDate;
    NSMutableDictionary *savedDates;
    
    NSMutableArray *currentEvents;
}

@end
