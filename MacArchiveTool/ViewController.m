//
//  ViewController.m
//  MacArchiveTool
//
//  Created by LT-MacbookPro on 17/5/22.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import "ViewController.h"
#import "ProjectModel.h"
#import "DJProgressHUD.h"
#import "AFNetworking.h"
#import "MJExtension.h"
#import "DataModel.h"
#import "FTPTool.h"
#import "ConfigModel.h"
#import "SSZipArchive.h"

#define DATAURL @"http://data.joymeng.com/sp/IOSBuildService.php?type=get&len="
#define ADRESS @"ftp://10.80.3.249/"

@interface ViewController ()<NSTableViewDelegate,NSTableViewDataSource,NSStreamDelegate>

@property (weak) IBOutlet NSButton *reloadButton;

@property (weak) IBOutlet NSButton *downloadButton;

@property (weak) IBOutlet NSButton *deleteButton;

@property (weak) IBOutlet NSTableView *tableView;

@property(nonatomic,strong) NSMutableArray * dataArray;

@property(nonatomic,strong) DataModel * dataModel;

@property(nonatomic,strong)ConfigModel * configModel;

@property(nonatomic,strong)ProjectModel * projectModel;


@end

@implementation ViewController

- (NSMutableArray * )dataArray{

    if(_dataArray == nil){
    
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //加载配置文件
    NSString * path = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"];
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:path];
    ConfigModel * model = [ConfigModel modelWithDic:dic];
    self.configModel = model;
    [self requestData];
    self.downloadButton.hidden = YES;
    self.deleteButton.hidden = YES;
    [self setupTableView];
    
}

#pragma mark - 解析FTP地址，下载

- (void)ftpDownloadWithPath:(NSString *)path{

    NSString * pathString = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"];
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:pathString];
    ConfigModel * model = [ConfigModel modelWithDic:dic];
    //
    NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
    NSString * desktopPath = [paths objectAtIndex:0];
    model.DownRootPath = [NSString stringWithFormat:@"%@/%@/",desktopPath,self.projectModel.path];
    model.DirRootPath = [NSString stringWithFormat:@"ftp://localhost/Desktop/%@/",self.projectModel.path];
    
    
    
    FTPTool * tool = [FTPTool sharedInstance] ;
    tool.configModel = model;

    tool.currentPath = path;
    tool.projectDirName = self.projectModel.path;
    tool.dirRootPath = model.DirRootPath;

    tool.downRootPath = model.DownRootPath;
    
    [tool startListReceive];

}


#pragma mark - 请求数据

- (void)requestData{

    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    NSString * urlString = [NSString stringWithFormat:@"%@%d",DATAURL,10];
    
    NSLog(@"------%@",urlString);
    
    [manager GET:urlString parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSString * status = [responseObject objectForKey:@"status"] ;
        
        if([status intValue] == 1){
            
            NSDictionary * dataDic = [responseObject objectForKey:@"data"] ;
            
            NSArray* allKeysArray = [dataDic allKeys];
            allKeysArray = [allKeysArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
                NSString *a = (NSString *)obj1;
                NSString *b = (NSString *)obj2;
                int aNum = [a intValue];
                int bNum = [b intValue];
                if (aNum > bNum) {
                    return NSOrderedDescending;
                }
                else if (aNum < bNum){
                    return NSOrderedAscending;
                }
                else {
                    return NSOrderedSame;
                }
            }];
            
            for(int i = 0;i<allKeysArray.count;i++){
                
                NSString * key = allKeysArray[i];
                NSDictionary * dic = [dataDic objectForKey:key];
                
                NSString * author = [dic objectForKey:@"author"];
                NSString * path = [dic objectForKey:@"path"];
                NSString * desc = [dic objectForKey:@"desc"];
                
                ProjectModel * projectModel = [[ProjectModel alloc] init];
                projectModel.ID = [key intValue];
                projectModel.author = author;
                projectModel.path = path;
                projectModel.desc = desc;
                
                [self.dataArray addObject:projectModel];
                
            }
            [DJProgressHUD dismiss];
            if(self.dataArray.count>0){
                
                self.downloadButton.hidden = NO;
                self.deleteButton.hidden = NO;
            }
            [self.tableView reloadData];
        
        }
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"==%@",error);
    }];
}



#pragma mark - 刷新列表按钮
- (IBAction)reloadData:(NSButton *)sender {
    
    [self.dataArray removeAllObjects];
    [DJProgressHUD showStatus:@"正在玩命刷新中。。。" FromView:self.view];
    [self requestData];

    NSLog(@"====reloadData");
}

#pragma mark - 下载按钮
- (IBAction)download:(NSButton *)sender {

  
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"提示"];
    [alert setAlertStyle:NSWarningAlertStyle];

    NSInteger index= self.tableView.selectedRow;
    if(index >= 0){
    
        ProjectModel * projectModel = self.dataArray[index];
        [DJProgressHUD showStatus:@"下载中。。。" FromView:self.view];
        self.projectModel = projectModel;
        [self ftpDownloadWithPath:[NSString stringWithFormat:@"ftp://10.80.3.249/%@/",projectModel.path]];
       // [self ftpDownloadWithPath:@"ftp://10.80.3.249/"];
        [alert setInformativeText:[NSString stringWithFormat:@"项目将会下载到 桌面/%@ 文件夹下",projectModel.path ]];
        NSUInteger action = [alert runModal];
    }else{
        [alert setInformativeText:@"无选择项目"];
        NSUInteger action = [alert runModal];
    }
    
}

#pragma mark - 删除按钮
- (IBAction)delete:(NSButton *)sender {
    
    NSInteger index = self.tableView.selectedRow;
    //当前用户桌面地址
    NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
    NSString * desktopPath = [paths objectAtIndex:0];
    [NSString stringWithFormat:@"%@/FTP_Download/",desktopPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExecutable = [fileManager isExecutableFileAtPath:@""];
    if(isExecutable){
     
        BOOL res=[fileManager removeItemAtPath:@"" error:nil];
        if(res){
        
        }else{
        
        }
        
    }

}


- (void)setupTableView{

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.target = self;
    self.tableView.action = @selector(tableViewClicked:);
}


#pragma  mark  - NSTableViewDataSource

// 这个方法返回列表的行数 : 类似于iOS中的numberOfRowsInSection:
- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView{

    return self.dataArray.count;
}

#pragma mark - NSTableViewDelegate
// 这个方法返回列表的cell ：参考iOS中的 cellForRowAtIndexPath:
- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{

    // 1.创建可重用的cell
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    // 2. 根据重用标识，设置cell 数据
    if( [tableColumn.identifier isEqualToString:@"TABLE1"] ){
        ProjectModel *model = [self.dataArray objectAtIndex:row];
        cellView.textField.stringValue = [NSString stringWithFormat:@"%@   %@   %@",model.path,model.desc,model.author];
        return cellView;
    }
    if( [tableColumn.identifier isEqualToString:@"TABLE0"] ){
        ProjectModel *model = [self.dataArray objectAtIndex:row];
        cellView.textField.stringValue = [NSString stringWithFormat:@"%d",model.ID];
        return cellView;
    }
    return cellView;
    
}

- (void)tableViewClicked:(id)sender {
    // This will return -1 if the click did not land on a row
    //NSLog(@"tableView.clickedRow = %ld", self.tableView.clickedRow);

    // This will return -1 if there is no row selected.
   // NSLog(@"tableView.selectedRow = %ld", self.tableView.selectedRow);
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
