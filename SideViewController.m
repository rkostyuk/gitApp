//
//  RevealViewController.m
//  gitApp
//
//  Created by Roman Kostyuk on 1/16/17.
//  Copyright © 2017 Roman Kostyuk. All rights reserved.
//

#import "SideViewController.h"
#import "RootViewController.h"
#import "KeychainWrapper.h"
#import <OCTUser.h>
#import <OCTClient.h>
#import <OCTServer.h>
#import <ReactiveCocoa/RACSignal.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <OCTEntity.h>
#import <OCTClient+User.h>


@interface SideViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak)   IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *items;

@end

@implementation SideViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.items = [[NSArray alloc] initWithObjects:@"profile", @"repositories", @"issues", @"events", @"logout", nil];
    self.title = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier = [self.items objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = [[self.items objectAtIndex:indexPath.row] capitalizedString];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 4) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CloseMenu" object:nil];
        [self removePasswordFromKeychain];
    }
}

- (void)removePasswordFromKeychain {
    KeychainWrapper *keychain = [[KeychainWrapper alloc] init];
    [keychain resetKeychainItem];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    UINavigationController *destViewController = (UINavigationController*)segue.destinationViewController;
    destViewController.title = [[self.items objectAtIndex:indexPath.row] capitalizedString];
}


@end
