//
//  AppDelegate.m
//  MacArchiveTool
//
//  Created by LT-MacbookPro on 17/5/22.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import "AppDelegate.h"
#import"KSNavigationController.h"
#import "MainViewController.h"
#import "DownloadViewController.h"
@interface AppDelegate ()

@property(nonatomic,strong) NSWindow * window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    self.window = [[NSWindow alloc] init];
    [self.window center];
    
    MainViewController *vc1 = [[MainViewController alloc] init];
    DownloadViewController * vc2 = [[DownloadViewController alloc] init];
    
    
//    if(nativeUserName.length>0){
//      
//        KSNavigationController *navVC = [[KSNavigationController alloc] initWithRootViewController:vc2];
//        navVC.view.frame = NSMakeRect(0.0, 0.0, 480.0, 272.0);
//        self.window.contentViewController = navVC;
//        [self.window orderFrontRegardless];
//    }else{
//
//        
//    }
    
    KSNavigationController *navVC = [[KSNavigationController alloc] initWithRootViewController:vc1];
    navVC.view.frame = NSMakeRect(0.0, 0.0, 600.0, 360.0);
    self.window.contentViewController = navVC;
    [self.window orderFrontRegardless];
   
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
