//
//  CSDMainViewController.m
//  Movie2AVI
//
//  Created by Tom on 06.12.16.
//  Copyright © 2016 Thomas Bodlien Software. All rights reserved.
//

#import "CSDMainViewController.h"
#import "CSDDataController.h"
#import "CSDMovieData.h"
#import "CSDBatchViewController.h"
@import AVFoundation;

typedef enum : NSInteger {
  ProfileValue_very_good = 0,ProfileValue_good,ProfileValue_compressed,ProfileValue_very_compressed,ProfileValue_none
} ProfileValue;

@interface CSDMainViewController ()
@property (weak) IBOutlet NSPathControl *inputFilePathControl;
@property (weak) IBOutlet NSPathControl *outputDirectoryPathControl;
@property (weak) IBOutlet NSSlider *videoQualitySlider;
@property (weak) IBOutlet NSSlider *audioQualitySlider;
@property (weak) IBOutlet NSTextField *videoQualityTextField;
@property (weak) IBOutlet NSTextField *audioQualityTextField;
@property (unsafe_unretained) IBOutlet NSTextView *outputTextView;
@property (weak) IBOutlet NSPopUpButton *profilePopupButton;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSButton *startButton;
@property (weak) IBOutlet NSButton *stopButton;
@end

@implementation CSDMainViewController {
  NSAlert *_copyProtectionAlert;
  NSTask __block *_encoderTask;
  NSPipe __block *_outputPipe;
  NSNotification *_batchJobNotification;
  NSInteger _batchJobIndex;
  float __block _durationValue;
  BOOL __block _isRunning;
  BOOL __block _stopProcessingBatchJob;
}

#pragma mark - Class

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self != nil) {
    [[CSDDataController sharedInstance] registerUserDefaults];
    [[CSDDataController sharedInstance] readUserDefaults];
    [[CSDDataController sharedInstance] resolveOutputBookmark];
  }
  return self;
}

- (void)getBundleIdentifier {
#ifdef DEBUG
  NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
  NSLog(@"%@",bundleIdentifier);
#endif
}

- (void)getSystemInfo {
//  NSHost *host = NSHost.currentHost;
  NSProcessInfo *processInfo = NSProcessInfo.processInfo;
  NSString *systemVersion = processInfo.operatingSystemVersionString;
  CGFloat scaleFactor = NSScreen.mainScreen.backingScaleFactor;
  NSNumber *scaleFactorNumber = [NSNumber numberWithDouble:scaleFactor];
  NSString *screenScale = scaleFactorNumber.stringValue;
  [CSDDataController sharedInstance].activeProcessorCount = processInfo.activeProcessorCount;
  [CSDDataController sharedInstance].systemVersion = systemVersion;
  [CSDDataController sharedInstance].screenScale = screenScale;
#ifdef DEBUG
//  NSLog(@"HostName=%@",host.name);
  NSLog(@"System-%@",systemVersion);
  NSLog(@"Clang %s",__clang_version__);
  NSLog(@"Number of Cores=%lu",(unsigned long)processInfo.activeProcessorCount);
  NSLog(@"Screen-Scale=%@",screenScale);
#endif
}

- (void)getVersionInfo {
  NSString *appVersionString = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  NSString *appBuildString = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
  NSString *versionBuildString = [NSString stringWithFormat:@"Version: %@ (%@) %s %s",appVersionString,appBuildString,__DATE__,__TIME__];
#ifdef DEBUG
  NSLog(@"%@",versionBuildString);
#endif
  [CSDDataController sharedInstance].versionBuildString = versionBuildString;
  [CSDDataController sharedInstance].compileDateString = [NSString stringWithUTF8String:__DATE__];
  [CSDDataController sharedInstance].compileTimeString = [NSString stringWithUTF8String:__TIME__];
}

- (void)getStackSize {
#ifdef DEBUG
  NSThread *currentThread = [NSThread currentThread];
  NSLog(@"Stacksize=%ld\n",(unsigned long)currentThread.stackSize);
#endif
}

- (void)updateUserInterface {
  if (_isRunning) {
    _startButton.enabled = NO;
    _stopButton.enabled = YES;
  }
  else {
    _startButton.enabled = YES;
    _stopButton.enabled = NO;
  }
  _outputDirectoryPathControl.URL = [CSDDataController sharedInstance].securityScopedOutputURL;
  NSInteger videoQuality = [CSDDataController sharedInstance].videoQuality;
  [_videoQualityTextField setIntegerValue:videoQuality];
  [_videoQualitySlider setIntegerValue:videoQuality];
  NSInteger audioQuality = [CSDDataController sharedInstance].audioQuality;
  [_audioQualityTextField setIntegerValue:audioQuality];
  [_audioQualitySlider setIntegerValue:audioQuality];
  [_profilePopupButton selectItemAtIndex:[CSDDataController sharedInstance].profile];
}

- (void)setProfile {
  switch ([CSDDataController sharedInstance].profile) {
    case ProfileValue_very_good:
      [CSDDataController sharedInstance].videoQuality = 1;
      [CSDDataController sharedInstance].audioQuality = 1;
      break;
    case ProfileValue_good:
      [CSDDataController sharedInstance].videoQuality = 2;
      [CSDDataController sharedInstance].audioQuality = 2;
      break;
    case ProfileValue_compressed:
      [CSDDataController sharedInstance].videoQuality = 4;
      [CSDDataController sharedInstance].audioQuality = 5;
      break;
    case ProfileValue_very_compressed:
      [CSDDataController sharedInstance].videoQuality = 10;
      [CSDDataController sharedInstance].audioQuality = 6;
      break;
    case ProfileValue_none:
      break;
  }
}

- (void)registerBatchJobNotification {
  _batchJobNotification = [NSNotification notificationWithName:@"BatchJobNotification" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNextBatchJob:) name:@"BatchJobNotification" object:nil];
}

- (void)unregisterBatchJobNotification {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BatchJobNotification" object:nil];
}

- (BOOL)checkForDirectory:(NSURL *)directoryURL {
  BOOL result;
  NSString *directoryPath = [directoryURL path];
  if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&result]) {
  }
  else {
    result = NO;
    NSLog(@"directoryURL does not exist");
  }
  return result;
}

- (BOOL)checkOutputDirectoryPathWithURL:(NSURL *)outputDirectoryURL {
  BOOL rc;
  if ([self checkForDirectory:outputDirectoryURL] == NO) {
    rc = NO;
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"O.K."];
    [alert setMessageText:@"Select a Directory"];
    [alert setInformativeText:@"The Output-Directory is missing."];
    [alert setAlertStyle:NSAlertStyleWarning];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
    }
  }
  else {
    rc = YES;
    NSLog(@"OutputPath = Directory");
  }
  return rc;
}

- (BOOL)checkForFile:(NSURL *)fileURL {
  BOOL result, isDirectory;
  NSString *filePath = fileURL.path;
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory]) {
    if (isDirectory)
      result = NO;
    else
      result = YES;
  }
  else {
    result = NO;
    NSLog(@"checkForFile fileURL does not exist");
  }
  return result;
}

- (BOOL)checkInputFileURL:(NSURL *)inputFileURL {
  BOOL rc;
  if ([self checkForFile:inputFileURL] == NO) {
    rc = NO;
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"O.K."];
    [alert setMessageText:@"Select a File!"];
    [alert setInformativeText:@"The Input-File is missing."];
    [alert setAlertStyle:NSWarningAlertStyle];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
    }
  }
  else {
    rc = YES;
    NSLog(@"InputPath = File");
  }
  return rc;
}

- (BOOL)isMovieCiphered:(NSURL *)movieURL {
  BOOL returnValue;
  AVAsset *movieAsset = [AVAsset assetWithURL:movieURL];
  if ([movieAsset hasProtectedContent]) {
    returnValue = YES;
  }
  else {
    returnValue = NO;
  }
  return returnValue;
}

- (void)copyProtectionAlert {
  if (_copyProtectionAlert == nil) {
    _copyProtectionAlert = [NSAlert new];
    [_copyProtectionAlert addButtonWithTitle:@"O.K."];
    [_copyProtectionAlert setMessageText:@"Movie2AVI Copy-Protection-Alert"];
    [_copyProtectionAlert setInformativeText:@"Copy protected Movie-Files will not be converted."];
    [_copyProtectionAlert setAlertStyle:NSWarningAlertStyle];
    if ([_copyProtectionAlert runModal] == NSAlertFirstButtonReturn) {
    }
  }
}

- (NSString *)scanTime:(NSString *)inputString rangeString:(NSString *)theRangeString {
  NSString *timeValueString;
  NSRange timeValueStringRange;
  NSRange durationRange = [inputString rangeOfString:theRangeString options:NSLiteralSearch];
  if (durationRange.location == NSNotFound) {
    timeValueString = nil;
  }
  else {
    timeValueStringRange.location = durationRange.location + durationRange.length;
    timeValueStringRange.length = 8;
    if (inputString.length < timeValueStringRange.location + timeValueStringRange.length) {
      timeValueString = nil;
    }
    else {
      timeValueString = [inputString substringWithRange:timeValueStringRange];
    }
  }
  return timeValueString;
}

- (float)secondsFromTimeString:(NSString *)timeString {
  float seconds = 0;
  if (timeString.length == 8) {
    NSRange hRange;
    hRange.location = 0;
    hRange.length = 2;
    NSString *hString = [timeString substringWithRange:hRange];
    float hValue = [hString floatValue];
    NSRange mRange;
    mRange.location = 3;
    mRange.length = 2;
    NSString *mString = [timeString substringWithRange:mRange];
    float mValue = [mString floatValue];
    NSRange sRange;
    sRange.location = 6;
    sRange.length = 2;
    NSString *sString = [timeString substringWithRange:sRange];
    float sValue = [sString floatValue];
    seconds = hValue * 3600 + mValue * 60 + sValue;
  }
  return seconds;
}

- (void)setProgress:(NSString *)timeString {
  float progress = 100 / _durationValue * [self secondsFromTimeString:timeString];
  _progressIndicator.doubleValue = progress;
}

- (void)startEncoder {
  if ([[CSDDataController sharedInstance] startUsingOutputBookmark] == NO) {
    NSLog(@"startUsingOutputBookmark Error!");
  }
  if ([CSDDataController sharedInstance].isBatchWindowOpen == YES) {
    [self processBatchJobs];
  }
  else {
    if ([self checkInputFileURL:_inputFilePathControl.URL] && [self checkOutputDirectoryPathWithURL:[CSDDataController sharedInstance].securityScopedOutputURL]) {
      [self encodeFile:nil inputFileURL:_inputFilePathControl.URL outputDirectoryURL:[CSDDataController sharedInstance].securityScopedOutputURL];
    }
    else {
      [[CSDDataController sharedInstance] stopUsingOutputBookmark];
    }
  }
}

- (void)processBatchJobs {
  CSDMovieData *movieData;
  _batchJobIndex = 0;
  _stopProcessingBatchJob = NO;
  if ([CSDDataController sharedInstance].batchProcessingList.count == 0) {
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"O.K."];
    [alert setMessageText:@"Input-Files are missing"];
    [alert setInformativeText:@"Add Files in the BatchProcessing-Window or close it, to convert the File from the Main-Window."];
    [alert setAlertStyle:NSWarningAlertStyle];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
    }
    [[CSDDataController sharedInstance] stopUsingOutputBookmark];
  }
  else {
    [CSDDataController sharedInstance].batchJobActive = YES;
    [self registerBatchJobNotification];
    if (_batchJobIndex < [CSDDataController sharedInstance].batchProcessingList.count && [CSDDataController sharedInstance].isBatchJobActive == YES) {
      movieData = [[CSDDataController sharedInstance].batchProcessingList objectAtIndex:_batchJobIndex];
      [movieData startUsingBookmark];
      NSLog(@"fileName=%@",movieData.fileName);
      if ([self checkInputFileURL:movieData.securityScopedInputFileURL] &&
          [self checkOutputDirectoryPathWithURL:[CSDDataController sharedInstance].securityScopedOutputURL]) {
        [[CSDDataController sharedInstance].batchViewController selectTableViewRow:_batchJobIndex++];
        [self encodeFile:movieData inputFileURL:movieData.securityScopedInputFileURL outputDirectoryURL:[CSDDataController sharedInstance].securityScopedOutputURL];
      }
      else {
        [movieData stopUsingBookmark];
        [[CSDDataController sharedInstance] stopUsingOutputBookmark];
      }
    }
  }
}

- (void)processNextBatchJob:(NSNotification *)notification {
  CSDMovieData *movieData;
  NSLog(@"processNextBatchJob");
  if (_batchJobIndex < [CSDDataController sharedInstance].batchProcessingList.count && _stopProcessingBatchJob == NO) {
    movieData = [[CSDDataController sharedInstance].batchProcessingList objectAtIndex:_batchJobIndex];
    [movieData startUsingBookmark];
    NSLog(@"fileName=%@",movieData.fileName);
    [[CSDDataController sharedInstance].batchViewController selectTableViewRow:_batchJobIndex++];
    if ([self checkForFile:movieData.securityScopedInputFileURL] == YES) {
      [self encodeFile:movieData inputFileURL:movieData.securityScopedInputFileURL outputDirectoryURL:[CSDDataController sharedInstance].securityScopedOutputURL];
    }
    else {
      [[NSNotificationCenter defaultCenter] postNotification:_batchJobNotification];
    }
  }
  else {
    [CSDDataController sharedInstance].batchJobActive = NO;
    [self unregisterBatchJobNotification];
    [self updateUserInterface];
    if ([CSDDataController sharedInstance].playSystemsound) {
      [[NSSound soundNamed:[CSDDataController sharedInstance].systemSoundTitle] play];
    }
    [movieData stopUsingBookmark];
    [[CSDDataController sharedInstance] stopUsingOutputBookmark];
  }
}

- (void)encodeFile:(CSDMovieData *)movieData inputFileURL:(NSURL *)inputFileURL outputDirectoryURL:(NSURL *)outputDirectoryURL {
  NSString *encoderPath = [NSBundle.mainBundle pathForResource:@"ffmpeg" ofType:nil];
  NSString *inputFilePath = inputFileURL.path;
  NSString *inputFileName = inputFileURL.lastPathComponent;
  NSString *outputDirectoryPath;
  if ([self isMovieCiphered:inputFileURL]) {
    _outputTextView.string = [_outputTextView.string stringByAppendingString:@"\nskipping copy protected Movie-File\n"];
    if ([CSDDataController sharedInstance].batchJobActive == NO) {
      [[CSDDataController sharedInstance] stopUsingOutputBookmark];
      [self copyProtectionAlert];
    }
    else {
      [movieData stopUsingBookmark];
      [[NSNotificationCenter defaultCenter] postNotification:_batchJobNotification];
    }
  }
  else {
    if ([self checkForDirectory:outputDirectoryURL]) {
      outputDirectoryPath = outputDirectoryURL.path;
    }
    else {
      outputDirectoryPath = [[outputDirectoryURL URLByDeletingLastPathComponent] path];
    }
    NSString *outputFileName = [[inputFileName stringByDeletingPathExtension] stringByAppendingPathExtension:@"avi"];
    NSString *videoQualityString = [NSString stringWithFormat:@"%ld",(long)[CSDDataController sharedInstance].videoQuality];
    NSString *audioQualityString = [NSString stringWithFormat:@"%ld",(long)[CSDDataController sharedInstance].audioQuality];
    NSString *threads = @"-threads";
    if ([CSDDataController sharedInstance].numberOfThreads == 0)
      threads = [threads stringByAppendingFormat:@" %ld",[CSDDataController sharedInstance].activeProcessorCount];
    else
      threads = [threads stringByAppendingFormat:@" %ld",[CSDDataController sharedInstance].numberOfThreads];
    NSString *outputFilePath = [outputDirectoryPath stringByAppendingPathComponent:outputFileName];
    if ([CSDDataController sharedInstance].overwriteFiles && [self checkForFile:[NSURL URLWithString:[outputFilePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]) {
      BOOL result;
      NSError *error;
      result = [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:&error];
      if (result == NO) {
        NSLog(@"removeItemAtPath Error:%@",error);
      }
    }
    else if ([self checkForFile:[NSURL URLWithString:[outputFilePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]) {
      NSLog(@"OutputFilePath existing");
      NSAlert *alert = [NSAlert new];
      [alert addButtonWithTitle:@"O.K."];
      [alert addButtonWithTitle:@"Cancel"];
      [alert setMessageText:@"Replace File?"];
      [alert setInformativeText:@"The OutputFile is existing."];
      [alert setAlertStyle:NSWarningAlertStyle];
      if ([alert runModal] == NSAlertFirstButtonReturn) {
        BOOL result;
        NSError *error;
        result = [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:&error];
        if (result == NO) {
          NSLog(@"removeItemAtPath Error:%@",error);
        }
      }
      else {
        if ([CSDDataController sharedInstance].batchJobActive == YES) {
          [[NSNotificationCenter defaultCenter] postNotification:_batchJobNotification];
        }
        return;
      }
    }
    NSArray *arguments = @[encoderPath,inputFilePath,videoQualityString,audioQualityString,threads,outputFilePath];
    _outputTextView.string = @"";
    _progressIndicator.doubleValue = 0;
    _isRunning = YES;
    [self updateUserInterface];
    [self runScript:movieData arguments:arguments];
  }
}

- (void)runScript:(CSDMovieData *)movieData arguments:(NSArray*)arguments {
  NSString __block *timeValueString;
  NSString __block *textViewString = [NSString new];
  NSMutableArray __block *mutableTextViewArray = [NSMutableArray new];
  BOOL __block firstFrameString = YES;
  dispatch_queue_t taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0);
  dispatch_async(taskQueue,^{
    @try {
      NSString *launchPath = [[NSBundle mainBundle] pathForResource:@"encodeFile" ofType:@"sh"];
      self->_encoderTask = [NSTask new];
      self->_encoderTask.launchPath = launchPath;
      self->_encoderTask.arguments = arguments;
      self->_outputPipe = [NSPipe new];
      self->_encoderTask.standardOutput = self->_outputPipe;
      self->_encoderTask.standardError = self->_outputPipe;
      [[self->_outputPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
      [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:[self->_outputPipe fileHandleForReading] queue:nil usingBlock:^(NSNotification *notification) {
        NSData *output = [[self->_outputPipe fileHandleForReading] availableData];
        NSString __block *outputString = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
        dispatch_sync(dispatch_get_main_queue(),^{
          if (outputString != nil) {
            NSRange frameRange = [outputString rangeOfString:@"frame=" options:NSLiteralSearch];
            if (frameRange.location == NSNotFound) {
              [mutableTextViewArray addObject:outputString];
            }
            else {
              if (!firstFrameString) {
                [mutableTextViewArray removeLastObject];
              }
              else {
                firstFrameString = NO;
              }
              [mutableTextViewArray addObject:outputString];
            }
            textViewString = [mutableTextViewArray componentsJoinedByString:@"\r"];
            self.outputTextView.string = textViewString;
            NSRange endOfOutputTextRange;
            endOfOutputTextRange = NSMakeRange(self.outputTextView.string.length,0);
            [self.outputTextView scrollRangeToVisible:endOfOutputTextRange];
            if (self->_durationValue == 0) {
              timeValueString = [self scanTime:outputString rangeString:@"Duration: "];
              if (timeValueString != nil) {
                self->_durationValue = [self secondsFromTimeString:timeValueString];
              }
            }
            timeValueString = [self scanTime:outputString rangeString:@"time="];
            if (timeValueString != nil && self->_durationValue != 0) {
              [self setProgress:timeValueString];
            }
          }
        });
        [[self->_outputPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
      }];
      [self->_encoderTask launch];
      [self->_encoderTask waitUntilExit];
    }
    @catch (NSException *exception) {
      NSLog(@"Problem Running Task: %@",exception);
      dispatch_sync(dispatch_get_main_queue(),^{
        NSAlert *alert = [NSAlert new];
        [alert addButtonWithTitle:@"O.K."];
        [alert setMessageText:@"Error Running Task!"];
        [alert setInformativeText:[exception description]];
        [alert setAlertStyle:NSWarningAlertStyle];
        if ([alert runModal] == NSAlertFirstButtonReturn) {
        }
      });
    }
    @finally {
      dispatch_sync(dispatch_get_main_queue(),^{
        self.outputTextView.string = [self.outputTextView.string stringByAppendingString:@"READY."];
        NSRange endOfOutputTextRange;
        endOfOutputTextRange = NSMakeRange(self.outputTextView.string.length,0);
        [self.outputTextView scrollRangeToVisible:endOfOutputTextRange];
        [self encodingFinished];
        [self updateUserInterface];
        if ([CSDDataController sharedInstance].batchJobActive == YES) {
          [movieData stopUsingBookmark];
          [[NSNotificationCenter defaultCenter] postNotification:self->_batchJobNotification];
        }
        else {
          if ([CSDDataController sharedInstance].playSystemsound) {
            [[NSSound soundNamed:[CSDDataController sharedInstance].systemSoundTitle] play];
          }
          [[CSDDataController sharedInstance] stopUsingOutputBookmark];
        }
      });
    }
  });
}

- (void)encodingFinished {
  _isRunning = NO;
  _durationValue = 0;
}

- (void)stopEncoder {
  _stopProcessingBatchJob = YES;
  if ([_encoderTask isRunning]) {
    [_encoderTask terminate];
  }
}

#pragma mark - View

- (void)viewDidLoad {
  [super viewDidLoad];
  [self getBundleIdentifier];
  [self getSystemInfo];
  [self getVersionInfo];
  [self getStackSize];
  [self updateUserInterface];
}

- (void)viewDidAppear {
  [super viewDidAppear];
  [CSDDataController sharedInstance].mainWindowOpen = YES;
}

- (void)viewDidDisappear {
  [super viewDidDisappear];
  [CSDDataController sharedInstance].mainWindowOpen = NO;
}

#pragma mark - Actions

- (IBAction)sourceFileChanged:(id)sender {
  NSLog(@"SourceFileChanged not implemented, yet.");
}

- (IBAction)outputPathChanged:(id)sender {
  NSPathControl *pathControl = sender;
  [[CSDDataController sharedInstance] setupOutputDirectory:pathControl.URL];
}

- (IBAction)videoQualitySliderChanged:(id)sender {
  NSSlider *slider = sender;
  NSInteger newValue = slider.integerValue;
  [CSDDataController sharedInstance].videoQuality = newValue;
  [CSDDataController sharedInstance].profile = ProfileValue_none;
  [self updateUserInterface];
}

- (IBAction)audioQualitySliderChanged:(id)sender {
  NSSlider *slider = sender;
  NSInteger newValue = slider.integerValue;
  [CSDDataController sharedInstance].audioQuality = newValue;
  [CSDDataController sharedInstance].profile = ProfileValue_none;
  [self updateUserInterface];
}

- (IBAction)videoQualityTextFieldChanged:(id)sender {
  NSTextField *textField = sender;
  NSInteger newValue = textField.integerValue;
  [CSDDataController sharedInstance].videoQuality = newValue;
  [CSDDataController sharedInstance].profile = ProfileValue_none;
  [self updateUserInterface];
}

- (IBAction)audioQualityTextFieldChanged:(id)sender {
  NSTextField *textField = sender;
  NSInteger newValue = textField.integerValue;
  [CSDDataController sharedInstance].audioQuality = newValue;
  [CSDDataController sharedInstance].profile = ProfileValue_none;
  [self updateUserInterface];
}

- (IBAction)profilePopupButtonChanged:(id)sender {
  NSPopUpButton *popupButton = sender;
  [CSDDataController sharedInstance].profile = popupButton.indexOfSelectedItem;
  [self setProfile];
  [self updateUserInterface];
}

- (IBAction)startButtonPressed:(id)sender {
  [self startEncoder];
}

- (IBAction)stopButtonPressed:(id)sender {
  [self stopEncoder];
}

@end
