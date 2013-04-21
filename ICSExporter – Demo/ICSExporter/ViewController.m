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
    if (![[savedDates objectForKey:[NSNumber numberWithInt:year]] objectForKey:[NSNumber numberWithInt:month]]) {
        MBProgressHUD *loadingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [loadingHUD setMode:MBProgressHUDModeIndeterminate];
        [loadingHUD setLabelText:@"Loading..."];
        
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *daysArray = [[NSMutableArray alloc] init];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyyddMM"];
            
            for (MXLCalendarEvent *event in currentCalendar.events) {
                NSDateComponents *components = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[event eventStartDate]];
                
                if ([components month] == month) {
                    [daysArray addObject:[NSNumber numberWithInteger:[components day]]];
                    [currentCalendar addEvent:event onDateString:[dateFormatter stringFromDate:[event eventStartDate]]];
                } else {
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
            
            if (![savedDates objectForKey:[NSNumber numberWithInt:year]]) {
                [savedDates setObject:[NSMutableDictionary dictionaryWithObject:@[] forKey:[NSNumber numberWithInt:month]] forKey:[NSNumber numberWithInt:year]];
            }

            [[savedDates objectForKey:[NSNumber numberWithInt:year]] setObject:daysArray forKey:[NSNumber numberWithInt:month]];

            dispatch_async( dispatch_get_main_queue(), ^{
                [calendarView markDates:daysArray];
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            });
        });
    } else {
        [calendarView markDates:[[savedDates objectForKey:[NSNumber numberWithInt:year]] objectForKey:[NSNumber numberWithInt:month]]];    
    }
    
    
}

-(void)calendarView:(VRGCalendarView *)calendarView dateSelected:(NSDate *)date {    
    if (![currentCalendar hasLoadedAllEventsForDate:date]) {
        MBProgressHUD *progressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [progressHUD setMode:MBProgressHUDModeIndeterminate];
        [progressHUD setLabelText:@"Loading..."];
    }
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (![currentCalendar hasLoadedAllEventsForDate:date]) {
            for (MXLCalendarEvent *event in currentCalendar.events) {
                if ([event checkDate:date]) {
                    [currentCalendar addEvent:event onDate:date];
                }
            }
            [currentCalendar loadedAllEventsForDate:date];
        }
        
        currentEvents = [currentCalendar eventsForDate:date];
        
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
