//
//  CapturePhotoViewController.m
//  CapturePhotoTester
//
//  Created by Narendar N on 16/11/21.
//  Copyright © 2021 Mohammad Ali Yektaie. All rights reserved.
//

#import "CapturePhotoViewController.h"
#import "CapturePhoto/CapturePhoto/CapturePhoto.h"
#import "CameraExampleViewController.h"
@interface CapturePhotoViewController ()

@end

@implementation CapturePhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.captureView = [[CapturePhotoView alloc] init];
    self.captureView.delegate = self;
    [self.view addSubview:self.captureView];
    
    [self.view setNeedsLayout];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}
- (void)viewDidLayoutSubviews {
    self.captureView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [super viewDidLayoutSubviews];
}

- (void) viewDidAppear:(BOOL)animated {
    [self.captureView onContainerResume];
}

-(void) viewWillDisappear:(BOOL)animated {
    [self.captureView onContainerPause];
}

- (void)onRecordingStarted {
    self.title = @"Recording";
}

- (void)onRecordingStopped: (NSArray* )files; {
    self.title = @"Record Capture Tester";
//    [self onError:@"Recording Completed" withMessage:[NSString stringWithFormat:@"Your recording stored %d images with depth data on device internal memory.", (int)files.count]];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Recording Completed"
                               message:[NSString stringWithFormat:@"Your recording stored %d images with depth data on device internal memory.", (int)files.count]
                               preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        CameraExampleViewController *cpvc = [storyboard instantiateViewControllerWithIdentifier:@"CameraExampleViewController"];
        [self.navigationController pushViewController:cpvc animated:YES];

    }];

    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];

    
    

    
}

- (void)onError:(NSString *_Nonnull)title withMessage:(NSString *_Nonnull)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    
    }];
    [alert addAction: okButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onPreviewLoad {
    NSLog(@"onPreviewLoad - callback");
}

- (void)onCloseModule {
    NSLog(@"onCloseModule - callback");
}
@end
