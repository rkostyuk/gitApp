//
//  IssueDescriptionController.m
//  gitApp
//
//  Created by Roman Kostyuk on 1/20/17.
//  Copyright © 2017 Roman Kostyuk. All rights reserved.
//

#import "DescriptionController.h"
#import <SVProgressHUD.h>

@interface DescriptionController () <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;

@end

@implementation DescriptionController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = nil;
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.URL]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [SVProgressHUD show];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [SVProgressHUD dismiss];
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
