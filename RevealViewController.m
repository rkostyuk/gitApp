//
//  RevealViewController.m
//  gitApp
//
//  Created by Roman Kostyuk on 1/17/17.
//  Copyright © 2017 Roman Kostyuk. All rights reserved.
//

#import "RevealViewController.h"

@interface RevealViewController ()

@end

@implementation RevealViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self customizeSlideOutMenu];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)customizeSlideOutMenu {
    self.frontViewPosition = FrontViewPositionLeft;
    //    self.revealViewController.rearViewRevealWidth = 290.0f;
    self.rearViewRevealOverdraw = 0.0f;
    self.bounceBackOnOverdraw = NO;
    
    // TOGGLING MENU DISPLACEMENT: how much displacement is applied to the menu when animating or dragging the content
    self.rearViewRevealDisplacement = 60.0f;
    
    // TOGGLING ANIMATION: Configure the animation while the menu gets hidden
    self.toggleAnimationType = SWRevealToggleAnimationTypeSpring;
    self.toggleAnimationDuration = 0.4f;
    self.springDampingRatio = 1.0f;
    
    // SHADOW: Configure the shadow that appears between the menu and content views
    self.frontViewShadowRadius = 10.0f;
    self.frontViewShadowOffset = CGSizeMake(0.0f, 2.5f);
    self.frontViewShadowOpacity = 0.8f;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
