//
//  CSDDataController.h
//  Movie2AVI
//
//  Created by Tom on 13.10.14.
//  Copyright (c) 2014 Thomas Bodlien Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSDBatchViewController.h"

@interface CSDDataController : NSObject
// AppDelegate
@property (nonatomic) NSInteger outputDirectoryBookmarkCounter;
@property (nonatomic, getter = isMainhWindowOpen) BOOL mainWindowOpen;
@property (nonatomic, getter = isBatchWindowOpen) BOOL batchWindowOpen;
@property (nonatomic, getter = isSettingsWindowOpen) BOOL settingsWindowOpen;
@property (nonatomic, getter = isInformationWindowOpen) BOOL informationWindowOpen;
@property (nonatomic, getter = isDebugWindowOpen) BOOL debugWindowOpen;
// MainView
@property (nonatomic) NSWindowController *mainWindowController;
@property (nonatomic) NSURL *outputDirectoryURL;
@property (nonatomic) NSURL *securityScopedOutputURL;
@property (nonatomic) NSInteger videoQuality;
@property (nonatomic) NSInteger audioQuality;
@property (nonatomic) NSInteger profile;
@property (nonatomic) NSString *systemVersion;
@property (nonatomic) NSString *screenScale;
@property (nonatomic) NSString *versionBuildString;
@property (nonatomic) NSString *compileDateString;
@property (nonatomic) NSString *compileTimeString;
// BatchWindow
@property (nonatomic) NSWindowController *batchWindowController;
@property (nonatomic) CSDBatchViewController *batchViewController;
@property (nonatomic) NSMutableArray *batchProcessingList;
@property (nonatomic, getter = isBatchJobActive) BOOL batchJobActive;
@property (nonatomic) BOOL batchListModified;
// Settings
@property (nonatomic) NSWindowController *settingsWindowController;
@property (nonatomic) BOOL storeBatchList;
@property (nonatomic) BOOL overwriteFiles;
@property (nonatomic) BOOL playSystemsound;
@property (nonatomic) NSString *systemSoundTitle;
@property (nonatomic) NSUInteger activeProcessorCount;
@property (nonatomic) NSUInteger numberOfThreads;
// Information
@property (nonatomic) NSWindowController *informationWindowController;
// Debug
@property (nonatomic) NSWindowController *debugWindowController;
+ (CSDDataController *)sharedInstance;
- (NSString *)applicationSupportPath;
- (void)registerUserDefaults;
- (void)readUserDefaults;
- (void)writeUserDefaults;
- (void)removeUserDefaults;
- (void)storeBatchProcessingList;
- (void)setupOutputDirectory:(NSURL *)url;
- (BOOL)createOutputBookmark;
- (BOOL)resolveOutputBookmark;
- (BOOL)startUsingOutputBookmark;
- (void)stopUsingOutputBookmark;
- (void)checkBookmarkCounter;
@end
