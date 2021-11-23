//
//  CapturePhotoView.m
//  CapturePhoto
//
//  Created by Mohammad Ali Yektaie on 9/14/20.
//  Copyright © 2020 Mohammad Ali Yektaie. All rights reserved.
//

#import "CapturePhotoView.h"
#import <tflite_photos_example-Swift.h>
#import "CapturedData.h"

#define FOLDER_NAME  @"temp_capture"

@implementation CapturePhotoView

- (id)init {
    self = [super init];
    
    self.content = [SwiftCapturePhotoView new];
    [self.content setupWithListener:self];
    [self addSubview:self.content];
    
    return self;
}

- (void) layoutSubviews {
    CGRect frame = self.frame;
    self.content.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    
    [super layoutSubviews];
}

- (void) onContainerResume {
    [self.content onContainerResume];
}

- (void) onContainerPause {
    [self.content onContainerPause];
}

- (void)onRecordingStarted {
    if (self.delegate != nil) {
        [self.delegate onRecordingStarted];
    }
}

- (void)onRecordingStopped {
    if (self.delegate != nil) {
        NSMutableArray* files = [[NSMutableArray alloc] init];
        NSArray* fileInPath = [self getFilesInFolder:FOLDER_NAME];
        NSString* folder = [[FileSystem getFolderURLInDocuments:FOLDER_NAME] absoluteString];
        
        BOOL hasDepth = NO; // This method is correct with the assumption of AVCaptureDataOutputSynchronizer
        for (int i = 0; i < fileInPath.count; i++) {
            NSString* file = [[fileInPath objectAtIndex:i] absoluteString];
            
            NSRange range = [file rangeOfString:@"video_"];
            if (range.location > 0 && range.location != NSNotFound) {
                NSString* indexStr = [file substringFromIndex:range.location + 6];
                indexStr = [indexStr substringToIndex:indexStr.length - 4];
                
                CapturedData* entry = [[CapturedData alloc] init];
                
                entry.folder = folder;
                entry.index = [indexStr intValue];
                entry.type = PhotoRGB;
                
                [files addObject:entry];
            }
            
            range = [file rangeOfString:@"depth_"];
            if (range.location > 0 && range.location != NSNotFound) {
                hasDepth = YES;
            }
        }
        
        if (hasDepth) {
            for (int i = 0; i < files.count; i++) {
                CapturedData* entry = [files objectAtIndex:i];
                entry.type = PhotoRGBD;
            }
        }
        
        files = [self sortFilesList:files];
        [self.delegate onRecordingStopped:files];
    }
}

- (NSArray*)sortFilesList:(NSArray*)files {
    return [files sortedArrayUsingSelector:@selector(compare:)];
}
    
- (void)onPreviewLoad {
    if (self.delegate != nil) {
        [self.delegate onPreviewLoad];
    }
}

- (void)onCloseModule {
    if (self.delegate != nil) {
        [self.delegate onCloseModule];
    }
}

- (void)onErrorWithTitle:(NSString *)title message:(NSString *)message {
    if (self.delegate != nil) {
        [self.delegate onError:title withMessage:message];
    }
}

- (NSArray*)getFilesInFolder:(NSString*)name {
    NSURL *folder = [FileSystem getFolderURLInDocuments:name];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    return [fileManager contentsOfDirectoryAtURL:folder includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
}

@end
