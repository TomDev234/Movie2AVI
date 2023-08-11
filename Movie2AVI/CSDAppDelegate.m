//
//  CSDAppDelegate.m
//  Movie2AVI
//
//  Created by Tom on 12.10.14.
//  Copyright (c) 2014 Thomas Bodlien Software. All rights reserved.
//

#import "CSDAppDelegate.h"
#import "CSDDataController.h"

@interface CSDAppDelegate ()
@property (weak) IBOutlet NSMenuItem *batchProcessingMenuItem;
@property (weak) IBOutlet NSMenuItem *debugMenuItem;
@end

@implementation CSDAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self removeMenuItems];
  if ([CSDDataController sharedInstance].isBatchWindowOpen)
    [self openBatchWindow];
  if ([CSDDataController sharedInstance].isSettingsWindowOpen)
    [self openSettingsWindow];
  if ([CSDDataController sharedInstance].isInformationWindowOpen)
    [self openInformationWindow];
#ifdef DEBUG
  if ([CSDDataController sharedInstance].isDebugWindowOpen)
    [self openDebugWindow];
#endif
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  if ([CSDDataController sharedInstance].storeBatchList) {
    [[CSDDataController sharedInstance] storeBatchProcessingList];
  }
  [[CSDDataController sharedInstance] writeUserDefaults];
  [[CSDDataController sharedInstance] checkBookmarkCounter];
  return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

#pragma mark - MenuItems

- (void)removeMenuItems {
#ifndef DEBUG
  NSMenu *mainMenu = [NSApp windowsMenu];
  NSMenuItem *debugMenuItem = [mainMenu itemWithTitle:@"Debug-Information"];
  [mainMenu removeItem:debugMenuItem];
#endif
}

#pragma mark - Windows

- (void)openMainWindow {
  [[CSDDataController sharedInstance].mainWindowController showWindow:self];
}

- (void)openBatchWindow {
  if ([CSDDataController sharedInstance].batchWindowController == nil) {
    NSStoryboard *mainStoryBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    [CSDDataController sharedInstance].batchWindowController = [mainStoryBoard instantiateControllerWithIdentifier:@"BatchWindowController"];
  }
  [[CSDDataController sharedInstance].batchWindowController showWindow:self];
}

- (void)openSettingsWindow {
  if ([CSDDataController sharedInstance].settingsWindowController == nil) {
    NSStoryboard *mainStoryBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    [CSDDataController sharedInstance].settingsWindowController = [mainStoryBoard instantiateControllerWithIdentifier:@"SettingsWindowController"];
  }
  [[CSDDataController sharedInstance].settingsWindowController showWindow:self];
}

- (void)openInformationWindow {
  if ([CSDDataController sharedInstance].informationWindowController == nil) {
    NSStoryboard *mainStoryBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    [CSDDataController sharedInstance].informationWindowController = [mainStoryBoard instantiateControllerWithIdentifier:@"InformationWindowController"];
  }
  [[CSDDataController sharedInstance].informationWindowController showWindow:self];
}

- (void)openDebugWindow {
  if ([CSDDataController sharedInstance].debugWindowController == nil) {
    NSStoryboard *mainStoryBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    [CSDDataController sharedInstance].debugWindowController = [mainStoryBoard instantiateControllerWithIdentifier:@"DebugWindowController"];
  }
  [[CSDDataController sharedInstance].debugWindowController showWindow:self];
}

#pragma mark - Actions

- (IBAction)openMainWindowSelected:(id)sender {
  [self openMainWindow];
}

- (IBAction)openBatchWindowSelected:(id)sender {
  [self openBatchWindow];
}

- (IBAction)openSettingsWindowSelected:(id)sender {
  [self openSettingsWindow];
}

- (IBAction)openInformationWindowSelected:(id)sender {
  [self openInformationWindow];
}

- (IBAction)openDebugWindowSelected:(id)sender {
  [self openDebugWindow];
}

@end
