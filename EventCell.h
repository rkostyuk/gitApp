//
//  EventCell.h
//  gitApp
//
//  Created by Roman Kostyuk on 1/17/17.
//  Copyright © 2017 Roman Kostyuk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *date;
@property (nonatomic, weak) IBOutlet UILabel *eventDescription;
@property (nonatomic, weak) IBOutlet UILabel *commitCount;

@end
