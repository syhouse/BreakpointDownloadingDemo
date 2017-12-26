//
//  ViewController.m
//  BreakpointDownloadingDemo
//
//  Created by macmini on 2017/12/25.
//  Copyright © 2017年 macmini. All rights reserved.
//

#import "ViewController.h"

#import "DataDownLoadManager.h"

#define kUrl @"http://c.hiphotos.baidu.com/zhidao/pic/item/c83d70cf3bc79f3da25bb440b8a1cd11728b2903.jpg"
#define kFileName @"test"

@interface ViewController ()<DownloadManagerDelegate>

@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setUI];
}

- (void)setUI{
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *startButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 100, 100, 30)];
    startButton.backgroundColor = [UIColor blueColor];
    [startButton setTitle:@"开始" forState:UIControlStateNormal];
    [startButton addTarget:self action:@selector(startDownLoad) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startButton];
    
    UIButton *puaseButton = [[UIButton alloc] initWithFrame:CGRectMake(200, 100, 100, 30)];
    puaseButton.backgroundColor = [UIColor blueColor];
    [puaseButton setTitle:@"暂停" forState:UIControlStateNormal];
    [puaseButton addTarget:self action:@selector(cancelDownLoad) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:puaseButton];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 200, 200, 200)];
    [self.view addSubview:self.imageView];
    
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(50, 150, 300, 20)];
    self.progressView.progress = 0;
    self.progressView.progressTintColor = [UIColor redColor];
    self.progressView.trackTintColor = [UIColor blueColor];
    [self.view addSubview:self.progressView];
}


- (void)cancelDownLoad{
    [[DataDownLoadManager shareDataDownLoadManager] cancelDownload:kFileName];
}

- (void)startDownLoad{
    [[DataDownLoadManager shareDataDownLoadManager] startDownload:kUrl fileName:kFileName andDelegate:self];
}

#pragma mark DownloadManagerDelegate;

- (void)downloadStarted:(NSString *)fileName{
    self.imageView.image = nil;
    self.progressView.progress = 0.0;
    NSLog(@"开始下载");
}

- (void)downloadComplete:(NSString *)fileName error:(NSError *)error{
    if(error){
        NSLog(@"%@",error);
    }
    else{
        NSLog(@"下载完成");
        NSString *path = [[DataDownLoadManager shareDataDownLoadManager] pathForFileName:fileName];
        self.imageView.image = [UIImage imageWithContentsOfFile:path];
    }
}

- (void)downloadProgress:(NSString *)fileName progress:(float)value{
    self.progressView.progress = value;
}



@end
