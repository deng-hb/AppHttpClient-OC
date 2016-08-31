//
//  AppHttpClient.h
//  AppHttpClient-OC
//
//  Created by denghb on 16/8/27.
//  Copyright © 2016年 denghb. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kFileName;
extern NSString * const kFileData;
extern NSString * const kFilePath;// 与以上二选一，默认data

typedef void(^DownloadProgress)(double progress);

typedef void(^DownloadCompletion)(NSError * error);

@interface AppHttpClient : NSObject

/**
 * 发送GET请求
 *
 * @param url 服务器地址
 * @param handler 回调、返回值
 */
- (void)get:(NSString *) url completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error)) handler;

/**
 * 发送POST请求
 *
 * @param url 服务器地址
 * @param parameters
 *          普通提交，参数格式 @{@"username":@"denghb",@"password":@"123456"}
 *          上传文件，参数格式 @{@"file":@{KfileName:@"文件名",KfileData:文件二进制数据},@"file2":@{KfileName:@"文件名2",KfileData:文件二进制数据2}}
 *          一个字段上传多文件，参数格式 @{@"file":@[@{KfileName:@"文件名",KfileData:文件二进制数据},...]}
 * @param handler 回调、返回值
 */
- (void)post:(NSString *) url parameters:(NSDictionary *)parameters completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error)) handler;

/**
 *
 * 文件下载
 * TODO 暂停、断点续传
 *
 * @param url 文件地址
 * @param docPath 本地Documents下的地址及文件名字
 * @param progress 进度％
 * @param handler 回调、没有错误就是下载成功
 *
 */
- (void)download:(NSString *) url saveAs:(NSString *) docPath progress:(DownloadProgress) progress completionHandler:(DownloadCompletion) handler;

@end
