//
//  CSDInformationViewController.m
//  Movie2AVI
//
//  Created by Tom on 22.12.18.
//  Copyright © 2018 Thomas Bodlien Software. All rights reserved.
//

#import "CSDInformationViewController.h"
#import "CSDDataController.h"

@interface CSDInformationViewController ()
@property (unsafe_unretained) IBOutlet NSTextView *mainTextView;
@end

@implementation CSDInformationViewController

#pragma mark - Setup

- (void)setupInformationView {
  NSDictionary *attributes = @{NSFontAttributeName:[NSFont systemFontOfSize:13], NSForegroundColorAttributeName:NSColor.textColor};

  NSString *aboutString = @"Movie2AVI is a Video-Converter, which converts various Video-File-Formats to the AVI-File-Format. Multithreading is supported to speed up the Conversion-Process.\n\n";
  NSAttributedString *aboutAttributedString = [[NSAttributedString alloc] initWithString:aboutString attributes:attributes];
  [_mainTextView.textStorage appendAttributedString:aboutAttributedString];

  NSString *systemVersionString = [NSString stringWithFormat:@"System-%@\n",[CSDDataController sharedInstance].systemVersion];
  NSAttributedString *systemVersionAttributedString = [[NSAttributedString alloc] initWithString:systemVersionString attributes:attributes];
  [_mainTextView.textStorage appendAttributedString:systemVersionAttributedString];

  NSString *clangVersionString = [NSString stringWithFormat:@"Clang %s\n",__clang_version__];
  NSAttributedString *clangVersionAttributedString = [[NSAttributedString alloc] initWithString:clangVersionString attributes:attributes];
  [_mainTextView.textStorage appendAttributedString:clangVersionAttributedString];
  
  NSString *numberOfCores = [NSString stringWithFormat:@"Number of Cores=%lu\n",[CSDDataController sharedInstance].activeProcessorCount];
  NSAttributedString *numberOfCoresAttributedString = [[NSAttributedString alloc] initWithString:numberOfCores attributes:attributes];
  [_mainTextView.textStorage appendAttributedString:numberOfCoresAttributedString];

  NSString *screenScaleString = [NSString stringWithFormat:@"Screen Scale=%@\n",[CSDDataController sharedInstance].screenScale];
  NSAttributedString *screenScaleStringAttributedString = [[NSAttributedString alloc] initWithString:screenScaleString attributes:attributes];
  [_mainTextView.textStorage appendAttributedString:screenScaleStringAttributedString];

  NSString *versionBuildString = [NSString stringWithFormat:@"App %@\n",[CSDDataController sharedInstance].versionBuildString];
  NSAttributedString *versionBuildAttributedString = [[NSAttributedString alloc] initWithString:versionBuildString attributes:attributes];
  [_mainTextView.textStorage appendAttributedString:versionBuildAttributedString];
}

#pragma mark - View

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupInformationView];
}

- (void)viewDidAppear {
  [super viewDidAppear];
  [CSDDataController sharedInstance].informationWindowOpen = YES;
}

- (void)viewDidDisappear {
  [super viewDidDisappear];
  [CSDDataController sharedInstance].informationWindowOpen = NO;
}

@end
