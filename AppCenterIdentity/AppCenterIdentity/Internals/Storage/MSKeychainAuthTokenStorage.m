// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSKeychainAuthTokenStorage.h"
#import "MSAuthTokenInfo.h"
#import "MSIdentityConstants.h"
#import "MSIdentityPrivate.h"
#import "MSKeychainUtil.h"
#import "MSLogger.h"
#import "MSUtility.h"

@implementation MSKeychainAuthTokenStorage

@synthesize authTokensHistoryState = _authTokensHistoryState;

- (nullable NSString *)retrieveAuthToken {
  NSMutableArray<MSAuthTokenInfo *> *authTokensHistory = [self authTokensHistoryState];
  MSAuthTokenInfo *latestAuthTokenInfo = authTokensHistory.lastObject;
  return latestAuthTokenInfo.authToken;
}

- (nullable NSString *)retrieveAccountId {
  return [MS_USER_DEFAULTS objectForKey:kMSIdentityMSALAccountHomeAccountKey];
}

- (NSMutableArray<MSAuthTokenInfo *> *)authTokenArray {
  NSMutableArray<MSAuthTokenInfo *> *tokenArray = [MSKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey];
  if (tokenArray == nil) {
    return [NSMutableArray<MSAuthTokenInfo *> new];
  }
  return tokenArray;
}

- (void)saveAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId expiresOn:(nullable NSDate *)expiresOn {
  @synchronized(self) {

    // Read token array from storage.
    NSMutableArray<MSAuthTokenInfo *> *authTokensHistory = [self authTokensHistoryState];
    if (authTokensHistory.count == 0) {

      /*
       * Adding a nil entry is required during the first initialization to differentiate
       * anonymous usage before the moment and situation when we don't have a token
       * in history because of the size limit for example.
       */
      [authTokensHistory addObject:[MSAuthTokenInfo new]];
    }

    // If new token differs from the last token of array - add it to array.
    NSString *latestAuthToken = [authTokensHistory lastObject].authToken;
    if (latestAuthToken ? ![latestAuthToken isEqualToString:(NSString * _Nonnull) authToken] : authToken != nil) {
      MSAuthTokenInfo *newAuthToken = [[MSAuthTokenInfo alloc] initWithAuthToken:authToken andStartTime:[NSDate date] andEndTime:expiresOn];
      [authTokensHistory addObject:newAuthToken];
    }

    // Cap array size at max available size const (deleting from beginning).
    if ([authTokensHistory count] > kMSIdentityMaxAuthTokenArraySize) {
      [authTokensHistory removeObjectAtIndex:0];
    }

    // Save new array.
    [self setAuthTokensHistoryState:authTokensHistory];
    if (authToken && accountId) {
      [MS_USER_DEFAULTS setObject:(NSString *)accountId forKey:kMSIdentityMSALAccountHomeAccountKey];
    } else {
      [MS_USER_DEFAULTS removeObjectForKey:kMSIdentityMSALAccountHomeAccountKey];
    }
  }
}

- (void)removeAuthToken:(nullable NSString *)__unused authToken {

  @synchronized(self) {

    // Read token array from storage.
    NSMutableArray<MSAuthTokenInfo *> *tokenArray = [self authTokensHistoryState];

    // Do nothing if there's just one entry in the history or no history at all.
    if (!tokenArray || tokenArray.count == 1) {
      return;
    }

    // Find, delete the oldest entry. Do not delete the most recent entry.
    for (NSUInteger i = 0; i < tokenArray.count - 1; i++) {
      if ([tokenArray[i] authToken] == authToken) {
        [tokenArray removeObjectAtIndex:i];
        break;
      }
    }

    // Save new array after changes.
    [self storeAuthTokensHistoryState:tokenArray];
  }
}

- (NSMutableArray<MSAuthTokenInfo *> *)authTokensHistoryState {
  if (_authTokensHistoryState) {
    return _authTokensHistoryState;
  }
  NSMutableArray<MSAuthTokenInfo *> *history = [MSKeychainUtil arrayForKey:kMSIdentityAuthTokenArrayKey];
  if (history) {
    MSLogDebug([MSIdentity logTag], @"Retrieved history state from the keychain.");
  } else {
    MSLogWarning([MSIdentity logTag], @"Failed to retrieve history state from the keychain or none was found.");
    history = [NSMutableArray<MSAuthTokenInfo *> new];
  }
  _authTokensHistoryState = history;
  return _authTokensHistoryState;
}

- (void)setAuthTokensHistoryState:(NSMutableArray<MSAuthTokenInfo *> *)authTokensHistory {
  if ([MSKeychainUtil storeArray:authTokensHistory forKey:kMSIdentityAuthTokenArrayKey]) {
    MSLogDebug([MSIdentity logTag], @"Saved new history state in the keychain.");
    _authTokensHistoryState = authTokensHistory;
  } else {
    MSLogWarning([MSIdentity logTag], @"Failed to save new history state in the keychain.");
  }
}

@end