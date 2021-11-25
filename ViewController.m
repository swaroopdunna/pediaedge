//
//  ViewController.m
//  CapturePhotoTester
//
//  Created by Mohammad Ali Yektaie on 9/2/20.
//  Copyright © 2020 Mohammad Ali Yektaie. All rights reserved.
//

#import "ViewController.h"
#import "CapturePhotoViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *captureButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.captureButton setTitle:@"Capture Video" forState:UIControlStateNormal];
    [self.captureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.captureButton.backgroundColor = [UIColor colorWithRed:207.0/255.0 green:95.0/255.0 blue:15.0/255.0 alpha:1.0];
    self.captureButton.tintColor = [UIColor whiteColor];

}
- (IBAction)onClickOfCaptureVideoButton:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    CapturePhotoViewController *cpvc = [storyboard instantiateViewControllerWithIdentifier:@"CapturePhotoViewController"];
    [self.navigationController pushViewController:cpvc animated:YES];
    
}



@end
