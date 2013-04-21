//
//  ViewController.m
//  ICSExporter
//
//  Created by Kiran Panesar on 09/04/2013.
//  Optimised by Cory Withaz
//  Copyright (c) 2013 MobileX Labs. All rights reserved.
//

#import "ViewController.h"
#import "MXLCalendarManager.h"
#import "MBProgressHUD.h"

@interface ViewController ()

@end

@implementation ViewController

-(void)calendarView:(VRGCalendarView *)calendarView switchedToMonth:(int)month year:(int)year numOfDays:(int)days targetHeight:(float)targetHeight animated:(BOOL)animated {
    // If this month hasn't already loaded and been cached, start loading events
    if (![[savedDates objectForKey:[NSNumber numberWithInt:year]] objectForKey:[NSNumber numberWithInt:month]]) {
        
        // Show a loading HUD (https://github.com/jdg/MBProgressHUD)
        MBProgressHUD *loadingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [loadingHUD setMode:MBProgressHUDModeIndeterminate];
        [loadingHUD setLabelText:@"Loading..."];
        
        // Check the month on a background thread
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSMutableArray *daysArray = [[NSMutableArray alloc] init];
            
            // Create a formatter to provide the date
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyyddMM"];
            
            // For this initial check, all we need to know is whether there's at least ONE event on each day, nothing more.
            // So we loop through each event...
            for (MXLCalendarEvent *event in currentCalendar.events) {
                
                NSDateComponents *components = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[event eventStartDate]];
                
                // If the event starts this month, add it to the array
                if ([components month] == month) {
                    [daysArray addObject:[NSNumber numberWithInteger:[components day]]];
                    [currentCalendar addEvent:event onDateString:[dateFormatter stringFromDate:[event eventStartDate]]];
                } else {
                    // We loop through each day, check if there's an event already there
                    // and if there is, we move onto the next one and repeat until we find a day WITHOUT an event on.
                    // Then we check if this current event occurs then.
                    // This is a way of reducing the number of checkDate: runs we need to do. It also means the algorithm speeds up as it progresses
                    for (int i = 1; i <= days; i++) {
                        if (![daysArray containsObject:[NSNumber numberWithInt:i]]) {
                            if ([event checkDay:i month:month year:year]) {
                                [daysArray addObject:[NSNumber numberWithInteger:i]];
                                [currentCalendar addEvent:event onDay:i month:month year:year];
                            }
                        }
                    }
                }
            }
            
            // Cache the events
            if (![savedDates objectForKey:[NSNumber numberWithInt:year]]) {
                [savedDates setObject:[NSMutableDictionary dictionaryWithObject:@[] forKey:[NSNumber numberWithInt:month]] forKey:[NSNumber numberWithInt:year]];
            }
            [[savedDates objectForKey:[NSNumber numberWithInt:year]] setObject:daysArray forKey:[NSNumber numberWithInt:month]];

            // Refresh the UI on main thread
            dispatch_async( dispatch_get_main_queue(), ^{
                [calendarView markDates:daysArray];
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            });
        });
    } else {
        // If it's already cached, we're done
        [calendarView markDates:[[savedDates objectForKey:[NSNumber numberWithInt:year]] objectForKey:[NSNumber numberWithInt:month]]];    
    }
}

-(void)calendarView:(VRGCalendarView *)calendarView dateSelected:(NSDate *)date {
    // Check if all the events on this day have loaded
    if (![currentCalendar hasLoadedAllEventsForDate:date]) {
        // If not, show a loading HUD
        MBProgressHUD *progressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [progressHUD setMode:MBProgressHUDModeIndeterminate];
        [progressHUD setLabelText:@"Loading..."];
    }
    
    // Run on a background thread
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // If the day hasn't already loaded events...
        if (![currentCalendar hasLoadedAllEventsForDate:date]) {
            // Loop through each event and check whether it occurs on the selected date
            for (MXLCalendarEvent *event in currentCalendar.events) {
                // If it does, save it for the date
                if ([event checkDate:date]) {
                    [currentCalendar addEvent:event onDate:date];
                }
            }
            // Set that the calendar HAS loaded all the events for today
            [currentCalendar loadedAllEventsForDate:date];
        }
        
        // load up the events for today
        currentEvents = [currentCalendar eventsForDate:date];
        
        // Refresh UI
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            
            selectedDate = date;
            [eventsTableView reloadData];
        });
    });
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [currentEvents count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell.textLabel setAdjustsFontSizeToFitWidth:YES];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    
    NSString *string = [NSString stringWithFormat:@"%@ – %@", [[currentEvents objectAtIndex:indexPath.row] eventSummary], [dateFormatter stringFromDate:[[currentEvents objectAtIndex:indexPath.row] eventStartDate]]];
    [cell.textLabel setText:string];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MXLCalendarEvent *currentEvent = [[currentCalendar eventsForDate:selectedDate] objectAtIndex:indexPath.row];
    
    NSLog(@"Event: %@", currentEvent.eventDescription);
    NSLog(@"Event ID: %@", currentEvent.eventUniqueID);
    NSLog(@"Descr: %@", currentEvent.eventSummary);
    NSLog(@"Start: %@", currentEvent.eventStartDate);
    NSLog(@"End  : %@", currentEvent.eventEndDate);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    savedDates = [[NSMutableDictionary alloc] init];
    
    VRGCalendarView *calendar = [[VRGCalendarView alloc] init];
    [calendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"CST"]];
    
    [calendar setDelegate:self];
    [self.view addSubview:calendar];
    
    
    MXLCalendarManager *calendarManager = [[MXLCalendarManager alloc] init];
    
    [calendarManager scanICSFileAtLocalPath:[[NSBundle mainBundle] pathForResource:@"basic" ofType:@"ics"] withCompletionHandler:^(MXLCalendar *calendar, NSError *error) {
        currentCalendar = [[MXLCalendar alloc] init];
        currentCalendar = calendar;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [eventsTableView reloadData];
        });
    }];
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
