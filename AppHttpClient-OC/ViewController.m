//
//  ViewController.m
//  AppHttpClient-OC
//
//  Created by denghb on 16/8/27.
//  Copyright © 2016年 denghb. All rights reserved.
//

#define mScreenHeight         ([UIScreen mainScreen].bounds.size.height)
#define mScreenWidth          ([UIScreen mainScreen].bounds.size.width)

#import "ViewController.h"
#import "AppHttpClient.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    UITableView *_tableView;
    NSArray *_array;
    NSString *_serverAddress;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setTitle:@"Example"];
    _array = @[@"GET",@"POST",@"Upload",@"Uploads",@"Download"];
    
    _serverAddress = @"http://192.168.58.45:8090";
    
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, mScreenWidth, mScreenHeight)];
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
    [_tableView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:_tableView];
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if(!cell){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    [cell.textLabel setText:_array[indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"click %ld",(long)indexPath.row);
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *doc = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    
    __weak typeof(self) weakSelf = self;
    switch (indexPath.row) {
        case 0:
        {
            AppHttpClient *clinet = [[AppHttpClient alloc]init];
            [clinet get:[NSString stringWithFormat:@"%@/",_serverAddress] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if(error){
                    [weakSelf setTitle:[NSString stringWithFormat:@"GET %@",error.localizedDescription]];
                    NSLog(@"%@",error);
                }else{
                    [weakSelf setTitle:@"GET SUCCESS"];
                }
                
                NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
                
                if(200 == res.statusCode && nil != data){
                    
                    NSString *res = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                    NSError *err;
                    NSLog(@"%@",res);
                    // 转JSON
                    [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&err];
                    if (err) {
                        NSLog(@"JSON ERR:%@", [err localizedDescription]);
                    }
                }
            }];
            

            break;
        }
        case 1:
        {
            
            NSDictionary *dict = @{@"amount":@"123"};
            
            AppHttpClient *clinet = [[AppHttpClient alloc]init];
            [clinet post:[NSString stringWithFormat:@"%@/post",_serverAddress] parameters:dict completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSString *body = [[NSString alloc]initWithData:data encoding:(NSUTF8StringEncoding)];
                NSLog(@"%@",body);
                
                if(error){
                    [weakSelf setTitle:[NSString stringWithFormat:@"POST %@",error.localizedDescription]];
                    NSLog(@"%@",error);
                }else{
                    [weakSelf setTitle:@"POST SUCCESS"];
                }
            }];
            break;
        }
        case 2:
        {
            UIImage *image = [self grabScreenWithScale];
            NSData *data = UIImagePNGRepresentation(image);
            
            NSDictionary *dict = @{@"amount":@"123",@"images":@{kFileName:@"截屏",kFileData:data}};
            
            AppHttpClient *clinet = [[AppHttpClient alloc]init];
            [clinet post:[NSString stringWithFormat:@"%@/upload",_serverAddress] parameters:dict completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSString *body = [[NSString alloc]initWithData:data encoding:(NSUTF8StringEncoding)];
                NSLog(@"%@",body);
                
                if(error){
                    [weakSelf setTitle:[NSString stringWithFormat:@"Upload %@",error.localizedDescription]];
                    NSLog(@"%@",error);
                }else{
                    [weakSelf setTitle:@"Upload SUCCESS"];
                }
            }];
            break;
        }
        case 3:
        {
            UIImage *image = [self grabScreenWithScale];
            NSData *data = UIImagePNGRepresentation(image);
            
            NSDictionary *parameters = @{@"amount":@"123",@"images":@[@{kFileName:@"截屏1",kFileData:data},@{kFilePath:[NSString stringWithFormat:@"%@/images/1.png",doc]}]};
            
            AppHttpClient *clinet = [[AppHttpClient alloc]init];
            [clinet post:[NSString stringWithFormat:@"%@/upload",_serverAddress]
              parameters:parameters completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSString *body = [[NSString alloc]initWithData:data encoding:(NSUTF8StringEncoding)];
                NSLog(@"%@",body);
                
                if(error){
                    [weakSelf setTitle:[NSString stringWithFormat:@"Uploads %@",error.localizedDescription]];
                    NSLog(@"%@",error);
                }else{
                    [weakSelf setTitle:@"Uploads SUCCESS"];
                }
            }];
            break;
        }
        case 4:
        {
            NSLog(@"%@",doc);
            AppHttpClient *clinet = [[AppHttpClient alloc]init];
            [clinet download:[NSString stringWithFormat:@"%@/download",_serverAddress]
                      saveAs:@"images/1.png"
                    progress:^(double progress) {
                        NSLog(@"%@",[NSString stringWithFormat:@"Download %.2f%%",progress]);
                    } completionHandler:^(NSError *error) {
                        
                        if(error){
                            [weakSelf setTitle:[NSString stringWithFormat:@"Download %@",error.localizedDescription]];
                            NSLog(@"%@",error);
                        }else{
                            [weakSelf setTitle:@"Download SUCCESS"];
                        }
                    }];
        }
        default:
            break;
    }
    
}

- (UIImage *)grabScreenWithScale
{
    UIWindow *screenWindow = [[UIApplication sharedApplication] keyWindow];
    //    UIGraphicsBeginImageContext(screenWindow.frame.size);
    UIGraphicsBeginImageContextWithOptions(screenWindow.frame.size, YES, 1);
    [screenWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end
