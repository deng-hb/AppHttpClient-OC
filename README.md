# AppHttpClient-OC

## 基于Objective-C

>#import "AppHttpClient.h"

### GET请求
```
AppHttpClient *clinet = [[AppHttpClient alloc]init];
[clinet get:@"https://denghb.com/" completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    NSString *body = [[NSString alloc]initWithData:data encoding:(NSUTF8StringEncoding)];
    NSLog(@"%@",body);
}];
```

### POST请求
```
NSDictionary *dict = @{@"amount":@"123"};

AppHttpClient *clinet = [[AppHttpClient alloc]init];
[clinet post:[NSString stringWithFormat:@"%@/post",_serverAddress] parameters:dict completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    NSString *body = [[NSString alloc]initWithData:data encoding:(NSUTF8StringEncoding)];
    NSLog(@"%@",body);
}];
```

### more 请查看demo



