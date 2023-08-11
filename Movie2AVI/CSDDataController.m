//
//  CSDDataController.m
//  Movie2AVI
//
//  Created by Tom on 13.10.14.
//  Copyright (c) 2014 Thomas Bodlien Software. All rights reserved.
//

#import "CSDDataController.h"
#import "CSDMovieData.h"

@implementation CSDDataController {
  NSData *_outputDirectoryBookmarkData;
}

@synthesize mainWindowOpen = _mainWindowOpen;
@synthesize batchWindowOpen = _batchWindowOpen;
@synthesize settingsWindowOpen = _settingsWindowOpen;
@synthesize informationWindowOpen = _informationWindowOpen;
@synthesize debugWindowOpen = _debugWindowOpen;
@synthesize batchJobActive = _batchJobActive;

+ (CSDDataController *)sharedInstance {
  static CSDDataController *_sharedInstance = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    _sharedInstance = [CSDDataController new];
  });
  return _sharedInstance;
}

- (id)init {
  self = [super init];
  if (self != nil) {
    [self createApplicationSupportDirectory];
    [self listApplicationSupportDirectory];
  }
  return self;
}

#pragma mark - UserDefaults

- (void)registerUserDefaults {
  NSString *userDefaultsPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
  NSDictionary *userDefaultsDictionary = [NSDictionary dictionaryWithContentsOfFile:userDefaultsPath];
  [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsDictionary];
}

- (void)readUserDefaults {
  _outputDirectoryBookmarkData = [[NSUserDefaults standardUserDefaults] dataForKey:@"kBookmarkData"];
  _batchWindowOpen = [[NSUserDefaults standardUserDefaults] boolForKey:@"kBatchWindowOpen"];
  _settingsWindowOpen = [[NSUserDefaults standardUserDefaults] boolForKey:@"kSettingsWindowOpen"];
  _informationWindowOpen = [[NSUserDefaults standardUserDefaults] boolForKey:@"kInformationWindowOpen"];
  _debugWindowOpen = [[NSUserDefaults standardUserDefaults] boolForKey:@"kDebugWindowOpen"];
  _videoQuality = [[NSUserDefaults standardUserDefaults] integerForKey:@"kVideoQuality"];
  _audioQuality = [[NSUserDefaults standardUserDefaults] integerForKey:@"kAudioQuality"];
  _profile = [[NSUserDefaults standardUserDefaults] integerForKey:@"kProfile"];
  _storeBatchList = [[NSUserDefaults standardUserDefaults] boolForKey:@"kStoreBatchList"];
  _overwriteFiles = [[NSUserDefaults standardUserDefaults] boolForKey:@"kOverwriteFiles"];
  _playSystemsound = [[NSUserDefaults standardUserDefaults] boolForKey:@"kPlaySystemsound"];
  _systemSoundTitle = [[NSUserDefaults standardUserDefaults] stringForKey:@"kSystemSoundTitle"];
  _numberOfThreads = [[NSUserDefaults standardUserDefaults] integerForKey:@"kNumberOfThreads"];
}

- (void)writeUserDefaults {
  [[NSUserDefaults standardUserDefaults] setObject:_outputDirectoryBookmarkData forKey:@"kBookmarkData"];
  [[NSUserDefaults standardUserDefaults] setBool:_batchWindowOpen forKey:@"kBatchWindowOpen"];
  [[NSUserDefaults standardUserDefaults] setBool:_settingsWindowOpen forKey:@"kSettingsWindowOpen"];
  [[NSUserDefaults standardUserDefaults] setBool:_informationWindowOpen forKey:@"kInformationWindowOpen"];
  [[NSUserDefaults standardUserDefaults] setBool:_debugWindowOpen forKey:@"kDebugWindowOpen"];
  [[NSUserDefaults standardUserDefaults] setInteger:_videoQuality forKey:@"kVideoQuality"];
  [[NSUserDefaults standardUserDefaults] setInteger:_audioQuality forKey:@"kAudioQuality"];
  [[NSUserDefaults standardUserDefaults] setInteger:_profile forKey:@"kProfile"];
  [[NSUserDefaults standardUserDefaults] setBool:_storeBatchList forKey:@"kStoreBatchList"];
  [[NSUserDefaults standardUserDefaults] setBool:_overwriteFiles forKey:@"kOverwriteFiles"];
  [[NSUserDefaults standardUserDefaults] setBool:_playSystemsound forKey:@"kPlaySystemsound"];
  [[NSUserDefaults standardUserDefaults] setObject:_systemSoundTitle forKey:@"kSystemSoundTitle"];
  [[NSUserDefaults standardUserDefaults] setInteger:_numberOfThreads forKey:@"kNumberOfThreads"];
}

- (void)removeUserDefaults {
  [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
}

#pragma mark - ApplicationSupport

- (NSString *)applicationSupportPath {
  NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
  NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES);
  NSString *searchPath = [searchPaths[0] stringByAppendingPathComponent:bundleIdentifier];
  return searchPath;
}

- (void)createApplicationSupportDirectory {
  BOOL result = NO;
  NSError *error;
  if (![[NSFileManager defaultManager] fileExistsAtPath:[self applicationSupportPath]]) {
    result = [[NSFileManager defaultManager] createDirectoryAtPath:[self applicationSupportPath] withIntermediateDirectories:NO attributes:nil error:&error];
    if (result == NO) {
      NSLog(@"createApplicationSupportDirectory:%@",error.localizedDescription);
    }
  }
}

- (void)listApplicationSupportDirectory {
#ifdef DEBUG
  NSError *error;
  NSArray <NSString *> *urlArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self applicationSupportPath] error:&error];
  if (error != nil) {
    NSLog(@"listApplicationSupportDirectory:%@",error.localizedDescription);
  }
  else {
    for (NSURL *url in urlArray) {
      NSLog(@"Document:%@",[url lastPathComponent]);
    }
  }
#endif
}

#pragma mark - OutputBookmark

- (void)setupOutputDirectory:(NSURL *)url {
  _outputDirectoryURL = url;
  [self createOutputBookmark];
  [self resolveOutputBookmark];
}

- (BOOL)createOutputBookmark {
  NSError *error;
  BOOL returnCode;
  _outputDirectoryBookmarkData = [_outputDirectoryURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
  if (error != nil) {
    returnCode = NO;
    NSLog(@"createOutputBookmark:%@",error);
  }
  else {
    returnCode = YES;
  }
  return returnCode;
}

- (BOOL)resolveOutputBookmark {
  BOOL bookmarkDataIsStale;
  NSError *error;
  BOOL returnCode;
  if (_outputDirectoryBookmarkData == nil) {
    returnCode = NO;
    NSLog(@"Output-Bookmarkdata is nil.");
  }
  else {
    _securityScopedOutputURL = [NSURL URLByResolvingBookmarkData:_outputDirectoryBookmarkData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&bookmarkDataIsStale error:&error];
    if (bookmarkDataIsStale) {
      NSLog(@"Output-Bookmarkdata is stale.");
    }
    if (error != nil) {
      returnCode = NO;
      NSLog(@"resolveOutputBookmark:%@",error);
    }
    else {
      returnCode = YES;
    }
  }
  return returnCode;
}

- (BOOL)startUsingOutputBookmark {
  NSLog(@"startUsingOutputBookmark");
  _outputDirectoryBookmarkCounter++;
  return [_securityScopedOutputURL startAccessingSecurityScopedResource];
}

- (void)stopUsingOutputBookmark {
  NSLog(@"stopUsingOutputBookmark");
  _outputDirectoryBookmarkCounter--;
  [_securityScopedOutputURL stopAccessingSecurityScopedResource];
}

- (void)checkBookmarkCounter {
  if (_outputDirectoryBookmarkCounter != 0) {
    NSLog(@"OutputDirectoryBookmarkCounter != 0 Error!");
  }
}

#pragma mark - BatchProcessingList

- (void)enumerateBatchProcessingList {
  for (NSInteger i = 0; i < _batchProcessingList.count; i++) {
    CSDMovieData *movieData = _batchProcessingList[i];
    movieData.integerValue = i;
  }
}

- (void)sortBatchProcessingList {
  [_batchProcessingList sortUsingComparator:^(id obj1,id obj2) {
    NSComparisonResult result;
    if ([obj1 integerValue] > [obj2 integerValue])
      result = (NSComparisonResult)NSOrderedDescending;
    else if ([obj1 integerValue] < [obj2 integerValue])
      result = (NSComparisonResult)NSOrderedAscending;
    else
      result = (NSComparisonResult)NSOrderedSame;
    return result;
  }];
}

- (NSMutableArray *)batchProcessingList {
  if (_batchProcessingList == nil) {
    CSDMovieData *movieData;
    NSArray *fileArray,*movieArray;
    NSError *error;
    NSString *applicationSupportDirectory = [self applicationSupportPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    _batchProcessingList = [NSMutableArray new];
    fileArray = [fileManager contentsOfDirectoryAtPath:applicationSupportDirectory error:&error];
    if (error != nil) {
      NSLog(@"%@",error.localizedDescription);
    }
    movieArray = [fileArray pathsMatchingExtensions:@[@"md"]];
    for (NSString *file in movieArray) {
      NSString *moviePath = [applicationSupportDirectory stringByAppendingPathComponent:file];
      NSData *codedData = [NSData dataWithContentsOfFile:moviePath];
      if (codedData != nil) {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:codedData];
        movieData = [unarchiver decodeObjectForKey:@"CSDMovieData"];
        [unarchiver finishDecoding];
        if (![movieData resolveBookmark])
          _batchListModified = YES;
        else
          [_batchProcessingList addObject:movieData];
      }
    }
    [self sortBatchProcessingList];
  }
  return _batchProcessingList;
}

- (void)storeBatchProcessingList {
  if (!_storeBatchList) {
    [self deleteBatchProcessingList];
  }
  if (_storeBatchList && _batchListModified) {
    [self deleteBatchProcessingList];
    [self enumerateBatchProcessingList];
    for (CSDMovieData *movieData in [_batchProcessingList reverseObjectEnumerator]) {
      NSString *dataPath = [[self applicationSupportPath] stringByAppendingPathComponent:movieData.fileName];
      NSString *movieDataPath = [dataPath stringByAppendingPathExtension:@"md"];
      NSMutableData *data = [NSMutableData new];
      NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
      [archiver encodeObject:movieData forKey:@"CSDMovieData"];
      [archiver finishEncoding];
      [data writeToFile:movieDataPath atomically:NO];
    }
  }
  for (CSDMovieData *movieData in [_batchProcessingList reverseObjectEnumerator]) {
    if (movieData.inputFileBookmarkCounter != 0) {
      NSLog(@"%@ Bookmarkcounter=%ld Error!",movieData.fileName,(long)movieData.inputFileBookmarkCounter);
      for (short i = 0; i < movieData.inputFileBookmarkCounter; i++) {
        [movieData stopUsingBookmark];
      }
    }
  }
  _batchListModified = NO;
}

- (void)deleteBatchProcessingList {
  NSError *error;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray <NSString *> *pathArray = [fileManager contentsOfDirectoryAtPath:[self applicationSupportPath] error:&error];
  for (NSString *fileName in pathArray) {
    NSString *lastPathComponent = fileName.lastPathComponent;
    if ([lastPathComponent.pathExtension isEqualToString:@"md"]) {
      NSString *filePath = [[self applicationSupportPath] stringByAppendingPathComponent:fileName];
      BOOL success = [fileManager removeItemAtPath:filePath error:&error];
      if (!success) {
        NSLog(@"Could not delete Batchlistitem Error!");
      }
    }
  }
}

@end
