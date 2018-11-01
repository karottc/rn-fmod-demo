//
//  OpenNativeModule.h
//  test_rn_native
//
//  Created by cy on 2018/10/25.
//  Copyright © 2018 Facebook. All rights reserved.
//

#ifndef OpenNativeModule_h
#define OpenNativeModule_h

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface OpenNativeModule : RCTEventEmitter<RCTBridgeModule>

@end

#endif /* OpenNativeModule_h */
