//
//  MXLCalendarManager.h
//  ICSExporter
//
//  Created by Kiran Panesar on 09/04/2013.
//  Copyright (c) 2013 MobileX Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MXLCalendar.h"
#import "MXLCalendarEvent.h"

@interface MXLCalendarManager : NSObject

-(void)scanICSFileAtLocalPath:(NSString *)filePath withCompletionHandler:(void (^)(MXLCalendar *calendar, NSError *error))callback;

@end
