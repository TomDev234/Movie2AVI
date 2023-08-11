//
//  CSDMainWindowController.m
//  Movie2AVI
//
//  Created by Tom on 11.04.18.
//  Copyright © 2018 Thomas Bodlien Software. All rights reserved.
//

#import "CSDMainWindowController.h"
#import "CSDDataController.h"

@implementation CSDMainWindowController

- (void)windowDidLoad {
  [super windowDidLoad];
  [CSDDataController sharedInstance].mainWindowController = self;
}

@end
