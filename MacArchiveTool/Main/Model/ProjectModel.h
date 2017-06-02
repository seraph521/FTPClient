//
//  ProjectModel.h
//  MacArchiveTool
//
//  Created by LT-MacbookPro on 17/5/22.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProjectModel : NSObject

@property(nonatomic,assign) int ID;
//作者
@property(nonatomic,copy) NSString * author;
//工程路径
@property(nonatomic,copy) NSString * path;
//描述
@property(nonatomic,copy) NSString * desc;

@end
