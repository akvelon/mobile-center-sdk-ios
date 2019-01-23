#import "MSAppCenterInternal.h"
#import "MSChannelGroupProtocol.h"
#import "MSChannelUnitConfiguration.h"
#import "MSChannelUnitProtocol.h"
#import "MSConstants+Internal.h"
#import "MSIdentityInternal.h"
#import "MSServiceAbstractProtected.h"
#import "MSServiceInternal.h"
#import <MSAL/MSALPublicClientApplication.h>

// Service name for initialization.
static NSString *const kMSServiceName = @"Identity";

// The group Id for storage.
static NSString *const kMSGroupId = @"Identity";

// Singleton
static MSIdentity *sharedInstance = nil;
static dispatch_once_t onceToken;

// Authentication URL formats.
static NSString *const kMSAuthorityFormat = @"https://login.microsoftonline.com/tfp/%@.onmicrosoft.com/%@";
static NSString *const kMSAuthScopeFormat = @"https://%@.onmicrosoft.com/%@/user_impersonation";

// Configuration (Temporary). Fill constant values for your backend.
static NSString *const kMSTenantName = @"";
static NSString *const kMSPolicyName = @"";
static NSString *const kMSAPIIdentifier = @"";
static NSString *const kMSClientId = @"";

@implementation MSIdentity

@synthesize channelUnitConfiguration = _channelUnitConfiguration;

#pragma mark - Service initialization

- (instancetype)init {
  if ((self = [super init])) {

    // Init channel configuration.
    _channelUnitConfiguration = [[MSChannelUnitConfiguration alloc] initDefaultConfigurationWithGroupId:[self groupId]];

    // Init client application.
    NSError *error;
    _clientApplication = [[MSALPublicClientApplication alloc] initWithClientId:kMSClientId error:&error];
    if (error != nil) {
      MSLogError([MSIdentity logTag], @"Failed to initialize client application.");
    }
  }
  return self;
}

#pragma mark - MSServiceInternal

+ (instancetype)sharedInstance {
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [[MSIdentity alloc] init];
    }
  });
  return sharedInstance;
}

+ (NSString *)serviceName {
  return kMSServiceName;
}

- (void)startWithChannelGroup:(id<MSChannelGroupProtocol>)channelGroup
                    appSecret:(nullable NSString *)appSecret
      transmissionTargetToken:(nullable NSString *)token
              fromApplication:(BOOL)fromApplication {
  [super startWithChannelGroup:channelGroup appSecret:appSecret transmissionTargetToken:token fromApplication:fromApplication];
  MSLogVerbose([MSIdentity logTag], @"Started Identity service.");
}

+ (NSString *)logTag {
  return @"AppCenterIdentity";
}

- (NSString *)groupId {
  return kMSGroupId;
}

#pragma mark - MSServiceAbstract

- (void)setEnabled:(BOOL)isEnabled {
  [super setEnabled:isEnabled];
}

- (void)applyEnabledState:(BOOL)isEnabled {
  [super applyEnabledState:isEnabled];
  if (isEnabled) {
    [self.channelGroup addDelegate:self];
    [self acquireToken];
    MSLogInfo([MSIdentity logTag], @"Identity service has been enabled.");
  } else {
    self.accessToken = nil;
    [self.channelGroup removeDelegate:self];
    MSLogInfo([MSIdentity logTag], @"Identity service has been disabled.");
  }
}

#pragma mark - MSChannelDelegate

- (void)channel:(id<MSChannelProtocol>)channel willSendLog:(id<MSLog>)log {
  (void)channel;
  (void)log;
}

- (void)channel:(id<MSChannelProtocol>)channel didSucceedSendingLog:(id<MSLog>)log {
  (void)channel;
  (void)log;
}

- (void)channel:(id<MSChannelProtocol>)channel didFailSendingLog:(id<MSLog>)log withError:(NSError *)error {
  (void)channel;
  (void)log;
  (void)error;
}

#pragma mark - Service methods

+ (void)resetSharedInstance {

  // Resets the once_token so dispatch_once will run again.
  onceToken = 0;
  sharedInstance = nil;
}

+ (void)handleUrlResponse:(NSURL *)url {
  [MSALPublicClientApplication handleMSALResponse:url];
}

- (void)acquireToken {
  if (self.clientApplication == nil) {
    return;
  }
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kMSAuthorityFormat, kMSTenantName, kMSPolicyName]];
  MSALAuthority *authority = [MSALAuthority authorityWithURL:url error:nil];
  [self.clientApplication acquireTokenForScopes:@[ [NSString stringWithFormat:kMSAuthScopeFormat, kMSTenantName, kMSAPIIdentifier] ]
                           extraScopesToConsent:nil
                                      loginHint:nil
                                     uiBehavior:MSALUIBehaviorDefault
                           extraQueryParameters:nil
                                      authority:authority
                                  correlationId:nil
                                completionBlock:^(MSALResult *result, NSError *e) {
                                  // TODO: Implement error handling.
                                  if (e) {
                                  } else {
                                    NSString __unused *accountIdentifier = result.account.homeAccountId.identifier;
                                    self.accessToken = result.accessToken;
                                  }
                                }];
}
@end