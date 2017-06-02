//
//  MainViewController.m
//  MacArchiveTool
//
//  Created by LT-MacbookPro on 17/5/26.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import "MainViewController.h"
#import "DownloadViewController.h"
#include <sys/socket.h>
#include <sys/dirent.h>
#include <CFNetwork/CFNetwork.h>
#import <Foundation/NSStream.h>
#import "NetworkManager.h"
#import "DJProgressHUD.h"

@interface MainViewController ()<NSStreamDelegate>

@property (weak) IBOutlet NSTextField *userNameField;
@property (weak) IBOutlet NSTextField *passwordField;
@property (weak) IBOutlet NSButton *loginBtn;
@property (weak) IBOutlet NSTextField *hostField;

@end

@implementation MainViewController
@synthesize navigationController = _navigationController;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupField];
    
}

- (void)setupField{
   
    NSUserDefaults * user =  [NSUserDefaults standardUserDefaults];
    NSString * host = [user objectForKey:@"host"];
    NSString * userName = [user objectForKey:@"userName"];
    NSString * password = [user objectForKey:@"password"];
    
    if(self.hostField.stringValue != nil){
        self.hostField.stringValue = host;
    }
    if(self.userNameField.stringValue != nil){
    
        self.userNameField.stringValue = userName;
    }
    if(self.passwordField.stringValue != nil){
        self.passwordField.stringValue = password;
    }
}

//连接FTP
- (IBAction)clickLoginBtn:(NSButton *)sender {
    
    
    if(self.hostField.stringValue.length>0 && self.userNameField.stringValue.length>0 && self.passwordField.stringValue.length>0){
        
      
        [DJProgressHUD showStatus:@"连接FTP服务器" FromView:self.view];
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"ftp://%@/",self.hostField.stringValue]];
        NSInputStream * stream =  CFBridgingRelease(
                                                    CFReadStreamCreateWithFTPURL(NULL, (__bridge CFURLRef) url)
                                                    
                                                    );
        
        stream.delegate = self;
        [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [stream open];
        
        [stream setProperty:self.userNameField.stringValue forKey:(id)kCFStreamPropertyFTPUserName];
        [stream setProperty:self.passwordField.stringValue forKey:(id)kCFStreamPropertyFTPPassword];

        
    }else{
        
        NSAlert *alert = [NSAlert new];
        [alert addButtonWithTitle:@"确定"];
        [alert addButtonWithTitle:@"取消"];
        [alert setMessageText:@"提示"];
        [alert setInformativeText:@"主机地址，用户名或密码不能为空!"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
            if(returnCode == NSAlertFirstButtonReturn){
                NSLog(@"确定");
                [self dismissController:self];
            }else if(returnCode == NSAlertSecondButtonReturn){
                NSLog(@"删除");
            }
        }];
        
    }
    
}


#pragma mark - delegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{

    switch (eventCode) {
        case NSStreamEventOpenCompleted:
        {
            NSUserDefaults * user =  [NSUserDefaults standardUserDefaults];
            
            [user setObject:self.hostField.stringValue forKey:@"host"];
            [user setObject:self.userNameField.stringValue forKey:@"userName"];
            [user setObject:self.passwordField.stringValue forKey:@"password"];
            [user synchronize];
              [DJProgressHUD showStatus:@"连接FTP服务器成功" FromView:self.view];
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                 [DJProgressHUD dismiss];
                  DownloadViewController * downloadViewController = [[DownloadViewController alloc] init];
                  [self.navigationController pushViewController:downloadViewController animated:YES];
              });
            
        }
            break;
        case NSStreamEventErrorOccurred:
        {

                [DJProgressHUD showStatus:@"连接FTP服务器失败" FromView:self.view];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [DJProgressHUD dismiss];
                });
          
        }
            break;
        default:
            break;
    }
}

@end
