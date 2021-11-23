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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    self.view.backgroundColor = [UIColor whiteColor];

}
- (IBAction)onClickOfCaptureVideoButton:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    CapturePhotoViewController *cpvc = [storyboard instantiateViewControllerWithIdentifier:@"CapturePhotoViewController"];
    [self.navigationController pushViewController:cpvc animated:YES];
    
}



@end
