//
//  RCTAudioEngine.h
//  rn-audioengine
//
//  Created by 夏友彬 on 2017/8/26.
//  Copyright © 2017年 夏友彬. All rights reserved.
//

#ifndef RCTAudioEngine_h
#define RCTAudioEngine_h

//在react-native中使用时，打开此宏
#define USE_RN_BRIDGE ;

#ifdef USE_RN_BRIDGE
#import <React/RCTConvert.h>
#import <React/RCTBridge.h>
#import <React/RCTUtils.h>
#import <React/RCTEventDispatcher.h>
#endif



#ifdef USE_RN_BRIDGE
@interface RCTAudioEngine : NSObject<RCTBridgeModule>
#else
@interface RCTAudioEngine : NSObject
#endif


//发送录音分贝值
-(void)emitRecorderDecibel:(float)input :(float)output;

//发送录音时间长度
-(void)emitRecorderTimeLength:(NSTimeInterval)crt :(NSTimeInterval)cmt;

//发送录制错误信息
-(void)emitRecordError:(int)errCode :(NSString*) error;

//发送录制完成信息
-(void)emitRecordFinish:(NSString*)outPath :(NSString*)recordPath :(NSTimeInterval)recordLen :(NSTimeInterval)musicLen;

//发射背景音乐信息
-(void)emitBackgoundMusicInfo:(NSTimeInterval) length :(NSTimeInterval) currentTime :(BOOL)isLoop;


@end



#endif /* RCTAudioEngine_h */
