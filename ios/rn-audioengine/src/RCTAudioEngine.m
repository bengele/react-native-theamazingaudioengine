//
//  RCTAudioEngine.m
//  rn-audioengine
//
//  Created by 夏友彬 on 2017/8/26.
//  Copyright © 2017年 夏友彬. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTAudioEngine.h"
#import "AudioEnginePlugin.h"

NSString *const AudioEngineEventDecibelChange = @"recordingEventDecibelChange";
NSString *const AudioEngineEventProgressChange= @"recordingEventProgress";
NSString *const AudioEngineEventRecordError = @"recordingEventError";
NSString *const AudioEngineEventRecordFinish =@"recordingEventFinished";
NSString *const AudioEngineEventBackgroundMusic =@"backgroundMusicInfo";

@implementation RCTAudioEngine{
    NSString* _localOutPath ;    //输出本地存储路径
    NSString* _recordOutPath;    //输出录音文件存储路径
    
    AudioEnginePlugin* audioEnginePlugin;
    int _lastMinRecoderDecibel;
    
}

#ifdef USE_RN_BRIDGE

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

/******************公开给js调用的方法*******************/

//初始化Audio Engine
RCT_EXPORT_METHOD(audioEngineInit){
    dispatch_async(dispatch_get_main_queue(),^{
        BOOL isMain = [NSThread isMainThread];
        NSLog(@"isMainThread=%d",isMain);
        if(!audioEnginePlugin){
            audioEnginePlugin = [AudioEnginePlugin alloc];
        }
        [audioEnginePlugin recorderInfoInit:self];
    });
}


RCT_EXPORT_METHOD(prepareRecordingWithPath:
                  (NSString *) outPath:(NSString*) recordPath){
    _localOutPath = outPath;
    _recordOutPath = recordPath;
}


RCT_EXPORT_METHOD(startRecord:(NSString*)bgMp3Music){
     dispatch_async(dispatch_get_main_queue(),^{
         if(audioEnginePlugin){
             if(!_recordOutPath || !_localOutPath || _recordOutPath.length <= 0 || _localOutPath.length <= 0){
                 return [self emitRecordError:-10002 :@"输入的录音文件路径或输出路径错误"];
             }
             [audioEnginePlugin startRecord:bgMp3Music :_recordOutPath :_localOutPath];
         }
     });
}

RCT_EXPORT_METHOD(pauseRecord){
    if(audioEnginePlugin){
        [audioEnginePlugin pauseRecord];
    }
}

RCT_EXPORT_METHOD(stopRecord){
    dispatch_async(dispatch_get_main_queue(),^{
        if(audioEnginePlugin){
            [audioEnginePlugin stopRecord];
            _recordOutPath = nil;
            _localOutPath = nil;
        }
    });
}

RCT_EXPORT_METHOD(playMusic:(NSString*)musicPath){
    if(audioEnginePlugin){
        [audioEnginePlugin playMp3:musicPath];
    }
}

RCT_EXPORT_METHOD(compressPCMtoMp3:(NSString*)filePath :(NSString*)outPath){
    dispatch_async(dispatch_get_main_queue(), ^{
        if(audioEnginePlugin){
            [audioEnginePlugin compressPCMtoMp3:filePath :outPath];
        }
    });
}

#endif
/******************发射js监听的事件*******************/

//能量平均值的转换成0～120的分贝值
-(int) averagePowerToDecibel:(float)avg{
    float level;                // The linear 0.0 .. 1.0 value we need.
    float minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
    float decibels = avg;
    int value;
    
    if (decibels < minDecibels) {
        level = 0.0f;
    } else if (decibels >= 0.0f) {
        level = 1.0f;
    } else {
        float root = 2.0f;
        float minAmp = powf(10.0f, 0.05f * minDecibels);
        float inverseAmpRange = 1.0f / (1.0f - minAmp);
        float amp = powf(10.0f, 0.05f * decibels);
        float adjAmp = (amp - minAmp) * inverseAmpRange;
        
        level = powf(adjAmp, 1.0f / root);
    }
    value = (int) (round(level * 120));
    return  value;
}


//发射录音分贝
//根据进来的实测值在转换成0～120
-(void)emitRecorderDecibel:(float)input :(float)output{
    //转换成分贝值
    int inputDecibel = [self averagePowerToDecibel:input];
    int outputDecibel = [self averagePowerToDecibel:output];
    
    if(inputDecibel != _lastMinRecoderDecibel){
        _lastMinRecoderDecibel = inputDecibel;
        
        NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
        body[@"inputDecibel"] = @(inputDecibel);
        body[@"outputDecibel"] = @(outputDecibel);
#ifdef USE_RN_BRIDGE
        [self.bridge.eventDispatcher sendAppEventWithName:AudioEngineEventDecibelChange body:body];
#endif
    }
}

//发射录音时间长度
//@crt:当前录音时间长度
//@cmt:当前音乐时间长度
-(void)emitRecorderTimeLength:(NSTimeInterval) crt:(NSTimeInterval)cmt{
    
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    body[@"currRecordTime"] = [NSNumber numberWithFloat:crt];
    body[@"currMuiscTime"] = [NSNumber numberWithFloat:cmt];
    
#ifdef USE_RN_BRIDGE
    [self.bridge.eventDispatcher sendAppEventWithName:AudioEngineEventProgressChange body:body];
#endif
}

//发射录制错误
-(void)emitRecordError:(int)errCode :(NSString *)error{
    
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    body[@"errCode"] = @(errCode);
    body[@"errMsg"] = error;
#ifdef USE_RN_BRIDGE
    [self.bridge.eventDispatcher sendAppEventWithName:AudioEngineEventRecordError body:body];
#endif
}

//发射录制混音完成
-(void)emitRecordFinish:(NSString*)outPath :(NSString*)recordPath :(NSTimeInterval)recordLen :(NSTimeInterval)musicLen{
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    body[@"outPath"] = outPath;
    body[@"recordPath"] = recordPath;
    body[@"recordLength"] = [NSNumber numberWithFloat:recordLen];
    body[@"musicLength"]=[NSNumber numberWithFloat:musicLen];
#ifdef USE_RN_BRIDGE
    [self.bridge.eventDispatcher sendAppEventWithName:AudioEngineEventRecordFinish body:body];
#endif
}

//发射背景音乐信息
-(void)emitBackgoundMusicInfo:(NSTimeInterval) length:(NSTimeInterval) currentTime :(BOOL)isLoop{
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    body[@"length"] = [NSNumber numberWithFloat:length];
    body[@"currentTime"] = [NSNumber numberWithFloat:currentTime];
    body[@"isLoop"] = @(isLoop);
#ifdef USE_RN_BRIDGE
    [self.bridge.eventDispatcher sendAppEventWithName:AudioEngineEventBackgroundMusic body:body];
#endif
}


- (NSString *)getPathForDirectory:(int)directory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    return [paths firstObject];
}

//导出常量配置信息
- (NSDictionary *)constantsToExport {
    return @{
             @"MainBundlePath": [[NSBundle mainBundle] bundlePath],
             @"NSCachesDirectoryPath": [self getPathForDirectory:NSCachesDirectory],
             @"NSDocumentDirectoryPath": [self getPathForDirectory:NSDocumentDirectory],
             @"NSLibraryDirectoryPath": [self getPathForDirectory:NSLibraryDirectory]
             };
}

@end
