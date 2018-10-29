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

#include <iostream>
using namespace std;

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

RCT_EXPORT_METHOD(testNativeCPP:(NSDictionary *)dict) {
  NSLog(@"chenyang log: %@", dict);
  //NSLog(@"chenyang log: %lu", dict.count);
  //NSLog(@"chenyang log: %@", [dict objectForKey:@"title"]);
  for (NSString *key in dict) {
    NSLog(@"chenyang log: key = %@, value = %@", key, [dict objectForKey:key]);
    NSObject *t = [dict objectForKey:key];
    if ([t isKindOfClass:[NSArray class]] == true) {
      NSArray *tt = (NSArray *)t;
      for (int i = 0; i < tt.count; ++i) {
        NSLog(@"chenyang log: url=%@", tt[i]);
      }
    }
  }
  
  cout << "chenyang log: xxxxxx" << endl;
  
  //获取根目录
  NSString *homePath = NSHomeDirectory();
  // 获取Library 文件路径
  NSString *libFilePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) firstObject];
  // 获取caches 文件路径
  NSString *cacheFilePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) firstObject];
  // Tmp文件路径
  NSString *tmpFilePath = NSTemporaryDirectory();
  NSLog(@"chenyang log: Home目录：%@",homePath);
  NSLog(@"chenyang log: Library目录：%@",libFilePath);
  NSLog(@"chenyang log: caches目录：%@",cacheFilePath);
  NSLog(@"chenyang log: Tmp目录：%@",tmpFilePath);
  //NSString *tmp = NSGet
}


@end

