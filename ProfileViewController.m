//
//  ProfileViewController.m
//  gitApp
//
//  Created by Roman Kostyuk on 1/19/17.
//  Copyright © 2017 Roman Kostyuk. All rights reserved.
//

#import "ProfileViewController.h"
#import "SWRevealViewController.h"

@interface ProfileViewController ()

@property (nonatomic, weak) IBOutlet UIBarButtonItem *revealButtonItem;
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet UILabel *username;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *items;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.items = [[NSArray alloc] initWithObjects:@"events", @"organizations", @"repositories", @"gists", nil];
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController) {
        [self.revealButtonItem setTarget: self.revealViewController];
        [self.revealButtonItem setAction: @selector(revealToggle:)];
        [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    }
    [self initAvatar];
    [self initUsername];
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
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [[self.items objectAtIndex:indexPath.row] capitalizedString];
    return cell;
}


- (void)initAvatar {
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    UIImage *image = [self loadImage:@"UserAvatar" ofType:@"jpg" inDirectory:documentsDirectoryPath];
    UIImageView *avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(150, 30, 74, 74)];
    avatarView.contentMode = UIViewContentModeScaleAspectFit;
    avatarView.layer.cornerRadius = avatarView.frame.size.width/2;
    avatarView.layer.borderWidth = 1;
    avatarView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    avatarView.clipsToBounds = YES;
    avatarView.image = image;
    [self.contentView addSubview:avatarView];
}

-(UIImage *)loadImage:(NSString *)fileName ofType:(NSString *)extension inDirectory:(NSString *)directoryPath {
    UIImage *result = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.%@", directoryPath, fileName, extension]];
    return result;
}

- (void)initUsername {
    self.username.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}


@end
