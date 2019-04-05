// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSDictionaryDocument.h"

@implementation MSDictionaryDocument

@synthesize dictionary = _dictionary;

- (instancetype)initFromDictionary:(NSDictionary *)dictionary {
  if ((self = [super init])) {
    _dictionary = dictionary;
  }
  return self;
}

- (nonnull NSDictionary *)serializeToDictionary {
  return [self dictionary];
}

@end
