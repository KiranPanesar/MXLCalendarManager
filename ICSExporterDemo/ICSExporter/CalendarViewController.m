//
//  CalendarViewController.m
//  ICSExporter
//
//  Created by Kiran Panesar on 19/03/2015.
//  Copyright (c) 2015 MobileX Labs. All rights reserved.
//

#import "CalendarViewController.h"
#import "MBProgressHUD.h"
#import "MXLCalendarManager.h"

@interface CalendarViewController () <UITableViewDataSource>

@property (strong, nonatomic, readwrite) NSLayoutConstraint *calendarContentViewHeightConstraint;

- (void)pushTodayButton:(id)sender;
- (void)pushChangeModeButton:(id)sender;
- (void)transitionCalendarMode;

- (void)setUpCalendar;
- (void)setUpMenuView;
- (void)setUpContentView;
- (void)setUpTableView;

- (void)setUpBarButtonItems;

@end

@implementation CalendarViewController

#pragma mark - 
#pragma mark IBActions

- (void)pushTodayButton:(id)sender {
    NSDate *currentDate = [NSDate date];

    [self.calendar setCurrentDateSelected:currentDate];
    [self.calendar setCurrentDate:currentDate];
    [self calendarDidDateSelected:self.calendar date:currentDate];;
}

- (void)pushChangeModeButton:(id)sender {
    self.calendar.calendarAppearance.isWeekMode = !self.calendar.calendarAppearance.isWeekMode;

    [self transitionCalendarMode];
}

- (void)transitionCalendarMode {
    CGFloat newHeight = 300.0f;

    if(self.calendar.calendarAppearance.isWeekMode){
        newHeight = 75.0f;
    }
    
    [UIView animateWithDuration:.5
                     animations:^{
                         self.calendarContentViewHeightConstraint.constant = newHeight;
                         [self.view layoutIfNeeded];
                     }];
    
    [UIView animateWithDuration:.25
                     animations:^{
                         self.calendarContentView.layer.opacity = 0;
                     }
                     completion:^(BOOL finished) {
                         [self.calendar reloadAppearance];
                         
                         [UIView animateWithDuration:.25
                                          animations:^{
                                              self.calendarContentView.layer.opacity = 1;
                                          }];
                     }];
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [currentEvents count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell.textLabel setText:[[currentEvents objectAtIndex:indexPath.row] eventSummary]];
    
    return cell;
}

- (void)loadEventsForDate:(NSDate *)currentDate {
    NSDateComponents *currentDateComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:currentDate];
    
    // If this month hasn't already loaded and been cached, start loading events
    if (![[savedDates objectForKey:[NSNumber numberWithInteger:currentDateComponents.year]] objectForKey:[NSNumber numberWithInteger:currentDateComponents.month]]) {
        
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
                
                NSDateComponents *components = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[event eventStartDate]];
                
                // If the event starts this month, add it to the array
                if ([components month] == currentDateComponents.month && [components year] == currentDateComponents.year) {
                    [daysArray addObject:[NSNumber numberWithInteger:[components day]]];
                    [currentCalendar addEvent:event onDateString:[dateFormatter stringFromDate:[event eventStartDate]]];
                } else {
                    NSCalendar *cal = [NSCalendar currentCalendar];
                    NSRange rng = [cal rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:currentDate];
                    NSUInteger numberOfDaysInMonth = rng.length;
                    
                    // We loop through each day, check if there's an event already there
                    // and if there is, we move onto the next one and repeat until we find a day WITHOUT an event on.
                    // Then we check if this current event occurs then.
                    // This is a way of reducing the number of checkDate: runs we need to do. It also means the algorithm speeds up as it progresses
                    for (int i = 1; i <= numberOfDaysInMonth; i++) {
                        
                        if (![daysArray containsObject:[NSNumber numberWithInt:i]]) {
                            if ([event checkDay:i month:currentDateComponents.month year:currentDateComponents.year]) {
                                [daysArray addObject:[NSNumber numberWithInteger:i]];
                                [currentCalendar addEvent:event onDay:i month:currentDateComponents.month year:currentDateComponents.year];
                            }
                        }
                    }
                }
            }
            
            // Cache the events
            if (![savedDates objectForKey:[NSNumber numberWithInteger:currentDateComponents.year]]) {
                [savedDates setObject:[NSMutableDictionary dictionaryWithObject:@[] forKey:[NSNumber numberWithInteger:currentDateComponents.month]]
                               forKey:[NSNumber numberWithInteger:currentDateComponents.year]];
            }
            
            [[savedDates objectForKey:[NSNumber numberWithInteger:currentDateComponents.year]] setObject:daysArray forKey:[NSNumber numberWithInteger:currentDateComponents.month]];
            
            // Refresh the UI on main thread
            dispatch_async( dispatch_get_main_queue(), ^{
                [self.calendar reloadData];
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            });
        });
    }
}

#pragma mark - 
#pragma mark Subview setup

- (void)setUpCalendar {
    
    self.calendar = [JTCalendar new];
    self.calendar.calendarAppearance.menuMonthTextFont = [UIFont systemFontOfSize:13.0f];
    self.calendar.calendarAppearance.menuMonthTextColor = [UIColor grayColor];
    self.calendar.calendarAppearance.monthBlock = ^NSString *(NSDate *date, JTCalendar *jt_calendar){
        NSCalendar *calendar = jt_calendar.calendarAppearance.calendar;
        NSDateComponents *comps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:date];
        NSInteger currentMonthIndex = comps.month;
        
        static NSDateFormatter *dateFormatter;
        if(!dateFormatter){
            dateFormatter = [NSDateFormatter new];
            dateFormatter.timeZone = jt_calendar.calendarAppearance.calendar.timeZone;
        }
        
        while(currentMonthIndex <= 0){
            currentMonthIndex += 12;
        }
        
        NSString *monthText = [[dateFormatter standaloneMonthSymbols][currentMonthIndex - 1] capitalizedString];
        
        return [NSString stringWithFormat:@"%ld %@", comps.year, monthText];
    };
    
    [self setUpMenuView];
    [self setUpContentView];
    [self setUpTableView];
    
    [self.calendar setMenuMonthsView:self.calendarMenuView];
    [self.calendar setContentView:self.calendarContentView];
    [self.calendar setDataSource:self];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self pushTodayButton:nil];
    });
}

- (void)setUpMenuView {
    self.calendarMenuView = [[JTCalendarMenuView alloc] initWithFrame:CGRectZero];
    self.calendarMenuView.translatesAutoresizingMaskIntoConstraints = NO;
    self.calendarMenuView.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.calendarMenuView];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarMenuView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarMenuView
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarMenuView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarMenuView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:0.0f
                                                           constant:25.0f]];
}

- (void)setUpContentView {
    self.calendarContentView = [[JTCalendarContentView alloc] initWithFrame:CGRectZero];
    self.calendarContentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.calendarContentView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.calendarContentView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarContentView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.calendarMenuView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarContentView
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarContentView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    self.calendarContentViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.calendarContentView
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.view
                                                                            attribute:NSLayoutAttributeHeight
                                                                           multiplier:0.0f
                                                                             constant:300.0f];
    [self.view addConstraint:self.calendarContentViewHeightConstraint];
}

- (void)setUpTableView {
    self.currentDayTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.currentDayTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.currentDayTableView.dataSource = self;
    
    [self.view addSubview:self.currentDayTableView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.currentDayTableView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.calendarContentView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0f
                                                           constant:5.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.currentDayTableView
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.currentDayTableView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.currentDayTableView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0f
                                                           constant:0.0f]];
}

- (void)setUpBarButtonItems {
    UIBarButtonItem *todayButton = [[UIBarButtonItem alloc] initWithTitle:@"Today" style:UIBarButtonItemStylePlain target:self action:@selector(pushTodayButton:)];
    UIBarButtonItem *changeModeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(pushChangeModeButton:)];
    
    [self.navigationItem setRightBarButtonItems:@[todayButton, changeModeButton]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setUpCalendar];
    [self setUpBarButtonItems];
    
    savedDates = [@{} mutableCopy];
    
    MXLCalendarManager *calendarManager = [[MXLCalendarManager alloc] init];
    
    [calendarManager scanICSFileAtLocalPath:[[NSBundle mainBundle] pathForResource:@"basic" ofType:@"ics"]
                      withCompletionHandler:^(MXLCalendar *calendar, NSError *error) {
                          currentCalendar = [[MXLCalendar alloc] init];
                          currentCalendar = calendar;
                          
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [self calendarDidLoadNextPage];
                          });
                      }];
    
}

- (void)viewDidLayoutSubviews {
    [self.calendar repositionViews];
}

- (void)calendarDidLoadNextPage {
    [self loadEventsForDate:self.calendar.currentDate];
}

- (void)calendarDidLoadPreviousPage {
    [self loadEventsForDate:self.calendar.currentDate];
}

- (BOOL)calendarHaveEvent:(JTCalendar *)calendar date:(NSDate *)date
{
    NSDateComponents *currentDateComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];

    for (NSNumber *number in [[savedDates objectForKey:[NSNumber numberWithInteger:currentDateComponents.year]]
                               objectForKey:[NSNumber numberWithInteger:currentDateComponents.month]]) {
        if ([number integerValue] == currentDateComponents.day) {
            return YES;
        }
    }
    
    return NO;
}

- (void)calendarDidDateSelected:(JTCalendar *)calendar date:(NSDate *)date {
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
            [self.currentDayTableView reloadData];
        });
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
