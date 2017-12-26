//
//  DataDownLoadManager.h
//  BreakpointDownloadingDemo
//
//  Created by macmini on 2017/12/25.
//  Copyright © 2017年 macmini. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DownloadManagerDelegate <NSObject>

/**
 开始下载回调

 @param fileName 下载文件名称
 */
- (void)downloadStarted:(NSString *)fileName;

/**
 完成下载回调

 @param fileName 下载文件名称
 @param error 下载成功或者失败错误信息
 */
- (void)downloadComplete:(NSString *)fileName error:(NSError *)error;

/**
 下载进度回调

 @param fileName 下载文件名称
 @param value 文件下载进度
 */
- (void)downloadProgress:(NSString *)fileName progress:(float)value;

@end

@interface DataDownLoadManager : NSObject

/**
 下载任务线程池
 */
@property(nonatomic,readonly)NSMutableArray *taskQueue;

+ (id)shareDataDownLoadManager;

/**
 开始下载

 @param url 下载路径
 @param fileName 文件名
 @param delegate 遵守协议对象
 */
- (void)startDownload:(NSString *)url fileName:(NSString *)fileName andDelegate:(id<DownloadManagerDelegate>)delegate;

/**
 取消下载（暂停）

 @param fileName 文件名
 */
- (void)cancelDownload:(NSString *)fileName;

/**
 下载文件保存路径（判断文件是否已下载）

 @param fileName 文件名
 @return 文件路径
 */
- (NSString *)pathForFileName:(NSString *)fileName;
@end
