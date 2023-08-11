//
//  CSDDebugViewController.m
//  Movie2AVI
//
//  Created by Tom on 23.12.18.
//  Copyright © 2018 Thomas Bodlien Software. All rights reserved.
//

#import "CSDDebugViewController.h"
#import "CSDDataController.h"

@interface CSDDebugViewController ()
@property (unsafe_unretained) IBOutlet NSTextView *consoleTextView;
@end

@implementation CSDDebugViewController {
  NSMutableArray *_mutableConsoleArray;
}

#pragma mark - Initialization

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self != nil) {
    _mutableConsoleArray = [NSMutableArray new];
  }
  return self;
}

#pragma mark - Setup

- (void)setupTextView {
  [_consoleTextView setFont:[NSFont fontWithName:@"Menlo" size:12]];
}

#pragma mark - View

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupTextView];
}

- (void)viewDidAppear {
  [super viewDidAppear];
  [CSDDataController sharedInstance].debugWindowOpen = YES;
}

- (void)viewDidDisappear {
  [super viewDidDisappear];
  [CSDDataController sharedInstance].debugWindowOpen = NO;
}

#pragma mark - Requester

- (void)deleteApplicationSupportRequester {
  NSAlert *alert = [NSAlert new];
  alert.alertStyle = NSAlertStyleInformational;
  alert.messageText = @"DebugViewController-Request";
  alert.informativeText = @"Really delete ApplicationSupport?";
  [alert addButtonWithTitle:@"O.K."];
  [alert addButtonWithTitle:@"Cancel"];
  [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode){
    if (returnCode == NSAlertFirstButtonReturn) {
      [self clearApplicationSupport];
    }
  }];
}

- (void)clearUserDefaultsRequester {
  NSAlert *alert = [NSAlert new];
  alert.alertStyle = NSAlertStyleInformational;
  alert.messageText = @"DebugViewController-Request";
  alert.informativeText = @"Really delete UserDefaults?";
  [alert addButtonWithTitle:@"O.K."];
  [alert addButtonWithTitle:@"Cancel"];
  [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode){
    if (returnCode == NSAlertFirstButtonReturn) {
      [self removeUserDefaults];
      [self appendString:@"UserDefaults cleared"];
      [self update];
    }
  }];
}

#pragma mark - Console

- (void)appendString:(NSString *)string {
  [_mutableConsoleArray addObject:string];
}

- (void)appendFormat:(NSString *)formatString,... {
  va_list argumentsList;
  va_start(argumentsList,formatString);
  NSString *resultString = [[NSString alloc] initWithFormat:formatString arguments:argumentsList];
  [_mutableConsoleArray addObject:resultString];
  va_end(argumentsList);
}

- (void)update {
  NSString *textViewString = [_mutableConsoleArray componentsJoinedByString:@"\r"];
  if ([[NSThread currentThread] isMainThread]) {
    self.consoleTextView.string = textViewString;
  }
  else {
    dispatch_sync(dispatch_get_main_queue(),^{
      self.consoleTextView.string = textViewString;
    });
  }
}

- (void)scrollDown {
  if ([[NSThread currentThread] isMainThread]) {
    NSRange endOfOutputTextRange;
    endOfOutputTextRange = NSMakeRange(self.consoleTextView.string.length,0);
    [self.consoleTextView scrollRangeToVisible:endOfOutputTextRange];
  }
  else {
    dispatch_sync(dispatch_get_main_queue(),^{
      NSRange endOfOutputTextRange;
      endOfOutputTextRange = NSMakeRange(self.consoleTextView.string.length,0);
      [self.consoleTextView scrollRangeToVisible:endOfOutputTextRange];
    });
  }
}

#pragma mark - ApplicationSupport

- (NSString *)applicationSupportPath {
  NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
  NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES);
  NSString *searchPath = [searchPaths[0] stringByAppendingPathComponent:bundleIdentifier];
  return searchPath;
}

#pragma mark - Debug

- (void)listApplicationSupportDirectory {
  NSError *error;
  NSArray <NSString *> *urlArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.applicationSupportPath error:&error];
  if (error != nil) {
    NSLog(@"%@",error.localizedDescription);
  }
  else {
    for (NSURL *url in urlArray) {
      [self appendFormat:@"Document:%@",[url lastPathComponent]];
    }
  }
  [self update];
}

- (void)clearApplicationSupport {
  NSError *error;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray <NSString *> *pathArray = [fileManager contentsOfDirectoryAtPath:self.applicationSupportPath error:&error];
  for (NSString *fileName in pathArray) {
    NSString *filePath = [[CSDDataController sharedInstance].applicationSupportPath stringByAppendingString:fileName];
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    if (!success)
      [self appendFormat:@"clearApplicationSupport %@",error.localizedDescription];
    else
      [self appendString:@"ApplicationSupport cleared"];
    [self update];
  }
}

- (void)removeUserDefaults {
  [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
}

#pragma mark - Actions

- (IBAction)listApplicationSupportButtonPressed:(id)sender {
  [self listApplicationSupportDirectory];
}

- (IBAction)clearApplicationSupportButtonPressed:(id)sender {
  [self deleteApplicationSupportRequester];
}

- (IBAction)clearUserDefaultsButtonPressed:(id)sender {
  [self clearUserDefaultsRequester];
}

@end
