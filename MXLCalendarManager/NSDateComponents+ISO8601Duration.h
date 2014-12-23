//
//  NSDateComponents+ISO8601Duration.h
//  ISO8601Duration
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Kevin Randrup
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

#import <Foundation/Foundation.h>

/*
 * This category converts ISO 8601 duration strings with the format: P[n]Y[n]M[n]DT[n]H[n]M[n]S or P[n]W into date components.
 * Ex. PT12H = 12 hours
 * Ex. P3D = 3 days
 * Ex. P3DT12H = 3 days, 12 hours
 * Ex. P3Y6M4DT12H30M5S = 3 years, 6 months, 4 days, 12 hours, 30 minutes and 5 seconds
 * Ex. P10W = 70 days
 * For more information look here http://en.wikipedia.org/wiki/ISO_8601#Durations
 * WARNING: The specification allows decimal values which this category does not support. Pull requests are welcome.
 */
@interface NSDateComponents (ISO8601Duration)
+ (NSDateComponents *)durationFrom8601String:(NSString *)durationString;
@end
