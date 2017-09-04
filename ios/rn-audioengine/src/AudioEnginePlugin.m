//
//  AudioEnginePlugin.m
//  AudioEnginePlugin
//
//  Created by 夏友彬 on 2017/8/26.
//  Copyright © 2017年 夏友彬. All rights reserved.
//

#import "AudioEnginePlugin.h"
#import "lame.h"

const int RECORDER_ERROR_INIT_FAIL = -10001;     //录音设备初始化失败
const int RECORDER_ERROR_PATH_ERROR = -10002;    //录音的录音文件路径或者混音输出路径错误
const int RECORDER_ERROR_RECORD_FAILED = -10003; //录制失败
const int RECORDER_COMPRESS_MP3_FAILED = -10004; //转码mp3失败
const int RECORDER_COMPRESS_LAME_ERROR = -10005; //lame错误

@implementation AudioEnginePlugin{
    AERecorder* _recorder;
    AEAudioFilePlayer* _audioFilePlay;
    RCTAudioEngine* _mRctAudioEngine;
    AEAudioController *_audioController;
    AEChannelGroupRef _channelGroupRef;
    AEPlaythroughChannel* _playthrough;
    AEAudioUnitChannel* _audioUnitChannel;
    
    NSTimeInterval _currentRecordTime;
    NSTimeInterval _currentMusicTime;
    
    int _progressUpdateInterval;
    AudioFileTypeID _recordingFileType;
    
    id _progressUpdateTimer;
    NSDate *_prevProgressUpdateTime;
    
    NSString* _localOutPath;
    NSString* _recordOutPath;
    
}

- (AEAudioReceiverCallback)receiverCallback{
    return &audioCallback;
}

static void audioCallback(__unsafe_unretained AudioEnginePlugin* THIS,
                          __unsafe_unretained AEAudioController *audioController,
                          void *source,
                          const AudioTimeStamp *time,
                          UInt32 frames,
                          AudioBufferList *audio
                          ){
//    NSLog(@"");
//    AEFloatConverterToFloatBufferList(THIS->_floatConverter, audio, THIS->_conversionBuffer, frames);
}


//时间刷新
-(void)sendProgressUpdate{
    if(_recorder && _recorder.recording){
        if([_recorder currentTime] != 0){
            _currentRecordTime = [_recorder currentTime];
        }
    }else{
        return [self emitAveragePower:0 :0];
    }
    
    if(_audioFilePlay && _audioFilePlay.duration > 0){
        if([_audioFilePlay currentTime] != 0){
            _currentMusicTime = [_audioFilePlay currentTime];
        }
    }
    
    if (_prevProgressUpdateTime == nil ||(([_prevProgressUpdateTime timeIntervalSinceNow] * -1000.0) >= _progressUpdateInterval)){
        [self emitAudioProgress:_currentRecordTime :_currentMusicTime];
        
        _prevProgressUpdateTime = [NSDate date];
    }
    
    if(_audioController){
        Float32 inputAvg, inputPeak, outputAvg, outputPeak;
        [_audioController inputAveragePowerLevel:&inputAvg peakHoldLevel:&inputPeak];
        [_audioController outputAveragePowerLevel:&outputAvg peakHoldLevel:&outputPeak];
//        NSLog(@"inputAvg = %f ,outputAvg= %f ",inputAvg, outputAvg);
        [self emitAveragePower:inputAvg :outputAvg];
    }
}

//录音信息初始化
-(void)recorderInfoInit:(RCTAudioEngine*)rct{
    _mRctAudioEngine = rct;
    
    if(!_audioController){
        _audioController = [[AEAudioController alloc]initWithAudioDescription:AEAudioStreamBasicDescriptionNonInterleavedFloatStereo inputEnabled:true];
        _audioController.preferredBufferDuration =0.005;
        _audioController.useMeasurementMode=YES;
        BOOL started = [_audioController start:NULL];
        if(!started){
            return [self emitAudioError:RECORDER_ERROR_INIT_FAIL :@"录音设备初始化失败"];
        }
        _audioUnitChannel = [[AEAudioUnitChannel alloc]initWithComponentDescription:AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple, kAudioUnitType_Generator, kAudioUnitSubType_AudioFilePlayer)];
        NSMutableArray* array = [[NSMutableArray alloc]init];
        [array addObject:_audioUnitChannel];
        [_audioController addChannels:@[_audioUnitChannel]];
    }
    
}

//停止刷时间
-(void)stopRecordProgressTimer{
    [_progressUpdateTimer invalidate];
}

//开始刷时间
-(void)startRecordProgressTimer{
    _progressUpdateInterval = 250;
    _prevProgressUpdateTime = nil;
    [self stopRecordProgressTimer];
    
    //开始刷时钟
    _progressUpdateTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(sendProgressUpdate)];
    [_progressUpdateTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}


//开始录音
-(void)startRecord:(NSString*)bgMusicPath :(NSString*)recordPath :(NSString*)outPath{
    
    if(!recordPath || !outPath || recordPath.length <=0 || outPath.length <= 0){
        return [self emitAudioError:RECORDER_ERROR_PATH_ERROR :@"录音的录音文件路径或者混音输出路径错误"];
    }
    
    //背景音乐可以为nil和空字符串
    _currentRecordTime = 0;
    _currentMusicTime = 0;
    if(bgMusicPath && bgMusicPath.length > 0){
        if(![self playBackgoundMp3:bgMusicPath]){
            return [self emitAudioError:RECORDER_ERROR_PATH_ERROR :@"背景音乐播放失败，地址不可用"];
        }
    }
    
    _localOutPath = outPath;
    _recordOutPath = recordPath;
    
    NSError* error = nil;
    if(!_recorder){
        _recorder = [[AERecorder alloc]initWithAudioController:_audioController];
    }
    
    BOOL begin =[_recorder beginRecordingToFileAtPath:recordPath fileType:kAudioFileM4AType error:&error];
    if(!begin){
        _localOutPath = nil;
        _recordOutPath = nil;
        [self stopRecord];
        [self stopBackgoundMp3];
        [self emitAudioError:RECORDER_ERROR_RECORD_FAILED :@"录制失败，请重新录制"];
        return;
    }
    
    _playthrough = [[AEPlaythroughChannel alloc] init];
    //添加输入接收器监听(录音为输入)
    if(_audioController){
        [_audioController addInputReceiver:_recorder];
        [_audioController addOutputReceiver:_recorder];
        [_audioController addInputReceiver:_playthrough];
    }
    
    //开始时间
    [self startRecordProgressTimer];
    
}

//结束录音
-(void)stopRecord{
    if(_recorder){
        [_recorder finishRecording];
        [self stopRecordProgressTimer];
        
        //移除输入输出接收器
        if(_audioController){
            [_audioController removeOutputReceiver:_recorder];
            [_audioController removeInputReceiver:_recorder];
            if(_playthrough) [_audioController removeInputReceiver:_playthrough];
        }
        _playthrough = nil;
        [self stopBackgoundMp3];
        
        if(_localOutPath || _recordOutPath || _localOutPath.length > 0 || _recordOutPath.length > 0 ){
            //转换成mp3,输出音频的数据
//            [self compressMp3:_recordOutPath :_localOutPath];
        }
        _recorder = nil;
        _localOutPath = nil;
        _recordOutPath = nil;
        _currentRecordTime = 0;
        _currentMusicTime = 0;
        _prevProgressUpdateTime = nil;
    }
}

//暂停录音
-(void)pauseRecord{

    
}

//播放mp3音乐
-(BOOL)playMp3:(NSString*)path{
    return [self playBackgoundMp3:path];
}

//播放mp3背景音乐
-(BOOL)playBackgoundMp3:(NSString*)path{
    //检测播放地址是否存在
    NSFileManager* file = [NSFileManager defaultManager];
    if(![file fileExistsAtPath:path]){
        return NO;
    }
    if(_audioFilePlay){
        [self stopBackgoundMp3];
    }
    _audioFilePlay = [AEAudioFilePlayer audioFilePlayerWithURL:[NSURL fileURLWithPath:path] error:NULL];
    if (!_audioFilePlay) {
        return NO;
    }
    _audioFilePlay.channelIsMuted = false;
    _audioFilePlay.volume =0.5;
    _audioFilePlay.loop = false;
    _audioFilePlay.removeUponFinish = true;
    
    _channelGroupRef = [_audioController createChannelGroup];
    
    
    [_audioController addChannels:@[_audioFilePlay] toChannelGroup:_channelGroupRef];
    
    //添加输出接收器(播放音乐为输出)
    [_audioController addOutputReceiver:self];
    //发射背景音乐信息
    [self emitBgMusicInfo:_audioFilePlay.duration :_audioFilePlay.currentTime :_audioFilePlay.loop];
    
    //播放完成回调
    AudioEnginePlugin* plugin = self;
    _audioFilePlay.completionBlock =^{
        //背景音乐播放完成后停止录制
        [plugin stopRecord];
    };
    return YES;
}

//停止播放背景音乐
-(void)stopBackgoundMp3{
    if(_audioFilePlay){
        if(_channelGroupRef && _audioController){
            [_audioController removeOutputReceiver:self];
            [_audioController removeChannelGroup:_channelGroupRef];
        }
        _audioFilePlay = nil;
    }
}


//转码压缩成mp3文件
-(void)compressPCMtoMp3:(NSString*)filePath :(NSString*)outpath{
    
    NSFileManager* file = [NSFileManager defaultManager];
    
    if(!filePath || ![file fileExistsAtPath:filePath]){
        return [self emitAudioError: RECORDER_ERROR_PATH_ERROR :@"录制的文件路径错误或者录制的文件不存在"];
    }
    if(!outpath){
        return [self emitAudioError:RECORDER_ERROR_PATH_ERROR :@"转换成Mp3的目录地址错误"];
    }
    
    NSTimeInterval recordTimeLen = _currentRecordTime;
    NSTimeInterval musicTimeLen = _currentMusicTime;
    
    @try {
        FILE* pcm = fopen([filePath cStringUsingEncoding:1], "rb");
        fseek(pcm, 4*1024, SEEK_CUR);
        FILE* mp3 = fopen([outpath cStringUsingEncoding:1], "wb");
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        AudioStreamBasicDescription st = AEAudioStreamBasicDescriptionNonInterleavedFloatStereo;
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 22050);
//        lame_set_out_samplerate(lame, 11250);
//        lame_set_num_channels(lame,2);
//        lame_set_brate(lame, 16);
        lame_set_quality(lame, 2);
        
        lame_set_VBR(lame, vbr_default);
        int ret = lame_init_params(lame);
        if(ret < 0){
            return [self emitAudioError:RECORDER_COMPRESS_LAME_ERROR :@"转码库lame错误" ];
        }
        
        int read = 0;
        int write = 0;
        
        do{
            read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0){
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            }else{
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            }
            fwrite(mp3_buffer, write, 1, mp3);
        }while(read!=0);
        
        lame_close(lame);
        fclose(pcm);
        fclose(mp3);
    } @catch (NSException *exception) {
        return [self emitAudioError:RECORDER_COMPRESS_MP3_FAILED :@"转码Mp3失败"];
    }@finally{
        NSLog(@"转码完成 路径为:%@",outpath);
        [self emitAudioFinished:outpath :filePath :recordTimeLen :musicTimeLen];
    }
}


-(void)emitAudioError:(int)errCode :(NSString*)errMsg{
    if(_mRctAudioEngine){
        [_mRctAudioEngine emitRecordError:errCode :errMsg];
    }
}

-(void)emitAudioFinished:(NSString*)outPath :(NSString*)recordPath :(NSTimeInterval)recordLen :(NSTimeInterval)musicLen {
    if(_mRctAudioEngine){
        [_mRctAudioEngine emitRecordFinish:outPath :recordPath :recordLen :musicLen];
    }
}


-(void)emitAudioProgress:(NSTimeInterval)crt :(NSTimeInterval)cmt{
    if(_mRctAudioEngine){
        [_mRctAudioEngine emitRecorderTimeLength:crt:cmt];
    }
}

-(void)emitBgMusicInfo:(NSTimeInterval)length :(NSTimeInterval)currTime :(BOOL)isLoop{
    if(_mRctAudioEngine){
        [_mRctAudioEngine emitBackgoundMusicInfo:length :currTime :isLoop];
    }
}

-(void)emitAveragePower:(float)inputAvg :(float)outputAvg{
    if(_mRctAudioEngine){
        [_mRctAudioEngine emitRecorderDecibel:inputAvg :outputAvg];
    }
}

@end




