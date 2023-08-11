//    
//  CSDSettingsViewController.m
//  Movie2AVI
//
//  Created by Tom on 06.12.16.
//  Copyright © 2016 Thomas Bodlien Software. All rights reserved.
//

#import "CSDSettingsViewController.h"
#import "CSDDataController.h"

@interface CSDSettingsViewController ()
@property (weak) IBOutlet NSButton *overwriteFilesCheckbox;
@property (weak) IBOutlet NSButton *storeBatchListCheckbox;
@property (weak) IBOutlet NSButton *playSystemsoundCheckbox;
@property (weak) IBOutlet NSPopUpButton *systemSoundPopupButton;
@property (weak) IBOutlet NSTextField *processorsTextField;
@property (weak) IBOutlet NSTextField *threadsTextField;
@property (weak) IBOutlet NSStepper *threadsStepper;
@end

@implementation CSDSettingsViewController

- (void)setupSystemSoundTitles:(NSPopUpButton *)popUpbutton {
  NSError *error;
  NSArray *pathArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/System/Library/Sounds/" error:&error];
  if (error != nil) {
    NSLog(@"%@",error.localizedDescription);
  }
  else {
    [popUpbutton addItemWithTitle:@"none"];
    for (NSString *path in pathArray) {
      NSString *soundTitle = [path stringByDeletingPathExtension];
      [popUpbutton addItemWithTitle:soundTitle];
    }
  }
}

- (void)updateUserInterface {
  if ([CSDDataController sharedInstance].overwriteFiles)
    _overwriteFilesCheckbox.state = NSControlStateValueOn;
  else
    _overwriteFilesCheckbox.state = NSControlStateValueOff;
  if ([CSDDataController sharedInstance].storeBatchList)
    _storeBatchListCheckbox.state = NSControlStateValueOn;
  else
    _storeBatchListCheckbox.state = NSControlStateValueOff;
  if ([CSDDataController sharedInstance].playSystemsound) {
    _playSystemsoundCheckbox.state = NSControlStateValueOn;
    _systemSoundPopupButton.enabled = YES;
  }
  else {
    _playSystemsoundCheckbox.state = NSControlStateValueOff;
    _systemSoundPopupButton.enabled = NO;
  }
  if ([CSDDataController sharedInstance].systemSoundTitle != nil)
    [_systemSoundPopupButton selectItemWithTitle:[CSDDataController sharedInstance].systemSoundTitle];
  NSInteger numberOfThreads;
  if ([CSDDataController sharedInstance].numberOfThreads == 0)
    numberOfThreads = [CSDDataController sharedInstance].activeProcessorCount;
  else
    numberOfThreads = [CSDDataController sharedInstance].numberOfThreads;
  _processorsTextField.integerValue = [CSDDataController sharedInstance].activeProcessorCount;
  _threadsTextField.integerValue = numberOfThreads;
  _threadsStepper.maxValue = [CSDDataController sharedInstance].activeProcessorCount;
  _threadsStepper.integerValue = numberOfThreads;
}

#pragma mark - View

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupSystemSoundTitles:_systemSoundPopupButton];
  [self updateUserInterface];
}

- (void)viewDidAppear {
  [super viewDidAppear];
  [CSDDataController sharedInstance].settingsWindowOpen = YES;
}

- (void)viewDidDisappear {
  [super viewDidDisappear];
  [CSDDataController sharedInstance].settingsWindowOpen = NO;
}

#pragma mark - Actions

- (IBAction)overwriteFileCheckboxChanged:(id)sender {
  if (_overwriteFilesCheckbox.state == NSControlStateValueOn)
    [CSDDataController sharedInstance].overwriteFiles = YES;
  else
    [CSDDataController sharedInstance].overwriteFiles = NO;
}

- (IBAction)storeBatchListCheckboxChanged:(id)sender {
  if (_storeBatchListCheckbox.state == NSControlStateValueOn)
    [CSDDataController sharedInstance].storeBatchList = YES;
  else
    [CSDDataController sharedInstance].storeBatchList = NO;
}

- (IBAction)playSystemsoundCheckboxChanged:(id)sender {
  if (_playSystemsoundCheckbox.state == NSControlStateValueOn) {
    [CSDDataController sharedInstance].playSystemsound = YES;
    _systemSoundPopupButton.enabled = YES;
  }
  else {
    [CSDDataController sharedInstance].playSystemsound = NO;
    _systemSoundPopupButton.enabled = NO;
  }
}

- (IBAction)systemSoundPopupButtonChanged:(id)sender {
  NSPopUpButton *popupButton = sender;
  [CSDDataController sharedInstance].systemSoundTitle = popupButton.titleOfSelectedItem;
}

- (IBAction)threadsStepperChanged:(id)sender {
  NSStepper *stepper = sender;
  NSInteger numberOfThreads = stepper.integerValue;
  [CSDDataController sharedInstance].numberOfThreads = numberOfThreads;
  _threadsTextField.integerValue = numberOfThreads;
}

@end
