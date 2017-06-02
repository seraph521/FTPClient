//
//  FTPTool.h
//  MacArchiveTool
//
//  Created by seraphic on 17/5/22.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ConfigModel;

@interface FTPTool : NSObject

@property (nonatomic, strong)            NSMutableArray * listArray;
@property (nonatomic, strong)            NSString *  currentPath;
@property (nonatomic, strong)            NSString *  downRootPath;
@property (nonatomic, strong)            NSString *  dirRootPath;

@property (nonatomic, strong)            NSString *  projectDirName;
@property(nonatomic,strong) ConfigModel * configModel;


+ (instancetype) sharedInstance;

- (void)startListReceive;


@end
