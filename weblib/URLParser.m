//
//  VKURLParser.m
//  SovietPosters
//
//  Created by Evgeny Rusanau on 27.12.10.
//  Copyright 2010 Macsoftex. All rights reserved.
//

#import "URLParser.h"
#import "NSString+PercentEncoding.h"

@implementation URLParser

+ (NSString *)constructURL:(NSString *)baseUrl params:(NSDictionary *)params {
    if (!params) return baseUrl;
    
	NSURL* parsedURL = [NSURL URLWithString:baseUrl];
	NSString * queryPrefix = parsedURL.query ? @"&" : @"?";
	
	NSMutableArray * pairs = [NSMutableArray array];
	for (NSString * key in [params keyEnumerator]) {
		if (([[params valueForKey:key] isKindOfClass:[UIImage class]])
			||([[params valueForKey:key] isKindOfClass:[NSData class]])) 
		{
			continue;
		}
        
        id object = [params valueForKey:key];
        if ([object isKindOfClass:[NSString class]]) {
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, [object percentEncode]]];
        }
        else {
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, [object stringValue]]];
        }
	}
	NSString * query = [pairs componentsJoinedByString:@"&"];
	
	return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
}

+ (NSMutableDictionary *)parseURL:(NSString *)url {
	NSString *queryPrefix = @"?";
	if ([url rangeOfString:queryPrefix].location==NSNotFound)
		queryPrefix = @"#";
	NSArray *queryComponents = [url componentsSeparatedByString:queryPrefix];
	
	if ([queryComponents count]==1)
	{
		return nil;
	}
	NSString *query = [queryComponents objectAtIndex:1];
	
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val =
		[[kv objectAtIndex:1]
		 stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
	return params;
}

@end
