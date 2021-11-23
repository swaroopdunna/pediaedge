//
//  CapturePhotoView.h
//  CapturePhoto
//
//  Created by Mohammad Ali Yektaie on 9/14/20.
//  Copyright © 2020 Mohammad Ali Yektaie. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SwiftCapturePhotoView;
@protocol ISwiftCapturePhotoViewListener;

@protocol ICapturePhotoViewListener <NSObject>

- (void)onRecordingStarted;
- (void)onRecordingStopped: (NSArray* _Nonnull)files;
- (void)onError:(NSString *_Nonnull)title withMessage:(NSString *_Nonnull)message;
- (void)onPreviewLoad;
- (void)onCloseModule;

@end

NS_ASSUME_NONNULL_BEGIN

@interface CapturePhotoView : UIView <ISwiftCapturePhotoViewListener>

@property (strong, atomic) SwiftCapturePhotoView* content;
@property (weak, atomic) id<ICapturePhotoViewListener> delegate;

- (void) onContainerResume;
- (void) onContainerPause;
- (void)onRecordingStarted;
- (void)onRecordingStopped;
- (void)onErrorWithTitle:(NSString *)title message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
