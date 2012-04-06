//
//  WebService.h
//  iChat
//
//  Created by kartik patel on 08/12/11.
//  Copyright (c) 2011 info@elegantmicroweb.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebService : NSObject <NSXMLParserDelegate> {
    
    NSMutableData											* responseData;
    NSData                                          *respData;
	NSURL											* url;
	NSMutableURLRequest								* urlRequest;
	NSURLConnection									* cnn;
	NSMutableData									* postData;
	NSString											* str;
    NSString											* respStr;
    NSMutableString                             *responseString;
    NSXMLParser                                 *chatParser;
    NSMutableArray *messages;
    BOOL                                        inText;
    BOOL                                        inUser;
}

+ (WebService *) initWS;
- (void) callWebServiceWithPostData:(NSData *)postdata ID:(NSString *)identifier;

@end
