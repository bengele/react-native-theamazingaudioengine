//
//  AudioEnginePlugin.h
//  AudioEnginePlugin
//
//  Created by 夏友彬 on 2017/8/26.
//  Copyright © 2017年 夏友彬. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TheAmazingAudioEngine.h"
#import "AERecorder.h"
#import "AEAudioFilePlayer.h"
#import "RCTAudioEngine.h"
#import "AEPlaythroughChannel.h"


@interface AudioEnginePlugin : NSObject<AEAudioReceiver>


//录音信息初始化
-(void)recorderInfoInit:(RCTAudioEngine*) rct;

-(void)recorderRelease;

//开始录音
-(void)startRecord:(NSString*)bgMusicPath:(NSString*)recordPath:(NSString*)outPath;

//结束录音
-(void)stopRecord;

//暂停录音
-(void)pauseRecord;

//播放mp3音乐
-(BOOL)playMp3:(NSString*)path;

-(void)compressPCMtoMp3:(NSString*)filePath:(NSString*) outpath;


- (AEAudioReceiverCallback)receiverCallback;
@end
