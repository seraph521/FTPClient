//
//  DataModel.m
//  MacArchiveTool
//
//  Created by LT-MacbookPro on 17/5/22.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import "DataModel.h"
#import "ProjectModel.h"
#import "MJExtension.h"

@implementation DataModel

+ (NSDictionary *) mj_objectClassInArray{

    return @{
             
                   @"data" : @"ProjectModel"
             
             };
}


@end
