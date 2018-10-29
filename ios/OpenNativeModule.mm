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

/**
 * 下载文件
 *
 */
RCT_EXPORT_METHOD(testNativeDownloadFile:(NSDictionary *)dict) {
  NSArray *url_list = [dict objectForKey:@"url_list"];
  NSMutableArray *file_list = [NSMutableArray arrayWithCapacity:url_list.count];
  for (int i = 0; i < url_list.count; ++i) {
    // 替换url中的空格，否则ios不支持，会有错误码-1002
    NSString *tmpUrl = [url_list[i] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSURL* url = [NSURL URLWithString:tmpUrl];
    NSLog(@"chenyang log: download url: %@", tmpUrl);
    // 得到session对象
    NSURLSession* session = [NSURLSession sharedSession];
    
    // 创建任务
    
    NSURLSessionDownloadTask* downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
      //NSLog(@"chenyang log: file path: %@", location.path);
      // NSLog(@"chenyang log: file name: %@", response.suggestedFilename);
      //NSLog(@"chenyang log: error code: %@", error);   // 如果有异常，输出错误信息
      // [file_list addObject:response.suggestedFilename];
      
      NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
      // response.suggestedFilename ： 建议使用的文件名，一般跟服务器端的文件名一致
      NSString *file = [caches stringByAppendingPathComponent:response.suggestedFilename];
      
      // 将临时文件剪切或者复制Caches文件夹
      NSFileManager *mgr = [NSFileManager defaultManager];
      
      // AtPath : 剪切前的文件路径
      // ToPath : 剪切后的文件路径
      [mgr moveItemAtPath:location.path toPath:file error:nil];
      
      NSLog(@"chenyang log: file path:%@", file);
      
      [file_list addObject:file];
      NSLog(@"chenyang log: LINE:%d, file list: %lu", __LINE__, file_list.count);

      }];
    // 开始任务
    [downloadTask resume];
    NSLog(@"chenyang log: finish");
    
    //break;
  }
  NSLog(@"chenyang log: LINE:%d, file list: %lu", __LINE__, file_list.count);
  for (int i = 0; i < file_list.count; ++i) {
    NSLog(@"chenyang log: LINE:%d, file_name: %@", __LINE__, file_list[i]);
  }
}


@end

