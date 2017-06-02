//
//  DownloadTool.m
//  MacArchiveTool
//
//  Created by seraphic on 17/5/23.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import "DownloadTool.h"
#import "NetworkManager.h"
#include <CFNetwork/CFNetwork.h>
#import "ConfigModel.h"
#import "SSZipArchive.h"
#import "DJProgressHUD.h"

#define USER @"testuser"
#define PASSWORD @"123456"
static DownloadTool * downloadTool;

@interface DownloadTool ()<NSStreamDelegate>

@property (nonatomic, assign, readonly ) BOOL              isReceiving;
@property (nonatomic, strong, readwrite) NSInputStream *   networkStream;
@property (nonatomic, copy,   readwrite) NSString *        filePath;
@property (nonatomic, strong, readwrite) NSOutputStream *  fileStream;
@property(nonatomic,strong) NSMutableArray * array;
@property(nonatomic,assign) NSInteger arrayCount;
@end


@implementation DownloadTool

+ (instancetype)allocWithZone:(struct _NSZone *)zone{

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadTool =   [super allocWithZone:zone];
    });
    return downloadTool;
}


+ (instancetype) sharedInstance{
    
    return   [[self alloc] init];
}


-(id) copyWithZone:(struct _NSZone *)zone
{
    return downloadTool ;
}

- (BOOL)isReceiving
{
    return (self.networkStream != nil);
}

- (void)downFileWithArray:(NSMutableArray *)array{

    self.array = array;
    if(self.array>0){
        
        self.arrayCount = self.array.count;
        [self downloadFile];
 
    }
}

- (void)downloadFile{
    NSDictionary * dic = self.array[0];
    NSString * downUrl = [dic objectForKey:@"URL"];
    NSString * toUrl = [dic objectForKey:@"OUTURL"];
    //@"ftp://localhost/Desktop/FTP/FTPTest/1024.zip"
        ftp://localhost/Desktop/FTP/FTPTest/1024.zip
    //@"/Users/lt-macbookpro/Desktop/OUTFTP/FTP/FTPTest/1024.zip"
    //    /Users/lt-macbookpro/Desktop/OUTFTP/FTPTest/1024.zip
    
    [self downFileFromDownUrl:downUrl ToUrl:toUrl];
}


- (void)downFileFromDownUrl:(NSString *)downUrl ToUrl:(NSString *)toUrl{

    BOOL                success;
    NSURL *             url;
    assert(self.networkStream == nil);      // don't tap receive twice in a row!
    assert(self.fileStream == nil);         // ditto
    assert(self.filePath == nil);           // ditto
    
    // First get and check the URL.
    
    //url = [[NetworkManager sharedInstance] smartURLForString:downUrl];
    
    NSString * urlString = [downUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    url = [NSURL URLWithString:urlString];
    
    success = (url != nil);
    
    // If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    if ( ! success) {
        //self.statusLabel.text = @"Invalid URL";
        [self.array removeObjectAtIndex:0];
        [self downloadFile];
    } else {
        
        // Open a stream for the file we're going to receive into.
        
        self.filePath = toUrl;
        assert(self.filePath != nil);
        
        self.fileStream = [NSOutputStream outputStreamToFileAtPath:self.filePath append:NO];
        assert(self.fileStream != nil);
        
        [self.fileStream open];
        
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
        // Tell the UI we're receiving.
        
       // [self receiveDidStart];
        [[NetworkManager sharedInstance] didStartNetworkOperation];
    }

    
}


- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
// An NSStream delegate callback that's called when events happen on our
// network stream.
{
#pragma unused(aStream)
    assert(aStream == self.networkStream);
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
           // [self updateStatus:@"Opened connection"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSInteger       bytesRead;
            uint8_t         buffer[32768];
            
          //  [self updateStatus:@"Receiving"];
            
            // Pull some data off the network.
            
            bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead == -1) {
                [DJProgressHUD dismiss];
                [self stopReceiveWithStatus:@"Network read error"];
                NSLog(@"===Network read error===");
            } else if (bytesRead == 0) {
                [self stopReceiveWithStatus:nil];
            } else {
                NSInteger   bytesWritten;
                NSInteger   bytesWrittenSoFar;
                
                // Write to the file.
                
                bytesWrittenSoFar = 0;
                do {
                    bytesWritten = [self.fileStream write:&buffer[bytesWrittenSoFar] maxLength:(NSUInteger) (bytesRead - bytesWrittenSoFar)];
                    //更新下载进度
                    NSMutableDictionary * dic = [NSMutableDictionary dictionary];
                    [dic setObject:@(self.projectSize) forKey:@"count"];
                    [dic setObject:@(bytesWritten) forKey:@"index"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"DOWNLOADCOUNT" object:nil userInfo:dic];
                    //=========
                    
                    assert(bytesWritten != 0);
                    if (bytesWritten == -1) {
                        [DJProgressHUD dismiss];
                        NSLog(@"===当前文件下载失败path=%@===",self.filePath);
                        [self stopReceiveWithStatus:@"File write error"];
                        break;
                    } else {
                        bytesWrittenSoFar += bytesWritten;
                        NSLog(@"===下载数据中===");
                    }
                } while (bytesWrittenSoFar != bytesRead);
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventErrorOccurred: {
            [self stopReceiveWithStatus:@"Stream open error"];
            NSLog(@"===Stream open error===");
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
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
    [self receiveDidStopWithStatus:statusString];
    self.filePath = nil;
    if(self.array.count>0){
        [self.array removeObjectAtIndex:0];
        if(self.array.count>0){

          [self downloadFile];
            
        }else{//下载完成解压
            
            [DJProgressHUD dismiss];
            [self unZipFile];
        }
        
    }
    
}

#pragma mark - 解压文件
- (void)unZipFile{

    for(int i = 0;i<self.zipPathArray.count;i++){
    
        NSDictionary * dic = self.zipPathArray[i];
        
        NSString * zipFilePath = [dic objectForKey:@"zipFilePath"];
        NSString * zipFileName = [dic objectForKey:@"zipFileName"];
        NSString * zipDir = [zipFileName stringByReplacingOccurrencesOfString:@".zip" withString:@"/"];
        if([zipFileName isEqualToString:@"ios_sdk.zip"]){
            
            if([zipFilePath containsString:@"Libraries"]){
            
                 [SSZipArchive unzipFileAtPath:[NSString stringWithFormat:@"%@%@",zipFilePath,zipFileName] toDestination:zipFilePath];
            }else{
            
                 [SSZipArchive unzipFileAtPath:[NSString stringWithFormat:@"%@%@",zipFilePath,zipFileName] toDestination:[NSString stringWithFormat:@"%@/Libraries",zipFilePath]];
            }
            
        }else{
           [SSZipArchive unzipFileAtPath:[NSString stringWithFormat:@"%@%@",zipFilePath,zipFileName] toDestination:[NSString stringWithFormat:@"%@%@",zipFilePath,zipDir]];
        }
     
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        BOOL res=[fileManager removeItemAtPath:[NSString stringWithFormat:@"%@%@",zipFilePath,zipFileName] error:nil];
        
        if (res) {
            
            NSLog(@"文件删除成功");
            
        }else{
            
            NSLog(@"文件删除失败");
            NSLog(@"文件是否存在: %@",[fileManager isExecutableFileAtPath:zipFilePath]?@"存在":@"不存在");
        
        }
        
    }

}



- (void)receiveDidStopWithStatus:(NSString *)statusString
{

    [[NetworkManager sharedInstance] didStopNetworkOperation];
}


@end
