#import "XPCProtocol.h"
#import "SNTXPCConnection.h"
#import "ReorderWiFiHelperTool.h"

/// Sets up the XPC server and waits for a connection.
int main(int argc, const char * argv[]) {
  SNTXPCConnection *xpcc = [[SNTXPCConnection alloc] initServerWithName:kXPCServerName];
  
  @autoreleasepool {
    xpcc.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCProtocol)];
    NSSet *expectedClasses = [NSSet setWithObjects:[NSArray class], [CWNetworkProfile class], nil];
    [xpcc.exportedInterface setClasses:expectedClasses
                           forSelector:@selector(updateNetworkOrderInSystem:removeFromSystemKeychain:completionBlock:)
                         argumentIndex:0
                               ofReply:NO];

    xpcc.exportedObject = [[ReorderWiFiHelperTool alloc] init];
    xpcc.invalidationHandler = ^{
      NSLog(@"ReorderWiFi Helper Tool connection invalidated!");
    };
    [xpcc resume];
    NSLog(@"Helper tool is up and running.");
  }
  
  [[NSRunLoop currentRunLoop] run];
  return 0;
}
