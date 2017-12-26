//
//  DataDownLoadManager.m
//  BreakpointDownloadingDemo
//
//  Created by macmini on 2017/12/25.
//  Copyright © 2017年 macmini. All rights reserved.
//

#import "DataDownLoadManager.h"

@interface NSURLSessionDataTaskHelper : NSObject <NSURLSessionDataDelegate>

/**
 SessionDataTask对象
 */
@property (nonatomic,strong)NSURLSessionDataTask *task;
/**
 目标文件路径
 */
@property (nonatomic,strong)NSString *fileFullPath;

/**
 已下载文件大小
 */
@property (nonatomic,assign)NSInteger currentFileSize;

/**
 输出流
 */
@property (nonatomic,strong)NSOutputStream *outputStream;

/**
 文件总大小
 */
@property (nonatomic,assign)NSInteger fileTotalSize;

/**
 文件名称
 */
@property (nonatomic,readonly)NSString *fileName;

/**
 下载路径
 */
@property (nonatomic,readonly)NSString *url;
@property (nonatomic,weak) id<DownloadManagerDelegate> delegate;

/**
 下载完成回调
 */
@property (nonatomic, copy) void(^taskComplete)(id helper);
/**
 初始化下载对象

 @param url 下载链接
 @param fileName 文件名称
 @param delegate 协议对象
 @return 下载对象
 */
- (instancetype)initWithURLString:(NSString*)url  fileName:(NSString *)fileName delegate:(id)delegate;

/**
 开始下载
 */
-(void)startDownload;

/**
 取消下载（暂停）
 */
-(void)cancleDownload;

@end

@implementation NSURLSessionDataTaskHelper

- (instancetype)initWithURLString:(NSString*)url  fileName:(NSString *)fileName delegate:(id)delegate{
    self = [super init];
    if(self){
        self.delegate = delegate;
        _fileName = fileName;
        _url = url;
        
        [self initCurruntFielSize];
    }
    return self;
}

-(void)startDownload{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];

    NSString *range = [NSString stringWithFormat:@"bytes=%zd-",self.currentFileSize];
    configuration.HTTPAdditionalHeaders = @{@"Range" : range};
    configuration.timeoutIntervalForRequest = 30;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    self.task = [session dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_url]]];
    [self.task resume];
    [session finishTasksAndInvalidate];
}

-(void)cancleDownload{
    [self.task cancel];
}


/**
 设置文件已经下载的长度
 */
-(void)initCurruntFielSize{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    self.fileFullPath = [self downloadTempDestinationPathForFileName:_fileName];
    
    NSDictionary* attributes = [fileManager attributesOfItemAtPath:self.fileFullPath
                                                             error:nil];
    
    self.currentFileSize = [attributes[@"NSFileSize"] integerValue];
}

#pragma mark 文件路径

/**
 cache路径

 @return cache路径
 */
- (NSString *)cacheDirectory{
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory
                                                               , NSUserDomainMask
                                                               , YES) firstObject];
    return cachePath;
}


/**
 下载目标文件路径

 @param fileName 文件名称
 @return 下载目标文件路径
 */
- (NSString *)downloadDestinationPathForFileName:(NSString *)fileName {
    NSLog(@"%@",[[[self cacheDirectory] stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"jpg"]);
    return [[[self cacheDirectory] stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"jpg"];
}

/**
 下载临时数据路径

 @param fileName  文件名称
 @return  下载临时数据路径
 */
- (NSString *)downloadTempDestinationPathForFileName:(NSString *)fileName{
    //临时文件目录
    NSString *directory = [[self cacheDirectory]  stringByAppendingPathComponent:@"tmp"];
    if (![self isFileExist:directory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    //临时文件路径
    NSString *tmpFilePath = [[directory stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"tmp"];
    
    NSLog(@"%@",tmpFilePath);
    return tmpFilePath;
}


/**
 检测临时目录路径是否存在

 @param path 目录路径
 @return 是否存在
 */
- (BOOL)isFileExist:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    return [fileManager fileExistsAtPath:path isDirectory:&isDirectory] && !isDirectory;
}

#pragma mark - NSURLSessionDataDelegate 的代理方法
// 收到响应调用的代理方法
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:
(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    // 创建输出流，并打开流
    NSOutputStream *outputStream = [[NSOutputStream alloc] initToFileAtPath:self.fileFullPath append:YES];
    [outputStream open];
    self.outputStream = outputStream;
    
    self.fileTotalSize = response.expectedContentLength;
    
    completionHandler(NSURLSessionResponseAllow);
}

// 收到数据调用的代理方法
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    // 通过输出流写入数据
    [self.outputStream write:(uint8_t *)data.bytes maxLength:data.length];
    
    self.currentFileSize += data.length;
    
    if([self.delegate respondsToSelector:@selector(downloadProgress:progress:)]){
        [self.delegate  downloadProgress:self.fileName progress:self.currentFileSize * 1.0 / self.fileTotalSize];
    }
}

// 数据下载完成调用的方法
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if(!error){
        NSError *fileError;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *destination = [NSURL fileURLWithPath:[self downloadDestinationPathForFileName:_fileName]];
        NSURL *location = [NSURL fileURLWithPath:[self downloadTempDestinationPathForFileName:_fileName]];
        [fileManager removeItemAtURL:destination error:&fileError];
        [fileManager moveItemAtURL:location toURL:destination error:&fileError];
        
        [self.outputStream close];
        self.outputStream = nil;
    }
    
    if([self.delegate respondsToSelector:@selector(downloadComplete:error:)]){
        [self.delegate downloadComplete:self.fileName error:error];
    }
    self.taskComplete(self);
}
@end

@implementation DataDownLoadManager

+ (id)shareDataDownLoadManager
{
    static dispatch_once_t onceToken;
    static DataDownLoadManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[DataDownLoadManager alloc] init];
    });
    return manager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _taskQueue = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)startDownload:(NSString *)url fileName:(NSString *)fileName andDelegate:(id<DownloadManagerDelegate>)delegate{
    if([self isDownloaded:fileName]){
        [self setDownLoadedDelegateWithFileName:fileName delegate:delegate];
        return;
    }
    
    __block typeof (self)bself = self;
    
    //创建执行下载对象
    NSURLSessionDataTaskHelper *helper = [[NSURLSessionDataTaskHelper alloc] initWithURLString:url fileName:fileName delegate:delegate];
    
    [helper setTaskComplete:^(id task){
        @synchronized(bself->_taskQueue)
        {
            [bself->_taskQueue removeObject:task];
        };
    }];
    
    @synchronized(_taskQueue)
    {
        [_taskQueue addObject:helper];
    };
    
    //执行对象开始下载
    [helper startDownload];
    
    //开始下载回调
    if([delegate respondsToSelector:@selector(downloadStarted:)]){
        [delegate downloadStarted:fileName];
    }
    
}

- (void)cancelDownload:(NSString *)fileName{
    for (NSURLSessionDataTaskHelper *download in _taskQueue)
    {
        if ([download.fileName isEqual:fileName])
        {
            [download cancleDownload];
            break;
        }
    }
}

/**
 设置下载该文件的协议对象

 @param fileName 文件名
 @param delegate 遵守协议对象
 */
- (void)setDownLoadedDelegateWithFileName:(NSString *)fileName delegate:(id)delegate{
    for (NSURLSessionDataTaskHelper *download in _taskQueue)
    {
        if ([download.fileName isEqual:fileName])
        {
            download.delegate = delegate;
            break;
        }
    }
}

/**
 判断文件是否正在下载

 @param fileName 文件名
 @return 是否正在下载
 */
- (BOOL)isDownloaded:(NSString *)fileName{
    BOOL isDownloaded = NO;
    for(NSURLSessionDataTaskHelper *download in _taskQueue){
        if([download.fileName isEqualToString:fileName]){
            isDownloaded = YES;
            break;
        }
    }
    return isDownloaded;
}

- (NSString *)pathForFileName:(NSString *)fileName;{
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory
                                                               , NSUserDomainMask
                                                               , YES) firstObject];
    return [[cachePath stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"jpg"];
}

@end
