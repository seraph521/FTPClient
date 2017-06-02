//
//  ConfigModel.m
//  MacArchiveTool
//
//  Created by LT-MacbookPro on 17/5/24.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import "ConfigModel.h"

@implementation ConfigModel

+ (ConfigModel *)modelWithDic:(NSDictionary *) dic{
   
    //当前用户桌面地址
    NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
    NSString * desktopPath = [paths objectAtIndex:0];
    
    ConfigModel * model = [[ConfigModel alloc] init];
    model.Username = [dic objectForKey:@"Username"];
    model.Password = [dic objectForKey:@"Password"];
    model.NativeUsername = [dic objectForKey:@"NativeUsername"];
    model.NativePassword = [dic objectForKey:@"NativePassword"];
    model.FTPServicePath = [dic objectForKey:@"FTPServicePath"];
    model.DirRootPath = [dic objectForKey:@"DirRootPath"];
 // model.DownRootPath = [dic objectForKey:@"DownRootPath"];
    model.DownRootPath = [NSString stringWithFormat:@"%@/FTP_Download/",desktopPath];

    return model;
}

@end
