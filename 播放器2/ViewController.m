//
//  ViewController.m
//  播放器2
//
//  Created by gl on 2018/10/24.
//  Copyright © 2018年 gl. All rights reserved.
//

#import "ViewController.h"
#import "WJMoviePlayerView.h"

@interface ViewController ()
@property (nonatomic, strong) UIImageView *imgView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self playLocalMovie];
//    });
    
    self.imgView = [[UIImageView alloc] init];
    self.imgView.frame = CGRectMake(10, 0, self.view.frame.size.width - 20, 200);
    self.imgView.backgroundColor = [UIColor lightGrayColor];
    self.imgView.contentMode = UIViewContentModeScaleAspectFill;
    self.imgView.userInteractionEnabled = YES;
    self.imgView.clipsToBounds = YES;
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playLocalMovie)];
    [self.imgView addGestureRecognizer:tgr];
    [self.view addSubview:self.imgView];
}

//播放视频
- (void)playLocalMovie {
    NSString *path = @"http://qukufile2.qianqian.com/data2/video/597847057/84d570444d8e6cbfa6ddb77a728adb5d/597847057.mp4";
    WJMoviePlayerView *playerView = [[WJMoviePlayerView alloc] init];
    playerView.movieURL = [NSURL URLWithString:path];
    playerView.coverView = self.imgView;
    [playerView show];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
