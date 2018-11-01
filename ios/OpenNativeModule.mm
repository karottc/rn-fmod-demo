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
#include "fmod/fmod_studio.hpp"
#include "fmod/fmod.hpp"
#include "fmod/common.h"
#include "fmod/fmod_common.h"
#include "fmod/fmod_studio_common.h"
//#include "fmod.hpp"

using namespace std;

@implementation OpenNativeModule

RCT_EXPORT_MODULE();

static FMOD::Studio::System* gsystem = NULL;
static FMOD::Studio::EventDescription * geventDesc = NULL;
static FMOD::Studio::EventInstance * gengine = NULL;
static bool gStop = false;

RCT_EXPORT_METHOD(initFmod) {
  FMOD::Studio::System::create(&gsystem);
}

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
  NSMutableArray __block *file_list = [NSMutableArray arrayWithCapacity:url_list.count];
  NSInteger __block task_count = 0;
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
      --task_count;  // 任务完成
      }];
    // 开始任务
    ++task_count;
    [downloadTask resume];
    NSLog(@"chenyang log: finish");
    
    //break;
  }
  while (true) {
    if (task_count <= 0) {
      NSLog(@"chenyang log: LINE:%d, file list: %lu", __LINE__, file_list.count);
      for (int i = 0; i < file_list.count; ++i) {
        NSLog(@"chenyang log: LINE:%d, file_name: %@", __LINE__, file_list[i]);
      }
      break;
    }
  }
  
  // 调用fmod studio api
  const int BANK_COUNT = (int)file_list.count;
  FMOD::Studio::Bank* banks[BANK_COUNT];
  bool wantBankLoaded[BANK_COUNT];
  bool wantSampleLoad = true;
  
  void *extraDriverData = 0;
  Common_Init(&extraDriverData);
  
  FMOD::Studio::System* system;
  FMOD::Studio::EventDescription * eventDesc;
  FMOD::Studio::EventInstance * engine;
  ERRCHECK( FMOD::Studio::System::create(&system) );
  ERRCHECK( system->initialize(1024, FMOD_STUDIO_INIT_NORMAL, FMOD_INIT_NORMAL, extraDriverData) );
  ERRCHECK( system->setCallback(studioCallback, FMOD_STUDIO_SYSTEM_CALLBACK_BANK_UNLOAD) );
  int ret = 0;
  for (int i=0; i<BANK_COUNT; ++i)
  {
    //if (Common_BtnPress((Common_Button)(BTN_ACTION1 + i)))
    {
      // Toggle bank load, or bank unload
      //if (!wantBankLoaded[i])
      {
        //ERRCHECK(loadBank(system, LoadBank_File, Common_MediaPath([file_list[i] cStringUsingEncoding:NSUTF8StringEncoding]), &banks[i]));
        //wantBankLoaded[i] = true;
        
        char* file_name = (char *)[file_list[i] cStringUsingEncoding:NSUTF8StringEncoding];
        
        ret = system->loadBankFile(file_name, FMOD_STUDIO_LOAD_BANK_NORMAL, &banks[i]);
        
        cout << "LINE:" << __LINE__ << ",chenyang log:" << file_name << ",ret=" << ret << endl;
      }
      /*
      else
      {
        ERRCHECK(banks[i]->unload());
        wantBankLoaded[i] = false;
      }
       */
    }
  }
  /*
  if (Common_BtnPress(BTN_MORE))
  {
    wantSampleLoad = !wantSampleLoad;
  }
   */
  /*
  FMOD_RESULT loadStateResult[3] = { FMOD_OK, FMOD_OK, FMOD_OK };
  FMOD_RESULT sampleStateResult[3] = { FMOD_OK, FMOD_OK, FMOD_OK };
  FMOD_STUDIO_LOADING_STATE bankLoadState[3] = { FMOD_STUDIO_LOADING_STATE_UNLOADED, FMOD_STUDIO_LOADING_STATE_UNLOADED, FMOD_STUDIO_LOADING_STATE_UNLOADED };
  FMOD_STUDIO_LOADING_STATE sampleLoadState[3] = { FMOD_STUDIO_LOADING_STATE_UNLOADED, FMOD_STUDIO_LOADING_STATE_UNLOADED, FMOD_STUDIO_LOADING_STATE_UNLOADED };
  for (int i=0; i<BANK_COUNT; ++i)
  {
    if (banks[i] && banks[i]->isValid())
    {
      loadStateResult[i] = banks[i]->getLoadingState(&bankLoadState[i]);
    }
    if (bankLoadState[i] == FMOD_STUDIO_LOADING_STATE_LOADED)
    {
      sampleStateResult[i] = banks[i]->getSampleLoadingState(&sampleLoadState[i]);
      if (wantSampleLoad && sampleLoadState[i] == FMOD_STUDIO_LOADING_STATE_UNLOADED)
      {
        ERRCHECK(banks[i]->loadSampleData());
      }
      else if (!wantSampleLoad && (sampleLoadState[i] == FMOD_STUDIO_LOADING_STATE_LOADING || sampleLoadState[i] == FMOD_STUDIO_LOADING_STATE_LOADED))
      {
        ERRCHECK(banks[i]->unloadSampleData());
      }
    }
  }
   */
  cout << "LINE:" << __LINE__ << ",chenyang log:" << endl;
  ERRCHECK( system->update() );
  
  system->getEvent("event:/chapter1", &eventDesc);
  eventDesc->createInstance(&engine);
  engine->start();
  system->update();
}

//
// Load method as enum for our sample code
//
enum LoadBankMethod
{
  LoadBank_File,
  LoadBank_Memory,
  LoadBank_MemoryPoint,
  LoadBank_Custom
};

//
// Callback to free memory-point allocation when it is safe to do so
//
FMOD_RESULT F_CALLBACK studioCallback(FMOD_STUDIO_SYSTEM *system, FMOD_STUDIO_SYSTEM_CALLBACK_TYPE type, void *commanddata, void *userdata)
{
  if (type == FMOD_STUDIO_SYSTEM_CALLBACK_BANK_UNLOAD)
  {
    // For memory-point, it is now safe to free our memory
    FMOD::Studio::Bank* bank = (FMOD::Studio::Bank*)commanddata;
    void* memory;
    ERRCHECK(bank->getUserData(&memory));
    if (memory)
    {
      free(memory);
    }
  }
  return FMOD_OK;
}

//
// Helper function that loads a bank in using the given method
//
FMOD_RESULT loadBank(FMOD::Studio::System* system, LoadBankMethod method, const char* filename, FMOD::Studio::Bank** bank)
{
  cout << "LINE:" << __LINE__ << ",chenyang log:" << method << "," << filename << endl;
  if (method == LoadBank_File)
  {
    // return system->loadBankFile(filename, FMOD_STUDIO_LOAD_BANK_NONBLOCKING, bank);
    // loading 完成再返回
    return system->loadBankFile(filename, FMOD_STUDIO_LOAD_BANK_NORMAL, bank);
  }
  else if (method == LoadBank_Memory || method == LoadBank_MemoryPoint)
  {
    char* memoryBase;
    char* memoryPtr;
    int memoryLength;
    FMOD_RESULT result = loadFile(filename, &memoryBase, &memoryPtr, &memoryLength);
    if (result != FMOD_OK)
    {
      return result;
    }
    
    FMOD_STUDIO_LOAD_MEMORY_MODE memoryMode = (method == LoadBank_MemoryPoint ? FMOD_STUDIO_LOAD_MEMORY_POINT : FMOD_STUDIO_LOAD_MEMORY);
    result = system->loadBankMemory(memoryPtr, memoryLength, memoryMode, FMOD_STUDIO_LOAD_BANK_NONBLOCKING, bank);
    if (result != FMOD_OK)
    {
      free(memoryBase);
      return result;
    }
    
    if (method == LoadBank_MemoryPoint)
    {
      // Keep memory around until bank unload completes
      result = (*bank)->setUserData(memoryBase);
    }
    else
    {
      // Don't need memory any more
      free(memoryBase);
    }
    return result;
  }
  else
  {
    // Set up custom callback
    FMOD_STUDIO_BANK_INFO info;
    memset(&info, 0, sizeof(info));
    info.size = sizeof(info);
    //info.opencallback = customFileOpen;
    //info.closecallback = customFileClose;
    //info.readcallback = customFileRead;
    //info.seekcallback = customFileSeek;
    info.userdata = (void*)filename;
    
    return system->loadBankCustom(&info, FMOD_STUDIO_LOAD_BANK_NONBLOCKING, bank);
  }
}

//
// Helper function that loads a file into aligned memory buffer
//
FMOD_RESULT loadFile(const char* filename, char** memoryBase, char** memoryPtr, int* memoryLength)
{
  // If we don't support fopen then just return a single invalid byte for our file
  size_t length = 1;
  
#ifdef ENABLE_FILE_OPEN
  FILE* file = fopen(filename, "rb");
  if (!file)
  {
    return FMOD_ERR_FILE_NOTFOUND;
  }
  fseek(file, 0, SEEK_END);
  length = ftell(file);
  fseek(file, 0, SEEK_SET);
  if (length >= MAX_FILE_LENGTH)
  {
    fclose(file);
    return FMOD_ERR_FILE_BAD;
  }
#endif
  
  // Load into a pointer aligned to FMOD_STUDIO_LOAD_MEMORY_ALIGNMENT
  char* membase = reinterpret_cast<char*>(malloc(length + FMOD_STUDIO_LOAD_MEMORY_ALIGNMENT));
  char* memptr = (char*)(((size_t)membase + (FMOD_STUDIO_LOAD_MEMORY_ALIGNMENT-1)) & ~(FMOD_STUDIO_LOAD_MEMORY_ALIGNMENT-1));
  
#ifdef ENABLE_FILE_OPEN
  size_t bytesRead = fread(memptr, 1, length, file);
  fclose(file);
  if (bytesRead != length)
  {
    free(membase);
    return FMOD_ERR_FILE_BAD;
  }
#endif
  
  *memoryBase = membase;
  *memoryPtr = memptr;
  *memoryLength = (int)length;
  cout << "LINE: " << __LINE__ << ",chenyang log:" << length << endl;
  return FMOD_OK;
}


// 不重要的尝试
RCT_EXPORT_METHOD(testNativePlayOneFile:(NSDictionary *)dict) {
  NSArray *url_list = [dict objectForKey:@"url_list"];
  NSMutableArray __block *file_list = [NSMutableArray arrayWithCapacity:url_list.count];
  NSInteger __block task_count = 0;
  NSString __block *file_name = @"";
  // 替换url中的空格，否则ios不支持，会有错误码-1002
  NSString *tmpUrl = [url_list[2] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
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
    file_name = response.suggestedFilename;
    
    // 将临时文件剪切或者复制Caches文件夹
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    // AtPath : 剪切前的文件路径
    // ToPath : 剪切后的文件路径
    [mgr moveItemAtPath:location.path toPath:file error:nil];
    
    NSLog(@"chenyang log: file path:%@", file);
    
    [file_list addObject:file];
    NSLog(@"chenyang log: LINE:%d, file list: %lu", __LINE__, file_list.count);
    --task_count;  // 任务完成
  }];
  // 开始任务
  ++task_count;
  [downloadTask resume];
  NSLog(@"chenyang log: finish");

  while (true) {
    if (task_count <= 0) {
      NSLog(@"chenyang log: LINE:%d, file list: %lu", __LINE__, file_list.count);
      for (int i = 0; i < file_list.count; ++i) {
        NSLog(@"chenyang log: LINE:%d, file_name: %@", __LINE__, file_list[i]);
      }
      break;
    }
  }
  
  FMOD::Studio::System* system;
  FMOD::Studio::EventDescription * eventDesc;
  FMOD::Studio::EventInstance * engine;
  FMOD::Studio::Bank* banks;
  FMOD::Studio::System::create(&system);
  system->initialize(1024, FMOD_STUDIO_INIT_NORMAL, FMOD_INIT_NORMAL, 0);
  system->setCallback(studioCallback, FMOD_STUDIO_SYSTEM_CALLBACK_BANK_UNLOAD);
  system->loadBankFile([file_list[0] cStringUsingEncoding:NSUTF8StringEncoding], FMOD_STUDIO_LOAD_BANK_NORMAL, &banks);
  system->update();
  NSString *eventStr = [@"event:/" stringByAppendingString: file_name];
  //system->getEvent([eventStr cStringUsingEncoding:NSUTF8StringEncoding], &eventDesc);
  system->getEvent("event:/chapter1", &eventDesc);
  eventDesc->createInstance(&engine);
  engine->start();
  system->update();
  cout << "LINE:" << __LINE__ << ",chenyang log: play start" << endl;
}

// 测试播放
RCT_EXPORT_METHOD(testNativePlayFmodBanks:(NSDictionary *)dict) {
  NSArray *url_list = [dict objectForKey:@"url_list"];
  NSMutableArray __block *file_list = [NSMutableArray arrayWithCapacity:url_list.count];
  NSInteger __block task_count = 0;
  NSString __block *fmod_name = [dict objectForKey:@"event"];
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
      // caches = [caches stringByAppendingString: fmod_name];
      // response.suggestedFilename ： 建议使用的文件名，一般跟服务器端的文件名一致
      NSString *file = [caches stringByAppendingPathComponent:[fmod_name stringByAppendingString:response.suggestedFilename]];
      //if (i == url_list.count - 1) {
      //  fmod_name = response.suggestedFilename;
      //}
      
      // 将临时文件剪切或者复制Caches文件夹
      NSFileManager *mgr = [NSFileManager defaultManager];
      
      // AtPath : 剪切前的文件路径
      // ToPath : 剪切后的文件路径
      [mgr moveItemAtPath:location.path toPath:file error:nil];
      // 获取文件大小
      NSDictionary *fileDic = [mgr attributesOfItemAtPath:file error:nil];//获取文件的属性
      
      NSLog(@"chenyang log: file path:%@,size=%lu", file, [[fileDic objectForKey:NSFileSize] longLongValue]);
      
      [file_list addObject:file];
      NSLog(@"chenyang log: LINE:%d, file list: %lu", __LINE__, file_list.count);
      --task_count;  // 任务完成
    }];
    // 开始任务
    ++task_count;
    [downloadTask resume];
    NSLog(@"chenyang log: finish");
    
    //break;
  }
  while (true) {
    if (task_count <= 0) {
      NSLog(@"chenyang log: LINE:%d, file list: %lu", __LINE__, file_list.count);
      for (int i = 0; i < file_list.count; ++i) {
        NSLog(@"chenyang log: LINE:%d, file_name: %@", __LINE__, file_list[i]);
      }
      break;
    }
  }
  const int BANK_COUNT = (int)file_list.count;
  FMOD::Studio::Bank* banks[BANK_COUNT];
  if (gsystem == NULL) {
    NSLog(@"chenyang log: LINE:%d, init fmod studio system", __LINE__);
    //FMOD::Studio::System::create(&gsystem);
  } else {
    NSLog(@"chenyang log: LINE:%d, unloadAll fmod studio system", __LINE__);
    //gengine->stop(FMOD_STUDIO_STOP_IMMEDIATE);
    //gsystem->unloadAll();
    gsystem->release();
  }
  FMOD::Studio::System::create(&gsystem);
  gsystem->initialize(1024, FMOD_STUDIO_INIT_NORMAL, FMOD_INIT_NORMAL, 0);
  gsystem->setCallback(studioCallback, FMOD_STUDIO_SYSTEM_CALLBACK_BANK_UNLOAD);
  for (int i = 0; i < file_list.count; ++i) {
    gsystem->loadBankFile([file_list[i] cStringUsingEncoding:NSUTF8StringEncoding], FMOD_STUDIO_LOAD_BANK_NORMAL, &banks[i]);
  }
  gsystem->update();
  NSString *eventStr = [@"event:/" stringByAppendingString: fmod_name];
  NSLog(@"chenyang log: LINE:%d, event_file: %@", __LINE__, eventStr);
  gsystem->getEvent([eventStr cStringUsingEncoding:NSUTF8StringEncoding], &geventDesc);
  // 控制延迟的，暂时不用
  //FMOD::System *lowLevelSystem;
  //gsystem->getLowLevelSystem(&lowLevelSystem);
  //lowLevelSystem->setDSPBufferSize(4096, 2);
  //gsystem->getEvent("event:/chapter07", &geventDesc);
  geventDesc->createInstance(&gengine);
  gengine->setCallback(markerCallback,
                       FMOD_STUDIO_EVENT_CALLBACK_TIMELINE_MARKER
                       | FMOD_STUDIO_EVENT_CALLBACK_TIMELINE_BEAT
                       | FMOD_STUDIO_EVENT_CALLBACK_SOUND_PLAYED
                       | FMOD_STUDIO_EVENT_CALLBACK_SOUND_STOPPED);
  gengine->start();
  gsystem->update();
  cout << "LINE:" << __LINE__ << ",chenyang log: play start" << endl;
}

// 暂停播放
RCT_EXPORT_METHOD(testNativeFmodPause) {
  bool paused = false;
  int ret = gengine->getPaused(&paused);
  cout << "LINE:" << __LINE__ << ",chenyang log: pause:" << paused << ",ret:" << ret << endl;
  ret = gengine->setPaused(!paused);
  //gengine->setTimelinePosition(19.200000000000003 * 1000);
  gsystem->update();
  //cout << "LINE:" << __LINE__ << ",chenyang log: pause:" << ret << endl;
}
// 继续播放
RCT_EXPORT_METHOD(testNativeFmodStop) {
  //gengine->start();
  if (gStop == false) {
    gengine->stop(FMOD_STUDIO_STOP_IMMEDIATE);
    gStop = true;
  } else {
    gengine->start();
    gStop = false;
  }
  
  gsystem->update();
  cout << "LINE:" << __LINE__ << ",chenyang log: stop:" << gStop << endl;
}


// marker的回调
FMOD_RESULT F_CALLBACK markerCallback(FMOD_STUDIO_EVENT_CALLBACK_TYPE type, FMOD_STUDIO_EVENTINSTANCE *event, void *parameters) {
  cout << "LINE:" << __LINE__ << ",chenyang log: type:" << type << ",obj:" << FMOD_STUDIO_EVENT_CALLBACK_TIMELINE_MARKER << endl;
  if (type == FMOD_STUDIO_EVENT_CALLBACK_TIMELINE_MARKER) {
    FMOD_STUDIO_TIMELINE_MARKER_PROPERTIES* props = (FMOD_STUDIO_TIMELINE_MARKER_PROPERTIES*)parameters;
    cout << "LINE:" << __LINE__ << ",chenyang log: params marker:" << props->name << endl;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sendCustomEventNotification" object:[NSString stringWithUTF8String:props->name]];

  }
  return FMOD_OK;
}


// native 主动通知 rn端
- (instancetype)init {
  self = [super init];
  if (self) {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self];
    [defaultCenter addObserver:self
                      selector:@selector(sendCustomEvent:)
                          name:@"sendCustomEventNotification"
                        object:nil];
  }
  return self;
}
- (void)sendCustomEvent:(NSNotification *)notification {
  NSString *name = notification.object;
  NSLog(@"LINE: %d,chenyang log: notification:%@", __LINE__,name);
  [self sendEventWithName:@"customEvent" body:name];
}
/// 重写方法，定义支持的事件集合
- (NSArray<NSString *> *)supportedEvents {
  return @[@"customEvent"];
}

@end

