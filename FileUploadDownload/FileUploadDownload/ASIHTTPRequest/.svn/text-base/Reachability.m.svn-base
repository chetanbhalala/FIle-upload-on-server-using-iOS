/*
 Each reachability object now has a copy of the key used to store it in a dictionary.
 This allows each observer to quickly determine if the event is important to them.
*/

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <CoreFoundation/CoreFoundation.h>

#import "Reachability.h"

NSString *const kInternetConnection  = @"InternetConnection";
NSString *const kLocalWiFiConnection = @"LocalWiFiConnection";
NSString *const kReachabilityChangedNotification = @"NetworkReachabilityChangedNotification";

#define CLASS_DEBUG 1 // Turn on logReachabilityFlags. Must also have a project wide defined DEBUG.

#if (defined DEBUG && defined CLASS_DEBUG)
#define logReachabilityFlags(flags) (logReachabilityFlags_(__PRETTY_FUNCTION__, __LINE__, flags))

static NSString *reachabilityFlags_(SCNetworkReachabilityFlags flags) {
	
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 30000) // Apple advises you to use the magic number instead of a symbol.
    return [NSString stringWithFormat:@"Reachability Flags: %c%c %c%c%c%c%c%c%c",
			(flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
			(flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
			
			(flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
			(flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
			(flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
			(flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
			(flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
			(flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
			(flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'];
#else
	// Compile out the v3.0 features for v2.2.1 deployment.
    return [NSString stringWithFormat:@"Reachability Flags: %c%c %c%c%c%c%c%c",
			(flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
			(flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
			
			(flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
			(flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
			(flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
			// v3 kSCNetworkReachabilityFlagsConnectionOnTraffic == v2 kSCNetworkReachabilityFlagsConnectionAutomatic
			(flags & kSCNetworkReachabilityFlagsConnectionAutomatic)  ? 'C' : '-',
			// (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-', // No v2 equivalent.
			(flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
			(flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'];
#endif
	
} // reachabilityFlags_()

static void logReachabilityFlags_(const char *name, int line, SCNetworkReachabilityFlags flags) {
	
    NSLog(@"%s (%d) \n\t%@", name, line, reachabilityFlags_(flags));
	
} // logReachabilityFlags_()

#define logNetworkStatus(status) (logNetworkStatus_(__PRETTY_FUNCTION__, __LINE__, status))

static void logNetworkStatus_(const char *name, int line, NetworkStatus status) {
	
	NSString *statusString = nil;
	
	switch (status) {
		case kNotReachable:
			statusString = [NSString stringWithString: @"Not Reachable"];
			break;
		case kReachableViaWWAN:
			statusString = [NSString stringWithString: @"Reachable via WWAN"];
			break;
		case kReachableViaWiFi:
			statusString = [NSString stringWithString: @"Reachable via WiFi"];
			break;
	}
	
	NSLog(@"%s (%d) \n\tNetwork Status: %@", name, line, statusString);
	
} // logNetworkStatus_()

#else
#define logReachabilityFlags(flags)
#define logNetworkStatus(status)
#endif

@interface Reachability (private)

- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags;

@end

@implementation Reachability

@synthesize key = key_;

// Preclude direct access to ivars.
+ (BOOL) accessInstanceVariablesDirectly {
	
	return NO;

} // accessInstanceVariablesDirectly


- (void) dealloc {
	
	[self stopNotifier];
	if(reachabilityRef) {
		
		CFRelease(reachabilityRef); reachabilityRef = NULL;
		
	}
	
	self.key = nil;
	
	[super dealloc];
	
} // dealloc


- (Reachability *) initWithReachabilityRef: (SCNetworkReachabilityRef) ref {
	
	if (self = [super init]) {
		
		reachabilityRef = ref;
		
	}
	
	return self;
	
} // initWithReachabilityRef:


#if (defined DEBUG && defined CLASS_DEBUG)
- (NSString *) description {
	
	NSAssert(reachabilityRef, @"-description called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags = 0;
	
	SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
	
	return [NSString stringWithFormat: @"%@\n\t%@", self.key, reachabilityFlags_(flags)];
	
} // description
#endif


#pragma mark -
#pragma mark Notification Management Methods


//Start listening for reachability notifications on the current run loop
static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {

	#pragma unused (target, flags)
	NSCAssert(info, @"info was NULL in ReachabilityCallback");
	NSCAssert([(NSObject*) info isKindOfClass: [Reachability class]], @"info was the wrong class in ReachabilityCallback");
	
	//We're on the main RunLoop, so an NSAutoreleasePool is not necessary, but is added defensively
	// in case someone uses the Reachablity object in a different thread.
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	// Post a notification to notify the client that the network reachability changed.
	[[NSNotificationCenter defaultCenter] postNotificationName: kReachabilityChangedNotification 
														object: (Reachability *) info];
	
	[pool release];

} // ReachabilityCallback()


- (BOOL) startNotifier {
	
	SCNetworkReachabilityContext	context = {0, self, NULL, NULL, NULL};
	
	if(SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context)) {
		
		if(SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {

			return YES;
			
		}
		
	}
	
	return NO;

} // startNotifier


- (void) stopNotifier {
	
	if(reachabilityRef) {
		
		SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	}

} // stopNotifier


- (BOOL) isEqual: (Reachability *) r {
	
	return [r.key isEqualToString: self.key];
	
} // isEqual:


#pragma mark -
#pragma mark Reachability Allocation Methods


+ (Reachability *) reachabilityWithHostName: (NSString *) hostName {
	
	SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
	
	if (ref) {
		
		Reachability *r = [[[self alloc] initWithReachabilityRef: ref] autorelease];
		
		r.key = hostName;

		return r;
		
	}
	
	return nil;
	
} // reachabilityWithHostName


+ (NSString *) makeAddressKey: (in_addr_t) addr {
	// addr is assumed to be in network byte order.
	
	static const int       highShift    = 24;
	static const int       highMidShift = 16;
	static const int       lowMidShift  =  8;
	static const in_addr_t mask         = 0x000000ff;
	
	addr = ntohl(addr);
	
	return [NSString stringWithFormat: @"%d.%d.%d.%d", 
			(addr >> highShift)    & mask, 
			(addr >> highMidShift) & mask, 
			(addr >> lowMidShift)  & mask, 
			 addr                  & mask];
	
} // makeAddressKey:


+ (Reachability *) reachabilityWithAddress: (const struct sockaddr_in *) hostAddress {
	
	SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)hostAddress);

	if (ref) {
		
		Reachability *r = [[[self alloc] initWithReachabilityRef: ref] autorelease];
		
		r.key = [self makeAddressKey: hostAddress->sin_addr.s_addr];
		
		return r;
		
	}
	
	return nil;

} // reachabilityWithAddress


+ (Reachability *) reachabilityForInternetConnection {
	
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;

	Reachability *r = [self reachabilityWithAddress: &zeroAddress];

	r.key = kInternetConnection;
	
	return r;

} // reachabilityForInternetConnection


+ (Reachability *) reachabilityForLocalWiFi {
	
	struct sockaddr_in localWifiAddress;
	bzero(&localWifiAddress, sizeof(localWifiAddress));
	localWifiAddress.sin_len = sizeof(localWifiAddress);
	localWifiAddress.sin_family = AF_INET;
	// IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
	localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);

	Reachability *r = [self reachabilityWithAddress: &localWifiAddress];

	r.key = kLocalWiFiConnection;

	return r;

} // reachabilityForLocalWiFi


#pragma mark -
#pragma mark Network Flag Handling Methods


#if USE_DDG_EXTENSIONS
//
// iPhone condition codes as reported by a 3GS running iPhone OS v3.0.
// Airplane Mode turned on:  Reachability Flag Status: -- -------
// WWAN Active:              Reachability Flag Status: WR -t-----
// WWAN Connection required: Reachability Flag Status: WR ct-----
//         WiFi turned on:   Reachability Flag Status: -R ------- Reachable.
// Local   WiFi turned on:   Reachability Flag Status: -R xxxxxxd Reachable.
//         WiFi turned on:   Reachability Flag Status: -R ct----- Connection down. (Non-intuitive, empirically determined answer.)
const SCNetworkReachabilityFlags kConnectionDown =  kSCNetworkReachabilityFlagsConnectionRequired | 
												    kSCNetworkReachabilityFlagsTransientConnection;
//         WiFi turned on:   Reachability Flag Status: -R ct-i--- Reachable but it will require user intervention (e.g. enter a WiFi password).
//         WiFi turned on:   Reachability Flag Status: -R -t----- Reachable via VPN.
//
// In the below method, an 'x' in the flag status means I don't care about its value.
//
// This method differs from Apple's by testing explicitly for empirically observed values.
// This gives me more confidence in it's correct behavior. Apple's code covers more cases 
// than mine. My code covers the cases that occur.
//
- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags {
	
	if (flags & kSCNetworkReachabilityFlagsReachable) {
		
		// Local WiFi -- Test derived from Apple's code: -localWiFiStatusForFlags:.
		if (self.key == kLocalWiFiConnection) {

			// Reachability Flag Status: xR xxxxxxd Reachable.
			return (flags & kSCNetworkReachabilityFlagsIsDirect) ? kReachableViaWiFi : kNotReachable;

		}
		
		// Observed WWAN Values:
		// WWAN Active:              Reachability Flag Status: WR -t-----
		// WWAN Connection required: Reachability Flag Status: WR ct-----
		//
		// Test Value: Reachability Flag Status: WR xxxxxxx
		if (flags & kSCNetworkReachabilityFlagsIsWWAN) { return kReachableViaWWAN; }
		
		// Clear moot bits.
		flags &= ~kSCNetworkReachabilityFlagsReachable;
		flags &= ~kSCNetworkReachabilityFlagsIsDirect;
		flags &= ~kSCNetworkReachabilityFlagsIsLocalAddress; // kInternetConnection is local.
		
		// Reachability Flag Status: -R ct---xx Connection down.
		if (flags == kConnectionDown) { return kNotReachable; }
		
		// Reachability Flag Status: -R -t---xx Reachable. WiFi + VPN(is up) (Thank you Ling Wang)
		if (flags & kSCNetworkReachabilityFlagsTransientConnection)  { return kReachableViaWiFi; }
			
		// Reachability Flag Status: -R -----xx Reachable.
		if (flags == 0) { return kReachableViaWiFi; }
		
		// Apple's code tests for dynamic connection types here. I don't. 
		// If a connection is required, regardless of whether it is on demand or not, it is a WiFi connection.
		// If you care whether a connection needs to be brought up,   use -isConnectionRequired.
		// If you care about whether user intervention is necessary,  use -isInterventionRequired.
		// If you care about dynamically establishing the connection, use -isConnectionIsOnDemand.

		// Reachability Flag Status: -R cxxxxxx Reachable.
		if (flags & kSCNetworkReachabilityFlagsConnectionRequired) { return kReachableViaWiFi; }
		
		// Required by the compiler. Should never get here. Default to not connected.
#if (defined DEBUG && defined CLASS_DEBUG)
		NSAssert1(NO, @"Uncaught reachability test. Flags: %@", reachabilityFlags_(flags));
#endif
		return kNotReachable;

		}
	
	// Reachability Flag Status: x- xxxxxxx
	return kNotReachable;
	
} // networkStatusForFlags:


- (NetworkStatus) currentReachabilityStatus {
	
	NSAssert(reachabilityRef, @"currentReachabilityStatus called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags = 0;
	NetworkStatus status = kNotReachable;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
//		logReachabilityFlags(flags);
		
		status = [self networkStatusForFlags: flags];
		
		return status;
		
	}
	
	return kNotReachable;
	
} // currentReachabilityStatus


- (BOOL) isReachable {
	
	NSAssert(reachabilityRef, @"isReachable called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags = 0;
	NetworkStatus status = kNotReachable;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
//		logReachabilityFlags(flags);

		status = [self networkStatusForFlags: flags];

//		logNetworkStatus(status);
		
		return (kNotReachable != status);
		
	}
	
	return NO;
	
} // isReachable


- (BOOL) isConnectionRequired {
	
	NSAssert(reachabilityRef, @"isConnectionRequired called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		logReachabilityFlags(flags);
		
		return (flags & kSCNetworkReachabilityFlagsConnectionRequired);

	}
	
	return NO;
	
} // isConnectionRequired


- (BOOL) connectionRequired {
	
	return [self isConnectionRequired];
	
} // connectionRequired
#endif


#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 30000)
static const SCNetworkReachabilityFlags kOnDemandConnection = kSCNetworkReachabilityFlagsConnectionOnTraffic | 
                                                              kSCNetworkReachabilityFlagsConnectionOnDemand;
#else
static const SCNetworkReachabilityFlags kOnDemandConnection = kSCNetworkReachabilityFlagsConnectionAutomatic;
#endif

- (BOOL) isConnectionOnDemand {
	
	NSAssert(reachabilityRef, @"isConnectionIsOnDemand called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		logReachabilityFlags(flags);
		
		return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
				(flags & kOnDemandConnection));
		
	}
	
	return NO;
	
} // isConnectionOnDemand


- (BOOL) isInterventionRequired {
	
	NSAssert(reachabilityRef, @"isInterventionRequired called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		logReachabilityFlags(flags);
		
		return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
				(flags & kSCNetworkReachabilityFlagsInterventionRequired));
		
	}
	
	return NO;
	
} // isInterventionRequired


- (BOOL) isReachableViaWWAN {
	
	NSAssert(reachabilityRef, @"isReachableViaWWAN called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags = 0;
	NetworkStatus status = kNotReachable;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		logReachabilityFlags(flags);
		
		status = [self networkStatusForFlags: flags];
		
		return  (kReachableViaWWAN == status);
			
	}
	
	return NO;
	
} // isReachableViaWWAN


- (BOOL) isReachableViaWiFi {
	
	NSAssert(reachabilityRef, @"isReachableViaWiFi called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags = 0;
	NetworkStatus status = kNotReachable;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		logReachabilityFlags(flags);
		
		status = [self networkStatusForFlags: flags];
		
		return  (kReachableViaWiFi == status);
		
	}
	
	return NO;
	
} // isReachableViaWiFi


- (SCNetworkReachabilityFlags) reachabilityFlags {
	
	NSAssert(reachabilityRef, @"reachabilityFlags called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags = 0;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		logReachabilityFlags(flags);
		
		return flags;
		
	}
	
	return 0;
	
} // reachabilityFlags


#pragma mark -
#pragma mark Apple's Network Flag Handling Methods


#if !USE_DDG_EXTENSIONS
/*
 *
 *  Apple's Network Status testing code.
 *  The only changes that have been made are to use the new logReachabilityFlags macro and
 *  test for local WiFi via the key instead of Apple's boolean. Also, Apple's code was for v3.0 only
 *  iPhone OS. v2.2.1 and earlier conditional compiling is turned on. Hence, to mirror Apple's behavior,
 *  set your Base SDK to v3.0 or higher.
 *
 */

- (NetworkStatus) localWiFiStatusForFlags: (SCNetworkReachabilityFlags) flags
{
	logReachabilityFlags(flags);
	
	BOOL retVal = NotReachable;
	if((flags & kSCNetworkReachabilityFlagsReachable) && (flags & kSCNetworkReachabilityFlagsIsDirect))
	{
		retVal = ReachableViaWiFi;	
	}
	return retVal;
}


- (NetworkStatus) networkStatusForFlags: (SCNetworkReachabilityFlags) flags
{
	logReachabilityFlags(flags);
	if (!(flags & kSCNetworkReachabilityFlagsReachable))
	{
		// if target host is not reachable
		return NotReachable;
	}
	
	BOOL retVal = NotReachable;
	
	if (!(flags & kSCNetworkReachabilityFlagsConnectionRequired))
	{
		// if target host is reachable and no connection is required
		//  then we'll assume (for now) that your on Wi-Fi
		retVal = ReachableViaWiFi;
	}
	
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 30000) // Apple advises you to use the magic number instead of a symbol.	
	if ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) ||
		(flags & kSCNetworkReachabilityFlagsConnectionOnTraffic))
#else
	if (flags & kSCNetworkReachabilityFlagsConnectionAutomatic)
#endif
		{
			// ... and the connection is on-demand (or on-traffic) if the
			//     calling application is using the CFSocketStream or higher APIs
			
			if (!(flags & kSCNetworkReachabilityFlagsInterventionRequired))
			{
				// ... and no [user] intervention is needed
				retVal = ReachableViaWiFi;
			}
		}
	
	if (flags & kSCNetworkReachabilityFlagsIsWWAN)
	{
		// ... but WWAN connections are OK if the calling application
		//     is using the CFNetwork (CFSocketStream?) APIs.
		retVal = ReachableViaWWAN;
	}
	return retVal;
}


- (NetworkStatus) currentReachabilityStatus
{
	NSAssert(reachabilityRef, @"currentReachabilityStatus called with NULL reachabilityRef");
	
	NetworkStatus retVal = NotReachable;
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
	{
		if(self.key == kLocalWiFiConnection)
		{
			retVal = [self localWiFiStatusForFlags: flags];
		}
		else
		{
			retVal = [self networkStatusForFlags: flags];
		}
	}
	return retVal;
}


- (BOOL) isReachable {
	
	NSAssert(reachabilityRef, @"isReachable called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags = 0;
	NetworkStatus status = kNotReachable;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		logReachabilityFlags(flags);
		
		if(self.key == kLocalWiFiConnection) {
			
			status = [self localWiFiStatusForFlags: flags];
			
		} else {
			
			status = [self networkStatusForFlags: flags];
			
		}
		
		return (kNotReachable != status);
		
	}
	
	return NO;
	
} // isReachable


- (BOOL) isConnectionRequired {
	
	return [self connectionRequired];
	
} // isConnectionRequired


- (BOOL) connectionRequired {
	
	NSAssert(reachabilityRef, @"connectionRequired called with NULL reachabilityRef");
	
	SCNetworkReachabilityFlags flags;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
		
		logReachabilityFlags(flags);
		
		return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
		
	}
	
	return NO;
	
} // connectionRequired
#endif

@end
