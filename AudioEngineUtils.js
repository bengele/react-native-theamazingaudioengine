'use strict';
import React from "react";
import ReactNative, {
    NativeModules,
    NativeAppEventEmitter,
    DeviceEventEmitter,
    Platform
} from "react-native";


var platform = Platform.OS;
var native = NativeModules.AudioEngine;


var AudioEngineUtils = {};

if (Platform.OS === 'ios') {
    AudioEngineUtils = {
        MainBundlePath: native.MainBundlePath,
        CachesDirectoryPath: native.NSCachesDirectoryPath,
        DocumentDirectoryPath: native.NSDocumentDirectoryPath,
        LibraryDirectoryPath: native.NSLibraryDirectoryPath,
    };
} else if (Platform.OS === 'android') {

}

export default AudioEngineUtils;
