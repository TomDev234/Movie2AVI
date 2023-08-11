//
//  CSDMovieData.m
//  Movie2AVI
//
//  Created by Tom on 27.10.14.
//  Copyright (c) 2014 Thomas Bodlien Software. All rights reserved.
//

#import "CSDMovieData.h"

@interface CSDMovieData () <NSCoding>

@end

@implementation CSDMovieData

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  if (self != nil) {
    _fileName = [aDecoder decodeObjectForKey:@"kFileName"];
    _inputFileURL = [aDecoder decodeObjectForKey:@"kInputFileURL"];
    _inputFileBookmarkData = [aDecoder decodeObjectForKey:@"kInputFileBookmarkData"];
    _outputDirectoryURL = [aDecoder decodeObjectForKey:@"kOutputDirectoryURL"];
    _videoQuality = [aDecoder decodeIntegerForKey:@"kVideoQuality"];
    _audioQuality = [aDecoder decodeIntegerForKey:@"kAudioQuality"];
    _overwrite = [aDecoder decodeBoolForKey:@"kOverwrite"];
    _integerValue = [aDecoder decodeIntegerForKey:@"kIntegerValue"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:_fileName forKey:@"kFileName"];
  [aCoder encodeObject:_inputFileURL forKey:@"kInputFileURL"];
  [aCoder encodeObject:_inputFileBookmarkData forKey:@"kInputFileBookmarkData"];
  [aCoder encodeObject:_outputDirectoryURL forKey:@"kOutputDirectoryURL"];
  [aCoder encodeInteger:_videoQuality forKey:@"kVideoQuality"];
  [aCoder encodeInteger:_audioQuality forKey:@"kAudioQuality"];
  [aCoder encodeBool:_overwrite forKey:@"kOverwrite"];
  [aCoder encodeInteger:_integerValue forKey:@"kIntegerValue"];
}

#pragma mark - Bookmark

- (BOOL)createBookmark {
  NSError *error;
  BOOL returnCode;
  _inputFileBookmarkData = [_inputFileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
  if (error != nil) {
   returnCode = NO;
   NSLog(@"CSDMovieData createBookmark:%@",error);
  }
  else {
   returnCode = YES;
  }
  return returnCode;
}

- (BOOL)resolveBookmark {
  BOOL bookmarkDataIsStale;
  NSError *error;
  BOOL returnCode;
  if (_inputFileBookmarkData == nil) {
    returnCode = NO;
    NSLog(@"Input-Bookmarkdata is nil.");
  }
  else {
    _securityScopedInputFileURL = [NSURL URLByResolvingBookmarkData:_inputFileBookmarkData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&bookmarkDataIsStale error:&error];
    if (bookmarkDataIsStale) {
      NSLog(@"Bookmarkdata is stale.");
    }
    if (error != nil) {
      returnCode = NO;
      NSLog(@"CSDMovieData %@ resolveBookmark:%@",_fileName,error);
    }
    else {
      returnCode = YES;
    }
  }
  return returnCode;
}

- (BOOL)startUsingBookmark {
  NSLog(@"CSDMovieData startUsingBookmark");
  _inputFileBookmarkCounter++;
  return [_securityScopedInputFileURL startAccessingSecurityScopedResource];
}

- (void)stopUsingBookmark {
  NSLog(@"CSDMovieData stopUsingBookmark");
  _inputFileBookmarkCounter--;
  [_securityScopedInputFileURL stopAccessingSecurityScopedResource];
}

- (void)checkBookmarkCounter {
  if (_inputFileBookmarkCounter != 0) {
    NSLog(@"InputFileBookmarkCounter=%ld Error!",(long)_inputFileBookmarkCounter);
  }
}

@end
