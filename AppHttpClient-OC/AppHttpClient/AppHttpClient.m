//
//  AppHttpClient.m
//  AppHttpClient-OC
//
//  Created by denghb on 16/8/27.
//  Copyright © 2016年 denghb. All rights reserved.
//

#import "AppHttpClient.h"

NSString * const KfileName = @"file_name";
NSString * const KfileData = @"file_data";

@interface AppHttpClient ()<NSURLSessionDownloadDelegate>
{
    NSString *_docPath;
    DownloadProgress _downloadProgress;
    DownloadCompletion _downloadCompletion;
}
@end

@implementation AppHttpClient

/**
 * 暂时只支持GET、POST
 */
- (NSMutableURLRequest *)requestWithUrl:(NSString *)urlString parameters:(NSDictionary *)parameters method:(NSString *)method
{
    NSAssert(nil != urlString, @"url not nil");
    // 编码
    NSString *urlEncode = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:urlEncode]];
    [request setTimeoutInterval:30*10000];// 请求超时时长
    
    
    [request setValue:@"denghb" forHTTPHeaderField:@"User-Agent"];// TODO 可自定义
    [request setValue:@"denghb" forHTTPHeaderField:@"Xxx"];// TODO 可自定义
    [request setValue:@"https://huaban.com/" forHTTPHeaderField:@"Referer"];
    // POST 请求
    if(method && [@"POST" isEqualToString:method]){
        request.HTTPMethod = @"POST";
        
        if(parameters){

            // 判断是有流参数
            BOOL isMultipart = NO;
            for (NSString *key in parameters) {
                id value = parameters[key];
                if([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]){
                    isMultipart = YES;
                    break;
                }
            }
            
            if(isMultipart){
                
                NSMutableData *bodyData = [[NSMutableData alloc]initWithData:[request HTTPBody]];
                
                NSString *boundary = @"AppHttpClinet-denghb-com";
                [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
                boundary = [NSString stringWithFormat:@"--%@",boundary];
                
                for (NSString *key in parameters) {
                    id value = parameters[key];
                    // 数组多个文件
                    if([value isKindOfClass:[NSArray class]]){
                        // 循环
                        NSArray *array = (NSArray *)value;
                        for(NSDictionary *dict in array){
                            [self fileAppendWith:dict bodyData:bodyData boundary:boundary name:key];
                        }
                        
                    }else if([value isKindOfClass:[NSDictionary class]]){
                        [self fileAppendWith:(NSDictionary *)value bodyData:bodyData boundary:boundary name:key];
                    }else{
                        // 普通文本
                        NSString *field = boundary;
                        field = [field stringByAppendingString:[NSString stringWithFormat:@"\r\nContent-Disposition: form-data; name=\"%@\";",key]];
                        field = [field stringByAppendingString:[NSString stringWithFormat:@"\r\nContent-Type: text/plain; charset=UTF-8\r\nContent-Transfer-Encoding: 8bit\r\n\r\n"]];
                        
                        [bodyData appendData:[field dataUsingEncoding:NSUTF8StringEncoding]];
                        [bodyData appendData:[[NSString stringWithFormat:@"%@\r\n",nil == value?@"":value] dataUsingEncoding:NSUTF8StringEncoding]];
                    }
                }
                
                // 结尾
                [bodyData appendData:[[NSString stringWithFormat:@"%@--",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [request setHTTPBody:bodyData];
                

            }else{
                // 普通表单
                NSString *bodyStr = @"";
                for (NSString *key in parameters) {
                    id value = parameters[key];
                    bodyStr = [bodyStr stringByAppendingString:[NSString stringWithFormat:@"%@=%@&",key,value]];
                }
                
                [request setHTTPBody:[bodyStr dataUsingEncoding:NSUTF8StringEncoding]];
                [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            }
            
        }
    }
    
    return request;
}

/**
 * 文件流拼接
 */
- (void)fileAppendWith:(NSDictionary *)dict bodyData:(NSMutableData *) bodyData boundary:(NSString *) boundary name:(NSString *)name
{
    
    NSData *filedata = dict[KfileData];
    NSAssert(nil != filedata, @"file data not nil");
    NSString *filename = dict[KfileName];
    NSAssert(nil != filename, @"file name not nil");
    
    // 单个文件
    NSString *field = boundary;
    field = [field stringByAppendingString:[NSString stringWithFormat:@"\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"",name, filename]];
    field = [field stringByAppendingString:[NSString stringWithFormat:@"\r\nContent-Type: application/octet-stream\r\nContent-Transfer-Encoding: binary\r\n\r\n"]];
    
    [bodyData appendData:[field dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:filedata];
    [bodyData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)get:(NSString *)url completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error)) handler;
{
    
    NSMutableURLRequest *request = [self requestWithUrl:url parameters:nil method:@"GET"];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:handler];
    [task resume];
}

- (void)post:(NSString *)url parameters:(NSDictionary *)parameters completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error)) handler;
{
    NSMutableURLRequest *request = [self requestWithUrl:url parameters:parameters method:@"POST"];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:handler];
    
    [task resume];
}


- (void)download:(NSString *) url saveAs:(NSString *) docPath progress:(DownloadProgress) progress completionHandler:(DownloadCompletion) handler
{
    NSAssert(nil != docPath, @"docPath not nil");

    _docPath = docPath;
    _downloadProgress = progress;
    _downloadCompletion = handler;
    
    NSMutableURLRequest *request = [self requestWithUrl:url parameters:nil method:@"GET"];
    
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"AppHttpClinet-download"];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request];

    [task resume];
}


#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    
    // app 目录
    NSString *doc = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;

    // 另存下载来的文件
    NSString *path = [doc stringByAppendingPathComponent:_docPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 判断文件夹是否存在，如果不存在，则创建
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    // 存在文件就删除
    if([fileManager fileExistsAtPath:path]){
        [fileManager removeItemAtPath:path error:nil];
    }
    
    // 移动至指定目录
    [fileManager moveItemAtPath:location.path toPath:path error:nil];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    // 下载中
    if(_downloadProgress){
        _downloadProgress(totalBytesWritten*100.0/totalBytesExpectedToWrite);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    // 下载完成
    if(_downloadCompletion){
        _downloadCompletion(error);
    }
}

@end
