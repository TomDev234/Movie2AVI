//
//  CSDMovieData.h
//  Movie2AVI
//
//  Created by Tom on 27.10.14.
//  Copyright (c) 2014 Thomas Bodlien Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSDMovieData : NSObject
@property (nonatomic) NSString *fileName;
@property (nonatomic) NSURL *inputFileURL;
@property (nonatomic) NSData *inputFileBookmarkData;
@property (nonatomic) NSURL *securityScopedInputFileURL;
@property (nonatomic) NSInteger inputFileBookmarkCounter;
@property (nonatomic) NSURL *outputDirectoryURL;
@property (nonatomic) NSInteger videoQuality;
@property (nonatomic) NSInteger audioQuality;
@property (nonatomic) BOOL overwrite;
@property (nonatomic) NSInteger integerValue;
- (BOOL)createBookmark;
- (BOOL)resolveBookmark;
- (BOOL)startUsingBookmark;
- (void)stopUsingBookmark;
@end
