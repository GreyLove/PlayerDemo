//
//  WJMoviePlayerView.m
//  WJMoviePlayer
//
//  Created by 王杰 on 2018/9/15.
//  Copyright © 2018年 王杰. All rights reserved.
//  https://github.com/wangjiegit/WJMoviePlayer

#import "WJMoviePlayerView.h"
#import "UIView+SimAdditions.h"

@interface WJMoviePlayerView()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) WJPlayerView *playerView;//用来手势关闭的

@property (nonatomic, strong) UIImageView *transitionView;//做专场动画

@property (nonatomic, strong) WJProgressView *progressView;

@property (nonatomic, strong) NSURLSessionTask *task;

@property (nonatomic, copy) NSURL *playerURL;



@end

@implementation WJMoviePlayerView

//展示
- (void)show {
    if (self.movieURL.path.length == 0) {
        [WJMovieHUD showWithMessage:@"视频播放地址不存在"];
        return;
    }
    [self setupUI];
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [UIView animateWithDuration:0.25 animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1];
        self.transitionView.frame = self.bounds;
    } completion:^(BOOL finished) {
        [self prepareMovie];
    }];
}

- (void)setupUI {
    self.frame = [UIScreen mainScreen].bounds;
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    [self addSubview:self.transitionView];
    [self addSubview:self.playerView];
}

//判断视频地址是本地的还是网络的
- (void)prepareMovie {
    if ([self.movieURL.scheme isEqualToString:@"file"]) {//本地视频
        self.playerURL = self.movieURL;
        self.playerView.URL = self.playerURL;
    } else {
        [self insertSubview:self.progressView aboveSubview:self.transitionView];
        [self loadData];
    }
}

//移动当前视频
- (void)movePanGestureRecognizer:(UIPanGestureRecognizer *)pgr {
    if (pgr.state == UIGestureRecognizerStateBegan) {
        [self.playerView pause];
        self.progressView.hidden = YES;
    } else if (pgr.state == UIGestureRecognizerStateChanged) {
        CGPoint location = [pgr locationInView:pgr.view.superview];
        CGPoint point = [pgr translationInView:pgr.view];
        CGRect rect = pgr.view.frame;
        CGFloat height = rect.size.height - point.y;
        CGFloat width = rect.size.width * height / rect.size.height;
        CGFloat y = rect.origin.y + 1.5 * point.y;
        CGFloat x = location.x * (rect.size.width - width) / pgr.view.superview.frame.size.width + point.x + rect.origin.x;
        if (rect.origin.y < 0) {
            height = pgr.view.superview.frame.size.height;
            width = pgr.view.superview.frame.size.width;
            y = rect.origin.y + point.y;
            x = rect.origin.x + point.x;
        }
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:(pgr.view.superview.frame.size.height / 1.5 - y) /  (pgr.view.superview.frame.size.height / 1.5)];
        pgr.view.frame = CGRectMake(x, y, width, height);
        self.transitionView.frame = pgr.view.frame;
        [pgr setTranslation:CGPointZero inView:pgr.view];
    } else if (pgr.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [pgr velocityInView:pgr.view];
        if (velocity.y > 500 && pgr.view.frame.origin.y > 0) {
            [self closeMoviePlayerView];
        } else {
            [UIView animateWithDuration:0.25 animations:^{
                self.backgroundColor = [UIColor blackColor];
                pgr.view.frame = self.bounds;
                self.transitionView.frame = self.bounds;
            } completion:^(BOOL finished) {
                [self.playerView play];
                self.progressView.hidden = NO;
            }];
        }
    } else {
        [self closeMoviePlayerView];
    }
}

//点击关闭
- (void)closeTgrGestureRecognizer:(UITapGestureRecognizer *)tgr {
    [self closeMoviePlayerView];
}

//监听视频是否已经准备好
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    [self.playerView play];
    self.transitionView.hidden = YES;
}

//关闭视频播放
- (void)closeMoviePlayerView {
    [self.task cancel];
    [self.playerView pause];
    UIImage *image = [self getMovieCurrentImage];
    if (image) {
        self.transitionView.image = image;
        self.transitionView.frame = [self convertRect:((AVPlayerLayer *)self.playerView.layer).videoRect fromView:self.playerView];
    }
    self.transitionView.hidden = NO;
    self.playerView.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        self.transitionView.frame =  [self.coverView convertRect:self.coverView.bounds toView:nil];
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    } completion:^(BOOL finished) {
        self.transitionView.hidden = YES;
        [self removeFromSuperview];
    }];
}

- (void)dealloc {
    if (_playerView) [_playerView.layer removeObserver:self forKeyPath:@"readyForDisplay"];
}

#pragma mark UIGestureRecognizerDelegate
//下拉才能出发手势
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) return YES;
    UIPanGestureRecognizer *pgr = (UIPanGestureRecognizer *)gestureRecognizer;
    CGPoint point = [pgr translationInView:pgr.view];
    if (point.y > 0) return YES;
    return NO;
}

//获取当前帧画面
- (UIImage *)getMovieCurrentImage {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self.playerURL options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime now = [self.playerView currentTime];
    [gen setRequestedTimeToleranceAfter:kCMTimeZero];
    [gen setRequestedTimeToleranceBefore:kCMTimeZero];
    CGImageRef image = [gen copyCGImageAtTime:now actualTime:NULL error:NULL];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    if (image) CFRelease(image);
    return thumb;
}

#pragma mark loadData

- (void)loadData {
   self.task = [[WJMovieDownLoadManager shareManager] downloadMovieWithURL:self.movieURL progressBlock:^(CGFloat progress) {
        self.progressView.progress = progress;
    } success:^(NSURL *URL) {
        [self.progressView removeFromSuperview];
        self.playerURL = URL;
        self.playerView.URL = self.playerURL;
    } fail:^(NSString *message) {
        [self.progressView removeFromSuperview];
        [WJMovieHUD showWithMessage:message];
    }];
}

#pragma mark Getter

- (WJProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[WJProgressView alloc] init];
        _progressView.frame = self.bounds;
    }
    return _progressView;
}

- (UIView *)playerView {
    if (!_playerView) {
        _playerView = [[WJPlayerView alloc] initWithFrame:self.bounds];
        _playerView.backgroundColor = [UIColor clearColor];
        [_playerView.layer addObserver:self forKeyPath:@"readyForDisplay" options:NSKeyValueObservingOptionNew context:nil];
        UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(movePanGestureRecognizer:)];
        pgr.delegate = self;
        [_playerView addGestureRecognizer:pgr];
//        UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeTgrGestureRecognizer:)];
//        [_playerView addGestureRecognizer:tgr];
        __weak typeof(self) weakSelf = self;
        _playerView.close = ^{
            [weakSelf closeMoviePlayerView];
        };
    }
    return _playerView;
}

- (UIImageView *)transitionView {
    if (!_transitionView) {
        _transitionView = [[UIImageView alloc] init];
        _transitionView.frame = [self.coverView convertRect:self.coverView.bounds toView:nil];
        _transitionView.contentMode = UIViewContentModeScaleAspectFit;
        _transitionView.image = self.coverView.image;
    }
    return _transitionView;
}

@end

@interface WJPlayerView()


@property (nonatomic,strong) AVPlayerItem *playerItem;
@property (nonatomic,strong) UILabel *currentTimeLab;       //当前时间
@property (nonatomic,strong) UILabel *durationLab;          //总时间
@property (nonatomic,strong) UIButton *playBtn;             // 播放
@property (nonatomic,strong) UISlider *slider;

@property (nonatomic,strong) UIView *bottomView;

@property (nonatomic, copy) UIButton *closeBtn;

@property (nonatomic,assign) BOOL  isDrag;
@end

@implementation WJPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}

- (void)setURL:(NSURL *)URL {
    if (_URL != URL) {
        _URL = URL;
        _playerItem = [[AVPlayerItem alloc] initWithURL:URL];
        
        [_playerItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew) context:nil]; // 观察status属性， 一共有三种属性
        
        [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil]; // 观察缓冲进度
        
        [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        
        [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
        ((AVPlayerLayer *)self.layer).player = [AVPlayer playerWithPlayerItem:_playerItem];
        
        __weak typeof(self) weakSelf = self;
        CMTime interval = CMTimeGetSeconds(_playerItem.asset.duration) > 60 ? CMTimeMake(1, 1) : CMTimeMake(1, 30);

        NSInteger totleTime = CMTimeGetSeconds(self.playerItem.asset.duration);
        self.durationLab.text = [self transfromTime:totleTime];

        [((AVPlayerLayer *)self.layer).player addPeriodicTimeObserverForInterval:interval queue:nil usingBlock:^(CMTime time) {

            __strong typeof(self) strongSelf = weakSelf;

            NSInteger currentTime = CMTimeGetSeconds(time);

            NSLog(@"%f",CMTimeGetSeconds(time) / CMTimeGetSeconds(strongSelf.playerItem.asset.duration));

            CGFloat playProgress = CMTimeGetSeconds(time) / CMTimeGetSeconds(strongSelf.playerItem.asset.duration);
            if (!strongSelf.isDrag) {
                strongSelf.slider.value = playProgress;
            }

            strongSelf.currentTimeLab.text = [strongSelf transfromTime:currentTime];
        }];
    }
}

- (NSString*)transfromTime:(NSInteger)time{
    if (time <= 0) {
        return @"00:00";
    }else if (time > 60*60){
        return @"--:--";
    }else{
        NSInteger min = time/60;
        NSInteger sec = time%60;
        
        NSString *minStr = min<10?[NSString stringWithFormat:@"0%ld",min]:[NSString stringWithFormat:@"%ld",min];
        
        NSString *secStr = sec<10?[NSString stringWithFormat:@"0%ld",sec]:[NSString stringWithFormat:@"%ld",sec];
        
        return [NSString stringWithFormat:@"%@:%@",minStr,secStr];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([object isKindOfClass:[AVPlayerItem class]]) {
        if ([keyPath isEqualToString:@"status"]) {
            switch (_playerItem.status) {
                case AVPlayerItemStatusReadyToPlay:
                    [((AVPlayerLayer *)self.layer).player play];
                    break;
                    
                case AVPlayerItemStatusUnknown:
                    NSLog(@"AVPlayerItemStatusUnknown");
                    break;
                    
                case AVPlayerItemStatusFailed:
                    NSLog(@"AVPlayerItemStatusFailed");
                    break;
                    
                default:
                    break;
            }
            
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array = _playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        NSLog(@"当前缓冲时间：%f",totalBuffer);
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        
        //some code show loading
    }if([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        //由于 AVPlayer 缓存不足就会自动暂停，所以缓存充足了需要手动播放，才能继续播放
        [((AVPlayerLayer *)self.layer).player play];
    }
}

- (void)play {
    [((AVPlayerLayer *)self.layer).player play];
}

- (void)pause {
    [((AVPlayerLayer *)self.layer).player pause];
}

- (CMTime)currentTime {
    return [((AVPlayerLayer *)self.layer).player currentTime];
}

//播放结束 执行重复播放
- (void)playerItemDidPlayToEnd {
    [((AVPlayerLayer *)self.layer).player seekToTime:kCMTimeZero];
    [((AVPlayerLayer *)self.layer).player play];
}

- (void)removeObserver{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

- (void)dealloc {
    [self removeObserver];
}

//播放 暂停
- (void)play:(UIButton*)btn{
    if (btn.selected) {//暂停
        btn.selected = NO;
        [self play];
    } else {//播放
        btn.selected = YES;
        [self pause];
    }
}


- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.closeBtn.frame = CGRectMake(0, 0, 58, 58);
    
    self.bottomView.frame =  CGRectMake(0, CGRectGetHeight(self.frame)-60, CGRectGetWidth(self.frame), 60);
    
    self.playBtn.frame = CGRectMake(10, 0, 30, 30);
    self.playBtn.centerY = self.bottomView.height/2;
    
    self.currentTimeLab.frame = CGRectMake(self.playBtn.right+5, 0, 40, 20);
    self.currentTimeLab.centerY = self.playBtn.centerY;
    
    self.durationLab.frame = CGRectMake(0, 0, 40, 20);
    self.durationLab.centerY = self.playBtn.centerY;
    self.durationLab.right = self.bottomView.width-10;
    
    
    self.slider.frame = CGRectMake(self.currentTimeLab.right+5, 0, 10, 10);
    self.slider.width = self.durationLab.left - 5 - (self.currentTimeLab.right+5);
    self.slider.centerY = self.playBtn.centerY;
}


- (UIButton *)closeBtn{
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeBtn.backgroundColor  =[UIColor clearColor];
        [_closeBtn setImage:[UIImage imageNamed:@"icon_fs_video_close"] forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(closeVideo) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_closeBtn];
    }
    return _closeBtn;
}

- (void)closeVideo{
    if (self.close) {
        self.close();
    }
}


- (UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.userInteractionEnabled = YES;
        _bottomView.backgroundColor = [UIColor clearColor];
        [self addSubview:_bottomView];
    }
    return _bottomView;
}

//播放暂停
- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playBtn.backgroundColor  =[UIColor blackColor];
        _playBtn.selected = NO;
        _playBtn.enabled = YES;
        [_playBtn setImage:[UIImage imageNamed:@"icon_fs_video_play"] forState:UIControlStateNormal];
        [_playBtn setImage:[UIImage imageNamed:@"icon_fs_video_pause"] forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomView addSubview:_playBtn];
    }
    return _playBtn;
}

//当前时长
- (UILabel *)currentTimeLab {
    if (!_currentTimeLab) {
        _currentTimeLab = [[UILabel alloc] init];
        _currentTimeLab.text = @"00:00";
        _currentTimeLab.backgroundColor = [UIColor clearColor];
        _currentTimeLab.font = [UIFont systemFontOfSize:13];
        _currentTimeLab.textColor = [UIColor whiteColor];
        _currentTimeLab.textAlignment = NSTextAlignmentRight;
        [self.bottomView addSubview:_currentTimeLab];
    }
    return _currentTimeLab;
}

//总时长
- (UILabel *)durationLab {
    if (!_durationLab) {
        _durationLab = [[UILabel alloc] init];
        _durationLab.text = @"00:00";
        _durationLab.backgroundColor = [UIColor clearColor];
        _durationLab.font = [UIFont systemFontOfSize:13];
        _durationLab.textAlignment = NSTextAlignmentRight;
        _durationLab.textColor = [UIColor whiteColor];
        [self.bottomView addSubview:_durationLab];
    }
    return _durationLab;
}

- (UISlider *)slider{
    if (!_slider) {
        _slider = [[UISlider alloc] init];
        [_slider addTarget:self action:@selector(avSliderAction) forControlEvents:
         UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchUpOutside|UIControlEventTouchDragInside];
        [self.bottomView addSubview:_slider];
        [_slider setThumbImage:[UIImage imageNamed:@"icon_fs_video_dian@2x"] forState:UIControlStateNormal];
    }return _slider;
    
}

- (void)avSliderAction{
    _isDrag = YES;
    float totleTime = CMTimeGetSeconds(self.playerItem.asset.duration);
    float seconds = self.slider.value * totleTime;

    [self pause];
    
    __weak typeof(self) weakSelf = self;

    CMTime startTime = CMTimeMakeWithSeconds(seconds, _playerItem.currentTime.timescale);
    [((AVPlayerLayer *)self.layer).player seekToTime:startTime completionHandler:^(BOOL finished) {
        __strong typeof(self) strongSelf = weakSelf;

        if (finished) {
            [self play];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                strongSelf.isDrag = NO;
            });
        }
    }];
}
@end

//===================================================================================
//下载管理 只支持单个视频下载

@interface WJMovieDownLoadManager()<NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, copy) void(^success)(NSURL *URL);

@property (nonatomic, copy) void(^fail)(NSString *message);

@property (nonatomic, copy) void(^progressBlock)(CGFloat progress);

@end

@implementation WJMovieDownLoadManager

+ (instancetype)shareManager {
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:queue];
    }
    return self;
}

- (NSURLSessionDownloadTask *)downloadMovieWithURL:(NSURL *)URL
                                     progressBlock:(void(^)(CGFloat progress))progressBlock
                                           success:(void(^)(NSURL *URL))success
                                              fail:(void(^)(NSString *message))fail {
    self.progressBlock = progressBlock;
    self.success = success;
    self.fail = fail;
    NSString *name = [[NSFileManager defaultManager] displayNameAtPath:URL.path];
    NSString *filePath = [[[self class] filePath] stringByAppendingPathComponent:name];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if (fileExists) {
        if (self.success) self.success([NSURL fileURLWithPath:filePath]);
        [self clearAllBlock];
        return nil;
    }
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:URL];
    [task resume];
    return task;
}

- (void)clearAllBlock {
    self.success = nil;
    self.fail = nil;
    self.progressBlock = nil;
}

#pragma mark NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    NSString *name = [[NSFileManager defaultManager] displayNameAtPath:downloadTask.currentRequest.URL.path];
    NSString *filePath = [[[self class] filePath] stringByAppendingPathComponent:name];
    [[NSFileManager defaultManager] moveItemAtPath:location.path toPath:filePath error:nil];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.progressBlock) self.progressBlock(totalBytesWritten * 1.0 / totalBytesExpectedToWrite);
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    NSString *name = [[NSFileManager defaultManager] displayNameAtPath:task.currentRequest.URL.path];
    NSString *filePath = [[[self class] filePath] stringByAppendingPathComponent:name];
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isExists) {
            if (self.success) self.success([NSURL fileURLWithPath:filePath]);
        } else {
            if (error.code != NSURLErrorCancelled && self.fail) self.fail(@"下载失败");
        }
        [self clearAllBlock];
    });
}

#pragma mark 文件管理
+ (NSString *)filePath {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *filePath = [path stringByAppendingPathComponent:@"wj_movie_file"];
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if (!isExists) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return filePath;
}

+ (CGFloat)fileSize {
    unsigned long long  size = 0;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *filePath = [self filePath];
    NSDictionary *attributes = [manager attributesOfItemAtPath:filePath error:nil];
    if (attributes.fileType == NSFileTypeDirectory) {
         NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:filePath];
        for (NSString *subPath in enumerator) {
            NSString *fullSubPath = [filePath stringByAppendingPathComponent:subPath];
            size += [manager attributesOfItemAtPath:fullSubPath error:nil].fileSize;
        }
    }
    return size / 1024.0 / 1024.0;
}

+ (void)clearDisk {
    [[NSFileManager defaultManager] removeItemAtPath:[self filePath] error:nil];
}

@end

//===================================================================================
//下载进度条

@implementation WJProgressView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.radius = 20;
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [[UIColor colorWithWhite:0 alpha:0.1] set];
    UIBezierPath *bgPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0) radius:self.radius startAngle:-M_PI_2 endAngle:2 * M_PI - M_PI_2  clockwise:YES];
    [bgPath fill];
    
    [[UIColor colorWithWhite:1 alpha:0.9] set];
    [bgPath addArcWithCenter:CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0) radius:self.radius startAngle:-M_PI_2 endAngle:2 * M_PI - M_PI_2  clockwise:YES];
    [bgPath stroke];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0) radius:self.radius - 2 startAngle:-M_PI_2 endAngle:self.progress * 2 * M_PI - M_PI_2  clockwise:YES];
    [path addLineToPoint:CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0)];
    [path fill];
}

@end

//===================================================================================
//播放失败提示
@implementation WJMovieHUD {
    UILabel *label;
}

- (instancetype)initWithMessage:(NSString *)message {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:15];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = message;
        label.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        label.layer.cornerRadius = 6;
        label.layer.masksToBounds = YES;
        [self addSubview:label];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    label.frame = CGRectMake(20, (self.frame.size.height - 60) / 2.0, self.frame.size.width - 40, 60);
}

+ (void)showWithMessage:(NSString *)message {
    if (message.length == 0) return;
    WJMovieHUD *hud = [[WJMovieHUD alloc] initWithMessage:message];
    hud.backgroundColor = [UIColor clearColor];
    hud.frame = [UIScreen mainScreen].bounds;
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [hud removeFromSuperview];
    });
}

@end

