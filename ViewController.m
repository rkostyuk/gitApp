//
//  ViewController.m
//  gitApp
//
//  Created by Roman Kostyuk on 1/16/17.
//  Copyright © 2017 Roman Kostyuk. All rights reserved.
//

#import "KeychainWrapper.h"
#import "ViewController.h"
#import "RevealViewController.h"
#import "OCTUser.h"
#import "OCTClient.h"
#import "OCTServer.h"
#import <ReactiveCocoa/RACSignal.h>
#import <SVProgressHUD.h>

static  NSString *secretID     = @"02318aa34d850753abb8";
static  NSString *secretClient = @"61071a304f090e042850bf017a1fc73f032e7d7f";
static  NSString *accessToken  = @"8a6ecfbe57dc78f9dd40da56810cbb59dc7473b8";

@interface ViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *username;
@property (nonatomic, weak) IBOutlet UITextField *password;
@property (nonatomic, weak) IBOutlet UIButton    *loginButton;
@property (nonatomic, weak) IBOutlet UILabel     *usernameLabel;
@property (nonatomic, weak) IBOutlet UILabel     *passwordLabel;
@property (nonatomic, strong) KeychainWrapper    *keychain;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Login";
    self.keychain = [[KeychainWrapper alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.alpha = 1.0;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)login:(id)sender {
    [self dismissKeyboard];
    [SVProgressHUD show];

    self.view.userInteractionEnabled = NO;
    self.view.alpha = 0.7;
    
    NSString *username = self.username.text;
    NSString *password = self.password.text;
    
    OCTUser *user = [OCTUser userWithRawLogin:username server:OCTServer.dotComServer];
    [OCTClient setClientID:secretID clientSecret:secretClient];
    
    [[OCTClient signInAsUser:user password:password oneTimePassword:nil scopes:OCTClientAuthorizationScopesUser]
     subscribeNext:^(OCTClient *authenticatedClient) {
         [SVProgressHUD dismiss];
         self.view.userInteractionEnabled = YES;
         [self auth:authenticatedClient];
     } error:^(NSError *error) {
         self.view.userInteractionEnabled = YES;
         [SVProgressHUD dismiss];
         [self errorMessage:@"Incorrect login or password"];
     }];
}

- (void)auth:(OCTClient *)client {
    if (client.isAuthenticated) {
        [self setTokenToKeychain];
        [self setUsernameToDefaults];
        [self presentViewController:[self returnRevealViewController] animated:YES completion:nil];
    }
}

- (void)dismissKeyboard {
    [self.username resignFirstResponder];
    [self.password resignFirstResponder];
}

- (void)errorMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController  alertControllerWithTitle:@"Error!" message:message
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"ОК" style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action) {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];
    
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.view.alpha = 1.0;
    });
}

- (RevealViewController *)returnRevealViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RevealViewController *viewController = (RevealViewController *)[storyboard instantiateViewControllerWithIdentifier:@"revealViewController"];
    return viewController;
}

- (void)setTokenToKeychain {
    [self.keychain mySetObject:accessToken forKey:(__bridge id)(kSecValueData)];
}

- (void)setUsernameToDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.username.text forKey:@"username"];
    [defaults synchronize];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

@end
