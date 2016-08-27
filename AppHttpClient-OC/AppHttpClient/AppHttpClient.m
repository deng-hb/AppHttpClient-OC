//
//  AppHttpClient.m
//  AppHttpClient-OC
//
//  Created by denghb on 16/8/27.
//  Copyright © 2016年 denghb. All rights reserved.
//

#import "AppHttpClient.h"

@implementation AppHttpClient

static AppHttpClient *_instance;

- (instancetype)init {
    @throw [NSException exceptionWithName:@"This is Singleton"
                                   reason:@"[AppHttpClient xxxx]"
                                 userInfo:nil];
    return nil;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super init];
    });
    return _instance;
}

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
    [request setValue:@"https://www.baidu.com/" forHTTPHeaderField:@"Referer"];
    // POST 请求
    if(method && [@"POST" isEqualToString:method]){
        request.HTTPMethod = @"POST";
        
        if(parameters){

            // 判断是有流参数
            BOOL isMultipart = NO;
            for (NSString *key in parameters) {
                id value = parameters[key];
                if([value isKindOfClass:[NSData class]] || [value isKindOfClass:[NSArray class]]){
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
                        for(NSData *data in array){
                            NSString *field = boundary;
                            field = [field stringByAppendingString:[NSString stringWithFormat:@"\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"",key, key]];
                            field = [field stringByAppendingString:[NSString stringWithFormat:@"\r\nContent-Type: application/octet-stream\r\nContent-Transfer-Encoding: binary\r\n\r\n"]];
                            
                            [bodyData appendData:[field dataUsingEncoding:NSUTF8StringEncoding]];
                            [bodyData appendData:data];
                            [bodyData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                        }
                        
                    }else if([value isKindOfClass:[NSData class]]){
                        // 单个文件
                        NSString *field = boundary;
                        field = [field stringByAppendingString:[NSString stringWithFormat:@"\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"",key, key]];
                        field = [field stringByAppendingString:[NSString stringWithFormat:@"\r\nContent-Type: application/octet-stream\r\nContent-Transfer-Encoding: binary\r\n\r\n"]];
                        
                        [bodyData appendData:[field dataUsingEncoding:NSUTF8StringEncoding]];
                        [bodyData appendData:(NSData *)value];
                        [bodyData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                        
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

@end
