//
//  DataModel.h
//  MacArchiveTool
//
//  Created by LT-MacbookPro on 17/5/22.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataModel : NSObject

@property(nonatomic,copy) NSString * status;

@property(nonatomic,copy) NSString * msg;

@property(nonatomic,strong) NSMutableArray * data;


@end
