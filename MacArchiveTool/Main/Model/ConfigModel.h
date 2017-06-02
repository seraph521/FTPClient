//
//  ConfigModel.h
//  MacArchiveTool
//
//  Created by LT-MacbookPro on 17/5/24.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConfigModel : NSObject

@property (nonatomic,copy) NSString * Username;//FTP账号名

@property (nonatomic,copy) NSString * Password;//FTP密码

@property (nonatomic,copy) NSString * FTPServicePath;//远程FTP地址也可是Mac本地FTP地址

@property (nonatomic,copy) NSString * DirRootPath;//本地文件夹路径

@property (nonatomic,copy) NSString * DownRootPath;//文件下载到本地路径

@property (nonatomic,copy) NSString * NativeUsername;//创建文件夹在本地时当前登录用户名

@property (nonatomic,copy) NSString * NativePassword;//创建文件夹在本地时当前登录用户密码

+ (ConfigModel *)modelWithDic:(NSDictionary *) dic;

@end
