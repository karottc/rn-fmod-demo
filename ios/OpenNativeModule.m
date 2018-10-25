//
//  OpenNativeModule.m
//  test_rn_native
//
//  Created by cy on 2018/10/25.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "OpenNativeModule.h"
#import "AppDelegate.h"
#import "NativeViewController.h"

@implementation OpenNativeModule

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(openNativeVC:(NSDictionary *)dict) {
  NSLog(@"chenyang log: %@", dict);
  //NSLog(@"chenyang log: %lu", dict.count);
  //NSLog(@"chenyang log: %@", [dict objectForKey:@"title"]);
  for (NSString *key in dict) {
    NSLog(@"chenyang log: key = %@, value = %@", key, [dict objectForKey:key]);
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    AppDelegate *delegate = (AppDelegate *)([UIApplication sharedApplication].delegate);
    UINavigationController *rootNav = delegate.navController;
    NativeViewController *nativeVC = [[NativeViewController alloc] init];
    [rootNav pushViewController:nativeVC animated:YES];
  });
}

@end

