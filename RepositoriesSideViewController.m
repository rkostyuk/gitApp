//
//  RepositoriesSideViewController.m
//  gitApp
//
//  Created by Roman Kostyuk on 1/19/17.
//  Copyright © 2017 Roman Kostyuk. All rights reserved.
//

#import "RepositoriesSideViewController.h"
#import "SWRevealViewController.h"
#import "KeychainWrapper.h"
#import <OCTServer.h>
#import <OCTUser.h>
#import <ReactiveCocoa/RACSignal.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <OCTClient.h>
#import <OCTClient+Repositories.h>
#import <OCTClient+Events.h>
#import <SVProgressHUD.h>
#import <OCTRepository.h>


@interface RepositoriesSideViewController () <UISearchBarDelegate, UISearchResultsUpdating>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *revealButtonItem;
@property (nonatomic, strong) KeychainWrapper    *keychain;
@property (nonatomic, strong) NSMutableArray     *allItems;
@property (nonatomic, strong) NSMutableArray     *displayedItems;
@property (nonatomic, strong) NSMutableArray     *filteredItems;
@property (nonatomic, strong) UIRefreshControl   *refreshControl;
@property (nonatomic, strong) NSString           *rawLogin;
@property (nonatomic, strong) OCTUser            *user;
@property (nonatomic, strong) OCTClient          *client;
@property (strong, nonatomic) UISearchController *searchController;

@end

@implementation RepositoriesSideViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Repositories";
    
    self.keychain = [[KeychainWrapper alloc] init];
    self.allItems = [NSMutableArray new];
    self.filteredItems = [[NSMutableArray alloc] init];
    self.allItems = [[NSMutableArray alloc] init];
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController) {
        [self.revealButtonItem setTarget: self.revealViewController];
        [self.revealButtonItem setAction: @selector(revealToggle:)];
        [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    }

    self.rawLogin = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    self.user = [OCTUser userWithRawLogin:self.rawLogin server:OCTServer.dotComServer];
    self.client = [OCTClient authenticatedClientWithUser:self.user token:[self.keychain myObjectForKey:(__bridge id)(kSecValueData)]];
    
    [self fetchRepositories];
    [self initRefreshControl];
    [self initSearchController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)initRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.refreshControl.tintColor = [UIColor blackColor];
    [self.refreshControl addTarget:self action:@selector(fetchLatesRepositories) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 10, 0)];
}

- (void)fetchLatesRepositories {
    RACSignal *request = [self.client fetchUserRepositories];
    [[request collect] subscribeNext:^(NSArray *responseObject) {
        [self completeRequest:responseObject withSpinner:YES];
    } error:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)fetchRepositories {
    self.tableView.hidden = YES;
    [SVProgressHUD show];
    
    RACSignal *request = [self.client fetchUserRepositories];
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
    
    if (self.allItems.count > 0) {
        [self.allItems removeAllObjects];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.tableView.hidden = NO;
            [self.tableView reloadData];
        });
    }
    [self.allItems addObjectsFromArray:responseObject];
    self.displayedItems = self.allItems;
    [self.refreshControl endRefreshing];
}

#pragma mark - TableVew

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.displayedItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OCTRepository *repo = (OCTRepository *)[self.displayedItems objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"repoCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"repoCell"];
    }
    cell.textLabel.text = repo.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Owner: %@", repo.ownerLogin];
    cell.detailTextLabel.textColor = [UIColor blueColor];
    
    return cell;
}

#pragma mark - Search Controller

- (void)initSearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    [self.searchController.searchBar sizeToFit];
    [self.tableView setContentOffset:CGPointMake(0, self.searchController.searchBar.frame.size.height)];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)aSearchController {
    
    NSString *searchString = aSearchController.searchBar.text;
    
    if (![searchString isEqualToString:@""]) {
        [self.filteredItems removeAllObjects];
        for (OCTRepository *repo in self.allItems) {
            if ([searchString isEqualToString:@""] || [repo.name localizedCaseInsensitiveContainsString:searchString] == YES) {
                [self.filteredItems addObject:repo];
            }
        }
        self.displayedItems = self.filteredItems;
    }
    else {
        self.displayedItems = self.allItems;
    }
    [self.tableView reloadData];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
