//
//  HTTPrequest.m
//  FreeBarcodeScanner
//
//  Created by Evgeny Rusanov on 11/24/09.
//  Copyright 2009 Macsoftex. All rights reserved.
//

#import "HTTPrequest.h"

#import "FileSystem.h"

#define TIMER_TIMEOUT 90

@interface HTTPrequest(Private)
-(void)releaseAllItems;
@end

@implementation HTTPrequest
{
    NSString *dataFilePath;
    
    NSOutputStream *outStream;
    
    NSMutableData *receivedData;
    NSURLConnection *theConnection;
    
    NSTimer *timeOutTimer;
    
    NSString *_rString;
    
    id context;
}

-(id)init
{
    if (self = [super init])
    {
        _downloadToFile = NO;
    }
    return self;
}

-(void)stopTimeOut
{
	if (timeOutTimer && [timeOutTimer isValid])
	{
		[timeOutTimer invalidate];
	}
    
    timeOutTimer=nil;
}

-(void)restartTimeOut
{    
	[self stopTimeOut];
	timeOutTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_TIMEOUT 
													target:self 
												  selector:@selector(timeOut:)
												  userInfo:nil 
												   repeats:NO];
}

-(void)prepareRequest:(NSString*)requestString
{
	_rString = requestString;
}

-(void)send
{
	if (_rString)
	{
		[self sendRequest:_rString];
		_rString = nil;
	}
}

-(void)checkDownloadedBytes:(NSMutableURLRequest*)request
{
    unsigned long long downloadedBytes = 0;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:dataFilePath])
    {
        NSError *error = nil;
        NSDictionary *fileDictionary = [fm attributesOfItemAtPath:dataFilePath
                                                            error:&error];
        if (!error && fileDictionary)
            downloadedBytes = [fileDictionary fileSize];
        
        if (downloadedBytes > 0)
        {
            [request setHTTPMethod:@"GET"];
            NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
            [request setValue:requestRange forHTTPHeaderField:@"Range"];
            
            _downloadedBytes = downloadedBytes;
            _partialDownloadedSize = _downloadedBytes;
        }
    }
}

-(NSString*)checkUrlAlreadyEncoded:(NSString*)string
{
    NSString *test = [string stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if ([test isEqualToString:string])
        return [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return string;
}

-(void)sendRequest:(NSString*)requestString
{    
    _downloadedBytes = 0;
	    
    requestString = [self checkUrlAlreadyEncoded:requestString];
    
	NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    [theRequest setValue:@"" forHTTPHeaderField:@"Accept-Encoding"];
    receivedData=nil;
    
    if (!_downloadToFile)
    {
        receivedData=[[NSMutableData alloc] init];
    }
    else
    {
        NSString *fileName = _tmpFileName;
        if (!fileName)
        {
            fileName = [NSString stringWithFormat:@"%ld_%d.tmp",time(NULL),rand()];
            dataFilePath = [[FileSystem sharedFileSystem] cachesPathForFile:fileName];
        }
        else
            dataFilePath = fileName;
        
        [self checkDownloadedBytes:theRequest];
    }
    
	theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	if (theConnection) 
	{
		[self restartTimeOut];
        
        context = self;
	} 
	else 
	{
		if ([self.delegate respondsToSelector:@selector(httpRequest:error:)])
			[self.delegate httpRequest:self error:nil];
	}
}

-(void)cancel
{
    [theConnection cancel];
    [self releaseAllItems];
}

-(void)timeOut:(NSTimer*)timer
{
	if ([self.delegate respondsToSelector:@selector(httpRequest:error:)])
        [self.delegate httpRequest:self error:nil];

    [self releaseAllItems];
}

- (BOOL)connection:(NSURLConnection *)connection
canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *) space 
{
	if([[space authenticationMethod] 
		isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
		return YES;
	}
	return NO;
}

-(void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([challenge previousFailureCount] == 0)
	{
		NSURLCredential *newCredential;
        newCredential=[NSURLCredential credentialForTrust:[[challenge protectionSpace] serverTrust]];
        [[challenge sender] useCredential:newCredential
               forAuthenticationChallenge:challenge];
	}
	else
	{
		[[challenge sender] cancelAuthenticationChallenge:challenge];
	}
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if ([response respondsToSelector:@selector(statusCode)])
	{
		NSInteger statusCode = [((NSHTTPURLResponse *)response) statusCode];
		if (statusCode >= 400)
		{
			[connection cancel]; 
			NSDictionary *errorInfo
			= [NSDictionary dictionaryWithObject:[NSString stringWithFormat:
												  NSLocalizedString(@"Server returned status code %d",@""),
												  statusCode]
										  forKey:NSLocalizedDescriptionKey];
			NSError *statusError
			= [NSError errorWithDomain:NSOSStatusErrorDomain
								  code:statusCode
							  userInfo:errorInfo];
			[self connection:connection didFailWithError:statusError];
            
			return;
		}
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        BOOL partialContent = NO;
        if (statusCode == 206)
        {
            NSString *range = [httpResponse.allHeaderFields valueForKey:@"Content-Range"];
            
            NSError *error = nil;
            NSRegularExpression *regex = nil;
            
            // Check to see if the server returned a valid byte-range
            regex = [NSRegularExpression regularExpressionWithPattern:@"bytes (\\d+)-\\d+/(\\d+)"
                                                              options:NSRegularExpressionCaseInsensitive
                                                                error:&error];
            
            if (!error)
            {
                // If the regex didn't match the number of bytes, start the download from the beginning
                NSTextCheckingResult *match = [regex firstMatchInString:range
                                                                options:NSMatchingAnchored
                                                                  range:NSMakeRange(0, range.length)];
                if (match.numberOfRanges >= 3)
                {
                    
                    
                    // Extract the byte offset the server reported to us, and truncate our
                    // file if it is starting us at "0". Otherwise, seek our file to the
                    // appropriate offset.
                    NSString *byteStr = [range substringWithRange:[match rangeAtIndex:1]];
                    NSInteger bytes = [byteStr integerValue];
                    if (bytes > 0)
                        partialContent = YES;
                    byteStr = [range substringWithRange:[match rangeAtIndex:2]];
                    _expectedContentLength = [byteStr integerValue];
                }
            }
        }
        else
        {
            _expectedContentLength = [response expectedContentLength];
            if (_expectedContentLength==NSURLResponseUnknownLength)
                _expectedContentLength = 0;
        }

        if (!partialContent)
        {
            [[NSFileManager defaultManager] removeItemAtPath:dataFilePath error:NULL];
            _downloadedBytes = 0;
            _partialDownloadedSize = 0;
        }
	}
	
    [receivedData setLength:0];
	[self restartTimeOut];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	BOOL stopped = NO;
	if (theConnection==nil)
		stopped = YES;
	
	if (!stopped)
	{
		// append the new data to the receivedData
		// receivedData is declared as a method instance elsewhere
        if (!_downloadToFile)
        {
            [receivedData appendData:data];  
        }
        else
        {
            if (!outStream)
            {
                outStream = [[NSOutputStream alloc] initToFileAtPath:dataFilePath append:YES];
                [outStream open];
            }
            NSInteger numberOfBytes = [outStream write:[data bytes] maxLength:[data length]];
            if (numberOfBytes<0)
            {
                if ([self.delegate respondsToSelector:@selector(httpRequest:error:)])
                    [self.delegate httpRequest:self error:outStream.streamError];
                [self cancel];
                return;
            }
        }
        
        _downloadedBytes+=[data length];
        
        if ([self.delegate respondsToSelector:@selector(httpRequest:dataPortionAdded:)])
            [self.delegate httpRequest:self dataPortionAdded:receivedData];
		
		[self restartTimeOut];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	BOOL stopped = NO;
	if (theConnection==nil)
		stopped = YES;
    
    [self releaseAllItems];
	
	if (!stopped && [self.delegate respondsToSelector:@selector(httpRequest:error:)])
        [self.delegate httpRequest:self error:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	BOOL stopped = NO;
	if (theConnection==nil)
		stopped = YES;
	
	if (!stopped)
	{
		if ([self.delegate respondsToSelector:@selector(httpRequest:dataPortionAdded:)])
			[self.delegate httpRequest:self dataPortionAdded:receivedData];
        
        if (!_downloadToFile)
        {
            if (outStream)
            {
                [outStream close];
                outStream = nil;
            }
            
            NSString *str = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding] ;
            if (str && [str rangeOfString:@"This Account Has Been Suspended"].location!=NSNotFound)
            {
                if ([self.delegate respondsToSelector:@selector(httpRequest:error:)])
                    [self.delegate httpRequest:self error:nil];
            }
            else
            {
                if ([self.delegate respondsToSelector:@selector(httpRequest:dataLoaded:)])
                    [self.delegate httpRequest:self dataLoaded:receivedData];
                
            }	
        }
        else
        {
            if ([self.delegate respondsToSelector:@selector(httpRequest:dataFileLoaded:)])
            {
                [self.delegate httpRequest:self dataFileLoaded:dataFilePath];
            }
        }
	}
    
    [self releaseAllItems];
}

-(void)releaseAllItems
{
    [self stopTimeOut];
    
    theConnection=nil;
    receivedData=nil;
    dataFilePath = nil;
    
    [outStream close],outStream=nil;
    
    context = nil;
}

-(BOOL)stoped
{
	if (theConnection == nil) return YES;

	return NO;
}

-(void)dealloc
{
    self.tmpFileName = nil;
    [self cancel];
}


@end
