@import CoreWLAN;
@import Security;
@import SecurityFoundation;

#import "ReorderWiFiHelperTool.h"

@implementation ReorderWiFiHelperTool

- (OSStatus)removeFromSystemKeychain:(NSString *)ssid {
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
  return status;
}

- (void)updateNetworkOrderInSystem:(NSArray *)networks
          removeFromSystemKeychain:(NSString *)ssid
                   completionBlock:(void (^)(BOOL success))block{
  
  NSLog(@"Helper Tool has been called with selector: %@", NSStringFromSelector(_cmd));
  
  CWInterface *interface = [[CWWiFiClient sharedWiFiClient] interface];
  CWMutableConfiguration *config =
      [CWMutableConfiguration configurationWithConfiguration:interface.configuration];
  
  config.networkProfiles = [NSOrderedSet orderedSetWithArray:networks];
  SFAuthorization *auth = [SFAuthorization authorization];
  
  NSError *error;
  
  BOOL authSuccess = [auth obtainWithRight:"system.preferences"
                                     flags:(kAuthorizationFlagExtendRights |
                                            kAuthorizationFlagInteractionAllowed |
                                            kAuthorizationFlagPreAuthorize)
                                     error:&error];
  if (!authSuccess) {
    if (error) NSLog(@"Could not obtain authorisation: %@", error.localizedDescription);
    block(NO);
    return;
  }
  
  if (ssid) {
    OSStatus result = [self removeFromSystemKeychain:ssid];
    if (result != errSecSuccess) {
      NSLog(@"Could not remove item from keychain: %@", SecCopyErrorMessageString(result, NULL));
    }
  }
  
  BOOL commitSuccess = [interface commitConfiguration:config authorization:auth error:&error];
  if (error) NSLog(@"Could not commit changes: %@", error.localizedDescription);
  block(commitSuccess);
}

@end
