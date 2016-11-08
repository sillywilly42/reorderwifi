@import CoreWLAN;

#import "SNTXPCConnection.h"
#import "XPCProtocol.h"
#import "AppDelegate.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *tableView;
@property NSArray *persistentNetworks;
@property NSMutableArray *networks;
@property SNTXPCConnection *xpcc;
@end

@implementation AppDelegate

- (IBAction)removeNetwork:(NSButton *)sender {
  if (self.tableView.selectedRow >= 0) {
    CWNetworkProfile *profile = self.networks[self.tableView.selectedRow];
    if (![self.persistentNetworks containsObject:profile.ssid]) {
      NSMutableArray *tempArray = [self.networks mutableCopy];
      [tempArray removeObjectAtIndex:self.tableView.selectedRow];
      [[self.xpcc remoteObjectProxy] updateNetworkOrderInSystem:tempArray
                                       removeFromSystemKeychain:profile.ssid
                                                completionBlock:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (success) {
            NSLog(@"Network removed successfully.");
            self.networks = tempArray;
            [self.tableView reloadData];
          } else {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Error: Could not remove network.";
            alert.informativeText = @"Reopen this applicationt to try again or contact Support.";
            [alert runModal];
            [NSApp terminate:self];
          }
        });
      }];
    }
  }
}

#pragma mark App Delegate Methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  self.xpcc = [[SNTXPCConnection alloc] initClientWithName:kXPCServerName privileged:YES];
  self.xpcc.remoteInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCProtocol)];
  __unsafe_unretained typeof(self) weakSelf = self;
  self.xpcc.invalidationHandler = ^{
    NSLog(@"Connection Invalidated.");
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Error: Helper tool crashed.";
    alert.informativeText = @"Reopen this applicationt to try again or contact Support.";
    [alert performSelectorOnMainThread:@selector(runModal) withObject:NULL waitUntilDone:YES];
    [NSApp terminate:weakSelf];
  };
  [self.xpcc resume];

  self.persistentNetworks = [[NSProcessInfo processInfo] arguments];
  
  CWInterface *interface = [[CWWiFiClient sharedWiFiClient] interface];
  CWMutableConfiguration *config =
      [CWMutableConfiguration configurationWithConfiguration:interface.configuration];
  
  self.networks = [[config.networkProfiles array] mutableCopy];
  
  [self.tableView setDraggingSourceOperationMask:NSDragOperationLink forLocal:NO];
  [self.tableView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
  [self.tableView registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
  
  [self.tableView reloadData];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
  return YES;
}

#pragma mark Delegate & DataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [self.networks count];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex {
  return ((CWNetworkProfile *)self.networks[rowIndex]).ssid;
}

#pragma mark Drag & Drop Delegates

- (BOOL)tableView:(NSTableView *)aTableView
writeRowsWithIndexes:(NSIndexSet *)rowIndexes
     toPasteboard:(NSPasteboard*)pboard {
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
  [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
  [pboard setData:data forType:NSStringPboardType];
  return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv
                validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)op {
  return NSDragOperationEvery;
}


- (BOOL)tableView:(NSTableView*)tv
       acceptDrop:(id <NSDraggingInfo>)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)op {
  NSData *data = [[info draggingPasteboard] dataForType:NSStringPboardType];
  NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  
  NSMutableArray *tempArray = [self.networks mutableCopy];
  NSArray *tArr = [tempArray objectsAtIndexes:rowIndexes];
  [tempArray removeObjectsAtIndexes:rowIndexes];
  
  if (row > tempArray.count) {
    [tempArray insertObject:[tArr objectAtIndex:0] atIndex:row-1];
  } else {
    [tempArray insertObject:[tArr objectAtIndex:0] atIndex:row];
  }
  [[self.xpcc remoteObjectProxy] updateNetworkOrderInSystem:[tempArray copy]
                                   removeFromSystemKeychain:nil
                                            completionBlock:^(BOOL success) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (success) {
        NSLog(@"Network reordered successfully.");
        self.networks = tempArray;
        [self.tableView reloadData];
        [self.tableView deselectAll:nil];
      } else {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Error: Could not reorder networks.";
        alert.informativeText = @"Reopen this applicationt to try again or contact Support.";
        [alert runModal];
        [NSApp terminate:self];
      }
    });
  }];
  return YES;
}

@end
