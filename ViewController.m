//
//  ViewController.m
//  gitApp
//
//  Created by Roman Kostyuk on 1/16/17.
//  Copyright © 2017 Roman Kostyuk. All rights reserved.
//

#import "ViewController.h"
#import "RootViewController.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UITextView *username;
@property (nonatomic, weak) IBOutlet UITextView *password;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Login View";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
