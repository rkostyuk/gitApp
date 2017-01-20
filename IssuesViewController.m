//
//  IssuesViewController.m
//  gitApp
//
//  Created by Roman Kostyuk on 1/19/17.
//  Copyright © 2017 Roman Kostyuk. All rights reserved.
//

#import "IssuesViewController.h"
#import "DescriptionController.h"
#import "SWRevealViewController.h"
#import "KeychainWrapper.h"
#import <OCTServer.h>
#import <OCTUser.h>
#import <ReactiveCocoa/RACSignal.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <OCTClient.h>
#import <OCTIssueCommentEvent.h>
#import <SVProgressHUD.h>
#import <OCTIssue.h>
#import <OCTRepository.h>
#import <OCTClient+Private.h>
#import <OCTClient+Repositories.h>
#import <RACSignal+OCTClientAdditions.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface IssuesViewController () <UISearchBarDelegate, UISearchResultsUpdating>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *revealButtonItem;
@property (nonatomic, strong) NSMutableArray     *allItems;
@property (nonatomic, strong) NSMutableArray     *displayedItems;
@property (nonatomic, strong) NSMutableArray     *filteredItems;
@property (nonatomic, strong) NSMutableArray     *repos;
@property (nonatomic, strong) UIRefreshControl   *refreshControl;

@property (nonatomic, strong) KeychainWrapper    *keychain;
@property (nonatomic, strong) NSString           *rawLogin;
@property (nonatomic, strong) OCTUser            *user;
@property (nonatomic, strong) OCTClient          *client;
@property (strong, nonatomic) UISearchController *searchController;

@end

@implementation IssuesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Issues/Pull Requests";
    
    self.keychain = [[KeychainWrapper alloc] init];
    self.allItems = [NSMutableArray new];
    self.filteredItems = [[NSMutableArray alloc] init];
    self.allItems = [[NSMutableArray alloc] init];
    self.repos = [[NSMutableArray alloc] init];
    
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
    [self.refreshControl addTarget:self action:@selector(fetchLatesIssues) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 10, 0)];
}

- (void)fetchRepositories {
    [SVProgressHUD show];
    self.tableView.hidden = YES;
    self.revealButtonItem.enabled = NO;
    RACSignal *request = [self.client fetchUserRepositories];
    [[request collect] subscribeNext:^(NSArray *responseObject) {
        [self completeRequestRepos:responseObject];
        [self fetchIssuesFromServer];
    } error:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)fetchLatesIssues {
    [self fetchIssuesFromServer];
}

- (void)completeRequestRepos:(NSArray *)responseObject {
    [self.repos addObjectsFromArray:responseObject];
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
            self.revealButtonItem.enabled = YES;
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
    
    OCTIssue *issue = (OCTIssue *)[self.displayedItems objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"issueCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"issueCell"];
    }
    if (issue.pullRequest) {
        NSLog(@"%@", issue.pullRequest);
        cell.textLabel.text = issue.title;
        cell.detailTextLabel.text = @"PULL";
    }else{
        cell.textLabel.text = issue.title;
        cell.detailTextLabel.text = @"ISSUE";
    }
    
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
        for (OCTIssue *issue in self.allItems) {
            if ([searchString isEqualToString:@""] || [issue.title localizedCaseInsensitiveContainsString:searchString] == YES) {
                [self.filteredItems addObject:issue];
            }
        }
        self.displayedItems = self.filteredItems;
    }
    else {
        self.displayedItems = self.allItems;
    }
    [self.tableView reloadData];
}

- (void)fetchIssuesFromServer {
    NSURLRequest *request;
    RACSignal *requestSignal;
    
    for (OCTRepository *repo in self.repos) {
        request = [self.client requestWithMethod:@"GET" path:[NSString stringWithFormat:@"/repos/%@/%@/issues", self.rawLogin, repo.name] parameters:nil];
        requestSignal = [[self.client enqueueRequest:request resultClass:OCTIssue.class] oct_parsedResults];
        
        [[requestSignal collect] subscribeNext:^(NSArray *responseObject) {
            if (responseObject.count > 0) {
                [self completeRequest:responseObject withSpinner:NO];
            }
        } error:^(NSError *error) {
            NSLog(@"%@", error);
        }];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DescriptionController *descriptionController = [segue destinationViewController];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    OCTIssue *issue = [self.displayedItems objectAtIndex:indexPath.row];
    descriptionController.URL = issue.HTMLURL;
}

@end
