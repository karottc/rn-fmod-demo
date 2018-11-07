/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  Platform,
  StyleSheet,
  Text,
  View,
  Button,
  NativeModules,
  NativeEventEmitter,
  DeviceEventEmitter
} from 'react-native';

var nativeModule = NativeModules.OpenNativeModule;

const fmod_info = {};
fmod_info.url_list = [
 'https://xxxx/Master Bank.bank',
 'https://xxxxx/Master Bank.strings.bank',
 'https://xxxx/chapter07.bank',
];
fmod_info.event = 'chapter07';
fmod_info.name_pre = '7d88c523f61d1a0be126';

const fmod_info2 = {};
fmod_info2.url_list = [
 'https://xxxxx/Master Bank.bank',
 'https://xxxxx/Master Bank.strings.bank',
 'https://xxxx/chapter1.bank',
];
fmod_info2.event = 'chapter1';
fmod_info2.name_pre = 'ae5327eb3f106';

const instructions = Platform.select({
  ios: 'Press Cmd+R to reload,\n' +
    'Cmd+D or shake for dev menu',
  android: 'Double tap R on your keyboard to reload,\n' +
    'Shake or press menu button for dev menu',
});

export default class App extends Component<{}> {
  componentDidMount() {
    let eventEmitter = new NativeEventEmitter(nativeModule);
    this.listener = eventEmitter.addListener("customEvent", this.listenCallback);
    DeviceEventEmitter.addListener('customEvent', this.listenCallback);
  }
  listenCallback(item) {
    console.log("native notition:"+item);
  }
  componentWillUnmount() {
    this.listener && this.listener.remove();
  }
  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Welcome to React Native!
        </Text>
        <Text style={styles.instructions}>
          To get started, edit App.js
        </Text>
        <Text style={styles.instructions}>
          {instructions}
        </Text>
        <Button title={'跳转到原生页面'} onPress={() => {
          this.jumpToNativeView();
        }}/>
        <Button title={'OC和c++混编'} onPress={() => {
          this.jumpToNativeView2();
        }}/>
        <Button title={'文件下载'} onPress={() => {
          this.jumpToNativeView3();
        }}/>
        <Button title={'测试只播放一个文件'} onPress={() => {
          this.jumpToNativeView4();
        }}/>
        <Button title={'测试播放完整Bank - 1'} onPress={() => {
          this.jumpToNativeView5(1);
        }}/>
        <Button title={'测试播放完整Bank - 2'} onPress={() => {
          this.jumpToNativeView5(2);
        }}/>
        <Button title={'暂停/继续·播放'} onPress={() => {
          this.jumpToNativeView6();
        }}/>
        <Button title={'停止/开始·播放'} onPress={() => {
          this.jumpToNativeView7();
        }}/>
      </View>
    );
  }
  jumpToNativeView() {
    nativeModule.openNativeVC({
      title: '原生页面',
      id: 'xxx'
    });
  }
  jumpToNativeView2() {
    nativeModule.testNativeCPP(fmod_info);
  }
  jumpToNativeView3() {
    nativeModule.testNativeDownloadFile(fmod_info);
  }
  jumpToNativeView4() {
    nativeModule.testNativePlayOneFile(fmod_info);
  }
  jumpToNativeView5(type) {
    if (type == 1) {
      nativeModule.testNativePlayFmodBanks(fmod_info);
    } else {
      nativeModule.testNativePlayFmodBanks(fmod_info2);
    }
  }
  jumpToNativeView6() {
    nativeModule.testNativeFmodPause();
  }
  jumpToNativeView7() {
    nativeModule.testNativeFmodStop();
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});
