//
//  CapturedData.m
//  CapturePhoto
//
//  Created by Mohammad Ali Yektaie on 9/16/20.
//  Copyright © 2020 Mohammad Ali Yektaie. All rights reserved.
//

#import "CapturedData.h"

@implementation CapturedData

- (NSString*) getPathFor:(CapturedDataContent)content {
    NSString* result = nil;
    
    if (content == Video) {
        result = [self.folder stringByAppendingString:[NSString stringWithFormat:@"video_%d.mp4", self.index]];
    } else if (content == Photo) {
        result = [self.folder stringByAppendingString:[NSString stringWithFormat:@"video_%d.jpg", self.index]];
    } else if (content == DepthMap) {
        result = [self.folder stringByAppendingString:[NSString stringWithFormat:@"depth_%d.jpg", self.index]];
    }
    
    return result;
}

- (NSComparisonResult)compare:(id)object {
    CapturedData* obj = (CapturedData*)object;
    
    int index = obj.index;
    if (index == self.index) {
        return NSOrderedSame;
    } else if (index < self.index) {
        return NSOrderedDescending;
    }
    
    return NSOrderedAscending;
}
@end
