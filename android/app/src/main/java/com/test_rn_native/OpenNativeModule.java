package com.test_rn_native;

import android.content.Intent;
import android.util.Log;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;



public class OpenNativeModule extends ReactContextBaseJavaModule {

    private ReactContext mReactContext;

    public OpenNativeModule(ReactApplicationContext context) {
        super(context);
        this.mReactContext = context;
    }

    @Override
    public String getName() {
        return "OpenNativeModule";
    }

    @ReactMethod
    public void openNativeVC(ReadableMap map) {
        //Intent intent = new Intent();
        //intent.setClass(mReactContext, SettingsActivity.class);
        //intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        //mReactContext.startActivity(intent);
        Log.d("chenyang", "success");
    }
}
