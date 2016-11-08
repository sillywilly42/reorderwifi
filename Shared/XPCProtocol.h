@import CoreWLAN;

/// The MachServices name by which the client identifies the server.
static NSString *const kXPCServerName = @"ReorderWiFiDaemon";

/// Defines the methods provided by the XPC daemon.
@protocol XPCProtocol<NSObject>
- (void)updateNetworkOrderInSystem:(NSArray *)networks
          removeFromSystemKeychain:(NSString *)ssid
                   completionBlock:(void (^)(BOOL success))block;
@end
