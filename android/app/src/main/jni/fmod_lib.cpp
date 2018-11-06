//
// Created by cy on 2018/11/5.
//

#include "com_test_rn_native_OpenNativeModule.h"
#include <android/log.h>
#include <stdio.h>
#include <string>
#include <vector>

#include "fmod_studio.hpp"
#include "fmod.hpp"
#include "fmod_common.h"
#include "fmod_studio_common.h"

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
        // ERRCHECK(bank->getUserData(&memory));
        bank->getUserData(&memory);
        if (memory)
        {
            free(memory);
        }
    }
    return FMOD_OK;
}


JNIEXPORT jstring JNICALL Java_com_test_1rn_1native_OpenNativeModule_testParams
  (JNIEnv *env, jobject obj, jobjectArray urlList, jstring fmodName) {
    LOGD("STEP into native method");
    jboolean isCopy = false;
    const char *str = env->GetStringUTFChars(fmodName, &isCopy);
    if (str == NULL) {
        LOGD("this error");
        return NULL;
    }
    LOGD("fmodName:%s", str);
    string fmodNameStr = str;

    int len = env->GetArrayLength(urlList);
    vector<string> fileList;
    for (int i = 0; i < len; ++i) {
        jstring jstr = (jstring)env->GetObjectArrayElement(urlList, i);
        string url = env->GetStringUTFChars(jstr, NULL);
        fileList.push_back(url);
    }

    for (int i = 0; i < fileList.size(); ++i) {
        LOGD("file %d: %s",i, fileList[i].c_str());
    }

    FMOD::Studio::System* gsystem;
    FMOD::Studio::EventDescription * geventDesc;
    FMOD::Studio::EventInstance * gengine;

    const int BANK_COUNT = fileList.size();
    FMOD::Studio::Bank* banks[BANK_COUNT];

    FMOD::Studio::System::create(&gsystem);
    gsystem->initialize(1024, FMOD_STUDIO_INIT_NORMAL, FMOD_INIT_NORMAL, 0);
    gsystem->setCallback(studioCallback, FMOD_STUDIO_SYSTEM_CALLBACK_BANK_UNLOAD);
    for (int i = 0; i < fileList.size(); ++i) {
        gsystem->loadBankFile(fileList[i].c_str(), FMOD_STUDIO_LOAD_BANK_NORMAL, &banks[i]);
    }
    gsystem->update();

    string eventStr = "event:/" + fmodNameStr;

    LOGD("event:%s",eventStr.c_str());

    gsystem->getEvent(eventStr.c_str(), &geventDesc);
    geventDesc->createInstance(&gengine);

    gengine->start();
    gsystem->update();

    return env->NewStringUTF("success testParams");
}

#ifdef __cplusplus
}
#endif