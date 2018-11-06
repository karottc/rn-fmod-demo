//
// Created by cy on 2018/11/5.
//

#include "com_test_rn_native_OpenNativeModule.h"
#include <android/log.h>
#include <stdio.h>
#include <string>

using namespace std;

#define LOG_TAG "chenyang"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG,LOG_TAG ,__VA_ARGS__) // 定义LOGD类型
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,LOG_TAG ,__VA_ARGS__) // 定义LOGI类型
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN,LOG_TAG ,__VA_ARGS__) // 定义LOGW类型
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR,LOG_TAG ,__VA_ARGS__) // 定义LOGE类型
#define LOGF(...) __android_log_print(ANDROID_LOG_FATAL,LOG_TAG ,__VA_ARGS__) // 定义LOGF类型

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT jstring JNICALL Java_com_test_1rn_1native_OpenNativeModule_testParams
  (JNIEnv *env, jobject obj, jobjectArray urlList, jstring fmodName) {
    LOGD("STEP into native method");
    jboolean isCopy;
    //LOGD(fmodName);
    const char *str = env->GetStringUTFChars(fmodName, &isCopy);
    
    if (str == NULL) {
        LOGD("this error");
        return NULL;
    }

    LOGD("fmodName:%s", str);

    //char * tmpStr = "success testParams";
    //jstring retStr = env->NewStringUTF(tmpStr);
    return env->NewStringUTF("success testParams");
    //env->GetString
    //return NULL;
}

#ifdef __cplusplus
}
#endif