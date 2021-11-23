//
//  CapturedData.h
//  CapturePhoto
//
//  Created by Mohammad Ali Yektaie on 9/16/20.
//  Copyright © 2020 Mohammad Ali Yektaie. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum CapturedDataType {
    VideoRecording,
    PhotoRGB,
    PhotoRGBD
} CapturedDataType;

typedef enum CapturedDataContent {
    Video,
    Photo,
    DepthMap
} CapturedDataContent;

@interface CapturedData : NSObject

@property (strong) NSString* folder;
@property (nonatomic, assign) int index;
@property (nonatomic, assign) enum CapturedDataType type;

- (NSString*) getPathFor:(CapturedDataContent)content;
- (NSComparisonResult)compare:(id)object;

@end

NS_ASSUME_NONNULL_END
