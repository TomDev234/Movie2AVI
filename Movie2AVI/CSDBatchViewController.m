//
//  CSDBatchViewController.m
//  Movie2AVI
//
//  Created by Tom on 06.12.16.
//  Copyright © 2016 Thomas Bodlien Software. All rights reserved.
//

#import "CSDBatchViewController.h"
#import "CSDDataController.h"
#import "CSDMovieData.h"

@interface CSDBatchViewController () <NSWindowDelegate,NSTableViewDataSource,NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *mainTableView;
@property (weak) IBOutlet NSOutlineView *mainOutLineView;
@property (weak) IBOutlet NSButton *addButton;
@property (weak) IBOutlet NSButton *deleteButton;
@end

@implementation CSDBatchViewController

- (void)updateUserInterface {
  if ([CSDDataController sharedInstance].isBatchJobActive) {
    _mainTableView.enabled = NO;
    _addButton.enabled = NO;
    _deleteButton.enabled = NO;
  }
  else {
    _mainTableView.enabled = YES;
    _addButton.enabled = YES;
    _deleteButton.enabled = YES;
  }
}

- (void)addFiles {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = YES;
  panel.canChooseDirectories = NO;
  panel.allowsMultipleSelection = YES;
  if ([panel runModal] == NSModalResponseOK) {
    for (NSURL *url in panel.URLs) {
      CSDMovieData *movieData = [CSDMovieData new];
      movieData.fileName = [url lastPathComponent];
      movieData.inputFileURL = url;
      movieData.outputDirectoryURL = [CSDDataController sharedInstance].securityScopedOutputURL;
      movieData.videoQuality = [CSDDataController sharedInstance].videoQuality;
      movieData.audioQuality = [CSDDataController sharedInstance].audioQuality;
      movieData.overwrite = [CSDDataController sharedInstance].overwriteFiles;
      [movieData createBookmark];
      [[CSDDataController sharedInstance].batchProcessingList addObject:movieData];
    }
    [CSDDataController sharedInstance].batchListModified = YES;
    [_mainTableView reloadData];
  }
}

- (void)removeFiles {
  NSIndexSet *indexes = _mainTableView.selectedRowIndexes;
  [[CSDDataController sharedInstance].batchProcessingList removeObjectsAtIndexes:indexes];
  [CSDDataController sharedInstance].batchListModified = YES;
  [_mainTableView reloadData];
}

- (void)clearFiles {
  [[CSDDataController sharedInstance].batchProcessingList removeAllObjects];
  [CSDDataController sharedInstance].batchListModified = YES;
  [_mainTableView reloadData];
}

- (void)requestMovieURL:(NSInteger)clickedRow column:(NSInteger)clickedColumn {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = YES;
  panel.canChooseDirectories = NO;
  panel.allowsMultipleSelection = NO;
  if ([panel runModal] == NSModalResponseOK) {
    [self replaceMovie:panel.URL row:clickedRow column:clickedColumn];
  }
}

- (void)replaceMovie:(NSURL *)url row:(NSUInteger)row column:(NSUInteger)column {
  CSDMovieData *movieData = [CSDMovieData new];
  movieData.fileName = [url lastPathComponent];
  movieData.inputFileURL = url;
  movieData.outputDirectoryURL = [CSDDataController sharedInstance].securityScopedOutputURL;
  movieData.videoQuality = [CSDDataController sharedInstance].videoQuality;
  movieData.audioQuality = [CSDDataController sharedInstance].audioQuality;
  movieData.overwrite = [CSDDataController sharedInstance].overwriteFiles;
  [movieData createBookmark];
  [[CSDDataController sharedInstance].batchProcessingList replaceObjectAtIndex:row withObject:movieData];
  NSTableCellView *cellView = [_mainTableView viewAtColumn:0 row:_mainTableView.selectedRow makeIfNecessary:YES];
  cellView.textField.stringValue = movieData.fileName;
  NSIndexSet *rowIndexes = [NSIndexSet indexSetWithIndex:row];
  NSIndexSet *columnIndexes = [NSIndexSet indexSetWithIndex:column];
  [_mainTableView reloadDataForRowIndexes:rowIndexes columnIndexes:columnIndexes];
  [CSDDataController sharedInstance].batchListModified = YES;
}

#pragma mark - Window

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupTableView];
}

- (void)viewDidAppear {
  [super viewDidAppear];
  [CSDDataController sharedInstance].batchWindowOpen = YES;
}

- (void)viewDidDisappear {
  [super viewDidDisappear];
  [CSDDataController sharedInstance].batchWindowOpen = NO;
}

#pragma mark - TableView

- (void)setupTableView {
  _mainTableView.doubleAction = @selector(tableViewDoubleAction:);
  _mainTableView.verticalMotionCanBeginDrag = YES;
  _mainTableView.draggingDestinationFeedbackStyle = NSTableViewDraggingDestinationFeedbackStyleRegular;
  [_mainTableView registerForDraggedTypes:[NSArray arrayWithObject:@"public.text"]];
}

- (void)tableViewDoubleAction:(id)sender {
  NSTableView *tableView = sender;
  switch (tableView.clickedColumn) {
    case 0: {
      [self requestMovieURL:tableView.clickedRow column:tableView.clickedColumn];
    }
      break;
  }
}

- (void)selectTableViewRow:(NSUInteger)row {
  NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:row];
  [_mainTableView selectRowIndexes:indexes byExtendingSelection:NO];
}

- (void)reArrangeTableViewRows:(NSTableView *)tableView sourceRow:(NSUInteger)sourceRow targetRow:(NSUInteger)targetRow {
  CSDMovieData *movieData = [CSDDataController sharedInstance].batchProcessingList[sourceRow];
  [[CSDDataController sharedInstance].batchProcessingList insertObject:movieData atIndex:targetRow];
  if (sourceRow < targetRow)
    [[CSDDataController sharedInstance].batchProcessingList removeObjectAtIndex:sourceRow];
  else
    [[CSDDataController sharedInstance].batchProcessingList removeObjectAtIndex:sourceRow + 1];
  [tableView reloadData];
}

#pragma mark - NSTableView

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray<NSTableColumn *> *)tableColumns event:(NSEvent *)dragEvent offset:(NSPointPointer)dragImageOffset {
  NSImage *dragImage = [NSImage imageNamed:@"Movie2AVIIcon"];
  return dragImage;
}

- (BOOL)canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint {
  return YES;
}

- (void)setDraggingSourceOperationMask:(NSDragOperation)mask forLocal:(BOOL)isLocal {
  
}

- (void)setDropRow:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
  
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [CSDDataController sharedInstance].batchProcessingList.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSTableCellView *cellView;
  cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
  CSDMovieData *movieData = [[CSDDataController sharedInstance].batchProcessingList objectAtIndex:row];
  movieData.integerValue = row;
  cellView.textField.stringValue = movieData.fileName;
  return cellView;
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
  CSDMovieData *movieData = [[CSDDataController sharedInstance].batchProcessingList objectAtIndex:row];
  NSString *identifier = movieData.fileName;
  NSPasteboardItem *pasteboardItem = [NSPasteboardItem new];
  [pasteboardItem setString:identifier forType: @"public.text"];
  return pasteboardItem;
}

//- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
//  BOOL returnCode;
//
//  NSPasteboard *pasteboard = [info draggingPasteboard];
//  NSString *title = [pasteboard stringForType:@"public.text"];
//  NSTreeNode *sourceNode;
//
//  for(NSTreeNode *b in [targetItem childNodes]){
//    if ([[[b representedObject] title] isEqualToString:title]){
//      sourceNode = b;
//    }
//  }
//
//  if(!sourceNode){
//    // Not found
//    returnCode = NO;
//  }
//  else {
//
//  NSUInteger indexArr[] = {0,index};
//  NSIndexPath *toIndexPATH =[NSIndexPath indexPathWithIndexes:indexArr length:2];
//
//  [self.booksController moveNode:sourceNode toIndexPath:toIndexPATH];
//
//  returnCode = YES;
//  }
//  return returnCode;
//}

//- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
//
//  BOOL canDrag = index >= 0 && targetItem;
//
//  if (canDrag) {
//    return NSDragOperationMove;
//  }else {
//    return NSDragOperationNone;
//  }
//}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
  return NO;
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes {
  
}

- (void)tableView:(NSTableView *)tableView updateDraggingItemsForDrag:(id<NSDraggingInfo>)draggingInfo {
  
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
  
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors {
  
}

#pragma mark - NSTableViewDelegate

- (BOOL)tableView:(NSTableView *)tableView shouldReorderColumn:(NSInteger)columnIndex toColumn:(NSInteger)newColumnIndex {
  return NO;
}

- (void)tableView:(NSTableView *)tableView didDragTableColumn:(NSTableColumn *)tableColumn {
  
}

- (void)tableViewColumnDidMove:(NSNotification *)notification {
  
}

- (void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn {
  
}

#pragma mark - Actions

- (IBAction)addButtonPressed:(id)sender {
  [self addFiles];
}

- (IBAction)deleteButtonPressed:(id)sender {
  [self removeFiles];
}

- (IBAction)clearButtonPressed:(id)sender {
  [self clearFiles];
}

@end
