//
//  APIConnector.h
//  allotaxi
//
//  Created by Roman Kostyuk on 5/24/15.
//  Copyright (c) 2015 Roman Kostyuk. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface APIConnector : AFHTTPSessionManager

//+ (NSURLSessionDataTask *)authorization:(NSDictionary *)parameters onSuccess:(void (^)(NSURLSessionDataTask *task, id responseObject))success onFailure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

@end
