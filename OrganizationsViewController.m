//
//  OrganizationsViewController.m
//  gitApp
//
//  Created by Roman Kostyuk on 1/19/17.
//  Copyright © 2017 Roman Kostyuk. All rights reserved.
//

#import "OrganizationsViewController.h"
#import "KeychainWrapper.h"
#import <OCTServer.h>
#import <OCTUser.h>
#import <ReactiveCocoa/RACSignal.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <OCTClient.h>
#import <OCTClient+Organizations.h>
#import <SVProgressHUD.h>
#import <OCTOrganization.h>


@interface OrganizationsViewController ()

@property (nonatomic, weak) IBOutlet UITableView     *tableView;
@property (nonatomic, strong) KeychainWrapper        *keychain;
@property (nonatomic, strong) NSMutableArray         *orgs;
@property (nonatomic, strong) UIRefreshControl       *refreshControl;
@property (nonatomic, strong) NSString               *rawLogin;
@property (nonatomic, strong) OCTUser                *user;
@property (nonatomic, strong) OCTClient              *client;

@end

@implementation OrganizationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.keychain = [[KeychainWrapper alloc] init];
    self.orgs = [NSMutableArray new];
    
    self.rawLogin = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    self.user = [OCTUser userWithRawLogin:self.rawLogin server:OCTServer.dotComServer];
    self.client = [OCTClient authenticatedClientWithUser:self.user token:[self.keychain myObjectForKey:(__bridge id)(kSecValueData)]];
    
    [self fetchOrganizations];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)initRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.refreshControl.tintColor = [UIColor blackColor];
    [self.refreshControl addTarget:self action:@selector(getLatestOrganizations) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 10, 0)];
}

- (void)getLatestOrganizations {
    RACSignal *request = [self.client fetchUserOrganizations];
    [[request collect] subscribeNext:^(NSArray *responseObject) {
        [self completeRequest:responseObject withSpinner:YES];
    } error:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)fetchOrganizations {
    self.tableView.hidden = YES;
    [SVProgressHUD show];

    RACSignal *request = [self.client fetchUserOrganizations];
    [[request collect] subscribeNext:^(NSArray *responseObject) {
        [self completeRequest:responseObject withSpinner:NO];
    } error:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)completeRequest:(NSArray *)responseObject withSpinner:(BOOL)isHidden {
    if (!isHidden) {
        [SVProgressHUD dismiss];
    }
    
    if (self.orgs.count > 0) {
        [self.orgs removeAllObjects];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.title = @"No Organizations";
            self.tableView.hidden = NO;
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
        });
    }
    [self.orgs addObjectsFromArray:responseObject];
}

#pragma mark - TableVew

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.orgs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OCTOrganization *org = (OCTOrganization *)[self.orgs objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"orgCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"orgCell"];
    }
    cell.textLabel.text = org.name;
    
    return cell;
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
