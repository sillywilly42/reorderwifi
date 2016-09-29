@import CoreWLAN;
@import Security;
@import SecurityFoundation;

#import "AppDelegate.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *tableView;
@property NSArray *persistentNetworks;
@property NSMutableArray *networks;
@property CWInterface *interface;
@property CWMutableConfiguration *config;
@end

@implementation AppDelegate


- (BOOL)updateNetworkOrderInSystem:(NSArray *)array {
  self.config.networkProfiles = [NSOrderedSet orderedSetWithArray:array];
  SFAuthorization *auth = [SFAuthorization authorization];
  
  BOOL success = [auth obtainWithRight:"system.preferences"
                                 flags:(kAuthorizationFlagExtendRights |
                                        kAuthorizationFlagInteractionAllowed |
                                        kAuthorizationFlagPreAuthorize)
                                 error:nil];
  if (!success) return NO;
  
  return [self.interface commitConfiguration:self.config authorization:auth error:nil];
}

- (IBAction)removeNetwork:(NSButton *)sender {
  if (self.tableView.selectedRow >= 0) {
    CWNetworkProfile *profile = self.networks[self.tableView.selectedRow];
    if (![self.persistentNetworks containsObject:profile.ssid]) {
      NSMutableArray *tempArray = [self.networks mutableCopy];
      [tempArray removeObjectAtIndex:self.tableView.selectedRow];
      if ([self updateNetworkOrderInSystem:tempArray]) {
        [self removeFromSystemKeychain:profile.ssid];
        self.networks = tempArray;
        [self.tableView reloadData];
      }
    }
  }
}

- (void)removeFromSystemKeychain:(NSString *)ssid {
  NSDictionary *query = @{
      (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
      (__bridge id)kSecAttrSynchronizable: (__bridge id)kSecAttrSynchronizableAny,
      (__bridge id)kSecReturnRef: @YES,
      (__bridge id)kSecAttrAccount: ssid,
  };
  
  CFTypeRef result = NULL;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
  if (status == errSecSuccess) {
    status = SecKeychainItemDelete((SecKeychainItemRef)result);
    CFRelease(result);
  }
}

#pragma mark App Delegate Methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  self.persistentNetworks = [[NSProcessInfo processInfo] arguments];
  
  self.interface = [[CWWiFiClient sharedWiFiClient] interface];
  self.config =
      [CWMutableConfiguration configurationWithConfiguration:self.interface.configuration];
  
  self.networks = [[self.config.networkProfiles array] mutableCopy];
  
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
  
  if ([self updateNetworkOrderInSystem:tempArray]) {
    self.networks = tempArray;
    [self.tableView reloadData];
    [self.tableView deselectAll:nil];
  }
  
  return YES;
}

@end
