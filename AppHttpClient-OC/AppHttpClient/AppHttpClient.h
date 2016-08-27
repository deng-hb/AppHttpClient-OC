//
//  AppHttpClient.h
//  AppHttpClient-OC
//
//  Created by denghb on 16/8/27.
//  Copyright © 2016年 denghb. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AppHttpClient : NSObject

+ (void)get:(NSString *)url completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error)) handler;

+ (void)post:(NSString *)url parameters:(NSDictionary *)parameters completionHandler:(void (^)(NSData * data, NSURLResponse * response, NSError * error)) handler;

@end
