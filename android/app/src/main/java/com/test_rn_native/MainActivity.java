package com.test_rn_native;

import com.facebook.react.ReactActivity;

public class MainActivity extends ReactActivity {

    /**
     * Returns the name of the main component registered from JavaScript.
     * This is used to schedule rendering of the component.
     */
    @Override
    protected String getMainComponentName() {
        return "test_rn_native";
    }


    //固定写法，表示我们要加载的资源文件为libhello.so
    static {

        System.loadLibrary("fmodL");
        System.loadLibrary("fmod");
        System.loadLibrary("fmodstudio");
        System.loadLibrary("fmodstudioL");
        //System.loadLibrary("stlport_shared");

        System.loadLibrary("fmodNative");
    }

}
