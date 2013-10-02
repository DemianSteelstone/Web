//
//  PostBodyBuilder.m
//  photomovie
//
//  Created by Evgeny Rusanov on 08.09.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import "HttpBodyBuilder.h"

#import "FileSystem.h"

#define READ_CHUNK          1048576

@implementation HttpBodyBuilder
{
    NSString *outputStreamFileName;
    NSOutputStream *outputStream;
    NSData *outputData;
    
    int totalBytes;
    
    BOOL _streamToFile;
}

-(id)initWithFileStream:(BOOL)streamToFile
{
    if (self = [super init])
    {
        _streamToFile = streamToFile;
         if (_streamToFile)
         {
         FileSystem *fs = [FileSystem sharedFileSystem];
         outputStreamFileName = [fs cachesPathForFile:[FileSystem randomFileName:@"tmp"]];
         outputStream = [[NSOutputStream alloc] initToFileAtPath:outputStreamFileName append:NO];
         }
         else
         {
         outputStream = [NSOutputStream outputStreamToMemory];
         }
         [outputStream open];
        totalBytes = 0;
        
        NSData *begin = [self beginContent];
        [self appendBytes:begin.bytes length:begin.length];
    }
    
    return self;
}

-(void)appendBytes:(const void*)bytes length:(int)length
{
    [outputStream write:bytes maxLength:length];
    totalBytes+=length;
}

-(void)appendFile:(NSString*)path fileName:(NSString*)fileName fileKey:(NSString*)fileKey contentType:(NSString*)contentType
{
    NSData *partHeader = [self partHeaderData:fileKey fileName:fileName contentType:contentType];
    NSData *endLine = [self endLine];
    
    [self appendBytes:partHeader.bytes
               length:partHeader.length];
    
    uint8_t *buffer = (uint8_t*)malloc(sizeof(uint8_t)*READ_CHUNK);
    NSInputStream *input = [[NSInputStream alloc] initWithFileAtPath:path];
    [input open];
    while ([input hasBytesAvailable])
    {
        int bytesRead = [input read:buffer maxLength:READ_CHUNK];
        if (!bytesRead) break;
        
        [self appendBytes:buffer length:bytesRead];
    }
    free(buffer);
    
    [self appendBytes:endLine.bytes length:endLine.length];
}

-(void)appendData:(NSData*)data fileName:(NSString*)fileName fileKey:(NSString*)fileKey contentType:(NSString*)contentType
{
    NSData *partHeader = [self partHeaderData:fileKey fileName:fileName contentType:contentType];
    NSData *endLine = [self endLine];
    
    [self appendBytes:partHeader.bytes
               length:partHeader.length];
    
    [self appendBytes:data.bytes length:data.length];
    
    [self appendBytes:endLine.bytes length:endLine.length];
}

-(NSData*)beginContent
{
    return [[NSString stringWithFormat:@"--%@\r\n", kStringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
}

-(NSData*)partHeaderData:(NSString*)fileKey fileName:(NSString*)fileName contentType:(NSString*)contentType
{
    NSString *string = [NSString stringWithFormat:
                        @"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\";\r\n", fileKey, fileName];
    string = [string stringByAppendingFormat:@"Content-Type: %@\r\n\r\n",contentType];
    
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

-(NSData*)endLine
{
    NSString *string = [NSString stringWithFormat:@"\r\n--%@\r\n",kStringBoundary];
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

-(void)finish
{
    if (_streamToFile)
        [[NSFileManager defaultManager] removeItemAtPath:outputStreamFileName error:NULL];
}

-(NSInputStream*)postBodyStream
{
    [outputStream close];
    if (_streamToFile)
        return [NSInputStream inputStreamWithFileAtPath:outputStreamFileName];        
    return [NSInputStream inputStreamWithData:[outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey]];
}

-(int)length
{
    return totalBytes;
}

-(void)dealloc
{
    [self finish];
}


@end

