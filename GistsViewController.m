//
//  GistsViewController.m
//  gitApp
//
//  Created by Roman Kostyuk on 1/19/17.
//  Copyright © 2017 Roman Kostyuk. All rights reserved.
//

#import "GistsViewController.h"
#import "KeychainWrapper.h"
#import <OCTServer.h>
#import <OCTUser.h>
#import <ReactiveCocoa/RACSignal.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <OCTClient.h>
#import <OCTClient+Gists.h>
#import <SVProgressHUD.h>
#import <OCTGist.h>


@interface GistsViewController ()

@property (nonatomic, strong) KeychainWrapper  *keychain;
@property (nonatomic, strong) NSMutableArray   *gists;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSString         *rawLogin;
@property (nonatomic, strong) OCTUser          *user;
@property (nonatomic, strong) OCTClient        *client;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation GistsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.gists = [NSMutableArray new];
    self.keychain = [[KeychainWrapper alloc] init];
    self.rawLogin = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    self.user = [OCTUser userWithRawLogin:self.rawLogin server:OCTServer.dotComServer];
    self.client = [OCTClient authenticatedClientWithUser:self.user token:[self.keychain myObjectForKey:(__bridge id)(kSecValueData)]];
    
    [self fetchGists];
    [self initRefreshControl];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)initRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.refreshControl.tintColor = [UIColor blackColor];
    [self.refreshControl addTarget:self action:@selector(getLatestGists) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 10, 0)];
}

- (void)getLatestGists {
    RACSignal *request = [self.client fetchGists];
    [[request collect] subscribeNext:^(NSArray *responseObject) {
        [self completeRequest:responseObject withSpinner:YES];
    } error:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)fetchGists {
    self.tableView.hidden = YES;
    [SVProgressHUD show];
    
    RACSignal *request = [self.client fetchGists];
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
    
    if (self.gists.count) {
        [self.gists removeAllObjects];
    }
    
    [self.gists addObjectsFromArray:responseObject];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.tableView.hidden = NO;
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    });
}

#pragma mark - TableVew

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.gists.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OCTGist *gist = (OCTGist *)[self.gists objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"gistCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"gistCell"];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", gist.HTMLURL];
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
