// Copyright 2015-present 650 Industries. All rights reserved.

#import "ABI21_0_0EXScopedBridgeModule.h"

@implementation ABI21_0_0EXScopedBridgeModule

+ (NSString *)moduleName
{
  NSAssert(NO, @"ABI21_0_0EXScopedBridgeModule is abstract, you should only export subclasses to the bridge.");
  return @"ExponentScopedBridgeModule";
}

- (instancetype)initWithExperienceId:(NSString *)experienceId kernelServiceDelegate:(id)kernelServiceInstance params:(NSDictionary *)params
{
  if (self = [super init]) {
    _experienceId = experienceId;
  }
  return self;
}

@end
