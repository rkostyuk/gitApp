//
//  RootViewController.m
//  gitApp
//
//  Created by Roman Kostyuk on 1/16/17.
//  Copyright © 2017 Roman Kostyuk. All rights reserved.
//

#import "RootViewController.h"
#import "ViewController.h"
#import "RevealViewController.h"
#import "SWRevealViewController.h"
#import "KeychainWrapper.h"
#import <OCTServer.h>
#import <OCTUser.h>
#import <ReactiveCocoa/RACSignal.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <OCTClient.h>
#import <OCTClient+Events.h>
#import <SVProgressHUD.h>
#import <OCTEvent.h>
#import "EventCell.h"
#import <DateTools.h>
#import <OCTClient+User.h>

@interface RootViewController ()

@property (nonatomic, weak) IBOutlet UIBarButtonItem *revealButtonItem;
@property (nonatomic, weak) IBOutlet UITableView     *tableView;
@property (nonatomic, strong) KeychainWrapper        *keychain;
@property (nonatomic, strong) NSMutableArray         *events;
@property (nonatomic, strong) UIRefreshControl       *refreshControl;
@property (nonatomic, strong) NSString               *rawLogin;
@property (nonatomic, strong) OCTUser                *user;
@property (nonatomic, strong) OCTClient              *client;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Events";
    self.keychain = [[KeychainWrapper alloc] init];
    self.events = [NSMutableArray new];
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController) {
        [self.revealButtonItem setTarget: self.revealViewController];
        [self.revealButtonItem setAction: @selector(revealToggle:)];
        [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];

    }
    
    self.rawLogin = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    self.user = [OCTUser userWithRawLogin:self.rawLogin server:OCTServer.dotComServer];
    self.client = [OCTClient authenticatedClientWithUser:self.user token:[self.keychain myObjectForKey:(__bridge id)(kSecValueData)]];
    
    [self fetchUserInfo];
    [self fetchEvents];
    [self initRefreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeMenu) name:@"CloseMenu" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CloseMenu" object:nil];
}

- (void)initRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.refreshControl.tintColor = [UIColor blackColor];
    [self.refreshControl addTarget:self action:@selector(getLatestEvents) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 10, 0)];
}

- (void)fetchUserInfo {
    RACSignal *request = [self.client fetchUserInfo];
    [[request collect] subscribeNext:^(NSArray *responseObject) {
        [self completeRequestUserInfo:responseObject];
    } error:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)getLatestEvents {
    RACSignal *request = [self.client fetchUserEventsNotMatchingEtag:nil];
    [[request collect] subscribeNext:^(NSArray *responseObject) {
        [self completeRequest:responseObject withSpinner:YES];
    } error:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)fetchEvents {
    self.tableView.hidden = YES;
    [SVProgressHUD show];
    
    RACSignal *request = [self.client fetchUserEventsNotMatchingEtag:nil];
    [[request collect] subscribeNext:^(NSArray *responseObject) {
        [self completeRequest:responseObject withSpinner:NO];
    } error:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)completeRequestUserInfo:(NSArray *)responseObject {
    OCTUser *user = (OCTUser *)responseObject[0];
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    UIImage *imageFromURL = [self getImageFromURL:user.avatarURL];
    [self saveImage:imageFromURL withFileName:@"UserAvatar" ofType:@"jpg" inDirectory:documentsDirectoryPath];
}

- (void)completeRequest:(NSArray *)responseObject withSpinner:(BOOL)isHidden {
    if (!isHidden) {
        [SVProgressHUD dismiss];
    }
    
    if (self.events.count) {
        [self.events removeAllObjects];
    }
    
    [self.events addObjectsFromArray:responseObject];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.tableView.hidden = NO;
        [self.tableView reloadData];
    });
    [self.refreshControl endRefreshing];
}

#pragma mark - TableVew

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.events.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OCTEvent *event = (OCTEvent *)[self.events objectAtIndex:indexPath.row];

    EventCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventCell"];
    
    if (cell == nil) {
        cell = [[EventCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"eventCell"];
    }
    
    cell.date.text = event.date.timeAgoSinceNow;
    cell.eventDescription.text = [self eventDescription:event];
    cell.commitCount.text = [NSString stringWithFormat:@"Commits: %ld", (long)event.commitCount];
    
    return cell;
}

#pragma mark - Utils

- (NSString *)eventDescription:(OCTEvent *)event {
    
    NSString *username = event.actorLogin;
    NSString *userAction = [self userAction:event];
    NSString *repositoryName = event.repositoryName;
    
    return [NSString stringWithFormat:@"%@ %@ at %@", username, userAction, repositoryName];
}

- (NSString *)userAction:(OCTEvent *)event {
    NSString *action;
    if ([event.type isEqualToString:@"CommitCommentEvent"]) {
        action = @"comment commit";
        return action;
    }else if ([event.type isEqualToString:@"CreateEvent"]) {
        action = @"created branch";
        return action;
    }else if ([event.type isEqualToString:@"DeleteEvent"]) {
        action = @"deleted branch";
        return action;
    }else if ([event.type isEqualToString:@"IssueCommentEvent"]) {
        action = @"comment on issue";
        return action;
    }else if ([event.type isEqualToString:@"IssuesEvent"]) {
        action = @"issue";
        return action;
    }else if ([event.type isEqualToString:@"PullRequestEvent"]) {
        action = @"opened pull request";
        return action;
    }else if ([event.type isEqualToString:@"PullRequestReviewCommentEvent"]) {
        action = @"comment pull request";
        return action;
    }else if ([event.type isEqualToString:@"PushEvent"]) {
        action = @"pushed to";
        return action;
    }else {
        action = @"some action";
        return action;
    }
}

- (void)closeMenu {
    [self.revealViewController revealToggleAnimated:NO];
    [[self topMostController] presentViewController:[self returnLoginViewController] animated:YES completion:nil];
}


- (UIViewController *)returnLoginViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
   UIViewController *viewController = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"viewController"];
    return viewController;
}

- (UIViewController*)topMostController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

-(UIImage *)getImageFromURL:(NSURL *)fileURL {
    UIImage *result;
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    result = [UIImage imageWithData:data];
    
    return result;
}

-(void)saveImage:(UIImage *)image withFileName:(NSString *)imageName ofType:(NSString *)extension inDirectory:(NSString *)directoryPath {
    if ([[extension lowercaseString] isEqualToString:@"png"]) {
        [UIImagePNGRepresentation(image) writeToFile:[directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", imageName, @"png"]] options:NSAtomicWrite error:nil];
    } else if ([[extension lowercaseString] isEqualToString:@"jpg"] || [[extension lowercaseString] isEqualToString:@"jpeg"]) {
        [UIImageJPEGRepresentation(image, 1.0) writeToFile:[directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", imageName, @"jpg"]] options:NSAtomicWrite error:nil];
    } else {
        NSLog(@"Image Save Failed\nExtension: (%@) is not recognized, use (PNG/JPG)", extension);
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
