//
//  MXLCalendarAttendee.m
//  ICSExporter
//
//  Created by Rahul Somasunderam on 6/20/14.
//  Copyright (c) 2014 MobileX Labs. All rights reserved.
//

#import "MXLCalendarAttendee.h"

@implementation MXLCalendarAttendee

-(id) initWithRole: (Role) role
        commonName: (NSString *) commonName
               uri: (NSString *) uri
{
    self = super.self;
    if (self) {
        self.role = role;
        self.commonName = commonName;
        self.uri = uri;
    }
    return self;
}

@end
