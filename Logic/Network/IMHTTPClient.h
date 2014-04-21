//
//  PMHTTPClient.h
//  Pandume
//
//  Created by Mario Yohanes on 6/20/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "AFHTTPClient.h"
#import "AFNetworking.h"


@interface IMHTTPClient : AFHTTPClient

+ (IMHTTPClient *)sharedClient;
- (void)setNewBaseURL;

+ (void)setNewURL;
- (void)getJSONWithPath:(NSString *)path
             parameters:(NSDictionary *)parameters
                success:(void (^)(NSDictionary *jsonData, int statusCode))success
                failure:(void (^)(NSError *))failure;

- (void)postJSONWithPath:(NSString *)path
              parameters:(NSDictionary *)parameters
                 success:(void (^)(NSDictionary *jsonData, int statusCode))success
                 failure:(void (^)(NSDictionary *jsonData, NSError *error, int statusCode))failure;

- (void)getPhotoWithId:(NSString *)photoId
               success:(void (^)(NSData *imageData))success
               failure:(void (^)(NSError *error))failure;

- (void)setupAuthenticationHeader;



@end
