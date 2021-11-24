//
//  NSString+PercentEncoding.m
//  photomovie
//
//  Created by Evgeny Rusanov on 05.12.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import "NSString+PercentEncoding.h"

@implementation NSString (PercentEncoding)

- (NSString *)percentEncode {
    CFStringRef escaped_value = CFURLCreateStringByAddingPercentEscapes(
                                                                        NULL, /* allocator */
                                                                        (__bridge CFStringRef)self,
                                                                        NULL, /* charactersToLeaveUnescaped */
                                                                        (CFStringRef)@"!*'();:@&=+$,/?%#[]\\",
                                                                        kCFStringEncodingUTF8);
    NSString *returnValue = (__bridge NSString *)escaped_value;
    CFRelease(escaped_value);
    return returnValue;
}

@end
