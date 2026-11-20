// SPDX-License-Identifier: GPL-3.0-only
#import <Foundation/Foundation.h>

#ifndef NS_SWIFT_NAME
#define NS_SWIFT_NAME(name) __attribute__((swift_name(#name)))
#endif

typedef NS_ENUM(NSInteger, VMAvailability) { VMAvailabilityUnknown, VMAvailabilityAvailable, VMAvailabilityUnavailable, VMAvailabilityUntrusted, VMAvailabilityInvalid, VMAvailabilityTimedOut };
@interface VirtualMonitorProtocol : NSObject {
    VMAvailability _availability;
    BOOL _acceptsCapabilities;
}
@property(nonatomic, readonly) VMAvailability availability;
- (void)expire;
- (NSDictionary *)requestWithPaired:(BOOL)paired reachable:(BOOL)reachable protocolVersion:(NSInteger)version NS_SWIFT_NAME(request(paired:reachable:protocolVersion:));
- (NSDictionary *)receiveBody:(NSDictionary *)body type:(NSString *)type paired:(BOOL)paired reachable:(BOOL)reachable protocolVersion:(NSInteger)version NS_SWIFT_NAME(receive(body:type:paired:reachable:protocolVersion:));
- (BOOL)canOpenWithPaired:(BOOL)paired reachable:(BOOL)reachable protocolVersion:(NSInteger)version NS_SWIFT_NAME(canOpen(paired:reachable:protocolVersion:));
+ (BOOL)certificate:(NSData *)certificate matchesSaved:(NSData *)saved NS_SWIFT_NAME(certificate(_:matchesSaved:));
@end
