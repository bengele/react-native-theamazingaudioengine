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

const REORDER_ERROR_INIT_FAIL = -10001;     //录音设备初始化失败
const REORDER_ERROR_PATH_ERROR = -10002;    //录音的录音文件路径或者混音输出路径错误
const REORDER_ERROR_RECORD_FAILED = -10003; //录制失败
const REORDER_COMPRESS_MP3_FAILED = -10004; //转码mp3失败
const REORDER_COMPRESS_LAME_ERROR = -10005; //lame错误

var AudioEngine = {
    prepareRecordingWithPath: function (outPath, recordPath, options) {
        //分贝变换监听
        if (this.subscripDecibelChangeEvent) this.subscripDecibelChangeEvent.remove();
        this.subscripDecibelChangeEvent = NativeAppEventEmitter.addListener("recordingEventDecibelChange", (data) => {
            if (this.onDecibelChange) {
                this.onDecibelChange(data);
            }
        });
        //录制过程中的监听
        if (this.subscriptProgressEvent) this.subscriptProgressEvent.remove();
        this.subscriptProgressEvent = NativeAppEventEmitter.addListener("recordingEventProgress", (data) => {
            if (this.onProgressEvent) {
                this.onProgressEvent(data);
            }
        });
        //录制出现错误的监听
        if (this.subscripRecordErrorEvent) this.subscripRecordErrorEvent.remove();
        this.subscripRecordErrorEvent = NativeAppEventEmitter.addListener("recordingEventError", (data) => {
            if (this.onRecordingError) {
                this.onRecordingError(data);
            }
        });
        //录制完成的监听
        if (this.subscripRecordFinishEvent) this.subscripRecordFinishEvent.remove();
        this.subscripRecordFinishEvent = NativeAppEventEmitter.addListener("recordingEventFinished", (data) => {
            if (this.onRecordFinished) {
                this.onRecordFinished(data);
            }
        });
        //背景音乐信息
        if (this.subscripBgMusicMp3Event) this.subscripBgMusicMp3Event.remove();
        this.subscripBgMusicMp3Event = NativeAppEventEmitter.addListener("backgroundMusicInfo", (data) => {
            if (this.onBackgoundMusicInfo) {
                this.onBackgoundMusicInfo(data);
            }
        })


        var defaultOptions = {
            SampleRate: 44100.0,
            Channels: 2,
            AudioQuality: 'High',
            AudioEncoding: 'ima4',
            OutputFormat: 'mpeg_4',
            MeteringEnabled: false,
            AudioEncodingBitRate: 32000
        };
        var recordingOptions = { ...defaultOptions, ...options };
        if (platform == "ios") {
            native.prepareRecordingWithPath(outPath, recordPath);
        } else {

        }
    },

    audioEngineInit: function () {
        return native.audioEngineInit();
    },

    //开始录音
    startRecord: function (bgMp3MusicPath) {
        return native.startRecord(bgMp3MusicPath);
    },
    //暂停录音
    pauseRecord: function () {
        return native.pauseRecord();
    },
    //结束录音
    stopRecord: function () {
        return native.stopRecord();
    },
    //播放mp3文件
    playMusic: function (musicPath) {
        return native.playMusic(musicPath);
    },

    compressPCMtoMp3: function (filePath, outPath) {
        return native.compressPCMtoMp3(filePath, outPath);
    }
}

export default AudioEngine;
