import React, { Component } from "react";
import { View, Text, TouchableWithoutFeedback } from "react-native";

import AudioEngine from "./AudioEngine";
import AudioEngineUtils from "./AudioEngineUtils";

export default class Example extends Component {
    constructor(props) {
        super(props);
    }

    componentDidMount() {

        this._audioInit();
    }


    _audioInit() {
        this.cachePath = AudioEngineUtils.DocumentDirectoryPath;

        //初始化录音工具
        AudioEngine.audioEngineInit();


        //绑定监听回调
        AudioEngine.onDecibelChange = (data) => {
            console.log(data);
        };
        AudioEngine.onProgressEvent = (data) => {
            console.log(data);
        };
        AudioEngine.onRecordingError = (data) => {
            console.log(data);
        };
        AudioEngine.onRecordFinished = (data) => {
            console.log(data);
        };
        AudioEngine.onBackgoundMusicInfo = (data) => {
            console.log(data);
        };
    }

    async onTestPress() {
        if (!this.outPath && !this.recordPath) {
            this.outPath = this.cachePath + "/record.mp3";
            this.recordPath = this.cachePath + "/record.aac";
            AudioEngine.prepareRecordingWithPath(outPath, recordPath, {});
        }
    }

    onRecordPress() {
        //模拟器下请把mp3音频文件放置到缓存中
        //也可以先去下载音频
        if (!this.bgMusicPath) {
            return DApplication.showToast("背景音乐错误");
        }
        AudioEngine.startRecord(this.bgMusicPath);
    }


    onStopRecordPress() {
        AudioEngine.stopRecord();
    }

    onAuditionPress() {
        var path = this.cachePath + "/record.mp3";
        AudioEngine.playMusic(path);

    }

    onCompressPCMPress() {
        var filePath = this.cachePath + "/recordFile.pcm";
        var outPath = this.cachePath + "/pcm.mp3";
        AudioEngine.compressPCMtoMp3(filePath, outPath);
    }

    render() {
        return (
            <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
                <Button
                    style={styles.buttonStyle}
                    onPress={() => { this.testButtonPress() }}
                >
                    <Text>测试</Text>
                </Button>
                <Button
                    style={styles.buttonStyle}
                    onPress={() => { this.onRecordPress() }}
                >
                    <Text>录音</Text>
                </Button>
                <Button
                    style={styles.buttonStyle}
                    onPress={() => { this.onStopRecordPress() }}
                >
                    <Text>停止录音</Text>
                </Button>
                <Button
                    style={styles.buttonStyle}
                    onPress={() => { this.onAuditionPress() }}
                >
                    <Text>试听</Text>
                </Button>
                <Button
                    style={styles.buttonStyle}
                    onPress={() => { this.onCompressMp3Press() }}
                >
                    <Text>测试mp3转码</Text>
                </Button>
            </View>
        );

    }

}


class Button extends Component {
    constructor(props) {
        super(props);
    }

    render() {
        var attrs = {};
        attrs.onPress = this.props.onPress || null;
        let underlayColor = this.props.underlayColor || "transparent";
        return (
            <TouchableWithoutFeedback {...attrs} >
                <View style={this.props.style} underlayColor={underlayColor}>
                    {this.props.children}
                </View>
            </TouchableWithoutFeedback>
        );
    }
}

const styles = {
    buttonStyle: {
        width: 100,
        height: 50,
        justifyContent: "center",
        alignItems: "center",
        borderWidth: 0.5,
        borderColor: "#ebebeb"
    },
}