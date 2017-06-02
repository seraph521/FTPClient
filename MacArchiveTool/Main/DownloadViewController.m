//
//  DownloadViewController.m
//  MacArchiveTool
//
//  Created by LT-MacbookPro on 17/5/26.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import "DownloadViewController.h"
#import "ProjectModel.h"
#import "DJProgressHUD.h"
#import "AFNetworking.h"
#import "MJExtension.h"
#import "DataModel.h"
#import "FTPTool.h"
#import "ConfigModel.h"
#import "SSZipArchive.h"

#define DATAURL @"http://data.joymeng.com/sp/IOSBuildService.php?type=get&len="


@interface DownloadViewController ()<NSTableViewDelegate,NSTableViewDataSource,NSStreamDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSButton *reloadBtn;
@property (weak) IBOutlet NSButton *downloadBtn;
@property (weak) IBOutlet NSButton *deleteBtn;
@property (weak) IBOutlet NSTextField *downPathField;
@property (weak) IBOutlet NSButton *resoucePathBtn;
@property (weak) IBOutlet NSTextField *resoucePathField;
@property (weak) IBOutlet NSButton *loadBtn;

@property(nonatomic,strong) NSMutableArray * dataArray;

@property(nonatomic,strong) DataModel * dataModel;

@property(nonatomic,strong)ConfigModel * configModel;

@property(nonatomic,strong)ProjectModel * projectModel;

@property(nonatomic,assign) CGFloat currentSize;

@property(nonatomic,copy) NSString * downPathFieldText;

@property(nonatomic,copy) NSString * resoucePathFieldText;


@end

@implementation DownloadViewController

@synthesize navigationController = _navigationController;

- (NSMutableArray * )dataArray{
    
    if(_dataArray == nil){
        
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showProgress:) name:@"DOWNLOADCOUNT" object:nil];
    //加载配置文件
    NSString * path = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"];
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:path];
    ConfigModel * model = [ConfigModel modelWithDic:dic];
    self.configModel = model;
    [self requestData];
    self.downloadBtn.hidden = YES;
    self.deleteBtn.hidden = YES;
    self.loadBtn.hidden  =YES;
    self.resoucePathBtn.hidden = NO;
    [self setupTableView];
}

//显示下载进度
- (void)showProgress:(NSNotification *) notice{
    
    id countS = [notice.userInfo objectForKey:@"count"];
    id indexS = [notice.userInfo objectForKey:@"index"];
    CGFloat count = [countS floatValue];
    CGFloat index = [indexS floatValue];
    self.currentSize += index;
    [DJProgressHUD showProgress: self.currentSize / (count + 113467898) withStatus:@"下载进度" FromView:self.view];
}

#pragma mark - 解析FTP地址，下载

- (void)ftpDownloadWithPath:(NSString *)path{
    
    NSString * pathString = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"];
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:pathString];
    ConfigModel * model = [ConfigModel modelWithDic:dic];
    //
    NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
    NSString * desktopPath = [paths objectAtIndex:0];
    
    NSString * nativeHeadPath = [desktopPath stringByReplacingOccurrencesOfString:@"Desktop" withString:@""];
    
    //model.DownRootPath = [NSString stringWithFormat:@"%@/%@/",desktopPath,self.projectModel.path];
    model.DownRootPath = self.downPathField.stringValue;
   // model.DirRootPath = [NSString stringWithFormat:@"ftp://localhost/Desktop/%@/",self.projectModel.path];
    NSString * dirPath = [self.downPathField.stringValue stringByReplacingOccurrencesOfString:nativeHeadPath withString:@"ftp://localhost/"];
    model.DirRootPath = dirPath;
    
    
    FTPTool * tool = [FTPTool sharedInstance] ;
    tool.configModel = model;
    
    tool.currentPath = path;
    tool.projectDirName = self.projectModel.path;
    tool.dirRootPath = [NSString stringWithFormat:@"%@%@/",model.DownRootPath,tool.projectDirName]; //model.DirRootPath;
    
    tool.downRootPath = [NSString stringWithFormat:@"%@%@/",model.DownRootPath,tool.projectDirName];//model.DownRootPath;
    
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
            
            if(dataDic == nil){
            
                return ;
            }
            
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
                
                self.downloadBtn.hidden = NO;
                self.deleteBtn.hidden = NO;
            }
            [self.tableView reloadData];
            
        }
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"==%@",error);
    }];
}

- (void)setupTableView{
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.target = self;
    self.tableView.action = @selector(tableViewClicked:);
}
//开始导入
- (IBAction)clickLoadBtn:(NSButton *)sender {
    
    if(self.downPathField.stringValue.length > 0 && self.resoucePathFieldText.length > 0){
        
        // 1 判断下载路径下是否有此文件夹
        NSInteger index= self.tableView.selectedRow;
        ProjectModel * projectModel = self.dataArray[index];
        
        NSFileManager * fileManager = [NSFileManager defaultManager];
        
        NSString * dir = [NSString stringWithFormat:@"%@%@/Libraries/",self.downPathField.stringValue,projectModel.path];
        
        BOOL isExecutable = [fileManager isExecutableFileAtPath:dir];
        
        if(isExecutable){
        
            [DJProgressHUD showStatus:@"正在导入" FromView:self.view];
            NSLog(@"==========存在");
            // 2 压缩资源路径下的文件夹
         BOOL is = [SSZipArchive createZipFileAtPath:[NSString stringWithFormat:@"%@resouce.zip",dir] withContentsOfDirectory:self.resoucePathField.stringValue];
            if(is){
                // 3 删除压缩的文件，并解压写入的压缩文件
                
                [SSZipArchive unzipFileAtPath:[NSString stringWithFormat:@"%@resouce.zip",dir]  toDestination:dir];
                
                [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@resouce.zip",dir] error:nil];
                [DJProgressHUD showStatus:@"导入成功" FromView:self.view];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [DJProgressHUD dismiss];

                });
                self.resoucePathField.stringValue = @"";
                self.resoucePathFieldText = @"";
                
            }else{
            
                [DJProgressHUD showStatus:@"导入失败" FromView:self.view];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [DJProgressHUD dismiss];
                    
                });

            }
            
            
        }else{
            NSLog(@"==========不存在");
            NSAlert *alert = [NSAlert new];
            [alert addButtonWithTitle:@"确定"];
            [alert addButtonWithTitle:@"取消"];
            [alert setMessageText:@"提示"];
            [alert setInformativeText:@"当前下载路径不存在，不能导入!"];
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
        
    }else{
    
        NSAlert *alert = [NSAlert new];
        [alert addButtonWithTitle:@"确定"];
        [alert addButtonWithTitle:@"取消"];
        [alert setMessageText:@"提示"];
        [alert setInformativeText:@"下载路径与导入资源路径不能为空!"];
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
//选择导入资源路径
- (IBAction)clickResoucePathBtn:(NSButton *)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setResolvesAliases:YES];
    
    NSString *panelTitle = NSLocalizedString(@"Choose a file", @"Title for the open panel");
    [panel setTitle:panelTitle];
    
    NSString *promptString = NSLocalizedString(@"Choose", @"Prompt for the open panel prompt");
    [panel setPrompt:promptString];
    
    [panel beginSheetModalForWindow:[self.view window] completionHandler:^(NSInteger result){
        
        // Hide the open panel.
        [panel orderOut:self];
        
        // If the return code wasn't OK, don't do anything.
        if (result != NSOKButton) {
            return;
        }
        // Get the first URL returned from the Open Panel and set it at the first path component of the control.
        NSURL *url = [[panel URLs] objectAtIndex:0];
        
        self.resoucePathField.stringValue = url;
        
        self.resoucePathField.stringValue = [self.resoucePathField.stringValue stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        self.resoucePathFieldText = self.resoucePathField.stringValue;
        self.resoucePathField.stringValue = [self.resoucePathField.stringValue stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        self.loadBtn.hidden  = NO;

    }];

}

- (IBAction)clickReloadBtn:(NSButton *)sender {
    
    [self.dataArray removeAllObjects];
    [DJProgressHUD showStatus:@"正在玩命刷新中。。。" FromView:self.view];
    [self requestData];
}

- (IBAction)clickDownloadBtn:(NSButton *)sender {
    
    self.currentSize = 0;
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"提示"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
   // [self ftpDownloadWithPath:@"ftp://10.80.3.249/XCode201752693313"];
    NSInteger index= self.tableView.selectedRow;
    
    if(self.downPathField.stringValue.length == 0 ){
    
        [alert setInformativeText:@"请选择下载路径！"];
        NSUInteger action = [alert runModal];
        return;
    }
    
    
    if(index >= 0){
        
        //主机地址
        NSUserDefaults * user =  [NSUserDefaults standardUserDefaults];
        NSString * host = [user objectForKey:@"host"];
        
        ProjectModel * projectModel = self.dataArray[index];
        self.projectModel = projectModel;
        
        //覆盖下载（先删除）
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL res=[fileManager removeItemAtPath:[NSString stringWithFormat:@"%@%@",self.downPathField.stringValue,projectModel.path] error:nil];
        //开始下载
        [self ftpDownloadWithPath:[NSString stringWithFormat:@"ftp://%@/%@/",host,projectModel.path]];
      //  [alert setInformativeText:[NSString stringWithFormat:@"项目将会下载到 桌面/%@ 文件夹下",projectModel.path ]];
        [alert setInformativeText:[NSString stringWithFormat:@"项目将会下载到%@",self.downPathField.stringValue]];
        NSUInteger action = [alert runModal];
       // [DJProgressHUD showStatus:@"下载中。。。" FromView:self.view];
        [DJProgressHUD showProgress:0.0 withStatus:@"下载进度" FromView:self.view];
        self.resoucePathBtn.hidden = NO;


    }else{
        [alert setInformativeText:@"无选择项目"];
        NSUInteger action = [alert runModal];
    }
}
- (IBAction)clickDeleteBtn:(NSButton *)sender {
    
    NSInteger index= self.tableView.selectedRow;

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"提示"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    if(index>=0){
    
        ProjectModel * projectModel = self.dataArray[index];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        BOOL res=[fileManager removeItemAtPath:[NSString stringWithFormat:@"%@%@",self.downPathField.stringValue,projectModel.path] error:nil];
        
        if (res) {
            
            NSLog(@"文件删除成功");
            [alert setInformativeText:@"文件删除成功"];
            NSUInteger action = [alert runModal];
            
        }else{
            
            NSLog(@"文件删除失败");
            [alert setInformativeText:@"文件删除失败"];
            NSUInteger action = [alert runModal];
        }
        
    }else{
    
        [alert setInformativeText:@"选择删除的项目"];
        NSUInteger action = [alert runModal];
    }
    
    
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
    if( [tableColumn.identifier isEqualToString:@"table0"] ){
        ProjectModel *model = [self.dataArray objectAtIndex:row];
        cellView.textField.stringValue = [NSString stringWithFormat:@"%d",model.ID];
        return cellView;
    }
    if( [tableColumn.identifier isEqualToString:@"table1"] ){
        ProjectModel *model = [self.dataArray objectAtIndex:row];
        cellView.textField.stringValue = model.path;
        return cellView;
    }
    if( [tableColumn.identifier isEqualToString:@"table2"] ){
        ProjectModel *model = [self.dataArray objectAtIndex:row];
        if(model.desc.length>0){
            cellView.textField.stringValue = model.desc;

        }else{
        
            cellView.textField.stringValue = @"";
        }
        return cellView;
    }
    if( [tableColumn.identifier isEqualToString:@"table3"] ){
        ProjectModel *model = [self.dataArray objectAtIndex:row];
        if(model.author.length>0){
            cellView.textField.stringValue = model.author;

        }else{
            cellView.textField.stringValue = @"";

        }
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

- (IBAction)selectedDownloadPath:(NSButton *)sender {
    
    NSInteger index= self.tableView.selectedRow;
    if(index == -1){
    
        NSAlert *alert = [NSAlert new];
        [alert addButtonWithTitle:@"确定"];
        [alert addButtonWithTitle:@"取消"];
        [alert setMessageText:@"提示"];
        [alert setInformativeText:@"请先选择需要下载的项目!"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
            if(returnCode == NSAlertFirstButtonReturn){
                [self dismissController:self];
            }else if(returnCode == NSAlertSecondButtonReturn){
            }
        }];
        return;
    }
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setResolvesAliases:YES];
    
    NSString *panelTitle = NSLocalizedString(@"Choose a file", @"Title for the open panel");
    [panel setTitle:panelTitle];
    
    NSString *promptString = NSLocalizedString(@"Choose", @"Prompt for the open panel prompt");
    [panel setPrompt:promptString];
    
    [panel beginSheetModalForWindow:[self.view window] completionHandler:^(NSInteger result){
        
        // Hide the open panel.
        [panel orderOut:self];
        
        // If the return code wasn't OK, don't do anything.
        if (result != NSOKButton) {
            return;
        }
        // Get the first URL returned from the Open Panel and set it at the first path component of the control.
        NSURL *url = [[panel URLs] objectAtIndex:0];
        
        self.downPathField.stringValue = url;

        self.downPathField.stringValue = [self.downPathField.stringValue stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        self.downPathFieldText = self.downPathField.stringValue;
        self.downPathField.stringValue =   [self.downPathField.stringValue stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
       // [self.downPathField.stringValue str];

    }];
}

@end
