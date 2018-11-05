package com.test_rn_native;

import android.app.DownloadManager;
import android.content.Intent;
import android.os.Environment;
import android.util.Log;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableArray;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;


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
        System.out.print(map);
        //Log.d("chenyang", map);
    }

    @ReactMethod
    public void testNativeDownloadFile(ReadableMap map) {
        // 测试文件下载
        //Log.d("chenyang", "success");
        //System.out.print(map);
        Log.d("chenyang", map.getString("event"));
        ReadableArray urlList = map.getArray("url_list");
        for (int i = 0; i < urlList.size(); ++i) {
            Log.d("chenyang", "url:"+urlList.getString(i));
        }
        // /storage/emulated/0
        String path = Environment.getExternalStorageDirectory().getAbsolutePath();
        Log.d("chenyang","path: " + path);
        String path1 = Environment.getDataDirectory().getPath();
        Log.d("chenyang","path1: " + path1);   // /data
        String path2 = Environment.getDownloadCacheDirectory().getPath();
        Log.d("chenyang","path2: " + path2);   // /data/cache
        String path3 = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).getPath();
        Log.d("chenyang","path3: " + path3);   // /storage/emulated/0/Download
        String path4 = Environment.getExternalStorageDirectory().toString();
        Log.d("chenyang","path4: " + path4);
        String path5 = mReactContext.getExternalFilesDir(null).toString();
        Log.d("chenyang","path5:"+path5);  // /storage/emulated/0/Android/data/com.test_rn_native/files

        String namePre = map.getString("name_pre");
        String fmodName = map.getString("event");

        String[] fileList = new String[urlList.size()];

        for (int i = 0; i < urlList.size(); ++i) {
            String fileName = downloadFile(urlList.getString(i), namePre);
            fileList[i] = fileName;
        }
        for (int i = 0; i < fileList.length; ++i) {
            File f = new File(fileList[i]);
            if (f.exists() && f.isFile()) {
                Log.d("chenyang", fileList[i] + " size:" + f.length());
            } else {
                Log.d("chenyang", "file not exists:" + fileList[i]);
            }
        }
    }
    public String downloadFile(String url, String namePre) {
        Log.i("chenyang","step into");
        String filePath = "";
        try {
            String downPath = mReactContext.getExternalFilesDir(null).toString() + "/";
            long startTime = System.currentTimeMillis();
            String filename = namePre + url.substring(url.lastIndexOf("/") + 1);
            Log.i("chenyang","start download");
            URL myURL = new URL(url);
            URLConnection conn = myURL.openConnection();
            conn.connect();
            InputStream is = conn.getInputStream();
            int fileSize = conn.getContentLength();//根据响应获取文件大小
            if (fileSize <= 0) throw new RuntimeException("无法获知文件大小 ");
            if (is == null) throw new RuntimeException("stream is null");
            File file1 = new File(downPath);
            if (!file1.exists()) {
                file1.mkdirs();
            }
            filePath = downPath + filename;
            FileOutputStream fos = new FileOutputStream(filePath);
            byte buf[] = new byte[4096];
            int downLoadFileSize = 0;
            do{
                //循环读取
                int numread = is.read(buf);
                if (numread == -1)
                {
                    break;
                }
                fos.write(buf, 0, numread);
                downLoadFileSize += numread;
                //更新进度条
            } while (true);
            Log.i("chenyang","download success:" + filePath);
            Log.i("chenyang","totalTime="+ (System.currentTimeMillis() - startTime));
        } catch (Exception ex) {
            Log.e("chenyang", "error: " + ex.getMessage(), ex);
        }
        return filePath;
    }
}
