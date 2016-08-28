//
//  AppHttpClient.h
//  AppHttpClient-OC
//
//  Created by denghb on 16/8/27.
//  Copyright © 2016年 denghb. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const KfileName;
extern NSString * const KfileData;

typedef void(^DownloadProgress)(double progress);

typedef void(^DownloadCompletion)(NSError * error);

@interface AppHttpClient : NSObject

+ (void)get:(NSString *) url completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error)) handler;

+ (void)post:(NSString *) url parameters:(NSDictionary *)parameters completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error)) handler;

- (void)download:(NSString *) url saveAs:(NSString *) docPath progress:(DownloadProgress) progress completionHandler:(DownloadCompletion) handler;

@end
