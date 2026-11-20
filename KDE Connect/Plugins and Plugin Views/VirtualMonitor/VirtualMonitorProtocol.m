// SPDX-License-Identifier: GPL-3.0-only
#import "VirtualMonitorProtocol.h"
#include <string.h>

static BOOL integerIs(id value, NSInteger expected) {
    return [value isKindOfClass:[NSNumber class]] && strcmp([value objCType], [@(YES) objCType]) != 0 &&
        [value doubleValue] == expected;
}
static BOOL flag(id value) {
    return [value isKindOfClass:[NSNumber class]] && [value doubleValue] == 1;
}
@implementation VirtualMonitorProtocol
@synthesize availability = _availability;
- (BOOL)trusted:(BOOL)paired reachable:(BOOL)reachable version:(NSInteger)version {
    if (!paired || !reachable || version != 8) { _availability = VMAvailabilityUntrusted; _acceptsCapabilities = NO; return NO; }
    return YES;
}
- (NSDictionary *)requestWithPaired:(BOOL)paired reachable:(BOOL)reachable protocolVersion:(NSInteger)version {
    _availability = VMAvailabilityUnknown;
    _acceptsCapabilities = NO;
    if (![self trusted:paired reachable:reachable version:version]) return nil;
    _acceptsCapabilities = YES;
    return @{ @"protocolVersion": @2, @"action": @"requestCapabilities" };
}
- (NSDictionary *)receiveBody:(NSDictionary *)body type:(NSString *)type paired:(BOOL)paired reachable:(BOOL)reachable protocolVersion:(NSInteger)version {
    if (![self trusted:paired reachable:reachable version:version]) return nil;
    if (![type isEqualToString:@"kdeconnect.virtualmonitor"] && ![type isEqualToString:@"kdeconnect.virtualmonitor.request"]) return nil;
    if (![body isKindOfClass:[NSDictionary class]] || !integerIs([body objectForKey:@"protocolVersion"], 2)) { _availability = VMAvailabilityInvalid; return nil; }
    id action = [body objectForKey:@"action"];
    if ([type isEqualToString:@"kdeconnect.virtualmonitor"] && [action isEqual:@"capabilities"]) {
        if (!_acceptsCapabilities) return nil;
        _availability = flag([body objectForKey:@"supports_remote_desktop"]) && flag([body objectForKey:@"supports_virt_mon"]) && integerIs([body objectForKey:@"nativePanelVersion"], 1) ? VMAvailabilityAvailable : VMAvailabilityUnavailable;
    } else if ([type isEqualToString:@"kdeconnect.virtualmonitor.request"] && [action isEqual:@"requestCapabilities"]) {
        // The separate receiver owns the stream. This app must not claim it can decode RDP.
        return @{ @"protocolVersion": @2, @"action": @"capabilities", @"supports_rdp": @(NO),
                  @"supports_virt_mon": @(NO), @"supports_remote_desktop": @(NO),
                  @"sessionModes": @[], @"resolutions": @[] };
    } else if ([action isEqual:@"connect"] || [action isEqual:@"request"]) {
        // Never consume or forward an unsolicited session credential packet.
        _availability = VMAvailabilityInvalid;
    }
    return nil;
}
- (void)expire {
    if (_availability == VMAvailabilityUnknown) { _availability = VMAvailabilityTimedOut; _acceptsCapabilities = NO; }
}
- (BOOL)canOpenWithPaired:(BOOL)paired reachable:(BOOL)reachable protocolVersion:(NSInteger)version {
    return [self trusted:paired reachable:reachable version:version] && _availability == VMAvailabilityAvailable;
}
+ (BOOL)certificate:(NSData *)certificate matchesSaved:(NSData *)saved {
    if (![certificate isKindOfClass:[NSData class]] || certificate.length == 0) return NO;
    return saved == nil || ([saved isKindOfClass:[NSData class]] && [certificate isEqualToData:saved]);
}
@end
