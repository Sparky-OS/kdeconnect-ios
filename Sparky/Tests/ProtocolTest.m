// SPDX-License-Identifier: GPL-3.0-only
#import "VirtualMonitorProtocol.h"
#include <assert.h>
#include <stdio.h>
int main(void) { @autoreleasepool {
    VirtualMonitorProtocol *state = [VirtualMonitorProtocol new];
    NSDictionary *caps = @{ @"protocolVersion": @2, @"action": @"capabilities", @"supports_remote_desktop": @(YES), @"supports_virt_mon": @(YES), @"nativePanelVersion": @1 };
    for (int paired = 0; paired <= 1; ++paired) for (int reachable = 0; reachable <= 1; ++reachable) for (int version = 7; version <= 9; ++version) {
        BOOL trusted = paired && reachable && version == 8;
        assert(([state requestWithPaired:paired reachable:reachable protocolVersion:version] != nil) == trusted);
        [state receiveBody:caps type:@"kdeconnect.virtualmonitor" paired:paired reachable:reachable protocolVersion:version];
        assert([state canOpenWithPaired:paired reachable:reachable protocolVersion:version] == trusted);
    }
    [state requestWithPaired:YES reachable:YES protocolVersion:8];
    [state receiveBody:caps type:@"kdeconnect.virtualmonitor" paired:YES reachable:YES protocolVersion:8];
    assert([state canOpenWithPaired:YES reachable:YES protocolVersion:8]);
    assert(![state canOpenWithPaired:NO reachable:YES protocolVersion:8]);
    assert(![state canOpenWithPaired:YES reachable:YES protocolVersion:8]); // No stale trust after revoke.
    for (NSString *field in @[@"supports_remote_desktop", @"supports_virt_mon", @"nativePanelVersion"]) {
        [state requestWithPaired:YES reachable:YES protocolVersion:8];
        NSMutableDictionary *bad = [caps mutableCopy]; [bad removeObjectForKey:field];
        [state receiveBody:bad type:@"kdeconnect.virtualmonitor" paired:YES reachable:YES protocolVersion:8];
        assert(![state canOpenWithPaired:YES reachable:YES protocolVersion:8]);
    }
    [state requestWithPaired:YES reachable:YES protocolVersion:8];
    NSMutableDictionary *boolVersion = [caps mutableCopy];
    [boolVersion setObject:@(YES) forKey:@"nativePanelVersion"];
    [state receiveBody:boolVersion type:@"kdeconnect.virtualmonitor" paired:YES reachable:YES protocolVersion:8];
    assert(state.availability == VMAvailabilityUnavailable);
    for (id value in @[@"2", @3, @2.5, [NSNull null]]) {
        NSMutableDictionary *bad = [caps mutableCopy]; [bad setObject:value forKey:@"protocolVersion"];
        [state receiveBody:bad type:@"kdeconnect.virtualmonitor" paired:YES reachable:YES protocolVersion:8];
        assert(state.availability == VMAvailabilityInvalid);
    }
    NSDictionary *reply = [state receiveBody:@{@"protocolVersion":@2,@"action":@"requestCapabilities"} type:@"kdeconnect.virtualmonitor.request" paired:YES reachable:YES protocolVersion:8];
    assert(reply && ![[reply objectForKey:@"supports_rdp"] boolValue]);
    assert([reply objectForKey:@"password"] == nil && [reply objectForKey:@"certificateFingerprint"] == nil);
    [state receiveBody:@{@"protocolVersion":@2,@"action":@"connect",@"password":@"test-only"} type:@"kdeconnect.virtualmonitor.request" paired:YES reachable:YES protocolVersion:8];
    assert(![state canOpenWithPaired:YES reachable:YES protocolVersion:8]);
    [state requestWithPaired:YES reachable:YES protocolVersion:8];
    [state expire];
    assert(state.availability == VMAvailabilityTimedOut);
    [state receiveBody:caps type:@"kdeconnect.virtualmonitor" paired:YES reachable:YES protocolVersion:8];
    assert(![state canOpenWithPaired:YES reachable:YES protocolVersion:8]);
    [state requestWithPaired:YES reachable:YES protocolVersion:8];
    [state receiveBody:caps type:@"kdeconnect.virtualmonitor" paired:YES reachable:YES protocolVersion:8];
    assert([state canOpenWithPaired:YES reachable:YES protocolVersion:8]);
    NSData *first = [@"certificate A" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *changed = [@"certificate B" dataUsingEncoding:NSUTF8StringEncoding];
    assert([VirtualMonitorProtocol certificate:first matchesSaved:nil]);
    assert([VirtualMonitorProtocol certificate:first matchesSaved:first]);
    assert(![VirtualMonitorProtocol certificate:changed matchesSaved:first]);
    assert(![VirtualMonitorProtocol certificate:nil matchesSaved:first]);
    assert(![VirtualMonitorProtocol certificate:[NSData data] matchesSaved:nil]);
    puts("PASS: paired/reachable/version gates, capability schema, refusal/revocation, no credential forwarding, first-use/exact/changed/absent certificate policy");
} return 0; }
