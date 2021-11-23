//
//  CapturePhotoViewController.h
//  CapturePhotoTester
//
//  Created by Narendar N on 16/11/21.
//  Copyright © 2021 Mohammad Ali Yektaie. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CapturePhotoView;
@protocol ICapturePhotoViewListener;

NS_ASSUME_NONNULL_BEGIN

@interface CapturePhotoViewController : UIViewController<ICapturePhotoViewListener>

@property (strong, atomic) CapturePhotoView* captureView;


@end

NS_ASSUME_NONNULL_END
