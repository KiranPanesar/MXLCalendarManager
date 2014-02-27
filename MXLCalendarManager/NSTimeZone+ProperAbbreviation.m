//
//  NSTimeZone+ProperAbbreviation.m
//  MobileX Test
//
//  Created by Kiran Panesar on 02/10/2013.
//  Copyright (c) 2013 MobileX Labs. All rights reserved.
//

#import "NSTimeZone+ProperAbbreviation.h"

@implementation NSTimeZone (ProperAbbreviation)

-(NSString *)properAbbreviation {
    
    if ([[self abbreviation] isEqualToString:@"GMT"] || [[self abbreviation] isEqualToString:@"BST"]) {
        return [self abbreviation];
    }

    NSArray *timezoneNames = [NSTimeZone knownTimeZoneNames];
	for (NSString *name in
		 [timezoneNames sortedArrayUsingSelector:@selector(compare:)])
	{
		NSLog(@"%@",name);
	}
    
    NSDictionary *abbrev = [NSTimeZone abbreviationDictionary];
    NSLog(@"%@", abbrev);
    
    return [[[NSTimeZone abbreviationDictionary] allKeysForObject:self.name] objectAtIndex:0];
}

@end
