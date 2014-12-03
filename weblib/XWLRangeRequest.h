//
//  XWLRangeRequest.h
//  DownloaderPlus
//
//  Created by Evgeny Rusanov on 03.12.14.
//  Copyright (c) 2014 Macsoftex. All rights reserved.
//

#import "MDPFileCategory.h"

@interface XWLRangeRequest : MDPFileCategory

-(instancetype)initWithURL:(NSURL*)url;

@property (nonatomic,strong,readonly) NSURLResponse *resultResponse;
@property (nonatomic,strong,readonly) NSError *resultError;

@property (nonatomic,copy) void (^requestPresetBlock)(NSMutableURLRequest *request);

-(NSData*)sendRequestRange:(NSRange)range;

@end
