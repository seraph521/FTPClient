//
//  DownloadTool.h
//  MacArchiveTool
//
//  Created by seraphic on 17/5/23.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ConfigModel;

@interface DownloadTool : NSObject

@property(nonatomic,strong) ConfigModel * configModel;

@property(nonatomic,strong) NSMutableArray * zipPathArray;//需要解压路径数组

@property(nonatomic,assign) int  projectSize;


+ (instancetype)sharedInstance;

- (void)downFileFromDownUrl:(NSString *)downUrl ToUrl:(NSString *)toUrl;

- (void)downFileWithArray:(NSMutableArray *)array;

@end
