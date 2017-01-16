//
//  APIClient.h
//  gitApp
//
//  Created by Roman Kostyuk on 1/16/17.
//  Copyright © 2017 Roman Kostyuk. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface APIClient : AFHTTPSessionManager

+ (instancetype)sharedClient;

@end
