//
//  FTPTool.m
//  MacArchiveTool
//
//  Created by seraphic on 17/5/22.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import "FTPTool.h"
#import "NetworkManager.h"
#include <sys/socket.h>
#include <sys/dirent.h>
#include <CFNetwork/CFNetwork.h>
#import <Foundation/NSStream.h>
#import "DownloadTool.h"
#import"ConfigModel.h"

#define USER @"testuser"
#define PASSWORD @"123456"
#define URL @"ftp://localhost/Desktop/FTP/"
#define OUTURL @"/Users/lt-macbookpro/Desktop/OUTFTP/"

#define ADRESS @"ftp://10.80.3.249/"
#define ZIPFILE @"ios_sdk.zip"

static FTPTool * ftpTool;

@interface FTPTool ()<NSStreamDelegate>

@property (nonatomic, assign, readonly ) BOOL              isReceiving;
@property (nonatomic, assign )           BOOL              isGetListOver;
@property (nonatomic, strong, readwrite) NSInputStream *   networkStream;
@property (nonatomic, strong, readwrite) NSMutableData *   listData;
@property (nonatomic, strong, readwrite) NSMutableArray *  listEntries;
@property (nonatomic, copy,   readwrite) NSString *        status;
@property(nonatomic,assign) int  projectSize;


@property (nonatomic, strong)            NSString *  currentDirName;
@property (nonatomic, strong)            NSString *  ftpRootPath;

@property(nonatomic,strong) NSMutableArray * dirArray;

@property(nonatomic,strong) NSMutableArray * downloadArray;

@property(nonatomic,strong) NSMutableArray * zipPathArray;//解压路径数组

@end


@implementation FTPTool

+ (instancetype)allocWithZone:(struct _NSZone *)zone{

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      ftpTool =   [super allocWithZone:zone];

    });
    
    return ftpTool;
}

+ (instancetype) sharedInstance{

  return   [[self alloc] init];
}


-(id) copyWithZone:(struct _NSZone *)zone
{
    return ftpTool ;
}


- (NSMutableArray * )listEntries{
    
    if(_listEntries == nil){
        
        _listEntries = [NSMutableArray array];
        
    }
    return _listEntries;
}

- (NSMutableArray *)listArray{

    if(_listArray == nil){
    
        _listArray  = [NSMutableArray array];
    }
    return _listArray;
}


- (NSMutableArray * )dirArray{

    if(_dirArray == nil){
        _dirArray = [NSMutableArray array];
    }
    return _dirArray;
}

- (NSMutableArray *)downloadArray{

    if(_downloadArray == nil){
    
        _downloadArray = [NSMutableArray array];
    }
    return _downloadArray;
}

- (NSMutableArray * )zipPathArray{

    if(_zipPathArray == nil){
    
        _zipPathArray = [NSMutableArray array];
    }
    return _zipPathArray;
}

#pragma mark - FTP 相关
//遍历路径
- (void)startListReceive{
    
    NSString * dirName;
    NSString * currentpath;
    
    if(self.listArray.count>0){
        NSMutableDictionary * dic = self.listArray[0];
        dirName = [dic objectForKey:@"dirname"];
        currentpath = [dic objectForKey:@"currentpath"];
        [self.listArray removeObjectAtIndex:0];
    }else{
    
        currentpath = self.currentPath;
        self.ftpRootPath = self.currentPath;
    }

    BOOL                success;
    NSURL *             url;
    
    assert(self.networkStream == nil);      // don't tap receive twice in a row!
    
    // First get and check the URL.
    if(dirName.length>0){
        //url = [[NetworkManager sharedInstance] smartURLForString:[NSString stringWithFormat:@"%@%@/",currentpath,dirName]];
        NSString * urlString = [NSString stringWithFormat:@"%@%@/",currentpath,dirName];
        NSString* encodedString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        url = [NSURL URLWithString:encodedString];
    }else{
    
       //url = [[NetworkManager sharedInstance] smartURLForString:[NSString stringWithFormat:@"%@",currentpath]];
        NSString * urlString = [NSString stringWithFormat:@"%@",currentpath];
        NSString* encodedString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        url = [NSURL URLWithString:encodedString];

    }
    success = (url != nil);
    
    if(dirName.length>0){
    
        self.currentPath = [NSString stringWithFormat:@"%@%@/",currentpath,dirName];

    }else{
        self.currentPath = [NSString stringWithFormat:@"%@",currentpath];

    }
    
    self.currentDirName = dirName;
    // If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    if ( ! success) {
        // [self updateStatus:@"Invalid URL"];
        NSLog(@"currentPath===%@",currentpath);
        NSLog(@"dirName===%@",dirName);
        NSLog(@"Invalid URL===%@",url);
        [self getListOver];

        
    } else {
        
        // Create the mutable data into which we will receive the listing.
        
        self.listData = [NSMutableData data];
        assert(self.listData != nil);
        
        // Open a CFFTPStream for the URL.
        
        self.networkStream = CFBridgingRelease(
                                               CFReadStreamCreateWithFTPURL(NULL, (__bridge CFURLRef) url)
                                               
                                               );
        assert(self.networkStream != nil);
        self.networkStream.delegate = self;
        [self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.networkStream open];
        
        success = [self.networkStream setProperty:self.configModel.Username forKey:(id)kCFStreamPropertyFTPUserName];
        assert(success);
        success = [self.networkStream setProperty:self.configModel.Password forKey:(id)kCFStreamPropertyFTPPassword];
        assert(success);
        
        [self receiveDidStart];
    }

    
}


#pragma mark - FTP 开始接收数据
- (void)receiveDidStart
{
    [self.listEntries removeAllObjects];
    [[NetworkManager sharedInstance] didStartNetworkOperation];
}


- (NSDictionary *)entryByReencodingNameInEntry:(NSDictionary *)entry encoding:(NSStringEncoding)newEncoding

{
    NSDictionary *  result;
    NSString *      name;
    NSData *        nameData;
    NSString *      newName;
    
    newName = nil;
    
    // Try to get the name, convert it back to MacRoman, and then reconvert it
    // with the preferred encoding.
    
    name = [entry objectForKey:(id) kCFFTPResourceName];
    if (name != nil) {
        assert([name isKindOfClass:[NSString class]]);
        
        nameData = [name dataUsingEncoding:NSMacOSRomanStringEncoding];
        if (nameData != nil) {
            newName = [[NSString alloc] initWithData:nameData encoding:newEncoding];
        }
    }
    
    // If the above failed, just return the entry unmodified.  If it succeeded,
    // make a copy of the entry and replace the name with the new name that we
    // calculated.
    
    if (newName == nil) {
        assert(NO);                 // in the debug builds, if this fails, we should investigate why
        result = (NSDictionary *) entry;
    } else {
        NSMutableDictionary *   newEntry;
        
        newEntry = [entry mutableCopy];
        assert(newEntry != nil);
        
        [newEntry setObject:newName forKey:(id) kCFFTPResourceName];
        
        result = newEntry;
    }
    
    return result;
}

- (void)parseListData
{
    NSMutableArray *    newEntries;
    NSUInteger          offset;
    
    newEntries = [NSMutableArray array];
    assert(newEntries != nil);
    
    offset = 0;
    do {
        CFIndex         bytesConsumed;
        CFDictionaryRef thisEntry;
        
        thisEntry = NULL;
        
        assert(offset <= [self.listData length]);
        bytesConsumed = CFFTPCreateParsedResourceListing(NULL, &((const uint8_t *) self.listData.bytes)[offset], (CFIndex) ([self.listData length] - offset), &thisEntry);
        if (bytesConsumed > 0) {
            
            
            if (thisEntry != NULL) {
                NSDictionary *  entryToAdd;
                
                entryToAdd = [self entryByReencodingNameInEntry:(__bridge NSDictionary *) thisEntry encoding:NSUTF8StringEncoding];
                
                [newEntries addObject:entryToAdd];
            }
            
            offset += (NSUInteger) bytesConsumed;
        }
        
        if (thisEntry != NULL) {
            CFRelease(thisEntry);
        }
        
        if (bytesConsumed == 0) {
            // We haven't yet got enough data to parse an entry.  Wait for more data
            self.isGetListOver = YES;
            NSLog(@"Listing parse over");
            break;
        } else if (bytesConsumed < 0) {
            // We totally failed to parse the listing.  Fail.
            [self stopReceiveWithStatus:@"Listing parse failed"];
            NSLog(@"Listing parse failed");
            break;
        }
    } while (YES);
    
    if ([newEntries count] != 0) {
        [self addListEntries:newEntries];
    }
    if (offset != 0) {
        [self.listData replaceBytesInRange:NSMakeRange(0, offset) withBytes:NULL length:0];
    }
}


- (void)addListEntries:(NSArray *)newEntries
{
    assert(self.listEntries != nil);
    
    [self.listEntries addObjectsFromArray:newEntries];
}


- (void)updateStatus:(NSString *)statusString
{
    assert(statusString != nil);
    self.status = statusString;
    
}

- (void)receiveDidStopWithStatus:(NSString *)statusString
{
    
    [[NetworkManager sharedInstance] didStopNetworkOperation];
    [self getListOver];
}

#pragma mark  NSStreamDelegate代理   
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
// An NSStream delegate callback that's called when events happen on our
// network stream.
{
#pragma unused(aStream)
    assert(aStream == self.networkStream);
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self updateStatus:@"Opened connection"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSInteger       bytesRead;
            uint8_t         buffer[32768];
            
            [self updateStatus:@"Receiving"];
            
            // Pull some data off the network.
            
            bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead < 0) {
                 [self stopReceiveWithStatus:@"Network read error"];
            } else if (bytesRead == 0) {
                 [self stopReceiveWithStatus:nil];
            } else {
                assert(self.listData != nil);
                
                // Append the data to our listing buffer.
                
                [self.listData appendBytes:buffer length:(NSUInteger) bytesRead];
                
                // Check the listing buffer for any complete entries and update
                // the UI if we find any.
                
                [self parseListData];
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventErrorOccurred: {
             [self stopReceiveWithStatus:@"Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)stopReceiveWithStatus:(NSString *)statusString
// Shuts down the connection and displays the result (statusString == nil)
// or the error status (otherwise).
{
    if (self.networkStream != nil) {
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.networkStream.delegate = nil;
        [self.networkStream close];
        self.networkStream = nil;
    }
    self.listData = nil;
    [self receiveDidStopWithStatus:statusString];
    
}


- (void)getListOver{

   // if(self.listEntries.count>0){
         NSLog(@"解析List成功======");
         [self getDirUrlDict];
   // }
}

- (void )getDirUrlDict{
   
    //首先创建下载目录
    if(self.dirArray.count == 0){
        //ftp:// localhost/Desktop/MacArchiveTool_download/
        NSMutableDictionary * dic = [NSMutableDictionary dictionary];
        [dic setObject:self.projectDirName forKey:@"dirname"];
       // [dic setObject:@"ftp://localhost/Desktop/" forKey:@"currentpath"];
        [dic setObject:self.configModel.DownRootPath forKey:@"currentpath"];
        [self.dirArray addObject:dic];
    }
    
    for(int i =0 ;i< self.listEntries.count;i++){
        
        NSDictionary * listEntry = [self.listEntries objectAtIndex:i];
        NSString * listName =   [listEntry objectForKey:(id) kCFFTPResourceName];
        NSNumber * fileSize =   [listEntry objectForKey:(id) kCFFTPResourceSize];
        self.projectSize += [fileSize intValue];
        
        BOOL isDir =  [self isDirWithDic:listEntry];
        
        if(isDir){
            
            NSMutableDictionary * dic = [NSMutableDictionary dictionary];
            [dic setObject:listName forKey:@"dirname"];
            [dic setObject:self.currentPath forKey:@"currentpath"];
            [self.listArray addObject:dic];
            
            NSString * dirPath = [self.currentPath stringByReplacingOccurrencesOfString:self.ftpRootPath withString:self.dirRootPath];//@"10.80.3.249/"== @"localhost/Desktop/OUTFTP/"
            NSMutableDictionary * dirDic = [NSMutableDictionary dictionary];
            [dirDic setObject:listName forKey:@"dirname"];
            [dirDic setObject:dirPath forKey:@"currentpath"];
         //    [dirDic setObject:[NSString stringWithFormat:@"%@%@/",dirPath,self.projectDirName] forKey:@"currentpath"];
            [self.dirArray addObject:dirDic];
            //遍历文件夹
          //  [self startListReceive];
            
        }else{
            
            NSString * originUrl = [NSString stringWithFormat:@"%@%@",self.currentPath,listName] ;

            NSMutableDictionary * dic = [NSMutableDictionary dictionary];
            
            NSString * downPath   = [originUrl stringByReplacingOccurrencesOfString:self.ftpRootPath withString:self.downRootPath];//@"ftp://10.80.3.249/"
            
            [dic setObject:originUrl forKey:@"URL"];
            [dic setObject:downPath forKey:@"OUTURL"];
            [self.downloadArray addObject:dic];
            
            //判断是否需要解压
            if([listName isEqualToString:ZIPFILE]){
               
                NSString * zipFilePath = [self.currentPath stringByReplacingOccurrencesOfString:self.ftpRootPath withString:self.downRootPath ];
               // NSString * path = [NSString stringWithFormat:@"%@Libraries/",zipFilePath];
                NSMutableDictionary * dic = [NSMutableDictionary dictionary];
                [dic setObject:listName forKey:@"zipFileName"];
                [dic setObject:zipFilePath forKey:@"zipFilePath"];
                [self.zipPathArray addObject:dic];
                
            }
            
            if([listName isEqualToString:@"main.mm"]){
                //如果没有ios_sdk.zip则根目录下载，解压到libraries下
                //无ios_sdk.zip
                if(self.zipPathArray.count == 0){
                    
                    //1 下载
                    NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
                    NSString * desktopPath = [paths objectAtIndex:0];
                    NSString * downPath  = [NSString stringWithFormat:@"%@Libraries/ios_sdk.zip",self.downRootPath];
                    NSString * path = @"ftp://10.80.3.249/ios_sdk.zip";
                    NSMutableDictionary * dic = [NSMutableDictionary dictionary];
                    [dic setObject:path forKey:@"URL"];
                    [dic setObject:downPath forKey:@"OUTURL"];
                    [self.downloadArray addObject:dic];
                    
                    //2 解压
                    NSString * zipFilePath = [NSString stringWithFormat:@"%@Libraries/",self.downRootPath];
                    //[NSString stringWithFormat:@"%@/%@/Libraries/",desktopPath,self.projectDirName];
                    NSMutableDictionary * zipdic = [NSMutableDictionary dictionary];
                    [zipdic setObject:@"ios_sdk.zip" forKey:@"zipFileName"];
                    [zipdic setObject:zipFilePath forKey:@"zipFilePath"];
                    [self.zipPathArray addObject:zipdic];
                    
                }
            }
            
            if([listName isEqualToString:@"Native.zip"]){
            
                NSString * zipFilePath = [self.currentPath stringByReplacingOccurrencesOfString:self.ftpRootPath withString:self.downRootPath ];
                NSMutableDictionary * dic = [NSMutableDictionary dictionary];
                [dic setObject:listName forKey:@"zipFileName"];
                [dic setObject:zipFilePath forKey:@"zipFilePath"];
                [self.zipPathArray addObject:dic];
            }

        }
        
        //跳过含有空格的目录
        if(self.listEntries.count == 0 && self.listArray.count !=0){
            
            [self startListReceive];
        }
        
    }
    
    [self.listEntries removeAllObjects];
    //大于0递归，为0时递归完毕创建文件夹
   // if(self.listArray.count>0){
    
         // [self.listArray removeObjectAtIndex:0];
          //查找所有文件夹结束
          if(self.listArray.count == 0){
              //有文件夹先创建文件夹
              if(self.dirArray.count>0){
                  [self createDir];
              }else if (self.dirArray.count == 0 && self.downloadArray.count>0){
                  //无文件夹，有文件 则下载
                  DownloadTool * downloadTool = [DownloadTool sharedInstance];
                  downloadTool.zipPathArray = self.zipPathArray;
                  downloadTool.configModel = self.configModel;
                  downloadTool.projectSize = self.projectSize;
                  self.projectSize = 0;
                  [downloadTool downFileWithArray:self.downloadArray];
                  //开始下载时清理数据
//                  [self.downloadArray removeAllObjects];
//                  [self.zipPathArray removeAllObjects];
//                  if (self.networkStream != nil) {
//                      [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//                      self.networkStream.delegate = nil;
//                      [self.networkStream close];
//                      self.networkStream = nil;
//                  }
//                  self.listData = nil;

              }
      
          }else{
              [self startListReceive];
          }
  //  }
}

#pragma mark - 创建文件夹
- (void) createDir{
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    for(int i = 0;i<self.dirArray.count;i++){
    
        NSDictionary * dic = self.dirArray[i];
        NSString * dirname = [dic objectForKey:@"dirname"];
        NSString * currentpath = [dic objectForKey:@"currentpath"];
        
        [fileManager createDirectoryAtPath:[NSString stringWithFormat:@"%@%@",currentpath,dirname] withIntermediateDirectories:YES attributes:nil error:&error];
        
        if(i == self.dirArray.count - 1){
        
            NSLog(@"项目文件夹创建完成");
            DownloadTool * downloadTool = [DownloadTool sharedInstance];
            downloadTool.configModel = self.configModel;
            downloadTool.zipPathArray = self.zipPathArray;
            downloadTool.projectSize = self.projectSize;
            self.projectSize = 0;
            [downloadTool downFileWithArray:self.downloadArray];
            [self.dirArray removeAllObjects];
        }
    }
    
}



#pragma mark - 判断是否为文件夹

- (BOOL) isDirWithDic:(NSDictionary *) listEntry{

    int                 type;
    NSNumber *          modeNum;
    NSNumber *          typeNum;
    char                modeCStr[12];
    
    typeNum = [listEntry objectForKey:(id) kCFFTPResourceType];
    if (typeNum != nil) {
        assert([typeNum isKindOfClass:[NSNumber class]]);
        type = [typeNum intValue];
    } else {
        type = 0;
    }
    
    modeNum = [listEntry objectForKey:(id) kCFFTPResourceMode];
    if (modeNum != nil) {
        assert([modeNum isKindOfClass:[NSNumber class]]);
        
        strmode([modeNum intValue] + DTTOIF(type), modeCStr);
    } else {
        strlcat(modeCStr, "???????????", sizeof(modeCStr));
    }
    char isDir = modeCStr[0];
    
    if(isDir == 'd'){
        return YES;
    }else{
        return NO;
    }
    
}



@end
