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

static FMOD::Studio::System* gsystem = NULL;
static FMOD::Studio::EventDescription * geventDesc = NULL;
static FMOD::Studio::EventInstance * gengine = NULL;
static bool gStop = false;

// 回调使用
JavaVM *gVM = NULL;
jobject gObj;

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

// marker的回调
FMOD_RESULT F_CALLBACK markerCallback(FMOD_STUDIO_EVENT_CALLBACK_TYPE type, FMOD_STUDIO_EVENTINSTANCE *event, void *parameters) {
    //cout << "LINE:" << __LINE__ << ",chenyang log: type:" << type << ",obj:" << FMOD_STUDIO_EVENT_CALLBACK_TIMELINE_MARKER << endl;
    if (type == FMOD_STUDIO_EVENT_CALLBACK_TIMELINE_MARKER) {
        FMOD_STUDIO_TIMELINE_MARKER_PROPERTIES* props = (FMOD_STUDIO_TIMELINE_MARKER_PROPERTIES*)parameters;
         LOGD("jni params marker: %s",props->name);
        // [[NSNotificationCenter defaultCenter] postNotificationName:@"sendCustomEventNotification" object:[NSString stringWithUTF8String:props->name]];
        // 回调java代码
        // 获取方法ID, 通过方法名和签名, 调用静态方法
        // 非静态方法需要创建实例
        JNIEnv *env;
        int getEnvStat = gVM->GetEnv((void **) &env,JNI_VERSION_1_6);
        if (getEnvStat == JNI_EDETACHED) {
            //如果没有， 主动附加到jvm环境中，获取到env
            if (gVM->AttachCurrentThread(&env, NULL) != 0) {
                return FMOD_OK;
            }
        }
        //通过全局变量g_obj 获取到要回调的类
        jclass javaClass = env->GetObjectClass(gObj);
        if (javaClass == 0) {
            LOGD("Unable to find class");
            gVM->DetachCurrentThread();
            return FMOD_OK;
        }
        jmethodID mid = env->GetMethodID(javaClass, "callMethod", "(Ljava/lang/String;)V");
        if (mid == NULL) {
            LOGD("Unable to find method:callMethod");
            return FMOD_OK;
        }

        env->CallVoidMethod(gObj, mid, env->NewStringUTF(props->name));
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

    //FMOD::Studio::System* gsystem;
    //FMOD::Studio::EventDescription * geventDesc;
    //FMOD::Studio::EventInstance * gengine;

    const int BANK_COUNT = fileList.size();
    FMOD::Studio::Bank* banks[BANK_COUNT];

    if (gsystem == NULL) {
        LOGD("init fmod studio");
    } else {
        LOGD("release fmod studio");
        gsystem->release();
    }
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

    gengine->setCallback(markerCallback,
                         FMOD_STUDIO_EVENT_CALLBACK_TIMELINE_MARKER
                         | FMOD_STUDIO_EVENT_CALLBACK_TIMELINE_BEAT
                         | FMOD_STUDIO_EVENT_CALLBACK_SOUND_PLAYED
                         | FMOD_STUDIO_EVENT_CALLBACK_SOUND_STOPPED);

    env->GetJavaVM(&gVM);
    gObj = env->NewGlobalRef(obj);

    gengine->start();
    gsystem->update();

    return env->NewStringUTF("success testParams");
}

JNIEXPORT void JNICALL Java_com_test_1rn_1native_OpenNativeModule_testFmodPause
        (JNIEnv *env, jobject obj) {
    if (gsystem == NULL) {
        return;
    }
    bool paused = false;
    int ret = gengine->getPaused(&paused);
    LOGD("pause: %d, ret:%d", paused, ret);
    ret = gengine->setPaused(!paused);
    gsystem->update();
}

JNIEXPORT void JNICALL Java_com_test_1rn_1native_OpenNativeModule_testFmodStop
        (JNIEnv *env, jobject obj) {
    if (gsystem == NULL) {
        return;
    }
    if (gStop == false) {
        gengine->stop(FMOD_STUDIO_STOP_IMMEDIATE);
        gStop = true;
    } else {
        gengine->start();
        gStop = false;
    }

    gsystem->update();
    LOGD("stop status: %d", gStop);
}


#ifdef __cplusplus
}
#endif