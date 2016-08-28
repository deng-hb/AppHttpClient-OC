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
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _array = @[@"Method GET",@"Method POST",@"Upload",@"Uploads",@"Download"];
    
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

    switch (indexPath.row) {
        case 0:
        {
            AppHttpClient *clinet = [[AppHttpClient alloc]init];
            [clinet get:@"http://192.168.1.8:8090/" completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                
                NSString *res = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                NSError *err;
                NSLog(@"%@",res);
                // 转JSON
                [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&err];
                if (err) {
                    NSLog(@"JSON ERR:%@", [err localizedDescription]);
                }
            }];
            

            break;
        }
        case 1:
        {
            
            NSDictionary *dict = @{@"amount":@"123"};
            
            NSString *api = @"http://192.168.1.8:8090/post";
            AppHttpClient *clinet = [[AppHttpClient alloc]init];
            [clinet post:api parameters:dict completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSString *body = [[NSString alloc]initWithData:data encoding:(NSUTF8StringEncoding)];
                NSLog(@"%@",body);
                
                if(error){
                    NSLog(@"%@",error);
                }
            }];
            break;
        }
        case 2:
        {
            UIImage *image = [self grabScreenWithScale];
            NSData *data = UIImagePNGRepresentation(image);
            
            NSDictionary *dict = @{@"amount":@"123",@"images":@{KfileName:@"截屏",KfileData:data}};
            
            NSString *api = @"http://192.168.1.8:8090/upload";
            AppHttpClient *clinet = [[AppHttpClient alloc]init];
            [clinet post:api parameters:dict completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSString *body = [[NSString alloc]initWithData:data encoding:(NSUTF8StringEncoding)];
                NSLog(@"%@",body);
                
                if(error){
                    NSLog(@"%@",error);
                }
            }];
            break;
        }
        case 3:
        {
            UIImage *image = [self grabScreenWithScale];
            NSData *data = UIImagePNGRepresentation(image);
            
            NSDictionary *dict = @{@"amount":@"123",@"images":@[@{KfileName:@"截屏1",KfileData:data},@{KfileName:@"截屏2",KfileData:data}]};
            
            NSString *api = @"http://192.168.1.8:8090/upload";
            AppHttpClient *clinet = [[AppHttpClient alloc]init];
            [clinet post:api parameters:dict completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSString *body = [[NSString alloc]initWithData:data encoding:(NSUTF8StringEncoding)];
                NSLog(@"%@",body);
                
                if(error){
                    NSLog(@"%@",error);
                }
            }];
            break;
        }
        case 4:
        {
            AppHttpClient *clinet = [[AppHttpClient alloc]init];
            [clinet download:@"http://hbimg.b0.upaiyun.com/84194f2a3c400baea28c6e02e3a70c2918ad81d71327d-WBrvU5"
                      saveAs:@"images/1.jpg"
                    progress:^(double progress) {
                        NSLog(@"%2f",progress);
                    } completionHandler:^(NSError *error) {
                        
                        if(error){
                            NSLog(@"%@",error);
                        }else{
                            NSLog(@"download success");
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
