//
//  VKURLParser.h
//  SovietPosters
//
//  Created by Evgeny Rusanau on 27.12.10.
//  Copyright 2010 Macsoftex. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface URLParser : NSObject

+(NSString*)constructURL:(NSString*)baseURL params:(NSDictionary*)params;
+(NSMutableDictionary*)parseURL:(NSString*)url;

@end
