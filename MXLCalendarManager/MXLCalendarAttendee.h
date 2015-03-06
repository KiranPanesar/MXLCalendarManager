//
//  MXLCalendarAttendee.h
//  ICSExporter
//
//  Created by Rahul Somasunderam on 6/20/14.
//  Copyright (c) 2014 MobileX Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    CHAIR, REQ_PARTICIPANT, OPT_PARTICIPANT, NON_PARTICIPANT
}Role;

@protocol MXLCalendarAttendee

@end
@interface MXLCalendarAttendee : NSObject

@property (strong, nonatomic) NSString *uri;
@property (strong, nonatomic) NSString *commonName;
@property (nonatomic) Role role;

-(id) initWithRole: (Role) role
        commonName: (NSString *) commonName
               uri: (NSString *) uri;
@end
