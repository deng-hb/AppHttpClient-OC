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
    DownloadProgress _downloadProgress;
    DownloadCompletion _downloadCompletion;
}
@end

@implementation AppHttpClient

+ (NSURLSession *)urlSession
{
    
    NSURLSession *urlSession = [NSURLSession sharedSession];
    if (!urlSession) {
        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        // TODO
        // 设置超时时长
        cfg.timeoutIntervalForRequest = 10;
        // 是否允许使用蜂窝网络（手机自带网络）
        cfg.allowsCellularAccess = YES;
        urlSession = [NSURLSession sessionWithConfiguration:cfg];
    }
    return urlSession;
}

/**
 * 暂时只支持GET、POST   多线程下有问题
 */
+ (NSMutableURLRequest *)requestWithUrl:(NSString *)urlString parameters:(NSDictionary *)parameters method:(NSString *)method
{
    // 编码
    NSString *urlEncode = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlEncode];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:url];
    
    [request setValue:@"denghb" forHTTPHeaderField:@"User-Agent"];// TODO 可自定义
    [request setValue:@"denghb" forHTTPHeaderField:@"Xxx"];// TODO 可自定义
    [request setValue:@"https://denghb.com/" forHTTPHeaderField:@"Referer"];
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
+ (void)fileAppendWith:(NSDictionary *)dict bodyData:(NSMutableData *) bodyData boundary:(NSString *) boundary name:(NSString *)name
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

+ (void)get:(NSString *)url completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error)) handler;
{
    
    NSMutableURLRequest *request = [self requestWithUrl:url parameters:nil method:@"GET"];
    NSURLSession *urlSession = [self urlSession];
    __block NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:request completionHandler:handler];
    [task resume];
}

+ (void)post:(NSString *)url parameters:(NSDictionary *)parameters completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error)) handler;
{
    NSMutableURLRequest *request = [self requestWithUrl:url parameters:parameters method:@"POST"];
    NSURLSession *urlSession = [self urlSession];
    __block NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:request completionHandler:handler];
    
    [task resume];
}


- (void)download:(NSString *) url saveAs:(NSString *) docPath progress:(DownloadProgress) progress completionHandler:(DownloadCompletion) handler
{
    _downloadProgress = progress;
    _downloadCompletion = handler;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    __block NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        // 报错就返回
        if(error){
            handler(error);
        }
    }];
    
    [task resume];
}


#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    
}
@end
