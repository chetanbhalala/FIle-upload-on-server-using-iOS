//
//  WebService.m
//  iChat
//
//  Created by kartik patel on 08/12/11.
//  Copyright (c) 2011 info@elegantmicroweb.com. All rights reserved.
//

#import "WebService.h"

static WebService *sharedWS;

@implementation WebService

+ (WebService *) initWS
{
	@synchronized(self)
	{
		if (!sharedWS)
			sharedWS = [[WebService alloc] init];
	}
	return sharedWS;
}

- (void) callWebServiceWithPostData:(NSData *)postdata ID:(NSString *)identifier
{
    //if ([identifier isEqualToString:@"Send"]) {
        NSString *serviceURL = [NSString stringWithFormat:@"your url String"];
        url = [NSURL URLWithString:serviceURL];
        
        //postString = [NSString stringWithFormat:@"Party=%@",postString];
        //NSLog(@"postString %@",postString);
        //NSArray *arr = [postString componentsSeparatedByString:@":"];
        //postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
        postData = [NSMutableData data];
        [postData appendData:postdata];
        //[postData appendData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
        urlRequest = [[NSMutableURLRequest alloc] init];
        [urlRequest setURL:url];
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setHTTPBody:postData];
        
        NSURLResponse * response;
        NSError * error = nil;
        respData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
        respStr = [[NSString alloc] initWithData:respData encoding:NSUTF8StringEncoding];
        NSLog(@"Data:%@",error);
//        if ([respStr rangeOfString:@"success"].location != NSNotFound) {
//            NSLog(@"Successful");
//        } else {
//            NSLog(@"Wrong url");
//        }
//    } else {
//        ;
//    }
	
	//[self performSelectorOnMainThread:@selector(funcToBePerformedOnMainThread:) withObject:self.functionID waitUntilDone:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response  
{  
    [responseData setLength:0];  
}  

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data  
{  
    [responseData appendData:data];  
}  

- (void)connectionDidFinishLoading:(NSURLConnection *)connection  
{  
    //responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    if (chatParser)
        [chatParser release];
    
    if ( messages == nil )
		messages = [[NSMutableArray alloc] init];
    
    chatParser = [[NSXMLParser alloc] initWithData:responseData];
	[chatParser setDelegate:self];
	[chatParser parse];
    
    [responseData release];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	if ( [elementName isEqualToString:@"message"] ) {
		//msgAdded = [[attributeDict objectForKey:@"added"] retain];
		//msgId = [[attributeDict objectForKey:@"id"] intValue];
		//msgUser = [[NSMutableString alloc] init];
		//msgText = [[NSMutableString alloc] init];
        responseString = [[NSMutableString alloc] init];
		inText = NO;
        inUser = NO;
	}
	if ( [elementName isEqualToString:@"user"] ) {
		inUser = YES;
	}
	if ( [elementName isEqualToString:@"text"] ) {
		inText = YES;
	}
} 

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if ( inUser ) {
		[responseString appendString:[NSString stringWithFormat:@"%@:",string]];
	}
    
	if ( inText ) {
		[responseString appendString:string];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if ( [elementName isEqualToString:@"message"] ) {
        //[messages removeAllObjects];
		//[messages addObject:[NSDictionary dictionaryWithObjectsAndKeys:responseString,@"text",nil]];
		//NSLog(@"messages: %@",messages);
        NSMutableDictionary *msgDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:responseString, @"message", nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DisplayMessage" object:msgDict];
		[responseString release];
	}
	if ( [elementName isEqualToString:@"user"] ) {
		inUser = NO;
	}
	if ( [elementName isEqualToString:@"text"] ) {
		inText = NO;
	}
}

@end
